"""Route active sessions using live GitHub state and compare-and-swap Git refs."""

import argparse
from datetime import datetime, timedelta, timezone
import json
import subprocess
from uuid import UUID, uuid4

from .__main__ import DIRECTORY


def run(*args, input=None, check=True):
    return subprocess.run(args, input=input, check=check, text=True, capture_output=True)


def github(repo, kind, number, fields):
    return json.loads(run("gh", kind, "view", str(number), "--repo", repo, "--json", fields).stdout)


def reference(issue):
    return f"refs/heads/codex-claims/issue-{issue}"


def claim(remote, issue):
    ref = reference(issue)
    result = run("git", "ls-remote", "--refs", remote, ref).stdout.split()
    if not result:
        return None
    oid = result[0]
    run("git", "fetch", "--no-tags", "--no-write-fetch-head", remote, ref)
    data = json.loads(run("git", "show", "-s", "--format=%B", oid).stdout)
    UUID(data["run"])
    if data["issue"] != issue or datetime.fromisoformat(data["expires"]).utcoffset() is None:
        raise ValueError(f"Invalid claim for issue #{issue}")
    return data | {"commit": oid}


def acquire(remote, issue):
    data = {
        "run": str(uuid4()),
        "issue": issue,
        "expires": (datetime.now(timezone.utc) + timedelta(hours=24)).isoformat(),
    }
    ref = reference(issue)
    empty_tree = run("git", "mktree", input="").stdout.strip()
    oid = run("git", "commit-tree", empty_tree, input=json.dumps(data) + "\n").stdout.strip()
    result = run("git", "push", f"--force-with-lease={ref}:", remote, f"{oid}:{ref}", check=False)
    current = claim(remote, issue)
    if current and current["commit"] == oid:
        return current
    if current:
        return None
    raise RuntimeError(result.stderr.strip() or "Claim could not be verified")


def release(remote, issue, run_id):
    current = claim(remote, issue)
    if not current or current["run"] != run_id:
        raise ValueError(f"Run does not own the claim for issue #{issue}")
    ref = reference(issue)
    run("git", "push", f"--force-with-lease={ref}:{current['commit']}", remote, f":{ref}")


def route(tasks, issues, pulls, claims, now):
    decisions = {}
    for task_id, task in sorted(tasks.items(), key=lambda entry: (entry[1]["priority"], entry[1]["issue"])):
        issue = issues[task["issue"]]
        labels = {label["name"].casefold() for label in issue["labels"]}
        existing = [number for number in task["pull_requests"] if pulls[number]["state"] == "OPEN"]
        current = claims.get(task["issue"])
        if issue["state"] != "OPEN":
            status = "closed"
        elif labels & {"blocked", "on hold", "hold"}:
            status = "blocked"
        elif current:
            expires = datetime.fromisoformat(current["expires"])
            status = "claimed" if now < expires else "expired-review-required"
        elif existing:
            status = "existing-pr"
        elif any(issues[tasks[dep]["issue"]]["stateReason"] != "COMPLETED" for dep in task["depends_on"]):
            status = "dependency-blocked"
        else:
            status = "available"
        decisions[task_id] = task | {"status": status, "open_pull_requests": existing}
    return decisions


def live_routes(config, remote):
    repo = config["repository"]
    tasks = config["tasks"]
    issues = {
        task["issue"]: github(repo, "issue", task["issue"], "state,stateReason,labels")
        for task in tasks.values()
    }
    pulls = {
        number: github(repo, "pr", number, "state")
        for number in sorted({number for task in tasks.values() for number in task["pull_requests"]})
    }
    claims = {number: claim(remote, number) for number in issues if issues[number]["state"] == "OPEN"}
    return route(tasks, issues, pulls, claims, datetime.now(timezone.utc))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--remote", default="origin")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("route")
    commands.add_parser("claim-next")
    for name in ("verify", "release"):
        command = commands.add_parser(name)
        command.add_argument("issue", type=int)
        command.add_argument("run_id")
    args = parser.parse_args()
    try:
        config = json.loads((DIRECTORY / "dispatch.json").read_text())
        if args.command in {"route", "claim-next"}:
            decisions = live_routes(config, args.remote)
            if args.command == "route":
                print(json.dumps(decisions, indent=2))
                return
            for task in decisions.values():
                if task["status"] == "available":
                    winner = acquire(args.remote, task["issue"])
                    if winner:
                        print(json.dumps(winner))
                        return
            parser.exit(1, "No available assignment claimed. Run route for current states.\n")
        if args.issue not in {task["issue"] for task in config["tasks"].values()}:
            raise ValueError("Issue is outside dispatch configuration")
        if args.command == "release":
            release(args.remote, args.issue, args.run_id)
        else:
            current = claim(args.remote, args.issue)
            if (not current or current["run"] != args.run_id
                    or datetime.fromisoformat(current["expires"]) <= datetime.now(timezone.utc)):
                raise ValueError("Run has no current claim")
            print(json.dumps(current))
    except subprocess.CalledProcessError as exc:
        parser.exit(2, f"{exc.stderr.strip() or exc}\n")
    except (ValueError, RuntimeError) as exc:
        parser.exit(2, f"{exc}\n")


if __name__ == "__main__":
    main()
