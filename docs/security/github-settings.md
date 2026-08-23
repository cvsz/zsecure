# GitHub Repository Security Settings Baseline

These settings are repository/account controls and cannot be proven solely from source files. Apply and periodically verify them in GitHub repository settings.

## `main` protection / ruleset

Require pull requests before merge with at least one approving review, dismiss stale approvals after new commits, require review from Code Owners, require conversation resolution, and require the current CI/security checks before merge. Do not allow force-pushes or branch deletion. Administrators should be subject to the same rules except for documented emergency recovery.

Required checks should include the current jobs produced by:

- `CI / repository-baseline`
- `security / test-and-scan`
- `installer-validation / validate-installer`
- `codeql / analyze`
- `Dependency Review / dependency-review`
- `container-security / image-scan`

## Security features

Enable and verify:

- Private vulnerability reporting.
- Dependabot alerts.
- Dependabot security updates.
- Secret scanning.
- Push protection for secrets.
- Code scanning with CodeQL.
- Dependency graph.

## GitHub Actions policy

- Default workflow token permissions: read repository contents only.
- Grant `security-events: write`, `id-token: write`, `attestations: write`, or package permissions only to the specific job that needs them.
- Do not use `pull_request_target` to execute untrusted PR code.
- Keep `persist-credentials: false` on checkout unless a reviewed job explicitly requires writes.
- Prefer immutable commit-SHA pinning for third-party actions. Dependabot may update those SHAs through reviewed PRs.
- Treat major-version action upgrades as security-sensitive changes requiring fresh CI.

## Verification record

For each release candidate, record the date, reviewer, and evidence links for the ruleset and security-feature settings in the release notes or deployment ticket. A source-code checkbox must not be used as evidence that an account-level setting is enabled.
