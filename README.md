# configuration-aws-account

Crossplane configuration for AWS Organizations member accounts. Creates accounts and attaches SCPs.

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
  policyAttachments:                    # optional: list of SCP ARNs
    - arn:aws:organizations::111111111111:policy/o-example/p-deny-root
  tags:                                 # optional: AWS tags (automatically includes "hops: true")
    team: platform
    environment: dev
```

## Status

```yaml
status:
  accountId: "123456789012"
  organizationAccountAccessRoleArn: "arn:aws:iam::123456789012:role/OrganizationAccountAccessRole"
  ready: true
```

## Cross-Account Access

To manage resources in the new account, create a ProviderConfig that assumes the `OrganizationAccountAccessRole`:

```yaml
apiVersion: aws.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: team-platform-dev
spec:
  credentials:
    source: PodIdentity
  assumeRoleChain:
    - roleARN: arn:aws:iam::123456789012:role/OrganizationAccountAccessRole
```

Then reference it in other resources:

```yaml
spec:
  providerConfigRef:
    name: team-platform-dev
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
