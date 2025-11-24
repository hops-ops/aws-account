# Account Config Agent Guide

This repository publishes the `Account` configuration package for creating AWS Organizations member accounts. It observes an existing AWS Organization, creates member accounts, and emits ProviderConfigs for assumed-role access.

**Key Design Philosophy**: Keep it simple. This XRD does ONE thing - create member accounts. Organization creation is manual/separate, OU management is deferred to v2, baseline security is a separate concern.

## Repository Layout

- `apis/accounts/` — XRD, composition, and packaging metadata
- `examples/accounts/` — Minimal specs (dev, prod, test accounts)
- `functions/render/` — Go-template pipeline with numeric ordering for readability
- `tests/` — KCL-based render tests; e2e tests when live org testing is needed
- `.github/`, `.gitops/` — CI/CD workflows mirroring cert-manager pattern
- `_output/`, `.up/` — Generated artifacts; `make clean` to remove

## What This XRD Does (v1 Scope)

**Creates**:
- Member accounts in an existing AWS Organization
- ProviderConfig for assumed-role access via OrganizationAccountAccessRole
- Optional SCP attachments

**Does NOT Create**:
- AWS Organizations (user creates manually)
- Organizational Units (deferred to v2)
- Baseline security resources (separate account-baseline XRD)

## The Organization Observation Pattern

**Critical Learning**: Each Account XR creates its own Organization resource to observe the AWS org.

### Why?
- Multiple Accounts in the same namespace would conflict if they used the same Organization resource name
- Each Account needs the organization root ID to place the member account
- Solution: Each Account creates uniquely-named Organization resource: `org-observed-by-{account-name}`

### The Pattern
```gotmpl
# 01-observed-organization.yaml.gotmpl
apiVersion: organizations.aws.m.upbound.io/v1beta1
kind: Organization
metadata:
  name: {{ printf "org-observed-by-%s" $name }}  # Unique per Account!
spec:
  managementPolicies: ["Observe", "LateInitialize"]
  forProvider:
    featureSet: ALL  # Required even for Observe-only
```

**Why both Observe AND LateInitialize?**
- `Observe` - Read the existing organization, get status
- `LateInitialize` - Populate unspecified spec fields from AWS (useful for full resource representation)
- For pure observation you could use just `Observe`, but `LateInitialize` is harmless and may help with edge cases

**Why forProvider with Observe?**
- Schema validation requires `forProvider` even for observe-only resources
- Set `featureSet: ALL` to match what AWS returns

### The Flow
1. User creates AWS org manually: `aws organizations create-organization --feature-set ALL`
2. User creates Account XR
3. Composition renders Organization resource (observe-only) with unique name
4. Extracts `status.atProvider.roots[0].id` → `$organizationRootId`
5. Uses that as `parentId` when creating the member account

## Rendering Guidelines

### Variable Hoisting
- **ALL** spec values go in `00-desired-values.yaml.gotmpl`
- **ALL** observed state goes in `02-observed-values.yaml.gotmpl`
- Later templates ONLY reference these hoisted variables
- Never inline `$xr.spec.email` in render templates - always use `$email`

### Template Ordering
```
00-desired-values.yaml.gotmpl   # Extract spec values
01-observed-organization.yaml.gotmpl  # Observe org (always rendered)
02-observed-values.yaml.gotmpl  # Extract observed state
20-account.yaml.gotmpl          # Create account (gated on org ready)
30-scp-attachments.yaml.gotmpl  # Attach SCPs (gated on account ready)
40-providerconfig.yaml.gotmpl   # Create ProviderConfig (gated on account ready)
99-status.yaml.gotmpl           # Project status fields
```

**Numeric gaps**: Leave room between numbers (10, 20, 30) for future insertions without renaming.

### Conditional Rendering
Always gate resources on observed state being ready:

```gotmpl
{{ if and $organizationReady $organizationRootId }}
---
# Render account only when org is ready and we have root ID
{{ end }}
```

### AWS Tags Pattern
```gotmpl
{{ $defaultTags := dict "hops" "true" }}
{{ $tags := merge $defaultTags ($spec.tags | default (dict)) }}
```
Always include `hops: true`, merge with user tags.

### Keep It Simple
- Inline ARN construction: `printf "arn:aws:iam::%s:role/%s" $accountId $roleName`
- No complex maps or ternaries unless absolutely necessary
- Human readability > cleverness

## Testing

### Render Tests
- Live in `tests/test-render/main.k`
- Provide observed resources (Organization with roots, Account with ID)
- Assert partial manifests - only check what matters
- Don't snapshot full resources - templates must evolve

