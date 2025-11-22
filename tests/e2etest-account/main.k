import base64
import datetime
import file
import math
import models.ai.com.ops.hops.aws.v1alpha1 as awsv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1

_now = str(int(math.floor(datetime.ticks())))
_composite_name = "e2e-account-" + _now
_provider_config_name = "e2e-account-provider-" + _now
_email_prefix = "hops-e2e-account-" + _now
_ou_suffix = "testing/e2e-" + _now

_creds = file.read("secrets/aws-creds")
_base64_creds = base64.encode(_creds)

_items = [
    metav1alpha1.E2ETest{
        metadata.name: ""
        spec= {
            crossplane.autoUpgrade.channel: "Rapid"
            defaultConditions: ["Ready"]
            manifests: [
                awsv1alpha1.Account{
                    metadata: {
                        name: _composite_name
                        namespace: "default"
                    }
                    spec: {
                        providerConfigName: _provider_config_name
                        managementPolicies: ["*"]
                        parameters: {
                            name: "Hops E2E Account " + _now
                            emailPrefix: _email_prefix
                            emailDomain: "example.com"
                            ouPath: "root/" + _ou_suffix
                            tags: {
                                purpose: "e2e"
                            }
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
                        name: _provider_config_name
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
items= _items
