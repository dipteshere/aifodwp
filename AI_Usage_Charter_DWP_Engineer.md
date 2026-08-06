# Personal AI Usage Charter — DWP Desktop/Endpoint Engineer
**Version 1.0 | Effective: August 2026 | Review: annually or on policy change**

---

## 1. Tasks Appropriate for Public AI Assistant Help

I may use public LLMs (e.g. GitHub Copilot, ChatGPT, Copilot in Windows) for:

- **Scripting boilerplate** — generating PowerShell, Python, or Bash scaffolding for automation tasks that contain no environment-specific secrets or host details
- **Regex and query construction** — building log-parsing patterns, WMI/CIM queries, or registry search expressions
- **Documentation and runbooks** — drafting plain-English procedure guides, change-request descriptions, or knowledge-base articles (reviewed before publishing)
- **Explaining public technology** — understanding vendor documentation, CVE advisories, Group Policy settings, or SCCM/Intune behaviour
- **Test and lab code** — scripts intended only for isolated dev/test environments with synthetic data
- **Learning and skill development** — working through unfamiliar concepts, certifications, or tool syntax

---

## 2. Tasks NOT Appropriate for Public AI Assistants

I will **not** submit the following to any public or third-party AI service:

| Category | Examples |
|---|---|
| Claimant / end-user data | Names, NINOs, UC claim references, dates of birth, case notes |
| Internal network details | Hostnames, IP ranges, AD domain names, LDAP paths, site codes |
| Credentials or secrets | Passwords, API keys, service-account tokens, certificate private keys |
| Security configuration | Firewall rules, IDS/IPS tuning, BitLocker recovery keys, PAM policies |
| Incident or vulnerability data | Live incident tickets, unpatched CVE workarounds, pen-test findings |
| Unapproved internal tooling | Proprietary DWP scripts, config baselines, or GPO exports |
| Contractual or HR matters | Third-party contracts, staff data, disciplinary records |

> **Rule of thumb:** If the information would require an FOI request, a DPA assessment, or a security clearance to share with a colleague externally — it must not go to a public LLM.

---

## 3. Data-Handling Rule for End-User PII and Credentials

**Before pasting anything into a public AI tool I will ask:**
> *"Would this content identify a claimant, expose a credential, or reveal internal infrastructure?"*

If the answer is **yes or uncertain**, I will:

1. **Anonymise or redact** — replace real values with clearly fake placeholders (e.g. `NINO: QQ123456A` → `NINO: XX999999X`, hostnames → `HOST-LAB01`)
2. **Never reverse-substitute** — I will not then paste the AI output back into a live system with real values without a manual review step
3. **Treat AI output containing redacted values as a template only** — fill real values in a secure, offline context (ISE, VS Code with no cloud sync, or a locked terminal session)
4. **Report accidental disclosure** — if I mistakenly submit real PII or credentials to a public service, I will report it immediately to the DWP Data Protection Officer and my line manager as a potential data breach

---

## 4. Personal 'Generate → Verify' Rule for Scripts and System Changes

AI-generated code is a **first draft, not a finished product**. For any script or change touching a managed endpoint or service I commit to:

| Step | Action |
|---|---|
| **Generate** | Prompt the AI with a sanitised, specific task description |
| **Read every line** | Understand what each command does before running it — no blind copy-paste |
| **Static check** | Run `PSScriptAnalyzer` (PowerShell) or `pylint`/`shellcheck` (Python/Bash) on the output |
| **Test in isolation** | Execute in a lab VM or against a single non-production target first |
| **Diff before deploy** | For config changes, produce a before/after diff and attach it to the change record |
| **Own the output** | I am fully accountable for any AI-assisted script I deploy — "the AI wrote it" is not a defence |
| **Version-control** | Commit the final reviewed version to the team repo with a note that it was AI-assisted |

> **Hard stop:** If I cannot explain what a generated script does line-by-line, I will not run it on a managed system.

---

*This charter supplements, and does not replace, DWP Acceptable Use Policy, the Government Functional Standard GovS 007 (Security), and UK GDPR obligations.*
