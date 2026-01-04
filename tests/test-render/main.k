import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_composition = "apis/accounts/composition.yaml"
_xrd = "apis/accounts/definition.yaml"

# =============================================================================
# Test: Default providerConfigRef values
# When providerConfigRef is not specified, it should default to name="default", kind="ProviderConfig"
# =============================================================================
_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-default-provider-config-ref"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-defaults"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-defaults"
                    spec: {
                        providerConfigRef: {
                            name: "default"
                            kind: "ProviderConfig"
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Custom providerConfigRef is honored
# When providerConfigRef is specified, those values should be used
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-custom-provider-config-ref"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-custom-provider"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                    providerConfigRef: {
                        name: "my-custom-provider"
                        kind: "ProviderConfig"
                    }
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-custom-provider"
                    spec: {
                        providerConfigRef: {
                            name: "my-custom-provider"
                            kind: "ProviderConfig"
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Tags merge with default hops tag
# User-provided tags should merge with the default {"hops": "true"} tag
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-tags-merge-with-default"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-tags"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                    tags: {team: "platform", environment: "dev"}
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-tags"
                    spec: {
                        forProvider: {
                            tags: {
                                hops: "true"
                                team: "platform"
                                environment: "dev"
                            }
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: No tags still gets default hops tag
# When no tags are provided, the default {"hops": "true"} is applied
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-default-hops-tag-when-no-tags"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-no-tags"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-no-tags"
                    spec: {
                        forProvider: {
                            tags: {
                                hops: "true"
                            }
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: External name annotation for importing existing accounts
# When externalName is set, the crossplane.io/external-name annotation is added
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-external-name-annotation-for-import"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "imported-account"
                spec = {
                    externalName: "999888777666"
                    email: "existing@example.com"
                    parentId: "ou-abc1-12345678"
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "imported-account"
                        annotations: {
                            "crossplane.io/external-name": "999888777666"
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Account renders with basic fields when not importing
# This test verifies the Account renders correctly without externalName
# (Negative assertions for missing annotations aren't well-supported in KCL tests)
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-account-renders-without-external-name"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "new-account"
                spec = {
                    email: "new@example.com"
                    parentId: "r-root123"
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "new-account"
                    spec: {
                        forProvider: {
                            name: "new-account"
                            email: "new@example.com"
                            parentId: "r-root123"
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Default management policies
# When managementPolicies is not specified, it defaults to ["*"]
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-default-management-policies"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-mgmt-policies"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-mgmt-policies"
                    spec: {
                        managementPolicies: ["*"]
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Custom management policies are honored
# When managementPolicies is specified, those values should be used
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-custom-management-policies"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-observe-only"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                    managementPolicies: ["Observe"]
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-observe-only"
                    spec: {
                        managementPolicies: ["Observe"]
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Policy attachments don't render before account is ready
# PolicyAttachments should NOT render on initial claim (no observed resources)
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-policy-attachments-not-rendered-before-account-ready"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-scp-wait"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                    policyAttachments: [
                        "arn:aws:organizations::111111111111:policy/o-example/p-deny-root"
                    ]
                }
            }
            observedResources: []
            # Only Account should render, not PolicyAttachment
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-scp-wait"
                }
            ]
        }
    },

# =============================================================================
# Test: Policy attachments render after account is ready
# PolicyAttachments should render once the Account is observed as Ready
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-policy-attachments-render-after-account-ready"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-scp-ready"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                    providerConfigRef: {
                        name: "mgmt-aws"
                        kind: "ProviderConfig"
                    }
                    policyAttachments: [
                        "arn:aws:organizations::111111111111:policy/o-example/p-deny-root"
                    ]
                }
            }
            observedResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "test-scp-ready"
                        annotations: {
                            "crossplane.io/composition-resource-name": "member-account"
                        }
                    }
                    status: {
                        conditions: [{type: "Ready", status: "True"}]
                        atProvider: {id: "123456789012"}
                    }
                }
            ]
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-scp-ready"
                },
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "PolicyAttachment"
                    metadata.name: "test-scp-ready-p-deny-root"
                    spec: {
                        providerConfigRef: {
                            name: "mgmt-aws"
                            kind: "ProviderConfig"
                        }
                        forProvider: {
                            policyId: "arn:aws:organizations::111111111111:policy/o-example/p-deny-root"
                            targetId: "123456789012"
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Multiple policy attachments
# Multiple SCPs should each get their own PolicyAttachment resource
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-multiple-policy-attachments"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-multi-scp"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                    policyAttachments: [
                        "arn:aws:organizations::111111111111:policy/o-example/p-deny-root"
                        "arn:aws:organizations::111111111111:policy/o-example/p-require-mfa"
                    ]
                }
            }
            observedResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "test-multi-scp"
                        annotations: {
                            "crossplane.io/composition-resource-name": "member-account"
                        }
                    }
                    status: {
                        conditions: [{type: "Ready", status: "True"}]
                        atProvider: {id: "555666777888"}
                    }
                }
            ]
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "PolicyAttachment"
                    metadata.name: "test-multi-scp-p-deny-root"
                    spec: {
                        forProvider: {
                            policyId: "arn:aws:organizations::111111111111:policy/o-example/p-deny-root"
                            targetId: "555666777888"
                        }
                    }
                },
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "PolicyAttachment"
                    metadata.name: "test-multi-scp-p-require-mfa"
                    spec: {
                        forProvider: {
                            policyId: "arn:aws:organizations::111111111111:policy/o-example/p-require-mfa"
                            targetId: "555666777888"
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Usage resource renders after PolicyAttachment is ready
# Usage protects Account from deletion while PolicyAttachment exists
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-usage-renders-after-policy-attachment-ready"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-usage"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                    policyAttachments: [
                        "arn:aws:organizations::111111111111:policy/o-example/p-deny-root"
                    ]
                }
            }
            observedResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "test-usage"
                        annotations: {
                            "crossplane.io/composition-resource-name": "member-account"
                        }
                    }
                    status: {
                        conditions: [{type: "Ready", status: "True"}]
                        atProvider: {id: "111222333444"}
                    }
                },
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "PolicyAttachment"
                    metadata: {
                        name: "test-usage-p-deny-root"
                        annotations: {
                            "crossplane.io/composition-resource-name": "policy-attachment-p-deny-root"
                        }
                    }
                    status: {
                        conditions: [{type: "Ready", status: "True"}]
                    }
                }
            ]
            assertResources: [
                {
                    apiVersion: "protection.crossplane.io/v1beta1"
                    kind: "Usage"
                    metadata.name: "test-usage-usage-p-deny-root"
                    spec: {
                        replayDeletion: True
                        by: {
                            apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                            kind: "PolicyAttachment"
                            resourceRef.name: "test-usage-p-deny-root"
                        }
                        of: {
                            apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                            kind: "Account"
                            resourceRef.name: "test-usage"
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Status output includes accountId and role ARN
# When account is observed, status should reflect account details
# Note: XR status assertions use metadata.name matching the XR name
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-status-output"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-status"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                }
            }
            observedResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "test-status"
                        annotations: {
                            "crossplane.io/composition-resource-name": "member-account"
                        }
                    }
                    status: {
                        conditions: [{type: "Ready", status: "True"}]
                        atProvider: {id: "777888999000"}
                    }
                }
            ]
            assertResources: [
                {
                    apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                    kind: "Account"
                    metadata.name: "test-status"
                    status: {
                        ready: True
                        accountId: "777888999000"
                        organizationAccountAccessRoleArn: "arn:aws:iam::777888999000:role/OrganizationAccountAccessRole"
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Status shows not ready when account not ready
# When account is not Ready, status.ready should be false
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-status-not-ready"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-not-ready"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                }
            }
            observedResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "test-not-ready"
                        annotations: {
                            "crossplane.io/composition-resource-name": "member-account"
                        }
                    }
                    status: {
                        conditions: [{type: "Ready", status: "False"}]
                        atProvider: {}
                    }
                }
            ]
            assertResources: [
                {
                    apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                    kind: "Account"
                    metadata.name: "test-not-ready"
                    status: {
                        ready: False
                        accountId: ""
                        organizationAccountAccessRoleArn: ""
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: forProvider pass-through overrides template defaults
# Fields in spec.forProvider should be passed through to the Account resource
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-forprovider-passthrough"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-passthrough"
                spec = {
                    email: "test@example.com"
                    parentId: "r-root123"
                    forProvider: {
                        closeOnDeletion: True
                        iamUserAccessToBilling: "ALLOW"
                    }
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-passthrough"
                    spec: {
                        forProvider: {
                            name: "test-passthrough"
                            email: "test@example.com"
                            parentId: "r-root123"
                            closeOnDeletion: True
                            iamUserAccessToBilling: "ALLOW"
                        }
                    }
                }
            ]
        }
    },

# =============================================================================
# Test: Account uses OU as parentId (not just root)
# parentId can be an OU ID, not just root ID
# =============================================================================
    metav1alpha1.CompositionTest{
        metadata.name: "test-ou-parent-id"
        spec = {
            compositionPath: _composition
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            xr = {
                apiVersion: "aws.hops.ops.com.ai/v1alpha1"
                kind: "Account"
                metadata.name: "test-in-ou"
                spec = {
                    email: "test@example.com"
                    parentId: "ou-abc1-12345678"
                }
            }
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata.name: "test-in-ou"
                    spec: {
                        forProvider: {
                            parentId: "ou-abc1-12345678"
                        }
                    }
                }
            ]
        }
    }
]

items = _items
