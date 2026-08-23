# Contributing to Secure Web App Master

Contributions should preserve the project's security-first design and keep security-sensitive behavior explicit, reviewable, and testable.

## Development workflow

1. Create a focused branch from `main`.
2. Keep changes small enough to review security and compatibility impact.
3. Add or update tests for behavior/security changes.
4. Run `./install.sh --dev` before opening a pull request; use `./install.sh --dev --fix` only for safe mechanical Ruff fixes.
5. Update affected documentation and `CHANGELOG.md`.
6. Open a pull request describing the problem, implementation, testing, security impact, compatibility impact, and rollback plan where applicable.

## Branch and commit guidance

Use concise branch prefixes such as `feat/`, `fix/`, `docs/`, `chore/`, `refactor/`, `test/`, or `security/`. Conventional Commit-style messages are preferred, for example:

- `feat: add security control`
- `fix: enforce ownership on resource lookup`
- `security: harden session validation`
- `docs: update deployment guidance`

## Security requirements

- Never bypass authorization, CSRF, validation, or session checks to simplify a feature.
- Never concatenate user-controlled values into SQL or shell commands.
- Never commit credentials, `.env`, private keys, API tokens, local databases, or generated secrets.
- Avoid logging passwords, raw session tokens, CSRF tokens, or sensitive request bodies.
- Preserve fail-closed behavior for security-sensitive paths.
- Do not disable or weaken Ruff, tests, Bandit, `pip-audit`, CodeQL, or other security gates just to make CI green.
- High-impact authentication/authorization changes, dependency upgrades, and architecture changes require explicit review.

## Pull requests

Pull requests should include regression tests where practical. Changes to trust boundaries, authentication, authorization, persistence, deployment, dependencies, or CI/security workflows should explain the threat/security consequences and how they were verified.

## Vulnerabilities

Do not report exploitable vulnerabilities in public issues or pull requests. Follow `SECURITY.md` and use private vulnerability reporting when available.
