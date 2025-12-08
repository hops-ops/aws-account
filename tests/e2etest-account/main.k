import base64
import datetime
import file
import math
import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_now = str(int(math.floor(datetime.ticks())))

_creds = file.read("secrets/aws-creds")
_base64_creds = base64.encode(_creds)

# =============================================================================
# Test configuration
# =============================================================================

# Test OU - use the existing OU in the hops organization
_test_ou_id = "ou-hdvp-fbcb7sbw"

# Persistent test account - shared with configuration-aws-organization, imported each run
_test_account_name = "configuration-aws-organization"
_test_account_id = "544051101726"
_test_account_email = "configuration-aws-organization@ops.com.ai"

_items = [
    metav1alpha1.E2ETest{
        metadata.name: ""
        spec = {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                awsv1alpha1.Account{
                    metadata: {
                        name: _test_account_name
                        namespace: "default"
                    }
                    spec: {
                        externalName: _test_account_id
                        email: _test_account_email
                        parentId: _test_ou_id
                        # Orphan on delete - AWS accounts cannot be deleted via API
                        managementPolicies: ["Create", "Observe", "Update", "LateInitialize"]
                        tags: {
                            "e2etest": "true"
                            "test-run": _now
                        }
                    }
                }
            ]
            extraResources: [
                {
                    apiVersion: "v1"
                    kind: "Secret"
                    metadata: {
                        name: "aws-creds"
                        namespace: "default"
                    }
                    data: {
                        creds: _base64_creds
                    }
                },
                {
                    apiVersion: "aws.m.upbound.io/v1beta1"
                    kind: "ProviderConfig"
                    metadata: {
                        name: "default"
                        namespace: "default"
                    }
                    spec: {
                        credentials: {
                            source: "Secret"
                            secretRef: {
                                namespace: "default"
                                name: "aws-creds"
                                key: "creds"
                            }
                        }
                    }
                }
            ]
            skipDelete: False
            timeoutSeconds: 4500
        }
    }
]
items = _items
