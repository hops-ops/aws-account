# configuration-aws-account

Create and manage individual AWS Organizations member accounts. This is a low-level building block - most users should use the Organization XRD with inline accounts instead.

## When to Use This Directly

**Use Organization XRD (recommended):**
- Creating accounts as part of your org hierarchy
- Want accounts placed in specific OUs automatically
- Managing multiple accounts together

**Use Account XRD directly:**
- Creating accounts outside the Organization XRD
- Advanced scenarios requiring per-account control
- Programmatic account vending (account factory)

## How It Works

When you create an account via AWS Organizations:
1. AWS creates the account with the specified email
2. AWS automatically creates `OrganizationAccountAccessRole` in the new account
3. This role trusts the management account, enabling cross-account access
4. You can assume this role to manage resources in the new account

## Basic Usage

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: Account
metadata:
  name: team-platform-dev
  namespace: default
spec:
  email: platform-dev@acme.example.com  # Must be unique across all AWS
  parentId: ou-abc1-workloads           # OU ID or root ID (r-xxxx)
  providerConfigRef:
    name: management                    # Management account ProviderConfig
    kind: ProviderConfig
  managementPolicies: ["*"]

  tags:
    team: platform
    environment: dev
```

## Import Existing Account

Already have an account? Import it with `externalName`:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: Account
metadata:
  name: legacy-prod
  namespace: default
spec:
  externalName: "123456789012"  # Existing account ID
  email: legacy-prod@acme.example.com
  parentId: ou-abc1-prod
  providerConfigRef:
    name: management
    kind: ProviderConfig
  # Don't delete if removed from Crossplane
  managementPolicies: ["Create", "Observe", "Update", "LateInitialize"]
```

## Attach Service Control Policies

SCPs restrict what actions accounts can perform - use them for guardrails:

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: Account
metadata:
  name: team-sandbox
  namespace: default
spec:
  email: sandbox@acme.example.com
  parentId: ou-abc1-sandbox
  providerConfigRef:
    name: management
    kind: ProviderConfig

  # Attach SCPs for guardrails
  policyAttachments:
    - arn:aws:organizations::111111111111:policy/o-abc123/service_control_policy/p-deny-root
    - arn:aws:organizations::111111111111:policy/o-abc123/service_control_policy/p-region-restrict

  tags:
    environment: sandbox
    cost-center: engineering
```

## Status

The Account exposes the information needed for cross-account access:

```yaml
status:
  accountId: "123456789012"
  organizationAccountAccessRoleArn: arn:aws:iam::123456789012:role/OrganizationAccountAccessRole
  ready: true
```

## Cross-Account Access

Create a ProviderConfig that assumes the `OrganizationAccountAccessRole`:

```yaml
apiVersion: aws.m.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: team-platform-dev
spec:
  assumeRoleChain:
    - roleARN: arn:aws:iam::123456789012:role/OrganizationAccountAccessRole
  credentials:
    source: PodIdentity  # Or Secret, IRSA
```

Then reference it in resources:

```yaml
apiVersion: s3.aws.m.upbound.io/v1beta1
kind: Bucket
spec:
  providerConfigRef:
    name: team-platform-dev  # Creates bucket in the team's account
  forProvider:
    region: us-east-1
```

## Account Factory Pattern

For programmatic account creation, you can template Account resources:

```yaml
# Create accounts from a list
{{ range $team := .teams }}
---
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: Account
metadata:
  name: {{ $team.name }}-{{ $team.environment }}
  namespace: default
spec:
  email: {{ $team.name }}-{{ $team.environment }}@acme.example.com
  parentId: {{ if eq $team.environment "prod" }}ou-abc1-prod{{ else }}ou-abc1-nonprod{{ end }}
  providerConfigRef:
    name: management
    kind: ProviderConfig
  tags:
    team: {{ $team.name }}
    environment: {{ $team.environment }}
{{ end }}
```

## Recommendations

1. **Use Organization XRD for most cases** - It handles OU placement and keeps your hierarchy visible
2. **Always set tags** - Include team, environment, and cost-center for billing
3. **Use unique emails** - AWS requires globally unique emails; use `+` addressing if needed (aws+prod@acme.com)
4. **Don't delete production accounts** - Use `managementPolicies` without Delete to orphan on removal
5. **Account deletion takes 90 days** - AWS Organizations account closure is not immediate

## Development

```bash
make render              # Render example
make test                # Run tests
make validate            # Validate compositions
```

## License

Apache-2.0
