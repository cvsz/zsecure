# Development

## Local setup

```bash
git clone https://github.com/cvsz/zsecure.git
cd zsecure
./install.sh --dev --run
```

The installer requires Python 3.11+, creates `.venv`, installs `requirements-dev.txt`, creates a protected `.env` from `.env.example` when needed, runs verification, and optionally starts Uvicorn on `127.0.0.1:8000`.

## Verification commands

Run the full installer verification path:

```bash
./install.sh --dev
```

Apply only the repository's safe mechanical Ruff fixes before verification:

```bash
./install.sh --dev --fix
```

Equivalent focused checks include:

```bash
ruff check .
pytest -q
bandit -q -r app -x tests
pip-audit -r requirements.txt --strict
cyclonedx-py requirements requirements.txt --output-file sbom.json
```

## Security development rules

- Treat browser/API inputs, cookies, headers, identifiers, and external data as untrusted.
- Enforce authorization server-side and include ownership constraints in persistence queries where practical.
- Use parameterized database operations; never concatenate user-controlled SQL.
- Keep Pydantic models strict and reject unexpected privilege-bearing fields.
- Require CSRF verification for authenticated state-changing browser requests.
- Never commit `.env`, credentials, API tokens, private keys, local databases, or generated secrets.
- Do not log passwords, raw session tokens, CSRF secrets, or unnecessary sensitive payloads.
- Do not weaken lint, tests, SAST, dependency auditing, CodeQL, or other security gates to obtain a passing build.

## Tests

Behavior/security changes should add regression tests. Existing tests cover security headers, rejection of extra request fields, authentication/CSRF behavior, cross-user object access, and SQL-injection resistance. Additional coverage priorities are tracked in `ROADMAP.md`.

## Pull requests

Keep changes focused and reviewable. Explain security impact, compatibility impact, validation performed, and rollback considerations. High-impact dependency upgrades, authentication/authorization changes, and architecture changes require deliberate review rather than blind automation.

## Documentation

Update `README.md`, `CHANGELOG.md`, `ROADMAP.md`, `SECURITY.md`, architecture/development/release documentation, and ADRs whenever their assumptions change.
