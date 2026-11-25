import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "validate-check-shards.sh"

class ShardProofs(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / "r-check-proofs"
        self.env = dict(os.environ, RUNNER_TEMP=self.tmp.name, RUN_ID="77", RUN_ATTEMPT="2")
        self.paths = []
        for shard in range(1, 9):
            p = self.root / f"r-check-proof-77-2-{shard}" / "proof.txt"
            p.parent.mkdir(parents=True)
            p.write_text(f"77:2:{shard}\n")
            self.paths.append(p)

    def run_validator(self):
        return subprocess.run(["bash", str(SCRIPT)], env=self.env,
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode

    def test_complete_set(self):
        self.assertEqual(self.run_validator(), 0)

    def test_each_missing_and_wrong_record(self):
        for shard, p in enumerate(self.paths, 1):
            original = p.read_text()
            p.unlink()
            with self.subTest(shard=shard, problem="missing"):
                self.assertNotEqual(self.run_validator(), 0)
            p.write_text(f"77:1:{shard}\n")
            with self.subTest(shard=shard, problem="wrong_attempt"):
                self.assertNotEqual(self.run_validator(), 0)
            p.write_text(f"77:2:{shard + 1}\n")
            with self.subTest(shard=shard, problem="wrong_shard"):
                self.assertNotEqual(self.run_validator(), 0)
            p.write_text(original)

    def test_extra_record(self):
        p = self.root / "extra" / "proof.txt"
        p.parent.mkdir()
        p.write_text("77:2:9\n")
        self.assertNotEqual(self.run_validator(), 0)

if __name__ == "__main__":
    unittest.main()
