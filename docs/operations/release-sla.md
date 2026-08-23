# Supported Versions and Vulnerability Response SLA

## Supported versions

Until the project publishes multiple maintained release trains, only the latest tagged release and current `main` are supported for security fixes. Older tags are superseded unless release notes explicitly state otherwise.

Production deployments should track an immutable tagged release rather than an arbitrary branch head. A deployment that remains on a superseded release assumes the risk of fixes that are not backported.

## Vulnerability triage targets

Targets start when the maintainer receives a credible report or an automated alert is confirmed to affect supported code.

| Severity | Initial triage target | Remediation/release target |
| --- | ---: | ---: |
| Critical, exploitable | 4 hours | 24 hours where a safe fix/mitigation is available |
| High | 1 business day | 7 days |
| Medium | 3 business days | 30 days |
| Low | 5 business days | 90 days or next planned release |

Severity must consider exploitability, exposed attack surface, confidentiality/integrity/availability impact, privileges required, and deployment context rather than scanner score alone.

## Emergency mitigation

When a complete fix cannot meet the target, publish or deploy the safest available mitigation: disable the exposed feature, restrict network access, rotate affected credentials, pin/rollback a dependency, add a detection rule, or otherwise reduce exploitability. Do not weaken unrelated security gates to accelerate a release.

## Disclosure and evidence

Follow `SECURITY.md` for reporting. Security releases should document affected/safe versions, remediation or mitigation, relevant CVE/advisory identifiers when available, test/scan evidence, SBOM/provenance references, and operational actions such as secret rotation or data review.

These are project maintenance targets, not a contractual SLA for downstream deployments. Operators must define incident-response and patch-deployment targets appropriate to their own risk.