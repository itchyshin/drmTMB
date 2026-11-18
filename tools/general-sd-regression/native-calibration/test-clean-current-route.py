#!/usr/bin/env python3
"""Exercise the clean-current manifest through the bounded 95% runner."""
import csv
import importlib.util
from pathlib import Path
import sys
import tempfile
import csv


CAL = Path(__file__).resolve().parent
sys.path.insert(0, str(CAL))
spec = importlib.util.spec_from_file_location("run_095", CAL / "run-095.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)

manifest_path = Path(sys.argv[1])
with manifest_path.open(newline="", encoding="utf-8") as stream:
    manifest = list(csv.DictReader(stream))

# A prepared registry may also pin a stage-two-manifest.csv. The runner must
# resolve the prepared manifest by its exact basename, not a loose suffix.
with tempfile.TemporaryDirectory(prefix="manifest-registry-lookup-") as tmp:
    registry = Path(tmp) / "source-hashes.csv"
    prepared_manifest = Path(tmp) / "prepared" / "manifest.csv"
    stage_two_manifest = Path(tmp) / "docs" / "stage-two-manifest.csv"
    prepared_manifest.parent.mkdir()
    stage_two_manifest.parent.mkdir()
    prepared_manifest.write_text("index\n1\n")
    stage_two_manifest.write_text("index\n2\n")
    with registry.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
        writer.writeheader()
        writer.writerows([
            {"path": str(prepared_manifest), "sha256": "prepared"},
            {"path": str(stage_two_manifest), "sha256": "stage-two"},
        ])
    assert runner.registered_artifact(registry, "manifest.csv") == prepared_manifest.resolve()

design = {
    "design_mode": "clean_current", "master_seed": "2026101901",
    "profile_level": "0.95", "planned_attempts": "3000",
    "calibration_claim": "true", "clean_current_seed_stream": "2026101901",
    "excluded_historical_streams": "2026101702:6,2026101703:3000,2026101704:3000,2026101705:10000",
    "stage_two_manifest_sha256": "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98",
    "stage_two_status": "clean_current_manifest_frozen_adapter_reconciliation_outstanding_not_authorized",
}
assert runner.validate_design(manifest, design, list(range(1, 3001)), False) is True
assert runner.validate_clean_current_manifest(manifest, manifest_path) is True

try:
    runner.validate_design(manifest, {"design_mode": "clean_current", "master_seed": "2026101901"},
                           list(range(1, 3001)), False)
except ValueError:
    pass
else:
    raise AssertionError("runner accepted a receipt that omitted the frozen analysis contract")

wrong_seed_values = [dict(row, seed="1") for row in manifest]
try:
    runner.validate_clean_current_manifest(wrong_seed_values, manifest_path)
except ValueError:
    pass
else:
    raise AssertionError("runner accepted clean-current metadata with a non-frozen seed stream")

with tempfile.TemporaryDirectory(prefix="incomplete-clean-registry-") as tmp:
    registry = Path(tmp) / "source-hashes.csv"
    with registry.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
        writer.writeheader()
        writer.writerow({"path": str(manifest_path), "sha256": "unused"})
    try:
        runner.require_mode_registry(Path(tmp), "clean_current")
    except ValueError:
        pass
    else:
        raise AssertionError("runner accepted an incomplete source registry")

wrong_seed = [dict(row, master_seed="2026101703") for row in manifest]
try:
    runner.validate_design(wrong_seed, design, list(range(1, 3001)), False)
except ValueError:
    pass
else:
    raise AssertionError("runner accepted a manifest with historical seed metadata")

try:
    runner.validate_design(manifest, design, [1, 1001, 2001], True)
except ValueError:
    pass
else:
    raise AssertionError("runner accepted a qualification-style subset for clean look one")

worker = (CAL / "worker-095.R").read_text()
summarizer = (CAL / "summarize-095.R").read_text()
assert 'if (identical(suffix, "manifest.csv")) basename(paths) == suffix' in worker
assert "registry_matches(hashes$path, suffix)" in worker
assert 'identical(design[["design_mode"]], "clean_current")' in worker
assert "validate_clean_look1_manifest(file.path(out, \"manifest.csv\"), expected = frozen_look1)" in worker
assert "validate_clean_bernoulli_seed_bundle(clean_seed_dir)" in worker
assert "validate_clean_current_receipt(design, clean_look2_path)" in worker
assert "registered_source(\"native-calibration/clean-manifests.R\")" in worker
assert "source(registered_source(\"tests/testthat/helper-binomial-sd-regression.R\"))" in worker
assert "Executing worker differs from the source-registry-pinned worker" in worker
assert 'identical(design_mode, "clean_current") && master_seed == 2026101901L' in summarizer
assert "validate_clean_look1_manifest(manifest_path," in summarizer
assert "validate_clean_bernoulli_seed_bundle(dirname(clean_look1_path))" in summarizer
assert "validate_clean_current_receipt(design, clean_look2_path)" in summarizer
assert "if (!summary_tool_registered)" in summarizer

print("PASS: runner accepts the clean-current look-one manifest and rejects mismatched seeds/subsets")
