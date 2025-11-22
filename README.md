# configuration-account

`configuration-account` is the Crossplane configuration package that vends AWS Organizations accounts for Hops. It is the single public entrypoint for creating both root and workload accounts: it bootstraps (or observes) the org, builds OU hierarchies, provisions member accounts, wires any requested SCP attachments, and immediately exposes a ready-to-use AWS `ProviderConfig`.

## Highlights

- **Org-first workflow** – Creates (or observes) the Organizations root once, then ensures caller-requested OU paths exist before any member accounts render unless you pass a `parentId` override.
- **Managed/self modes** – `spec.managementMode` toggles whether we expect Hops to operate the account (`managed`) or hand it over after provisioning (`self`).
- **Automatic ProviderConfigs** – Every account emits an `aws.m.upbound.io/v1beta1, Kind=ProviderConfig` that points at the new account and assumes the standard `OrganizationAccountAccessRole`.
- **Account baseline handoff** – As soon as the member account is ready we emit the private `AccountBaseline` composite so GuardDuty, Security Hub, Config, and other controls flip on (or stay off for sandbox environments).
- **Status projection** – Surfaces the provisioned `accountId`, `orgId`, `adminRoleArn`, and ProviderConfig name directly on the composite.

## Spec

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: Account
metadata:
  name: acme-prod
spec:
  providerConfigName: management-aws
  managementMode: self            # default self, or "managed"
  managementPolicies: ["*"]       # optional Crossplane propagation controls
  parameters:
    name: "Acme Production"       # AWS account display name
    emailPrefix: acme-prod-2025   # becomes acme-prod-2025@<emailDomain>
    emailDomain: accounts.example.com   # optional, defaults to example.com
    email: prod-account@acme.com        # optional explicit address
    ouPath: root/workloads/prod/acme-prod # creates OU path if needed; "root" bootstraps the org
    parentId: ou-abc123example      # optional – skip OU creation and place account directly
    environment: prod             # root | sandbox | dev | prod | tenant | testing (default dev)
    policyAttachments:            # optional list of SCP ARNs
      - arn:aws:organizations::111111111111:policy/o-example/p-deny-root
    tags:
      team: platform
```

When `emailDomain` is omitted we append the prefix to `example.com`. You can also pass `parameters.email` to override the full address if needed.
The `environment` flag only drives the baseline feature toggles (GuardDuty, Security Hub, Config) so you can keep sandboxes lightweight without impacting production accounts.

## Status

```yaml
status:
  accountId: "123456789012"
  orgId: "o-1a2b3c4d5e"
  providerConfigName: "acme-prod"
  adminRoleArn: "arn:aws:iam::123456789012:role/OrganizationAccountAccessRole"
  ready: true
```

## Dependencies

This configuration depends on the following Crossplane packages (see `apis/accounts/configuration.yaml` for exact versions):

- `provider-aws-organizations`
- `provider-aws-iam`
- `provider-aws-iamidentitycenter` (for future integrations)
- `provider-aws-ram` (for sharing)
- `function-auto-ready`

## Examples

See `examples/accounts/` for ready-to-render specs covering the common environments (root bootstrap, prod, sandbox/testing). Run `make render-example` to render `examples/accounts/example-member.yaml`.

## Development

| Command            | Description                                       |
|--------------------|---------------------------------------------------|
| `make render-example` | Runs `up composition render` for the default example |
| `make validate`    | Validates the XRD + examples with `up xrd validate`    |
| `make test`        | Executes all `up test run tests/*` suites          |

Follow the plan in `docs/plan/01-account-xrd.md`; hoist variables in `functions/render/00-desired-values.yaml.gotmpl`, keep SCPs isolated, and prefer the IRSA-style observable/resource separation for future usage gating.
