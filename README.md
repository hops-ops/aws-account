# configuration-account

`configuration-account` is a Crossplane configuration package that provisions AWS Organizations member accounts. It creates a new account within an existing organizational unit, optionally attaches Service Control Policies, and automatically generates an IAM user with a ProviderConfig for immediate Crossplane access to the new account.

## Highlights

- **Simple member account creation** – Creates AWS Organizations member accounts within a specified parent (root or OU).
- **Automatic IAM access** – Generates an IAM user in the management account with credentials stored in a Secret, ready to assume the `OrganizationAccountAccessRole` in the new account.
- **ProviderConfig ready** – Emits a fully configured `aws.m.upbound.io/v1beta1, Kind=ProviderConfig` using assumeRoleChain for immediate use with other Crossplane resources.
- **SCP attachments** – Optionally attach Service Control Policies to the account for governance.
- **Status projection** – Surfaces the provisioned `accountId`, `adminRoleArn`, IAM user details, and ProviderConfig name on the composite status.

## Spec

```yaml
apiVersion: aws.hops.ops.com.ai/v1alpha1
kind: Account
metadata:
  name: team-platform-dev
  namespace: hops
spec:
  email: platform-dev@mycompany.com     # required: unique AWS account email
  parentId: r-1234                      # required: Organizations root or OU ID
  providerConfigName: management-aws    # optional: management account ProviderConfig (default: "default")
  managementPolicies: ["*"]             # optional: Crossplane propagation controls
  policyAttachments:                    # optional: list of SCP ARNs
    - arn:aws:organizations::111111111111:policy/o-example/p-deny-root
  tags:                                 # optional: AWS tags (automatically includes "hops: true")
    team: platform
    environment: dev
  providerConfig:                       # optional: customize generated ProviderConfig
    name: custom-name                   # override ProviderConfig name (default: account name)
    secretNamespace: custom-ns          # override Secret namespace (default: account namespace)
```

The account name (from `metadata.name`) becomes the AWS account name unless customized. The configuration creates an IAM user named `crossplane-{account-name}` in the management account and stores credentials in a Secret named `{account-name}-aws-credentials`.

## Status

```yaml
status:
  accountId: "123456789012"
  adminRoleArn: "arn:aws:iam::123456789012:role/OrganizationAccountAccessRole"
  providerConfigName: "team-platform-dev"
  iamUserName: "crossplane-team-platform-dev"
  credentialsSecretName: "team-platform-dev-aws-credentials"
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

See `examples/accounts/example.yaml` for a ready-to-render member account spec. Run `make render-example` to render the example.

## Development

| Command            | Description                                       |
|--------------------|---------------------------------------------------|
| `make render-example` | Runs `up composition render` for the default example |
| `make validate`    | Validates the XRD + examples with `up xrd validate`    |
| `make test`        | Executes all `up test run tests/*` suites          |

Variables are hoisted in `functions/render/00-desired-values.yaml.gotmpl`. The composition follows the standard Hops pattern with desired values, observed resources (for status projection), and conditional resource rendering based on readiness.
