
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_composition = "apis/accounts/composition.yaml"
_xrd = "apis/accounts/definition.yaml"

_account_observation = {
    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
    kind: "Account"
    metadata: {
        name: "team-platform-dev"
        annotations: {
            "gotemplating.fn.crossplane.io/composition-resource-name": "member-account"
            "crossplane.io/composition-resource-name": "member-account"
        }
    }
    status: {
        conditions: [
            {
                type: "Ready"
                status: "True"
            }
        ]
        atProvider: {
            id: "123456789012"
            email: "platform-dev@mycompany.com"
        }
    }
}

_items = [
    metav1alpha1.CompositionTest{
        metadata.name: "test-basic-account-rendering"
        spec = {
            compositionPath: _composition
            xrPath: "examples/accounts/standard.yaml"
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            observedResources: []
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "team-platform-dev"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "management-aws"
                            kind: "ProviderConfig"
                        }
                        forProvider: {
                            name: "team-platform-dev"
                            email: "platform-dev@mycompany.com"
                            parentId: "r-1234"
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
    metav1alpha1.CompositionTest{
        metadata.name: "test-account-with-observed-resources"
        spec = {
            compositionPath: _composition
            xrPath: "examples/accounts/standard.yaml"
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            observedResources: [
                _account_observation
            ]
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "team-platform-dev"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "management-aws"
                            kind: "ProviderConfig"
                        }
                        forProvider: {
                            name: "team-platform-dev"
                            email: "platform-dev@mycompany.com"
                            parentId: "r-1234"
                            tags: {
                                hops: "true"
                                team: "platform"
                                environment: "dev"
                            }
                        }
                    }
                },
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "PolicyAttachment"
                    metadata: {
                        name: "team-platform-dev-p-deny-root"
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "management-aws"
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
    metav1alpha1.CompositionTest{
        metadata.name: "test-account-import-with-external-name"
        spec = {
            compositionPath: _composition
            xrPath: "examples/accounts/import.yaml"
            xrdPath: _xrd
            timeoutSeconds: 180
            validate: True
            observedResources: []
            assertResources: [
                {
                    apiVersion: "organizations.aws.m.upbound.io/v1beta1"
                    kind: "Account"
                    metadata: {
                        name: "imported-account"
                        annotations: {
                            "crossplane.io/external-name": "123456789012"
                        }
                    }
                    spec: {
                        managementPolicies: ["*"]
                        providerConfigRef: {
                            name: "management-aws"
                            kind: "ProviderConfig"
                        }
                        forProvider: {
                            name: "imported-account"
                            email: "existing-account@mycompany.com"
                            parentId: "ou-abc1-12345678"
                            tags: {
                                hops: "true"
                                team: "platform"
                                environment: "prod"
                            }
                        }
                    }
                }
            ]
        }
    }
]
items = _items
