"""Generate the Allotment handoff from reviewed, append-only milestone records."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import re
import subprocess
from tempfile import NamedTemporaryFile

REPO = "https://github.com/jessicaleigh333/TheAllotment"
DIRECTORY = Path("docs/ai-handoff")
EVENTS = DIRECTORY / "events"
STATUSES = {"planned", "in progress", "tested", "merged"}
SECTIONS = {
    "CONVERSATION_LOG": "conversation",
    "CHANGELOG": "changes",
    "TEST_RESULTS": "tests",
    "DECISIONS": "decisions",
    "ISSUES": "issues",
    "SCREENSHOTS": "screenshots",
}
LISTS = set(SECTIONS.values()) | {"next"}
METADATA = {"id", "timestamp", "branch", "commit", "files"}
FIELDS = LISTS | {"title", "status", "summary", "pr", "backlog"}
TOKEN = re.compile(r"[a-z0-9][a-z0-9-]{0,79}")
SECRET = re.compile(
    r"-----BEGIN [^-]*PRIVATE KEY-----|\b(?:gh[pousr]_[A-Za-z0-9]{20,}|"
    r"github_pat_[A-Za-z0-9_]{20,}|AKIA[A-Z0-9]{16}|sk-[A-Za-z0-9_-]{20,})\b"
)


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def clean_text(value):
    return isinstance(value, str) and bool(value.strip()) and len(value) <= 4000 and all(
        ord(char) >= 32 for char in value
    )


def validate(event):
    if not isinstance(event, dict) or event.keys() - FIELDS - METADATA:
        raise ValueError("Unexpected milestone fields")
    if SECRET.search(json.dumps(event)):
        raise ValueError("Possible credential in milestone. Review the input before publishing.")
    if not all(clean_text(event.get(key)) for key in ("title", "summary", "status")):
        raise ValueError("title, summary and status are required single-line strings")
    if event["status"] not in STATUSES:
        raise ValueError("Unknown milestone status")
    if not TOKEN.fullmatch(event["id"]) or not re.fullmatch(
        r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z", event["timestamp"]
    ):
        raise ValueError("Invalid milestone ID or UTC timestamp")
    datetime.fromisoformat(event["timestamp"])
    if not clean_text(event["branch"]):
        raise ValueError("Invalid branch")
    commit = event["commit"]
    if commit is not None and not re.fullmatch(r"[a-f0-9]{40}", commit):
        raise ValueError("Invalid commit")
    if "pr" in event and (type(event["pr"]) is not int or event["pr"] < 1):
        raise ValueError("pr must be a positive GitHub pull request number")
    for field in LISTS | {"files"}:
        values = event.get(field, [])
        if not isinstance(values, list) or not all(map(clean_text, values)):
            raise ValueError(f"{field} must be a list of single-line strings")
    if event["status"] == "tested" and (not commit or not event.get("tests")):
        raise ValueError("Tested milestones require a source commit and test evidence")
    if event["status"] == "merged" and (not commit or not event.get("pr")):
        raise ValueError("Merged milestones require a merge commit and PR number")
    backlog = event.get("backlog", {})
    if not isinstance(backlog, dict):
        raise ValueError("backlog must map stable task IDs to updates")
    for key, value in backlog.items():
        if not TOKEN.fullmatch(key) or not clean_text(value):
            raise ValueError("Invalid backlog ID or update")


def records():
    result = []
    for path in EVENTS.glob("*.json"):
        event = json.loads(path.read_text(encoding="utf-8"))
        validate(event)
        if event["id"] != path.stem:
            raise ValueError(f"Milestone ID differs from filename in {path}")
        result.append(event)
    return sorted(result, key=lambda event: (event["timestamp"], event["id"]))


def link(event):
    return f"[{event['timestamp']} · {event['title']}](events/{event['id']}.json)"


def bullets(items):
    return "\n".join(f"- {item}" for item in items) or "No information recorded."


def render(events):
    output = {}
    for name, key in SECTIONS.items():
        blocks = [
            f"## {link(event)}\n\n{bullets(event[key])}"
            + (f"\n\n[Source commit]({REPO}/commit/{event['commit']})"
               if event["commit"] else "")
            for event in events if event.get(key)
        ]
        output[name] = "\n\n".join(blocks) or "No entries recorded."
    backlog = {}
    for event in events:
        for task, detail in event.get("backlog", {}).items():
            backlog[task] = (detail, event)
    output["BACKLOG"] = bullets(
        f"`{task}` — {detail} ({link(event)})"
        for task, (detail, event) in sorted(backlog.items())
    )
    latest = "No milestones recorded."
    if events:
        event = events[-1]
        commit = event["commit"]
        evidence = f"[`{commit}`]({REPO}/commit/{commit})" if commit else "No commit recorded."
        pr = f"[#{event['pr']}]({REPO}/pull/{event['pr']})" if event.get("pr") else "No PR number recorded."
        latest = (
            f"## {link(event)}\n\n"
            f"{event['summary']}\n\n"
            f"- Milestone status — **{event['status']}**\n"
            f"- Source branch — `{event['branch']}`\n"
            f"- Source commit — {evidence}\n"
            f"- Pull request — {pr}\n"
            f"- Changed paths — {len(event.get('files', []))}; see milestone or commit for details.\n\n"
            f"## Next priorities\n\n{bullets(event.get('next', []))}"
        )
    output["LATEST"] = (
        latest + "\n\n"
        "[Backlog](BACKLOG.md) · [Conversations](CONVERSATION_LOG.md) · "
        "[Changes](CHANGELOG.md) · [Tests](TEST_RESULTS.md) · [Decisions](DECISIONS.md) · "
        "[Issues](ISSUES.md) · [Screenshots](SCREENSHOTS.md) · [Guide](HANDOFF_GUIDE.md)\n\n"
        f"[Open pull requests]({REPO}/pulls?q=is%3Apr+is%3Aopen) · "
        f"[Merged pull requests]({REPO}/pulls?q=is%3Apr+is%3Amerged)"
    )
    return {
        DIRECTORY / f"{name}.md": (
            f"# {name.replace('_', ' ').title()}\n\n"
            "<!-- Generated by python -m tools.ai_handoff render. -->\n\n"
            f"{body}\n"
        )
        for name, body in output.items()
    }


def record(path, event_id, ref):
    if not TOKEN.fullmatch(event_id):
        raise ValueError("Use a lowercase milestone ID with letters, digits and hyphens")
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict) or data.keys() - FIELDS:
        raise ValueError("Unexpected input fields")
    branch = git("symbolic-ref", "--short", "HEAD")
    commit = git("rev-parse", "--verify", "--end-of-options", ref + "^{commit}") if ref else None
    files = git("show", "--first-parent", "--format=", "--name-only", commit).splitlines() if commit else []
    target = EVENTS / f"{event_id}.json"
    existing = json.loads(target.read_text(encoding="utf-8")) if target.exists() else None
    timestamp = existing["timestamp"] if existing else datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    event = dict(data, id=event_id, timestamp=timestamp, branch=branch, commit=commit, files=files)
    validate(event)
    if existing is not None:
        if event != existing:
            raise ValueError("Milestone ID already exists. Use a new ID for a follow-up.")
        return
    if event["status"] == "merged":
        git("merge-base", "--is-ancestor", commit, "refs/remotes/origin/main")
    EVENTS.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(mode="w", encoding="utf-8", dir=EVENTS, delete=False) as stream:
        pending = Path(stream.name)
        try:
            stream.write(json.dumps(event, indent=2, ensure_ascii=False) + "\n")
            stream.close()
            os.link(pending, target)
        finally:
            pending.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    add = commands.add_parser("record")
    add.add_argument("id")
    add.add_argument("input", type=Path)
    add.add_argument("--commit", help="Source commit for this milestone, usually HEAD")
    commands.add_parser("render")
    check = commands.add_parser("check")
    check.add_argument("--base", help="Git commit before this change for append-only verification")
    args = parser.parse_args()
    try:
        if args.command == "record":
            record(args.input, args.id, args.commit)
        if args.command == "check" and args.base:
            changed = git("diff", "--no-renames", "--name-only", "--diff-filter=MDT",
                          args.base, "HEAD", "--", str(EVENTS))
            if changed:
                raise ValueError(f"Historical records were changed or removed:\n{changed}")
        for path, content in render(records()).items():
            if args.command == "check":
                if not path.is_file() or path.read_text(encoding="utf-8") != content:
                    raise ValueError(f"Stale report: {path}. Run python -m tools.ai_handoff render")
            elif not path.is_file() or path.read_text(encoding="utf-8") != content:
                path.write_text(content, encoding="utf-8")
    except (ValueError, KeyError, TypeError, OSError, subprocess.CalledProcessError) as exc:
        parser.exit(1, f"Handoff: {exc}\n")


if __name__ == "__main__":
    main()
