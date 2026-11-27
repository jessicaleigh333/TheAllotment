# Agent registry

Track actual agents and their delegated assignments, not hypothetical roles or branches mistaken for agents. This is a maintained companion to the generated milestone reports; do not edit generated reports manually.

## Current roster

No individual subagent identities or assignments have been verified in the published handoff as of 2026-11-23. Populate from actual session evidence only. Use a stable project-local ID if a platform ID is unavailable; label it as locally assigned. Do not invent identities, activity, or test results.

| Agent ID | Display name | Specialty | Parent/delegator | Assignment ID | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Assignment and contribution history

Append one entry per material assignment or status transition. Preserve prior entries; correct errors with a linked follow-up.

| UTC date/time | Agent ID | Assignment ID | Task and outcome | Status | Deliverables / PR / commit | Verification / reviewer | Next action |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |

## Operating rules

- At delegation, record the actual agent, parent, specialty, scope and assignment ID. At milestones record observed status (assigned, active, blocked, completed, or cancelled), deliverables, checks, reviewer and remaining work. Distinguish reported completion from independently verified completion.
- Record multiple assignments for the same agent without replacing history. If a session cannot observe agent identities or historical activity, record that limitation; do not infer agents from branches or task titles.
- Update this registry alongside the existing milestone event and task PR; include a registry reference in the milestone changes or decisions. Preserve concurrent entries when integrating branches.
- Public repository: exclude private transcripts, credentials, personal data, internal sensitive identifiers and private links. Use reviewed project-local aliases where appropriate.
- The parent session is responsible for checking delegated work and reporting failures or unverified claims. The registry does not replace existing code review, test evidence, or owner approval.

## 2026-11-27 Windows verification handoff

| UTC date | Agent | Assignment and contribution | Status | Evidence |
| --- | --- | --- | --- | --- |
| 2026-11-27 | Codex (primary session) | Ran production-code launcher fixture suites, Windows-preset pack exports and isolated exported-game save/play checks. Recorded native acceptance steps. No subagents were delegated. | Linux checks complete, native and live release verification blocked | [Report](../WINDOWS_VERIFICATION_30.md), [#30](https://github.com/jessicaleigh333/TheAllotment/issues/30), [#33](https://github.com/jessicaleigh333/TheAllotment/pull/33) |
