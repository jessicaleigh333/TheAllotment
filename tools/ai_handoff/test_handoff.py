"""Exercise the command and publishing route with isolated Git repositories."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
REPORTS = Path("docs/ai-handoff")


class HandoffIntegration(unittest.TestCase):
    def setUp(self):
        sandbox = tempfile.TemporaryDirectory()
        self.addCleanup(sandbox.cleanup)
        self.root = Path(sandbox.name)
        self.work = self.root / "work"
        self.work.mkdir()
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Handoff test")
        self.git("config", "user.email", "handoff@example.invalid")
        (self.work / "feature.txt").write_text("Example change\n")
        self.commit("Feature")
        self.source = self.git("rev-parse", "HEAD").stdout.strip()
        self.git("switch", "-c", "codex/example")

    def run_command(self, *args, success=True):
        result = subprocess.run(args, cwd=self.work, text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def git(self, *args, success=True):
        return self.run_command("git", *args, success=success)

    def cli(self, *args, success=True):
        return self.run_command(
            sys.executable, str(ROOT / "tools/ai_handoff/__main__.py"), *args, success=success
        )

    def commit(self, message):
        self.git("add", ".")
        self.git("commit", "-m", message)

    def record(self, name, data, *args, success=True):
        payload = self.root / "milestone.json"
        payload.write_text(json.dumps(data))
        return self.cli("record", name, str(payload), *args, success=success)

    def read(self, path):
        return (self.work / REPORTS / path).read_text()

    def test_milestones_preserve_history_and_publish_with_retry(self):
        initial = dict(title="Example", summary="Plan the change.", status="planned")
        self.record("plan", initial)
        saved = self.read("events/plan.json")
        self.record("plan", initial)
        self.record("plan", dict(initial, summary="Rewrite history."), success=False)
        self.assertIn("No commit recorded", self.read("LATEST.md"))
        self.assertIn("No entries recorded", self.read("TEST_RESULTS.md"))
        self.commit("Record plan")
        base = self.git("rev-parse", "HEAD").stdout.strip()

        tested = dict(initial, summary="Verified feature.", status="tested",
                      tests=["PASS — example check"], pr=42,
                      backlog={"example": "P0 · tested · awaits review"})
        self.record("tested", tested, "--commit", self.source)
        self.assertEqual(self.read("events/plan.json"), saved)
        report = self.read("LATEST.md")
        self.assertIn(self.source, report)
        self.assertIn("/pull/42", report)
        self.assertIn("codex/example", report)
        self.assertEqual(json.loads(self.read("events/tested.json"))["files"], ["feature.txt"])
        self.commit("Record test")
        self.cli("check", "--base", base)

        self.git("remote", "add", "origin", str(self.root / "remote.git"))
        self.git("push", "origin", "HEAD", success=False)
        self.assertEqual(self.read("LATEST.md"), report)
        self.git("init", "--bare", str(self.root / "remote.git"))
        self.git("push", "origin", "HEAD")
        remote = self.git("ls-remote", "origin", "refs/heads/codex/example").stdout.split()[0]
        self.assertEqual(remote, self.git("rev-parse", "HEAD").stdout.strip())

        (self.work / REPORTS / "LATEST.md").write_text("stale")
        self.cli("check", success=False)
        self.cli("render")
        self.assertEqual(self.read("LATEST.md"), report)
        (self.work / REPORTS / "events/plan.json").unlink()
        self.cli("render")
        self.commit("Attempt to delete history")
        self.assertIn("changed or removed", self.cli("check", "--base", base, success=False).stderr)

    def test_rejects_missing_test_evidence_and_credential_patterns(self):
        incomplete = dict(title="Example", summary="Claim a test.", status="tested")
        self.record("untested", incomplete, "--commit", self.source, success=False)
        self.record("credential", dict(incomplete, status="planned", summary="ghp_" + "x" * 30),
                    success=False)
        self.assertFalse((self.work / REPORTS).exists())


if __name__ == "__main__":
    unittest.main()
