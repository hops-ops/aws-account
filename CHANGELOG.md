### What's changed in v0.19.0

* chore: file-based env vars for e2e tests (#27) (by @patrickleet)

  * feat: use file-based env vars for e2e tests

  Replace hardcoded AWS account IDs, subnet IDs, and other
  environment-specific values with file.read("env/...") pattern.
  CI writes env files from GitHub repo variables (${{ vars.* }}).
  Workflow versions updated to v2.19.1 + feat/kcl-env-files.

  Implements [[tasks/e2e-env-vars-via-files]]

  * chore: use e2e workflow v2.19.1 (released)

  Update e2e workflow ref from feat/kcl-env-files to v2.19.1.

  * feat: add TEST_ACCOUNT_NAME and TEST_ACCOUNT_EMAIL env vars

  Implements [[tasks/e2e-env-vars-via-files]]

  * chore: add write-env-files: true for explicit env file opt-in

  * fix: remove duplicate e2e workflow refs

* feat(deps): update crossplane-contrib/function-auto-ready docker tag to v0.6.3 (#30) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>


See full diff: [v0.18.0...v0.19.0](https://github.com/hops-ops/aws-account/compare/v0.18.0...v0.19.0)
