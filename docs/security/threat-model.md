# Initial threat model

This is an engineering baseline, not a claim of FERPA, COPPA, SOC 2, or other certification.

## Protected assets

- Student identity, enrollment, mastery history, and curriculum context
- Teacher identity and session cookies
- Provider credentials and object-storage credentials
- Investigation evidence, generated drafts, teacher edits, and decisions
- Audit-chain integrity

## Primary risks and current controls

| Risk | Current control | Follow-up before production |
| --- | --- | --- |
| Cross-tenant access | Organization-scoped Pundit policies and retrieval queries | Add database-level tenant consistency constraints and adversarial request specs |
| Account takeover | Password hashing, signed HttpOnly SameSite cookies, login rate limiting | Add Google SSO, MFA policy, session expiry, and recovery controls |
| Student data sent unnecessarily | Offline provider by default; bounded evidence payloads; synthetic seed data | Complete data-flow review, provider terms review, and configurable redaction |
| Hallucinated evidence | Strict output schema and citation allow-list validation | Add evaluation corpus and monitored grounding metrics |
| Autonomous harmful action | Draft-only output and explicit teacher approval/rejection | Add role-based approval policy and escalation rules |
| Prompt injection in curriculum | Developer instructions, bounded retrieval, structured output, citation validation | Add ingestion scanning, content provenance, and red-team tests |
| Malicious or duplicate uploads | PDF MIME/size validation, organization-scoped checksums, non-shell subprocess arguments | Add malware scanning, decompression limits, and quarantine storage |
| Malformed or cross-tenant CSV imports | Exact headers, row limits, teacher-owned section scope, full preview validation, atomic apply | Add malware scanning and configurable district mappings |
| Secret disclosure | Ignored `.env`, empty template values, no stored provider response | Add managed secrets, secret scanning, and key rotation procedures |
| Audit tampering | Per-organization SHA-256 hash chain and immutable original plan snapshot | Export to append-only storage with independent verification |

## Data-handling rules

- Use only synthetic student records in local development and CI.
- Do not place credentials or real student data in Git, prompts, logs, screenshots, fixtures, or support tickets.
- Minimize prompt fields to the evidence required for the educator's question.
- Treat AI observations as provisional and visible to authorized educators only.
- Define retention, deletion, legal basis, consent, incident response, and vendor agreements before production data is introduced.