**Example observed resource**:
```kcl
_org_observation = {
    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
    kind: "Organization"
    metadata: {
        name: "org-observed-by-team-platform-dev"
        annotations: {
            "gotemplating.fn.crossplane.io/composition-resource-name": "organization"
            "crossplane.io/composition-resource-name": "organization"
        }
    }
    status: {
        conditions: [{type: "Ready", status: "True"}]
        atProvider: {
            id: "o-example123"
            roots: [{id: "r-abc123"}]  # This is what we need!
        }
    }
}
```

### Common Test Gotchas
- `targetId` in PolicyAttachment depends on observed account ID - don't assert it or type mismatches occur
- Account ID must be string in observed resources: `"123456789012"` not `123456789012`
- Include both annotation keys: `gotemplating.fn.crossplane.io/composition-resource-name` AND `crossplane.io/composition-resource-name`

### Running Tests
```bash
make build    # Regenerates test models from XRD
make test     # Runs render tests
make validate # Schema validation
```

## Design Evolution & Lessons Learned

### What We Tried
1. **Complex OU path parsing** - Automatic OU creation from paths like `root/workloads/prod`
   - **Problem**: Conflicts when multiple accounts have overlapping paths
   - **Decision**: Removed for v1, defer to separate OU management

2. **emailPrefix + emailDomain** - Build emails from two fields
   - **Problem**: Over-engineered, users just want to specify email directly
   - **Decision**: Single `email` field

3. **rootAccount flag** - Flag to create organization vs member account
   - **Problem**: XRD tried to do too much, organization creation is special
   - **Decision**: Manual org creation, XRD only creates members

4. **Shared Organization resource** - Single org resource all Accounts reference
   - **Problem**: Naming conflicts with multiple Accounts in same namespace
   - **Decision**: Each Account creates uniquely-named observation resource

5. **Remove LateInitialize** - Only use Observe
   - **Testing**: Both work, LateInitialize is harmless and might help edge cases
   - **Decision**: Keep both for completeness

### The "Suspicious Code" Journey
Early implementation had this pattern:
```gotmpl
{{ if not $isRootPath }}
  {{ $organizationManagementPolicies = list "Observe" "LateInitialize" }}
{{ end }}
```

This looked suspicious because:
- Member accounts observed Organization to get root ID
- Seemed like each account was creating duplicate resources

**The Insight**: This pattern is CORRECT for the use case:
- Each Account needs org root ID
- Multiple Accounts in same namespace need unique resource names
- All observe the same AWS org, but each has its own k8s resource
- This is necessary and intentional, not a bug!

### Key Takeaways
1. **Simple > Complex**: Every layer of abstraction we removed made it clearer
2. **One Thing Well**: Don't combine organization creation + member creation + baseline
3. **Explicit > Implicit**: Require manual org creation, don't auto-discover everything
4. **Think in Namespaces**: Multiple XRs in same namespace must have unique resource names
5. **Observe is Powerful**: You can observe the same AWS resource from multiple k8s resources

## Prerequisites for Users

1. **AWS Organization must exist**:
   ```bash
   aws organizations create-organization --feature-set ALL
   aws organizations list-roots  # Note the root ID for debugging
   ```

2. **Crossplane provider configured** with management account credentials

3. **That's it!** No OU setup, no baseline, just org + credentials.

## Common Issues

### "Organization not found"
- User didn't create AWS org manually
- Wrong AWS credentials (not management account)
- Organization in different region (orgs are global but creds matter)

### "Multiple Accounts not working"
- Check each Account creates uniquely-named org observation: `org-observed-by-{name}`
- All should observe successfully and get same root ID

### "Account not being created"
- Check Organization observation is Ready: `kubectl get organization`
- Account won't render until `$organizationReady && $organizationRootId`
- Check composition function logs

## Future Enhancements (v2+)

**Deferred but designed for**:
- Account type profiles (team-dev, team-prod, sandbox, etc.) with preset SCPs/tags
- OU management (separate XRD or integrated with selector)
- Landing Zone XRD (creates full account structure)
- Integration with account-baseline XRD

**Don't add these without user request** - ship simple first, add complexity when needed.

## References

- Root repository guidelines: `/CLAUDE.md`
- Plan document: `docs/plan/01-account-xrd.md`
- Reference implementations: `configuration-cert-manager`, `configuration-aws-irsa`
- AWS Organizations API: https://docs.aws.amazon.com/organizations/

---

**Remember**: Less is more. Optimize for clarity and simplicity over feature completeness.
