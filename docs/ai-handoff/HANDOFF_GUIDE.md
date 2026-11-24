# Development handoff guide

Start with [LATEST.md](LATEST.md) and [BACKLOG.md](BACKLOG.md). The default branch holds the shared report history. For active work, open the report on the branch linked by its pull request and compare the latest event with the PR's commits, review state and checks. A PR can advance after a milestone was reported. The milestone timestamp and source SHA describe the evidence at the time of recording.

## Record and publish at milestones

Use Python 3.11 or newer and Git from the repository root. Start from current `origin/main` on a task branch. Record when a task starts, a material decision or blocker occurs, tests finish, or the work is handed off. Bundle several small changes into one event and publish with the task's existing draft PR. A distinct event can be recorded within a minute when there is meaningful new evidence.

1. Prepare a reviewed JSON input outside the repository. The public repository is visible to anyone. Summarize the available development instructions and Codex response in order, with a source date or link where available. Exclude raw transcripts, credentials, personal details, private links, sensitive output and identifying details in images. The script catches a few token formats. The operator is responsible for reviewing everything before committing it.
2. Commit code or screenshot files first if reporting a particular revision. Record the milestone with that commit and review the diff.
3. Commit the report files and push to the task branch. Open or update its draft PR. The path-filtered **AI handoff** workflow checks generated Markdown, validates input and protects earlier event files. It uses read-only permissions and performs no commits. Check the PR's Actions result before claiming the report passed validation.

```sh
python -m tools.ai_handoff record task-checks-passed /tmp/milestone.json --commit HEAD
python -m tools.ai_handoff check
git add docs/ai-handoff
git commit -m "Record task handoff milestone"
git push -u origin HEAD
gh pr create --draft --base main
```

Use a stable, unique ID, ideally prefixed with the task or PR name. Retrying the same ID with the same input and source commit is safe. For an error in already-published history, add a correcting event that cites the earlier event. Each event describes one source commit. When a milestone spans multiple commits, link the PR or commit range in `changes`.

## Input format

```json
{
  "title": "Milestone title",
  "status": "tested",
  "summary": "What happened and what still needs review.",
  "pr": 42,
  "conversation": ["Owner: requested a change.", "Codex: implemented it and reported the checks."],
  "changes": ["Describe affected behavior and link a PR or commit range if useful."],
  "tests": ["PASS — test command and observed result", "FAIL — observed error and recovery"],
  "decisions": ["Document the decision and its rationale."],
  "issues": ["Open or resolved blocker and its current state."],
  "screenshots": ["[Garden preview](https://example.org/replace-with-reviewed-image-link)"],
  "next": ["Next priority"],
  "backlog": {"stable-task-id": "P1 · tested · depends on owner review"}
}
```

Only `title`, `status` and `summary` are required for a planning entry. Optional list fields take single-line Markdown strings. Omit unknown data and explain any important gaps in the summary or issues. The generator captures UTC time, branch, source SHA and paths changed in the source commit. A backlog update replaces the task's current display value, and prior values remain in the event files.

Use **planned** for intended work, **in progress** for implementation or unresolved checks, **tested** for work with an identified source commit and actual test evidence, and **merged** for a verified merge. For a merged follow-up, fetch `origin/main`, confirm the PR is merged on GitHub, and record its merge SHA and PR number. The tool checks that the SHA is reachable from local `origin/main`. A tested milestone remains historically tested after its PR merges. The live PR determines review and merge state.

## Multiple sessions and publishing failures

- Fetch before resuming. For independent tasks, use distinct branches and event IDs. If generated Markdown conflicts after incorporating main, keep both sets of event files, regenerate Markdown with `python -m tools.ai_handoff render`, then stage and validate the result. For concurrent pushes on one branch, integrate the remote work and regenerate. Avoid force-pushing over another session.
- If a push fails, the local report commit is retained. Fix network or permission problems or integrate remote updates, then retry the existing push. Verify that GitHub shows the expected branch SHA and PR. A successful local render alone does not publish anything.
- If checks fail, open the Actions log. For stale Markdown regenerate and commit it. For an append-only failure restore the earlier event, then append a correction. For an infrastructure failure retry the job after the service recovers. Confirm green checks before requesting merge.
- ChatGPT can read the public GitHub files using the GitHub connector or an available browser. Ask it to read the default-branch report and open PRs, or give it a specific PR when the work is still under review. Use the commit link in each event to inspect code, and verify current PR status in GitHub.

## Capture limits

The repository has no supported feed for private Codex or ChatGPT conversations. Sessions contribute summaries from messages they can actually see. GitHub Actions cannot observe local edits or chat, and this workflow creates no timer-based commits. A future session should use this guide to record material milestones even when it cannot access earlier chats.

When visual evidence is relevant and the environment can render the game, capture a screenshot after running the affected scene, review it, and attach it to the PR or commit it in an appropriate repository location. Add a link and scene/revision context to `screenshots`. Use a stable GitHub link for evidence that must outlive CI artifact retention. Record any inability to capture a screenshot in the milestone. Reporting-only work has no game screen to capture.
