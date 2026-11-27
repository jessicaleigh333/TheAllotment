from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from pathlib import Path
from tempfile import TemporaryDirectory
from threading import Barrier
import unittest
from unittest.mock import patch

from . import dispatch


class DispatchTests(unittest.TestCase):
    def test_routes_using_live_states_and_dependency_completion(self):
        tasks = {
            "closed": {"issue": 1, "priority": 0, "depends_on": [], "pull_requests": []},
            "expired": {"issue": 2, "priority": 0, "depends_on": [], "pull_requests": []},
            "dependency": {"issue": 3, "priority": 0, "depends_on": ["closed"], "pull_requests": []},
            "existing": {"issue": 4, "priority": 0, "depends_on": [], "pull_requests": [7]},
            "blocked": {"issue": 5, "priority": 0, "depends_on": [], "pull_requests": []},
            "active": {"issue": 6, "priority": 0, "depends_on": [], "pull_requests": []},
            "fallback": {"issue": 7, "priority": 1, "depends_on": [], "pull_requests": [8]},
        }
        issues = {n: {"state": "OPEN", "labels": [], "stateReason": None} for n in range(1, 8)}
        issues[1].update(state="CLOSED", stateReason="NOT_PLANNED")
        issues[5]["labels"] = [{"name": "Blocked"}]
        pulls = {7: {"state": "OPEN"}, 8: {"state": "MERGED"}}
        now = datetime.now(timezone.utc)
        claims = {
            2: {"expires": (now - timedelta(hours=1)).isoformat()},
            6: {"expires": (now + timedelta(hours=1)).isoformat()},
        }
        result = dispatch.route(tasks, issues, pulls, claims, now)
        self.assertEqual(
            [entry["status"] for entry in result.values()],
            ["closed", "expired-review-required", "dependency-blocked", "existing-pr",
             "blocked", "claimed", "available"],
        )
        issues[1]["stateReason"] = "COMPLETED"
        self.assertEqual(dispatch.route(tasks, issues, pulls, claims, now)["dependency"]["status"], "available")

    def test_concurrent_claims_and_owner_only_release(self):
        with TemporaryDirectory() as directory:
            remote = str(Path(directory, "remote.git"))
            dispatch.run("git", "init", "--bare", remote)
            barrier = Barrier(2)
            real_run = dispatch.run

            def synchronized_push(*args, **kwargs):
                if args[:2] == ("git", "push"):
                    barrier.wait(timeout=10)
                return real_run(*args, **kwargs)

            with patch.object(dispatch, "run", side_effect=synchronized_push):
                with ThreadPoolExecutor(max_workers=2) as executor:
                    attempts = [executor.submit(dispatch.acquire, remote, 29) for _ in range(2)]
                    results = [attempt.result(timeout=20) for attempt in attempts]
            winners = [claim for claim in results if claim is not None]
            self.assertEqual(len(winners), 1)
            self.assertEqual(dispatch.claim(remote, 29), winners[0])
            with self.assertRaises(ValueError):
                dispatch.release(remote, 29, "another-run")
            dispatch.release(remote, 29, winners[0]["run"])
            self.assertIsNone(dispatch.claim(remote, 29))
            self.assertIsNotNone(dispatch.acquire(remote, 29))
