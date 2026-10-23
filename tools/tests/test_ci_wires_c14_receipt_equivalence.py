"""Forcing test for #1538: CI must run the C14/C17 receipt-equivalence check.

`capability_ledger.py --check` does not detect a stale C14/C17 receipt against
current source; `--check-c14-receipt-equivalence` does. If the workflow step
that validates the ledger omits it, receipt drift can merge green. This test
reads the workflow text (stdlib only) and fails closed when the command is
absent from the "Validate generated capability ledger" step, or when it appears
only in a comment.
"""

from __future__ import annotations

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "R-CMD-check.yaml"
STEP_NAME = "Validate generated capability ledger"
REQUIRED = "python3 tools/capability_ledger.py --check-c14-receipt-equivalence"


def ledger_step_commands() -> list[str]:
    """Non-comment lines of the ledger-validation step's `run: |` block."""
    lines = WORKFLOW.read_text(encoding="utf-8").splitlines()
    start = next(
        (i for i, line in enumerate(lines) if line.strip() == f"- name: {STEP_NAME}"),
        None,
    )
    if start is None:
        raise AssertionError(f"step {STEP_NAME!r} not found in {WORKFLOW}")
    commands: list[str] = []
    for line in lines[start + 1 :]:
        # The next list item at step indentation ends this step.
        if re.match(r"^\s*- name:", line):
            break
        text = line.strip()
        if text and not text.startswith("#"):
            commands.append(text)
    return commands


class CiWiresC14ReceiptEquivalenceTest(unittest.TestCase):
    def test_ledger_step_runs_receipt_equivalence_check(self):
        self.assertIn(REQUIRED, ledger_step_commands())

    def test_plain_check_is_still_run(self):
        self.assertIn("python3 tools/capability_ledger.py --check", ledger_step_commands())


if __name__ == "__main__":
    unittest.main()
