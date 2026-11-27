# Agent registry

Track actual agents and their delegated assignments, not hypothetical roles or branches mistaken for agents. This is a maintained companion to the generated milestone reports; do not edit generated reports manually.

## Current roster

No individual subagent identities or assignments have been verified in the published handoff as of 2026-11-23. Populate from actual session evidence only. Use a stable project-local ID if a platform ID is unavailable; label it as locally assigned. Do not invent identities, activity, or test results.

| Agent ID | Display name | Specialty | Parent/delegator | Assignment ID | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Issue #29 contribution

| UTC date | Agent | Assignment and contribution | Status | Evidence | Verification |
| --- | --- | --- | --- | --- | --- |
| 2026-11-24 | Codex (primary session) | Started the architecture audit, regression inventory and PR triage. No subagents were delegated. | Active | [Issue #29](https://github.com/jessicaleigh333/TheAllotment/issues/29), [draft PR #32](https://github.com/jessicaleigh333/TheAllotment/pull/32) | Reviewed source pinned to main. GitHub verified Windows and terrain ancestry. Runtime baseline remains pending. |

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

## 2026-11-27 audit handoff

| UTC date | Agent | Assignment and contribution | Status | Evidence |
| --- | --- | --- | --- | --- |
| 2026-11-27 | Codex (primary session) | Finished all remote branch comparisons, ran isolated Godot/Python regressions, captured graphical evidence and reviewed #31 claim behavior. No subagents were delegated. | Completed audit, awaiting owner review | [Audit and evidence](../ARCHITECTURE_AUDIT_29.md), [#32](https://github.com/jessicaleigh333/TheAllotment/pull/32), [#31 review](https://github.com/jessicaleigh333/TheAllotment/pull/31#issuecomment-7227173966) |
## 2026-11-27 Windows verification handoff

| UTC date | Agent | Assignment and contribution | Status | Evidence |
| --- | --- | --- | --- | --- |
| 2026-11-27 | Codex (primary session) | Ran production-code launcher fixture suites, Windows-preset pack exports and isolated exported-game save/play checks. Recorded native acceptance steps. No subagents were delegated. | Linux checks complete, native and live release verification blocked | [Report](../WINDOWS_VERIFICATION_30.md), [#30](https://github.com/jessicaleigh333/TheAllotment/issues/30), [#33](https://github.com/jessicaleigh333/TheAllotment/pull/33) |

## Issue #34 execution

| UTC date | Agent | Assignment and contribution | Status | Evidence |
| --- | --- | --- | --- | --- |
| 2026-11-27 | Codex (primary session) | Rechecked Windows release gates, fixed and tested the HUD Settings regression, reconciled the three reporting branches and exercised the dispatch claim race. This session had no delegated assignments. | Locally tested and awaiting review. Native Windows evidence remains open. | [#34](https://github.com/jessicaleigh333/TheAllotment/issues/34), [HUD PR #35](https://github.com/jessicaleigh333/TheAllotment/pull/35) |

| UTC date/time | Agent ID | Assignment ID | Task and outcome | Status | Deliverables / PR / commit | Verification / reviewer | Next action |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-11-27 | Codex (primary session) | issue-34 | Adapted courtyard surfaces, verified botanical intake and UTC growth, implemented the starter care and harvest loop, and connected the guide and diary. No subagents were delegated. | Tested on focused and combined review branches | [#37](https://github.com/jessicaleigh333/TheAllotment/pull/37), [#38](https://github.com/jessicaleigh333/TheAllotment/pull/38), [#39](https://github.com/jessicaleigh333/TheAllotment/pull/39), [#40](https://github.com/jessicaleigh333/TheAllotment/pull/40) | Godot targeted integration suites and 52 Python tests passed | Owner review of focused PRs; courtyard visual approval pending |
| 2026-11-27 | Codex (primary session) | greenhouse-atrium | Reviewed the owner reference, modeled a dimensional staging shell, and verified the existing avatar traversal. No subagents were delegated. | Staging tested; publication blocked | [#41](https://github.com/jessicaleigh333/TheAllotment/pull/41), [#42](https://github.com/jessicaleigh333/TheAllotment/issues/42) | Entrance, stair flights, turn landing and upper guardrail passed on the focused and combined branches | Owner acquisition and art decision, then live placement and catalog checks |
