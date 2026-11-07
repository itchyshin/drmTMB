#!/usr/bin/env python3
"""Fail-closed identity and execution helpers for the optional second look.

This adapter consumes the frozen seed manifest. It does not create seeds or
authorize a run; callers must provide the externally sealed GO record.
"""
from __future__ import annotations

import csv
import hashlib
import importlib.util
import json
import math
import subprocess
import sys
import shutil
import statistics
import tarfile
import tempfile
import time
from decimal import Decimal, InvalidOperation
from pathlib import Path

HERE = Path(__file__).resolve().parent
BASE = HERE.parent / "native-calibration"
sys.path.insert(0, str(BASE))
from integrity import verify as verify_registry  # noqa: E402

SEED_SHA = "8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96"
SOURCE_ARCHIVE_SHA = "d36bd0dac4c7bb8a8d7ce7a82e70299c95dcc5774e4a0071ea8bf2692e7aea60"
CLEAN_CURRENT_SOURCE_ARCHIVE_SHA = "84319a4620935d528a9bc84c8a69ffee9538f573d72ec16ccb6c65f31de8320e"
MASTER = 2026101705
ROWS_PER_BATCH = 3000
TRUTHS = (-0.5, 0.0, 0.5)
CAPS = {"workers": 16, "case_timeout_seconds": 120,
        "batch_timeout_seconds": 3300, "outer_timeout_seconds": 10500}

TIMING_CAPSULE_SHA256 = {
    "README.md": "5e7bd9c425b0415b42959a9075a6fd460f67ac41006a32bcd105078d7fd918bb",
    "capsule/manifest.csv": "47461e810a80c8aa7f6618497f9fe963c586f4db63f83ade4efdefccc767c1c7",
    "capsule/supervisor-receipt.json": "024db54bb93b2a2e9cc0a2237f6ea075d353c06e9ce134bfd3e2e53e78ef4a9d",
    "capsule/timing-summary.csv": "8bd9e399aa76ef33c3e0618cee4384c1e7182d169cfee52eab91b7421834eebe",
    "capsule/timing-summary.md": "466c864ec890e12a9197c86c730b8bdf2c8e93295be8a0b412e3d53d6e733408",
    "capsule/source-hashes.csv": "c192ec984e838c1f4d6a2a6211ff6892f8e1373a51ee738719524a743cdb4772",
    "source-used.tar.gz": "a37d402265530d4c514d91282e1bfb6b2c2cc1cb1b2b22bb7eae583eeebf8a9a",
}
# These are the approved clean-current manifest digests recorded in
# staged-calibration-contract.md; older/historical manifests are not accepted.
FROZEN_LOOK_MANIFEST_SHA256 = {
    "look-one": "5e4c567c21cdb3bdabc61119d453563751447fe2fc011faa09f8b795bbdf80cb",
    "look-two": "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def _registered_seed_set(path: Path, expected_sha256: str, label: str) -> set[str]:
    if sha256(path) != expected_sha256:
        raise ValueError(f"frozen {label} manifest digest differs from the approved contract")
    rows = read_csv(path)
    if not rows or "seed" not in rows[0]:
        raise ValueError(f"frozen seed manifest lacks seed values: {path}")
    seeds = [row["seed"] for row in rows]
    if any(not seed.isdigit() for seed in seeds) or len(set(seeds)) != len(seeds):
        raise ValueError(f"frozen seed manifest has malformed or duplicate seeds: {path}")
    return set(seeds)


def _require_timing_seed_disjoint(timing_seeds: set[str], look_one_seeds: set[str],
                                 look_two_seeds: set[str]) -> None:
    if timing_seeds & look_one_seeds:
        raise ValueError("timing capsule seeds overlap frozen look-one seeds")
    if timing_seeds & look_two_seeds:
        raise ValueError("timing capsule seeds overlap frozen look-two seeds")


def validate_timing_capsule(capsule_root: Path | None = None,
                            repo_root: Path | None = None,
                            look_one_manifest: Path | None = None,
                            look_two_manifest: Path | None = None) -> dict:
    """Authenticate the retained timing-only capsule; never qualifies the adapter."""
    repo_root = (Path(repo_root) if repo_root is not None else HERE.parents[2]).resolve(strict=True)
    capsule_root = (Path(capsule_root) if capsule_root is not None else
                    repo_root / "docs/dev-log/general-sd-regression/evidence"
                    / "calibration-20261023/timing-current-source-v1").resolve(strict=True)
    seed_root = (repo_root / "docs/dev-log/general-sd-regression/evidence"
                 / "calibration-20261019/clean-current-seed-design-v1")
    look_one_manifest = Path(look_one_manifest) if look_one_manifest is not None else seed_root / "look1.csv"
    look_two_manifest = Path(look_two_manifest) if look_two_manifest is not None else seed_root / "look2.csv"

    paths = {name: capsule_root / name for name in TIMING_CAPSULE_SHA256}
    for name, expected in TIMING_CAPSULE_SHA256.items():
        path = paths[name]
        if not path.is_file() or sha256(path) != expected:
            raise ValueError(f"timing capsule {name} digest differs from its frozen identity")

    readme = paths["README.md"].read_text()
    for digest in (TIMING_CAPSULE_SHA256["capsule/manifest.csv"],
                   TIMING_CAPSULE_SHA256["capsule/supervisor-receipt.json"],
                   TIMING_CAPSULE_SHA256["capsule/timing-summary.csv"],
                   TIMING_CAPSULE_SHA256["capsule/source-hashes.csv"],
                   TIMING_CAPSULE_SHA256["source-used.tar.gz"]):
        if digest not in readme:
            raise ValueError("timing capsule README does not bind its retained artifact hashes")

    manifest_path = paths["capsule/manifest.csv"]
    summary_path = paths["capsule/timing-summary.csv"]
    supervisor_path = paths["capsule/supervisor-receipt.json"]
    registry_path = paths["capsule/source-hashes.csv"]
    manifest = read_csv(manifest_path)
    if (len(manifest) != 45 or [int(row["index"]) for row in manifest] != list(range(1, 46))
            or any(row.get("design_mode") != "timing_only"
                   or row.get("master_seed") != "2026101903" for row in manifest)):
        raise ValueError("timing capsule manifest is not the frozen 45-row timing design")
    timing_seeds = {row["seed"] for row in manifest}
    if len(timing_seeds) != 45 or any(not seed.isdigit() for seed in timing_seeds):
        raise ValueError("timing capsule manifest has malformed or duplicate seeds")

    supervisor = json.loads(supervisor_path.read_text())
    cases = supervisor.get("cases", [])
    if (supervisor.get("manifest_sha256") != TIMING_CAPSULE_SHA256["capsule/manifest.csv"]
            or supervisor.get("registry_sha256") != TIMING_CAPSULE_SHA256["capsule/source-hashes.csv"]
            or supervisor.get("design_mode") != "timing_only"
            or supervisor.get("calibration_claim") is not False
            or supervisor.get("campaign_complete") is not True
            or supervisor.get("interrupted") is not False
            or len(cases) != 45
            or sorted(case.get("index", -1) for case in cases) != list(range(1, 46))
            or any(case.get("status") != "completed" or case.get("returncode") != 0
                   for case in cases)):
        raise ValueError("timing capsule supervisor receipt is incomplete or inconsistent")
    summary = read_csv(summary_path)
    if (len(summary) != 4
            or any(row.get("calibration_claim", "").lower() != "false" for row in summary)
            or summary[-1].get("planned") != "45"
            or summary[-1].get("completed") != "45"
            or summary[-1].get("status") != "timing_only_nonqualifying"):
        raise ValueError("timing capsule summary is not explicitly nonqualifying")

    manifest_by_index = {int(row["index"]): row for row in manifest}
    supervisor_by_index = {int(row["index"]): row for row in cases}
    result_paths = sorted((capsule_root / "capsule").glob("result-*.csv"))
    expected_result_names = [f"result-{index:04d}.csv" for index in range(1, 46)]
    if [path.name for path in result_paths] != expected_result_names:
        raise ValueError("timing capsule does not contain exactly results 0001 through 0045")
    result_rows = []
    required_result_fields = {
        "index", "a", "replicate", "seed", "state", "calibration_claim", "estimate", "se",
        "convergence", "pdHess", "max_abs_gradient", "clamp_at_optimum", "lower", "upper",
        "profile_level", "interval_status", "profile_boundary", "profile_message",
        "valid_interval", "laplace_oracle_error", "oracle_pass", "oracle_tolerance",
        "warnings", "error", "elapsed",
    }
    for result_path in result_paths:
        rows = read_csv(result_path)
        expected_index = int(result_path.stem.split("-")[1])
        if len(rows) != 1 or not required_result_fields.issubset(rows[0]):
            raise ValueError(f"timing result row is missing or malformed: {result_path.name}")
        row = rows[0]
        source = manifest_by_index[expected_index]
        supervisor_case = supervisor_by_index[expected_index]
        if (row.get("index") != str(expected_index)
                or row.get("seed") != source["seed"]
                or row.get("replicate") != source["replicate"]
                or not math.isclose(float(row["a"]), float(source["a"]), rel_tol=0, abs_tol=1e-12)
                or row.get("state") != "completed"
                or supervisor_case.get("status") != "completed"
                or supervisor_case.get("returncode") != 0):
            raise ValueError(f"timing result row identity or supervisor state differs: {result_path.name}")
        try:
            numeric = {key: float(row[key]) for key in (
                "estimate", "se", "max_abs_gradient", "lower", "upper", "profile_level",
                "laplace_oracle_error", "oracle_tolerance", "elapsed")}
        except (TypeError, ValueError) as exc:
            raise ValueError(f"timing result row has malformed diagnostics: {result_path.name}") from exc
        if any(not math.isfinite(value) for value in numeric.values()):
            raise ValueError(f"timing result row has nonfinite diagnostics: {result_path.name}")
        if (row.get("calibration_claim", "").lower() != "false"
                or row.get("convergence") != "0" or row.get("pdHess", "").lower() != "true"
                or numeric["se"] <= 0 or numeric["max_abs_gradient"] >= 1e-3
                or row.get("clamp_at_optimum") != "ok"
                or not math.isclose(numeric["profile_level"], 0.95, rel_tol=0, abs_tol=1e-12)
                or row.get("interval_status") != "profile"
                or row.get("profile_boundary", "").lower() != "false"
                or row.get("profile_message") != "ok"
                or row.get("valid_interval", "").lower() != "true"
                or row.get("oracle_pass", "").lower() != "true"
                or numeric["oracle_tolerance"] != 1e-6
                or abs(numeric["laplace_oracle_error"]) >= numeric["oracle_tolerance"]
                or numeric["lower"] >= numeric["upper"]
                or numeric["elapsed"] <= 0
                or row.get("warnings", "") != "" or row.get("error", "") != ""):
            raise ValueError(f"timing result diagnostics failed: {result_path.name}")
        row["_elapsed_value"] = numeric["elapsed"]
        result_rows.append(row)

    summary_by_truth = {float(row["a"]): row for row in summary if row.get("group") != "overall"}
    for truth in (-0.5, 0.0, 0.5):
        group = [row for row in result_rows if float(row["a"]) == truth]
        aggregate = summary_by_truth.get(truth)
        if aggregate is None or len(group) != 15:
            raise ValueError(f"timing result rows do not match the summary group for truth {truth}")
        observed_mean = statistics.mean(row["_elapsed_value"] for row in group)
        observed_median = statistics.median(row["_elapsed_value"] for row in group)
        if (aggregate.get("planned") != "15" or aggregate.get("completed") != "15"
                or aggregate.get("valid_profiles") != "15"
                or aggregate.get("profile_failures") != "0"
                or aggregate.get("profile_boundaries") != "0"
                or aggregate.get("warnings") != "0"
                or aggregate.get("elapsed_n") != "15"
                or not math.isclose(float(aggregate["mean_elapsed"]), observed_mean,
                                    rel_tol=0, abs_tol=5e-7)
                or not math.isclose(float(aggregate["median_elapsed"]), observed_median,
                                    rel_tol=0, abs_tol=5e-4)):
            raise ValueError(f"timing result rows disagree with summary group for truth {truth}")
    overall = next((row for row in summary if row.get("group") == "overall"), None)
    if (overall is None
            or overall.get("planned") != "45" or overall.get("completed") != "45"
            or overall.get("valid_profiles") != "45"
            or overall.get("profile_failures") != "0"
            or overall.get("profile_boundaries") != "0"
            or overall.get("warnings") != "0"
            or overall.get("elapsed_n") != "45"
            or not math.isclose(float(overall["mean_elapsed"]),
                                statistics.mean(row["_elapsed_value"] for row in result_rows),
                                rel_tol=0, abs_tol=5e-7)
            or not math.isclose(float(overall["median_elapsed"]),
                                statistics.median(row["_elapsed_value"] for row in result_rows),
                                rel_tol=0, abs_tol=5e-4)):
        raise ValueError("timing result rows disagree with overall summary")

    registry_rows = read_csv(registry_path)
    source_rows = [row for row in registry_rows if "/source/" in row["path"]]
    library_rows = [row for row in registry_rows if "/library/drmTMB/" in row["path"]]
    if len(source_rows) != 26 or len(library_rows) != 6:
        raise ValueError("timing capsule source registry does not contain 26 source and 6 installed-library hashes")
    archive_path = paths["source-used.tar.gz"]
    with tarfile.open(archive_path, "r:gz") as archive:
        archive_names = set(archive.getnames())
        for row in source_rows:
            relative = row["path"].split("/source/", 1)[1]
            relative_path = Path(relative)
            if relative_path.is_absolute() or ".." in relative_path.parts:
                raise ValueError("timing capsule source registry contains an unsafe path")
            source_path = repo_root / relative_path
            archive_name = (Path("source") / relative_path).as_posix()
            if (not source_path.is_file() or sha256(source_path) != row["sha256"]
                    or archive_name not in archive_names):
                raise ValueError(f"timing capsule source hash differs: {relative}")
            archived = archive.extractfile(archive_name)
            if archived is None or hashlib.sha256(archived.read()).hexdigest() != row["sha256"]:
                raise ValueError(f"timing capsule source tarball hash differs: {relative}")
    for row in library_rows:
        artifact = capsule_root / "library" / Path(row["path"]).name
        if not artifact.is_file() or sha256(artifact) != row["sha256"]:
            raise ValueError(f"timing capsule installed-library hash differs: {artifact.name}")

    look_one_seeds = _registered_seed_set(
        look_one_manifest.resolve(strict=True), FROZEN_LOOK_MANIFEST_SHA256["look-one"], "look-one")
    look_two_seeds = _registered_seed_set(
        look_two_manifest.resolve(strict=True), FROZEN_LOOK_MANIFEST_SHA256["look-two"], "look-two")
    _require_timing_seed_disjoint(timing_seeds, look_one_seeds, look_two_seeds)

    return {
        "schema": "native-sd-timing-capsule-identity-v1",
        "capsule_readme_sha256": TIMING_CAPSULE_SHA256["README.md"],
        "manifest_sha256": TIMING_CAPSULE_SHA256["capsule/manifest.csv"],
        "supervisor_sha256": TIMING_CAPSULE_SHA256["capsule/supervisor-receipt.json"],
        "summary_csv_sha256": TIMING_CAPSULE_SHA256["capsule/timing-summary.csv"],
        "summary_markdown_sha256": TIMING_CAPSULE_SHA256["capsule/timing-summary.md"],
        "source_registry_sha256": TIMING_CAPSULE_SHA256["capsule/source-hashes.csv"],
        "source_tarball_sha256": TIMING_CAPSULE_SHA256["source-used.tar.gz"],
        "source_file_count": len(source_rows),
        "installed_library_file_count": len(library_rows),
        "result_row_count": len(result_rows),
        "result_rows_consistent_with_manifest_supervisor_and_summary": True,
        "result_output_hashes_sealed": False,
        "timing_seed_count": len(timing_seeds),
        "disjoint_from_frozen_look_one": True,
        "disjoint_from_frozen_look_two": True,
        "evidence_scope": "timing_only_worker_health",
        "adapter_qualification": False,
        "calibration_claim": False,
    }


def resolve_registered_profile_worker(registry_rows: list[dict[str, str]]) -> Path:
    """Return the exact 95% worker path pinned by a batch source registry."""
    suffix = "native-calibration/worker-095.R"
    matches = [row for row in registry_rows
               if Path(row["path"]).as_posix().endswith(suffix)]
    if len(matches) != 1:
        raise ValueError("registry must pin exactly one 95% profile worker")
    worker = Path(matches[0]["path"]).resolve(strict=True)
    if sha256(worker) != matches[0]["sha256"]:
        raise ValueError("registry-pinned 95% profile worker hash does not match")
    return worker


def worker_library_search_path(package_directory: Path) -> str:
    """Return the R library root containing the pinned package directory."""
    return str(Path(package_directory).resolve().parent)


def sealed_reconstruction_file(seal: dict, name: str) -> Path:
    """Resolve a replay script only when it matches the external source seal."""
    source_directory = Path(seal["reconstruction_source_directory"])
    expected = seal["reconstruction_source_sha256"][name]
    path = source_directory / name
    if not path.is_file() or sha256(path) != expected:
        raise ValueError(f"reconstruction source differs from external seal: {name}")
    return path


def first_look_replay_command(seal: dict, first_look: Path, seal_path: Path,
                              standardized: Path, rscript: str = "Rscript") -> list[str]:
    """Build a replay command from the verifier pinned by the first-look seal."""
    verifier = sealed_reconstruction_file(seal, "verify-first-look.R")
    return [str(rscript), str(verifier), str(first_look), str(seal_path),
            str(standardized)]


def attempt_digest(directory: Path, expected_results: int | None = None,
                   expected_indices: list[int] | None = None,
                   allowed_indices: list[int] | None = None) -> str:
    """Digest ordered attempts, optionally requiring all planned or completed indices."""
    files = [directory / "manifest.csv", directory / "supervisor-receipt.json"]
    result_candidates = sorted(directory.glob("result-*.csv"))
    malformed = [path.name for path in result_candidates
                 if (not path.stem.startswith("result-")
                     or len(path.stem[7:]) != 4 or not path.stem[7:].isdigit())]
    if malformed:
        raise ValueError("result filenames must use exactly four digits: "
                         + ", ".join(malformed))
    results = result_candidates
    if expected_results is not None and (expected_indices is not None or allowed_indices is not None):
        raise ValueError("expected_results cannot be combined with index constraints")
    if expected_indices is not None and allowed_indices is None:
        allowed_indices = expected_indices
    if expected_results is not None:
        expected_names = [f"result-{i:04d}.csv" for i in range(1, expected_results + 1)]
        observed_names = [path.name for path in results]
        if observed_names != expected_names:
            raise ValueError(f"attempt capsule must contain exactly the expected results 1..{expected_results}")
    if expected_indices is not None:
        if any(not isinstance(i, int) or i < 1 for i in expected_indices) or len(set(expected_indices)) != len(expected_indices):
            raise ValueError("expected completed indices must be unique positive integers")
        observed_indices = {int(path.stem.split("-")[-1]) for path in results}
        if not set(expected_indices).issubset(observed_indices):
            raise ValueError("attempt capsule lacks a result for an expected completed index")
    if allowed_indices is not None:
        if any(not isinstance(i, int) or i < 1 for i in allowed_indices) or len(set(allowed_indices)) != len(allowed_indices):
            raise ValueError("allowed indices must be unique positive integers")
        observed_indices = {int(path.stem.split("-")[-1]) for path in results}
        if not observed_indices.issubset(set(allowed_indices)):
            raise ValueError("attempt capsule contains a result outside the planned index set")
    files += results
    if not all(p.is_file() for p in files[:2]):
        raise ValueError("attempt capsule lacks manifest or supervisor receipt")
    payload = "\n".join(f"{p.name}|{sha256(p)}" for p in files).encode()
    return hashlib.sha256(payload).hexdigest()


def validate_reconstruction_sources(first_seal: dict) -> None:
    """Verify the exact code that reconstructed and replayed the first look."""
    source_names = {"stage_two.py", "reconstruct-first-look.py", "stage-two-rules.R",
                    "verify-first-look.R", "combine-stage-two.R"}
    source_dir = first_seal.get("reconstruction_source_directory")
    hashes = first_seal.get("reconstruction_source_sha256")
    if (not isinstance(source_dir, str) or not source_dir
            or not isinstance(hashes, dict) or set(hashes) != source_names):
        raise ValueError("first-look seal lacks a complete reconstruction source map")
    directory = Path(source_dir)
    for name in sorted(source_names):
        expected = hashes[name]
        path = directory / name
        if (not isinstance(expected, str) or len(expected) != 64
                or any(char not in "0123456789abcdef" for char in expected)
                or not path.is_file() or sha256(path) != expected):
            raise ValueError(f"first-look reconstruction source differs from its seal: {name}")


def reconstruct_first_look(summary_root: Path, raw_attempt_root: Path, archive: Path,
                           original_seal_path: Path, original_seal_sha256: str,
                           output_root: Path, new_seal_path: Path,
                           expected_archive_sha256: str,
                           expected_results: int = 3000) -> dict:
    """Rebuild the raw first-look view from the archive without changing its source."""
    summary_root = summary_root.resolve(strict=True)
    raw_attempt_root = raw_attempt_root.resolve(strict=True)
    archive = archive.resolve(strict=True)
    original_seal_path = original_seal_path.resolve(strict=True)
    output_root = output_root.absolute()
    new_seal_path = new_seal_path.absolute()
    if output_root.exists() or new_seal_path.exists():
        raise FileExistsError("refusing to overwrite a reconstructed first-look artifact")

    old_seal = json.loads(original_seal_path.read_text())
    if sha256(original_seal_path) != original_seal_sha256:
        raise ValueError("original first-look seal differs from its retained digest")
    registry = summary_root / "source-hashes.csv"
    manifest = summary_root / "manifest.csv"
    supervisor_path = summary_root / "supervisor-receipt.json"
    collection_path = summary_root / "root-collection-receipt.json"
    if not all(path.is_file() for path in (registry, manifest, supervisor_path, collection_path)):
        raise ValueError("first-look summary capsule lacks sealed source or supervisor artifacts")
    registry_sha = sha256(registry)
    manifest_sha = sha256(manifest)
    if old_seal.get("registry_sha256") != registry_sha:
        raise ValueError("original first-look seal does not bind the summary registry")
    # The prior digest is deliberately checked and retained as evidence. In this
    # historical capsule it covers only manifest + supervisor, not raw results.
    if old_seal.get("attempts_sha256") != attempt_digest(summary_root):
        raise ValueError("original first-look attempt digest is not reproducible")

    collection = json.loads(collection_path.read_text())
    archive_sha = sha256(archive)
    if archive_sha != expected_archive_sha256:
        raise ValueError("raw-attempt archive differs from the independently supplied archive digest")
    if (archive_sha != collection.get("archive_sha256")
            or archive.stat().st_size != collection.get("archive_bytes")
            or collection.get("attempts") != expected_results
            or collection.get("campaign_complete") is not True):
        raise ValueError("raw-attempt archive does not match the retained collection receipt")
    reconstruction_sources = {
        "stage_two.py": sha256(Path(__file__).resolve()),
        "reconstruct-first-look.py": sha256(HERE / "reconstruct-first-look.py"),
        "stage-two-rules.R": sha256(HERE / "stage-two-rules.R"),
        "verify-first-look.R": sha256(HERE / "verify-first-look.R"),
        "combine-stage-two.R": sha256(HERE / "combine-stage-two.R"),
    }
    supervisor = json.loads(supervisor_path.read_text())
    cases = supervisor.get("cases", [])
    if (supervisor.get("campaign_complete") is not True
            or supervisor.get("subset_complete") is not True
            or supervisor.get("interrupted") is not False
            or supervisor.get("registry_sha256") != registry_sha
            or supervisor.get("manifest_sha256") != manifest_sha
            or len(cases) != expected_results
            or sorted(int(x.get("index", -1)) for x in cases) != list(range(1, expected_results + 1))
            or any(x.get("status") != "completed" or x.get("returncode") != 0 for x in cases)):
        raise ValueError("first-look supervisor does not attest the complete indexed campaign")

    expected_names = [f"result-{i:04d}.csv" for i in range(1, expected_results + 1)]
    raw_manifest = raw_attempt_root / "manifest.csv"
    raw_registry = raw_attempt_root / "source-hashes.csv"
    if (not raw_manifest.is_file() or sha256(raw_manifest) != manifest_sha
            or not raw_registry.is_file() or sha256(raw_registry) != registry_sha):
        raise ValueError("raw-attempt directory differs from the sealed manifest or registry")
    raw_results = sorted(raw_attempt_root.glob("result-????.csv"))
    if [p.name for p in raw_results] != expected_names:
        raise ValueError("raw-attempt directory does not contain every expected result file")
    with tarfile.open(archive, "r:gz") as tf:
        archive_names = set(tf.getnames())
        prefix = "production-prepared/"
        archived_results = {name[len(prefix):] for name in archive_names
                             if name.startswith(prefix) and name.endswith(".csv")
                             and name[len(prefix):].startswith("result-")}
        if archived_results != set(expected_names):
            raise ValueError("raw-attempt archive does not contain the exact indexed result set")
        archived_manifest = tf.extractfile(prefix + "manifest.csv")
        archived_registry = tf.extractfile(prefix + "source-hashes.csv")
        if (archived_manifest is None or hashlib.sha256(archived_manifest.read()).hexdigest() != manifest_sha
                or archived_registry is None or hashlib.sha256(archived_registry.read()).hexdigest() != registry_sha):
            raise ValueError("raw-attempt archive manifest or registry differs from the sealed capsule")
        for path in raw_results:
            member = tf.extractfile(prefix + path.name)
            if member is None or hashlib.sha256(member.read()).hexdigest() != sha256(path):
                raise ValueError(f"raw-attempt file differs from the retained archive: {path.name}")

    shutil.copytree(summary_root, output_root)
    try:
        if list(output_root.glob("result-????.csv")):
            raise ValueError("summary capsule unexpectedly contains raw result files")
        for path in raw_results:
            (output_root / path.name).symlink_to(path)
        full_digest = attempt_digest(output_root, expected_results=expected_results)
        new_seal = dict(old_seal)
        new_seal.update({"attempts_sha256": full_digest,
                         "attempt_digest_contract": f"manifest+supervisor+result-0001..{expected_results:04d}",
                         "raw_attempt_archive_sha256": archive_sha,
                         "raw_attempt_archive_bytes": archive.stat().st_size,
                         "raw_attempt_archive_path": str(archive),
                         "raw_attempt_result_files": expected_results,
                         "raw_attempt_manifest_sha256": manifest_sha,
                         "original_seal_sha256": original_seal_sha256,
                         "collection_receipt_sha256": sha256(collection_path),
                         "reconstruction_source_sha256": reconstruction_sources,
                         "reconstruction_source_directory": str(HERE),
                         "reconstruction_contract": "external-original-seal+external-archive-digest+collection-receipt+full-results",
                         "raw_attempt_source_directory": str(raw_attempt_root)})
        new_seal_path.write_text(json.dumps(new_seal, indent=2, sort_keys=True) + "\n")
    except Exception:
        shutil.rmtree(output_root)
        raise
    return {"status": "RECONSTRUCTED", "raw_result_files": expected_results,
            "raw_attempt_archive_sha256": archive_sha,
            "raw_attempt_archive_bytes": archive.stat().st_size,
            "original_seal_sha256": original_seal_sha256,
            "collection_receipt_sha256": sha256(collection_path),
            "reconstruction_source_sha256": reconstruction_sources,
            "registry_sha256": registry_sha, "manifest_sha256": manifest_sha,
            "attempts_sha256": full_digest, "new_seal_sha256": sha256(new_seal_path),
            "output_root": str(output_root), "new_seal_path": str(new_seal_path)}


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def validate_go(go: dict, go_sha: str, first_seal: dict, go_path: Path,
                first_seal_sha256: str | None = None) -> None:
    """Validate the recorded approval, qualification, runtime evidence, and caps."""
    if go.get("decision") != "look2_required":
        raise ValueError("second look requires an externally recorded look2_required decision")
    if go.get("first_look_registry_sha256") != first_seal.get("registry_sha256"):
        raise ValueError("GO record does not bind the retained first-look registry seal")
    if go.get("first_look_decision_sha256") != first_seal.get("decision_sha256"):
        raise ValueError("GO record does not bind the retained first-look decision digest")
    if go.get("look") != 1:
        raise ValueError("GO record is not for the first-look decision")
    validate_reconstruction_sources(first_seal)
    for key in ("approved_goal_sha256", "approved_plan_sha256",
                "qualification_receipt_sha256", "runtime_receipt_sha256"):
        value = go.get(key)
        if not isinstance(value, str) or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
            raise ValueError(f"GO record lacks a valid {key}")
    if not isinstance(go.get("approved_goal_id"), str) or not go["approved_goal_id"].strip():
        raise ValueError("GO record lacks approved_goal_id")
    base = go_path.resolve().parent
    for key in ("approved_goal_path", "approved_plan_path",
                "qualification_receipt_path", "runtime_receipt_path"):
        if not isinstance(go.get(key), str) or not go[key]:
            raise ValueError(f"GO record lacks {key}")
    goal_path = (base / go["approved_goal_path"]).resolve(strict=True)
    plan_path = (base / go["approved_plan_path"]).resolve(strict=True)
    if sha256(goal_path) != go["approved_goal_sha256"] or sha256(plan_path) != go["approved_plan_sha256"]:
        raise ValueError("approved goal or plan file differs from the GO record digest")
    qualification_path = (base / go["qualification_receipt_path"]).resolve(strict=True)
    runtime_path = (base / go["runtime_receipt_path"]).resolve(strict=True)
    if sha256(qualification_path) != go["qualification_receipt_sha256"]:
        raise ValueError("adapter qualification receipt digest differs")
    if sha256(runtime_path) != go["runtime_receipt_sha256"]:
        raise ValueError("runtime evidence receipt digest differs")
    qualification = json.loads(qualification_path.read_text())
    validate_adapter_qualification(qualification)
    if (qualification.get("aggregate_registry_sha256") != go.get("qualification_registry_sha256")
            or qualification.get("source_registry_sha256") != first_seal.get("registry_sha256")
            or qualification.get("first_look_registry_sha256") != first_seal.get("registry_sha256")
            or qualification.get("source_manifest_sha256") != SEED_SHA):
        raise ValueError("adapter qualification receipt is incomplete or not source-bound")
    if (first_seal_sha256 is not None
            and qualification.get("first_look_seal_sha256") != first_seal_sha256):
        raise ValueError("adapter qualification is bound to a different first-look seal")
    replay_adapter_qualification(qualification)
    library = Path(qualification.get("library", "")).resolve(strict=True)
    validate_binary_receipt(first_seal, library)
    for artifact in qualification["library_artifacts"]:
        artifact_path = Path(artifact["path"]).resolve(strict=True)
        if library not in artifact_path.parents or sha256(artifact_path) != artifact["sha256"]:
            raise ValueError("adapter qualification installed-library artifact has changed")
    for batch in qualification["batches"]:
        for prefix in ("registry", "manifest", "supervisor", "result"):
            artifact_path = Path(batch[f"{prefix}_path"]).resolve(strict=True)
            if sha256(artifact_path) != batch[f"{prefix}_sha256"]:
                raise ValueError(f"adapter qualification {prefix} artifact changed")
    timing = json.loads(runtime_path.read_text())
    if (timing.get("operational_stress") != "PASS" or timing.get("timing_gate") is not True
            or timing.get("independent_replicates") is not False
            or timing.get("planning_gate_seconds") != 3000
            or timing.get("campaign_cap_seconds") != 3600):
        raise ValueError("runtime evidence receipt does not pass its bounded timing gate")
    per_batch = float(timing.get("projected_production_seconds", float("nan")))
    projected = float(go.get("projected_total_seconds", float("nan")))
    timing_formula = (float(timing.get("maximum_worker_wall_seconds", float("nan")))
                      * float(timing.get("production_waves", float("nan")))
                      + float(timing.get("additional_overhead_allowance_seconds", float("nan"))))
    if (go.get("runtime_batches") != 3 or not (per_batch > 0)
            or timing.get("repeated_attempts") != 15
            or not math.isclose(per_batch, timing_formula, rel_tol=0, abs_tol=1e-9)
            or per_batch > timing["planning_gate_seconds"]
            or not math.isclose(projected, 3 * per_batch, rel_tol=0, abs_tol=1e-9)
            or projected > min(10800, CAPS["outer_timeout_seconds"])):
        raise ValueError("GO runtime estimate or three-batch calculation exceeds the approved bound")
    caps = go.get("caps")
    if caps != CAPS:
        raise ValueError("GO record declared caps differ from the frozen adapter caps")


def validate_prior_stream(rows: list[dict[str, str]], path: Path,
                          expected_rows: int, expected_master: int) -> None:
    if len(rows) != expected_rows or not rows:
        raise ValueError(f"prior seed stream row count mismatch: {path}")
    try:
        masters = {int(row["master_seed"]) for row in rows} if "master_seed" in rows[0] else set()
        index_key = "index" if "index" in rows[0] else "manifest_row"
        if index_key not in rows[0]:
            # The retained six-row pilot predates explicit row IDs. Admit only
            # that frozen stream; the paired R verifier checks its exact seed,
            # truth, and pilot-label order before preparation.
            if expected_rows != 6 or expected_master != 2026101702:
                raise KeyError(index_key)
            indices = list(range(1, expected_rows + 1))
        else:
            indices = [int(row[index_key]) for row in rows]
        seeds = [int(row["seed"]) for row in rows]
    except (KeyError, ValueError) as exc:
        raise ValueError(f"prior seed stream lacks valid identity columns: {path}") from exc
    if (masters not in (set(), {expected_master}) or indices != list(range(1, expected_rows + 1))
            or len(set(seeds)) != expected_rows):
        raise ValueError(f"prior seed stream identity mismatch: {path}")


def validate_binary_receipt(seal: dict, library: Path) -> None:
    """Require a mode-matched Bernoulli source/archive-to-library receipt."""
    source_mode = seal.get("source_design_mode", "production")
    archive_sha = {
        "legacy": SOURCE_ARCHIVE_SHA,
        "production": SOURCE_ARCHIVE_SHA,
        "clean_current": CLEAN_CURRENT_SOURCE_ARCHIVE_SHA,
    }.get(source_mode)
    if archive_sha is None or seal.get("harness_archive_sha256") != archive_sha:
        raise ValueError("first-look seal lacks the pinned source archive for its design mode")
    matched = set(seal.get("matched_original_native_artifacts", []))
    required = {"R/drmTMB.R", "R/methods.R", "R/profile.R", "src/drmTMB.cpp",
                "tests/testthat/helper-binomial-sd-regression.R"}
    if not required.issubset(matched):
        raise ValueError("source-to-installed-library receipt omits original Bernoulli source artifacts")
    runtime = [x for x in matched if Path(x).name in {"drmTMB.rdb", "drmTMB.rdx"}
               or Path(x).suffix.lower() in {".so", ".dylib", ".dll"}]
    library = library.resolve(strict=True)
    if len(runtime) < 3 or any(library not in Path(x).resolve(strict=True).parents for x in runtime):
        raise ValueError("source-to-installed-library receipt does not identify the supplied Bernoulli library")


def validate_batch_receipt(directory: Path, registry_sha: str,
                           expected_manifest_sha: str) -> dict:
    """Fail closed before the next batch unless this supervisor is terminal."""
    receipt_path = directory / "supervisor-receipt.json"
    receipt = json.loads(receipt_path.read_text())
    cases = receipt.get("cases", [])
    indices = [int(x.get("index", -1)) for x in cases]
    statuses = [x.get("status") for x in cases]
    if (receipt.get("registry_sha256") != registry_sha
            or receipt.get("manifest_sha256") != expected_manifest_sha
            or receipt.get("planned_indices") != list(range(1, 3001))
            or receipt.get("campaign_complete") is not True
            or receipt.get("subset_complete") is not True
            or receipt.get("interrupted") is not False
            or len(cases) != 3000 or len(set(indices)) != 3000
            or set(indices) != set(range(1, 3001))
            or any(s not in {"completed", "error", "timeout"} for s in statuses)):
        raise RuntimeError("stage-two batch supervisor receipt is incomplete or contradictory")
    if any(int(x.get("returncode", 0)) == 0 for x in cases if x.get("status") in {"error", "timeout"}):
        raise RuntimeError("stage-two supervisor marks a zero-exit case as failed")
    by_index = {int(x["index"]): x for x in cases}
    for i, case in by_index.items():
        result_path = directory / f"result-{i:04d}.csv"
        if case["status"] == "completed":
            if int(case.get("returncode", -1)) != 0 or not result_path.is_file():
                raise RuntimeError(f"completed batch case {i} lacks a successful result")
    return receipt


def validate_source(rows: list[dict[str, str]], path: Path,
                    excluded_seeds: set[int]) -> None:
    if path.is_file() and sha256(path) == _clean_current_adapter().EXPECTED_SHA256:
        adapter = _clean_current_adapter()
        frozen_rows = adapter.read_frozen_rows(path)
        if rows != frozen_rows:
            raise ValueError("clean-current rows differ from the exact frozen source manifest")
        adapter._validate_rows(frozen_rows)
        seeds = {int(row["seed"]) for row in frozen_rows}
        if seeds & excluded_seeds:
            raise ValueError("clean-current stage-two seeds overlap a prior stream")
        return
    if sha256(path) != SEED_SHA:
        raise ValueError("frozen stage-two source CSV SHA-256 mismatch")
    if len(rows) != 9000:
        raise ValueError("frozen stage-two source must contain exactly 9,000 rows")
    seeds = [int(r["seed"]) for r in rows]
    if len(set(seeds)) != 9000 or set(seeds) & excluded_seeds:
        raise ValueError("stage-two seeds are duplicated or overlap a prior stream")
    for i, row in enumerate(rows, 1):
        block = (i - 1) // 3000
        local = (i - 1) % 3000 + 1
        if (int(row["index"]) != i or float(row["a"]) != TRUTHS[block]
                or int(row["replicate"]) != 1000 + local
                or int(row["master_seed"]) != MASTER
                or row["design_mode"] != "stage_two_not_authorized"):
            raise ValueError(f"frozen source identity mismatch at row {i}")


def _clean_current_adapter():
    """Load the separately versioned, exact-source clean-current adapter."""
    adapter_path = HERE / "clean_current_stage_two.py"
    spec = importlib.util.spec_from_file_location(
        "clean_current_stage_two_for_orchestrator", adapter_path
    )
    if spec is None or spec.loader is None:
        raise ValueError("Could not load the clean-current stage-two validator")
    adapter = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(adapter)
    return adapter


def resolve_stage_two_source(registry_rows: list[dict[str, str]],
                             source_manifest_sha256: str) -> tuple[Path, bool]:
    """Resolve exactly one source manifest for the recorded stage-two mode."""
    clean_sha = _clean_current_adapter().EXPECTED_SHA256
    if source_manifest_sha256 == clean_sha:
        expected_name, clean_current = "look2.csv", True
    elif source_manifest_sha256 == SEED_SHA:
        expected_name, clean_current = "stage-two-manifest.csv", False
    else:
        raise ValueError("prepared root names an unsupported stage-two source digest")
    sources = [Path(row["path"]).resolve(strict=True) for row in registry_rows
               if Path(row["path"]).name == expected_name
               and row.get("sha256") == source_manifest_sha256]
    if len(sources) != 1 or sha256(sources[0]) != source_manifest_sha256:
        raise ValueError("registry does not pin exactly one frozen stage-two source manifest")
    return sources[0], clean_current


def validate_clean_current_batch_manifest(rows: list[dict[str, str]],
                                          frozen_path: Path,
                                          batch: int) -> bool:
    """Validate a clean-current batch against its pinned source transformation.

    The clean-current manifest has a separate seed stream and row schema from
    the legacy stage-two source. Delegate the byte-level and row-mapping
    contract to its dedicated adapter rather than coercing it through the
    legacy ``production`` manifest rules.
    """
    adapter = _clean_current_adapter()
    try:
        adapter.validate_batch(rows, frozen_path=frozen_path, batch_id=batch)
    except (ValueError, OSError, KeyError, TypeError) as exc:
        raise ValueError(f"clean-current stage-two batch {batch} is invalid: {exc}") from exc
    return True


def batch_rows(source_rows: list[dict[str, str]], batch: int) -> list[dict[str, str]]:
    if batch not in (1, 2, 3):
        raise ValueError("batch must be 1, 2, or 3")
    if len(source_rows) != 9000:
        raise ValueError("batch conversion requires the complete frozen 9,000-row source")
    if source_rows and source_rows[0].get("design_mode") == "clean_current":
        adapter = _clean_current_adapter()
        return adapter._transform_batch(source_rows, batch)
    rows = []
    for local, row in enumerate(source_rows[(batch-1)*3000:batch*3000], 1):
        if int(row["index"]) != (batch-1)*3000 + local:
            raise ValueError("source row order is not canonical")
        new = dict(row)
        new["stage_two_index"] = row["index"]
        new["index"] = str(local)
        new["batch_id"] = str(batch)
        new["design_mode"] = "production"
        new["master_seed"] = str(MASTER)
        rows.append(new)
    return rows


QUALIFICATION_CASES = {1: 1, 2: 1001, 3: 2001}


def same_finite_numeric_value(observed: object, expected: object) -> bool:
    """Compare numeric receipt values without depending on CSV formatting."""
    try:
        left = Decimal(str(observed))
        right = Decimal(str(expected))
    except (InvalidOperation, ValueError):
        return False
    return left.is_finite() and right.is_finite() and left == right


def qualification_registry_digest(batches: list[dict]) -> str:
    payload = "\n".join(f"{x['batch_id']}|{x['registry_sha256']}" for x in batches).encode()
    return hashlib.sha256(payload).hexdigest()


def validate_qualification_elapsed(elapsed_seconds: float) -> None:
    """Enforce the total 240-second adapter-probe deadline, including cleanup."""
    try:
        elapsed = float(elapsed_seconds)
    except (TypeError, ValueError) as exc:
        raise ValueError("adapter qualification lacks a valid elapsed-time receipt") from exc
    if not math.isfinite(elapsed) or elapsed < 0 or elapsed > 240:
        raise ValueError("adapter qualification exceeded its 240-second total cap")


def adapter_qualification_case(source_rows: list[dict[str, str]], batch: int) -> dict:
    """Return the frozen, cross-batch adapter probe identity for one truth."""
    if batch not in QUALIFICATION_CASES or len(source_rows) != 9000:
        raise ValueError("qualification mapping requires a complete source and batch 1..3")
    local_index = QUALIFICATION_CASES[batch]
    stage_two_index = (batch - 1) * ROWS_PER_BATCH + local_index
    row = source_rows[stage_two_index - 1]
    if (int(row["index"]) != stage_two_index or float(row["a"]) != TRUTHS[batch - 1]
            or int(row["replicate"]) != (1000 + local_index)):
        raise ValueError("qualification case does not match its frozen source row")
    return {"batch_id": batch, "local_index": local_index,
            "stage_two_index": stage_two_index, "replicate": int(row["replicate"]),
            "a": row["a"], "seed": int(row["seed"])}


def resolve_adapter_qualification_source(source_manifest: Path,
                                         source_mode: str = "legacy",
                                         excluded_seeds: set[int] | None = None) -> dict:
    """Validate a frozen adapter source and return its mode-specific probes.

    This shared resolver keeps preparation and execution on the same exact
    source identity.  The clean-current stream has its own schema and seed
    validation, so it must never be coerced through the legacy manifest rules.
    """
    path = Path(source_manifest).resolve(strict=True)
    excluded_seeds = set() if excluded_seeds is None else set(excluded_seeds)
    if source_mode == "clean_current":
        adapter = _clean_current_adapter()
        if sha256(path) != adapter.EXPECTED_SHA256:
            raise ValueError("source is not the frozen clean-current look-two manifest")
        batches = adapter.load_batches(path)
        source_rows = read_csv(path)
        source_seeds = {int(row["seed"]) for row in source_rows}
        if source_seeds.intersection(excluded_seeds):
            raise ValueError("clean-current adapter stream overlaps a prior seed stream")
        cases = adapter.adapter_qualification_cases(batches)
        if any(case["seed"] in source_seeds for case in cases):
            raise ValueError(
                "clean-current adapter qualification reuses look-two calibration seeds; "
                "qualify with an independent seed stream"
            )
        return {"source_manifest": path, "source_manifest_sha256": adapter.EXPECTED_SHA256,
                "source_design_mode": "clean_current",
                "worker_design_mode": "clean_current_stage_two",
                "source_rows": source_rows, "batches": batches, "cases": cases}
    if source_mode not in {"legacy", "production"}:
        raise ValueError("adapter source mode must be legacy or clean_current")
    if sha256(path) != SEED_SHA:
        raise ValueError("source is not the frozen legacy stage-two manifest")
    source_rows = read_csv(path)
    validate_source(source_rows, path, excluded_seeds)
    cases = [adapter_qualification_case(source_rows, b) for b in (1, 2, 3)]
    return {"source_manifest": path, "source_manifest_sha256": SEED_SHA,
            "source_design_mode": "production", "worker_design_mode": "production",
            "source_rows": source_rows, "batches": None, "cases": cases}


def validate_adapter_qualification(receipt: dict) -> None:
    """Validate the no-calibration, three-registry operational qualification."""
    if (receipt.get("schema") != "native-sd-adapter-qualification-v1"
            or receipt.get("status") != "PASS"
            or receipt.get("calibration_claim") is not False
            or receipt.get("campaign_complete") is not False
            or receipt.get("subset_complete") is not True
            or receipt.get("planned_attempts") != 9000
            or receipt.get("attempted") != 3):
        raise ValueError("adapter qualification receipt has wrong schema or campaign scope")
    source_mode = receipt.get("source_design_mode", "production")
    if source_mode == "clean_current":
        raise ValueError(
            "clean-current adapter qualification reuses look-two calibration seeds; "
            "qualify with an independent seed stream"
        )
    elif source_mode == "production":
        expected_source_sha = SEED_SHA
        expected_worker_mode = "production"
    else:
        raise ValueError("adapter qualification receipt names an unsupported source mode")
    if (receipt.get("source_manifest_sha256", expected_source_sha) != expected_source_sha
            or receipt.get("worker_design_mode", expected_worker_mode) != expected_worker_mode):
        raise ValueError("adapter qualification source mode or manifest digest is inconsistent")
    validate_qualification_elapsed(receipt.get("elapsed_seconds"))
    batches = receipt.get("batches")
    if not isinstance(batches, list) or len(batches) != 3:
        raise ValueError("adapter qualification must contain exactly three batch records")
    expected = ((1, 1, 1, 1001, "-0.5"),
                (2, 1001, 4001, 2001, "0.0"),
                (3, 2001, 8001, 3001, "0.5"))
    for item, (b, local, global_i, replicate, truth) in zip(batches, expected):
        if (item.get("batch_id") != b or item.get("local_index") != local
                or item.get("stage_two_index") != global_i
                or item.get("replicate") != replicate or not same_finite_numeric_value(item.get("a"), truth)
                or item.get("status") != "completed" or item.get("returncode") != 0
                or item.get("subset_complete") is not True
                or item.get("campaign_complete") is not False
                or item.get("valid_interval") is not True
                or item.get("oracle_pass") is not True):
            raise ValueError(f"adapter qualification batch {b} is incomplete or mismapped")
        for key in ("registry_sha256", "manifest_sha256", "supervisor_sha256", "result_sha256"):
            value = item.get(key)
            if not isinstance(value, str) or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
                raise ValueError(f"adapter qualification batch {b} lacks {key}")
        for key in ("registry_path", "manifest_path", "supervisor_path", "result_path"):
            if not isinstance(item.get(key), str) or not item[key]:
                raise ValueError(f"adapter qualification batch {b} lacks {key}")
    if len({x["registry_sha256"] for x in batches}) != 3:
        raise ValueError("adapter qualification must bind three distinct batch registries")
    if receipt.get("aggregate_registry_sha256") != qualification_registry_digest(batches):
        raise ValueError("adapter qualification aggregate registry digest is missing or mismatched")
    library_artifacts = receipt.get("library_artifacts")
    if (not isinstance(library_artifacts, list) or len(library_artifacts) < 3
            or any(not isinstance(x.get("path"), str) or not isinstance(x.get("sha256"), str)
                   or len(x["sha256"]) != 64 for x in library_artifacts)):
        raise ValueError("adapter qualification does not bind the original installed library artifacts")
    for key in ("qualification_root", "preparation_receipt_path", "preparation_receipt_sha256",
                "external_preparation_receipt_sha256"):
        if not isinstance(receipt.get(key), str) or not receipt[key]:
            raise ValueError(f"adapter qualification lacks {key}")
    if (len(receipt["preparation_receipt_sha256"]) != 64
            or any(c not in "0123456789abcdef" for c in receipt["preparation_receipt_sha256"])):
        raise ValueError("adapter qualification preparation receipt digest is malformed")
    if receipt["external_preparation_receipt_sha256"] != receipt["preparation_receipt_sha256"]:
        raise ValueError("adapter qualification external preparation digest does not match receipt")


def replay_adapter_qualification(receipt: dict) -> None:
    """Re-read every bound source, batch, supervisor, and result before GO."""
    root = Path(receipt["qualification_root"]).resolve(strict=True)
    prep_path = Path(receipt["preparation_receipt_path"]).resolve(strict=True)
    if prep_path != (root / "adapter-qualification-preparation-receipt.json").resolve():
        raise ValueError("adapter qualification preparation receipt is outside its root")
    if sha256(prep_path) != receipt["preparation_receipt_sha256"]:
        raise ValueError("adapter qualification preparation receipt changed")
    if receipt.get("external_preparation_receipt_sha256") != receipt["preparation_receipt_sha256"]:
        raise ValueError("adapter qualification external preparation digest changed")
    prepared = json.loads(prep_path.read_text())
    source_mode = receipt.get("source_design_mode", "production")
    source_path = prepared.get("source_manifest_path")
    if source_path is None:
        first_registry = read_csv(root / "batch-1" / "source-hashes.csv")
        source_path, _ = resolve_stage_two_source(
            first_registry, prepared.get("source_manifest_sha256", SEED_SHA))
    source_contract = resolve_adapter_qualification_source(
        Path(source_path), source_mode=source_mode)
    if (prepared.get("schema") != "native-sd-adapter-qualification-preparation-v1"
            or prepared.get("status") != "prepared_not_launched"
            or prepared.get("no_fits_launched") is not True
            or prepared.get("calibration_claim") is not False
            or prepared.get("source_manifest_sha256") != source_contract["source_manifest_sha256"]
            or prepared.get("source_design_mode", "production") != source_contract["source_design_mode"]
            or prepared.get("worker_design_mode", "production") != source_contract["worker_design_mode"]
            or prepared.get("first_look_seal_sha256") != receipt.get("first_look_seal_sha256")
            or prepared.get("first_look_registry_sha256") != receipt.get("first_look_registry_sha256")
            or prepared.get("source_registry_sha256") != receipt.get("source_registry_sha256")
            or prepared.get("library") != receipt.get("library")
            or prepared.get("library_artifacts") != receipt.get("library_artifacts")):
        raise ValueError("adapter qualification preparation receipt is not source-bound")
    source_rows = None
    source_path = None
    for b, batch in enumerate(receipt["batches"], 1):
        d = (root / f"batch-{b}").resolve(strict=True)
        if (Path(batch["registry_path"]).resolve(strict=True) != d / "source-hashes.csv"
                or Path(batch["manifest_path"]).resolve(strict=True) != d / "manifest.csv"
                or Path(batch["supervisor_path"]).resolve(strict=True) != d / "supervisor-receipt.json"
                or Path(batch["result_path"]).resolve(strict=True) != d / f"result-{batch['local_index']:04d}.csv"):
            raise ValueError(f"adapter qualification batch {b} artifact path escapes its batch directory")
        verify_registry(d)
        registry_rows = read_csv(d / "source-hashes.csv")
        source_name = "look2.csv" if source_mode == "clean_current" else "stage-two-manifest.csv"
        source_paths = [Path(x["path"]).resolve(strict=True) for x in registry_rows
                        if Path(x["path"]).name == source_name
                        and x.get("sha256") == source_contract["source_manifest_sha256"]]
        if len(source_paths) != 1 or sha256(source_paths[0]) != source_contract["source_manifest_sha256"]:
            raise ValueError(f"adapter qualification batch {b} does not pin the frozen source manifest")
        if source_rows is None:
            source_path = source_paths[0]
            source_rows = read_csv(source_paths[0])
            if source_mode == "legacy":
                validate_source(source_rows, source_paths[0], set())
        elif source_paths[0] != source_path:
            raise ValueError("adapter qualification batches point to different source manifests")
        source_path = source_paths[0]
        if source_mode == "clean_current":
            validate_clean_current_batch_manifest(read_csv(d / "manifest.csv"),
                                                  source_paths[0], b)
            expected = source_contract["cases"][b - 1]
        else:
            validate_batch_manifest(read_csv(d / "manifest.csv"), source_rows, b)
            expected = adapter_qualification_case(source_rows, b)
        for key in ("local_index", "stage_two_index", "replicate", "seed"):
            if batch.get(key) != expected[key]:
                raise ValueError(f"adapter qualification batch {b} changes source identity {key}")
        if not same_finite_numeric_value(batch.get("a"), expected["a"]):
            raise ValueError(f"adapter qualification batch {b} changes its truth value")
        supervisor_path = d / "supervisor-receipt.json"
        supervisor = json.loads(supervisor_path.read_text())
        validate_qualification_subset(supervisor, expected["local_index"],
                                       batch["registry_sha256"], batch["manifest_sha256"])
        result_path = d / f"result-{expected['local_index']:04d}.csv"
        rows = read_csv(result_path)
        if len(rows) != 1:
            raise ValueError(f"adapter qualification batch {b} result row count changed")
        row = rows[0]
        if (int(row.get("index", -1)) != expected["local_index"]
                or int(row.get("seed", -1)) != expected["seed"]
                or int(row.get("replicate", -1)) != expected["replicate"]
                or float(row.get("a", "nan")) != float(expected["a"])
                or row.get("state") != "completed"
                or row.get("valid_interval", "").lower() != "true"
                or row.get("oracle_pass", "").lower() != "true"
                or int(row.get("convergence", -1)) != 0
                or row.get("pdHess", "").lower() != "true"
                or row.get("clamp_at_optimum") != "ok"
                or row.get("interval_status") != "profile"
                or row.get("profile_boundary", "").lower() != "false"
                or not same_finite_numeric_value(row.get("profile_level"), 0.95)):
            raise ValueError(f"adapter qualification batch {b} result diagnostics failed")
        numeric = [float(row.get(k, "nan")) for k in
                   ("estimate", "se", "max_abs_gradient", "lower", "upper", "laplace_oracle_error")]
        if (not all(math.isfinite(x) for x in numeric) or numeric[1] <= 0
                or numeric[2] >= 1e-3 or numeric[3] >= numeric[4]
                or abs(numeric[5]) >= 1e-6):
            raise ValueError(f"adapter qualification batch {b} numeric diagnostics failed")
        prep_batches = prepared.get("batches", [])
        prep_item = prep_batches[b - 1] if len(prep_batches) == 3 else {}
        if (prep_item.get("batch_id") != b
                or prep_item.get("local_index") != batch["local_index"]
                or prep_item.get("stage_two_index") != batch["stage_two_index"]
                or prep_item.get("replicate") != batch["replicate"]
                or not same_finite_numeric_value(prep_item.get("a"), batch["a"])
                or prep_item.get("registry_sha256") != batch["registry_sha256"]
                or prep_item.get("manifest_sha256") != batch["manifest_sha256"]):
            raise ValueError(f"adapter qualification batch {b} differs from its preparation receipt")


def validate_qualification_subset(receipt: dict, local_index: int,
                                 registry_sha: str | None = None,
                                 manifest_sha: str | None = None) -> dict:
    """Require one terminal probe while retaining full-campaign semantics."""
    cases = receipt.get("cases", [])
    if (receipt.get("planned_indices") != [local_index]
            or receipt.get("subset_complete") is not True
            or receipt.get("campaign_complete") is not False
            or receipt.get("interrupted") is not False
            or (registry_sha is not None and receipt.get("registry_sha256") != registry_sha)
            or (manifest_sha is not None and receipt.get("manifest_sha256") != manifest_sha)
            or len(cases) != 1 or cases[0].get("index") != local_index
            or cases[0].get("status") != "completed"
            or cases[0].get("returncode") != 0):
        raise ValueError("adapter qualification subset is incomplete or mislabeled as a full campaign")
    return cases[0]


def validate_batch_manifest(rows: list[dict[str, str]], source_rows: list[dict[str, str]],
                            batch: int) -> None:
    expected = batch_rows(source_rows, batch)
    if len(rows) != ROWS_PER_BATCH:
        raise ValueError("batch manifest must contain exactly 3,000 rows")
    clean_current = bool(source_rows and source_rows[0].get("design_mode") == "clean_current")
    if clean_current:
        if rows != expected:
            raise ValueError(f"clean-current batch {batch} differs from its frozen source mapping")
        return
    for local, (observed, wanted) in enumerate(zip(rows, expected), 1):
        for key, value in wanted.items():
            if observed.get(key) != value:
                raise ValueError(f"batch {batch} source mapping differs at local row {local}, field {key}")
        if (int(observed.get("stage_two_index", -1)) != (batch-1)*3000+local
                or int(observed.get("index", -1)) != local
                or int(observed.get("batch_id", -1)) != batch
                or observed.get("design_mode") != "production"
                or int(observed.get("master_seed", -1)) != MASTER):
            raise ValueError(f"batch {batch} execution identity differs at local row {local}")


def write_batch_manifest(rows: list[dict[str, str]], path: Path) -> None:
    if path.exists():
        raise FileExistsError(f"refusing to overwrite {path}")
    fields = list(rows[0])
    with path.open("x", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def clean_current_stage_two_design_receipt(batch_id: int,
                                          source_manifest_sha256: str) -> str:
    """Return the worker contract for one frozen clean-current look-two batch."""
    adapter = _clean_current_adapter()
    if batch_id not in (1, 2, 3):
        raise ValueError("clean-current stage-two batch must be 1, 2, or 3")
    if source_manifest_sha256 != adapter.EXPECTED_SHA256:
        raise ValueError("clean-current stage-two receipt requires the frozen look-two manifest")
    fields = [
        "design_id=native-bernoulli-sd-ordinary-q1-stage-two-v1",
        "design_mode=clean_current_stage_two",
        "master_seed=2026101902",
        "planned_attempts=3000",
        f"workers={CAPS['workers']}",
        f"per_case_timeout_seconds={CAPS['case_timeout_seconds']}",
        f"campaign_timeout_seconds={CAPS['batch_timeout_seconds']}",
        f"batch_id={batch_id}",
        "stage_two_status=authorized_by_external_go_record",
        "profile_level=0.95",
        "calibration_claim=true",
        "clean_current_seed_stream=2026101902",
        f"stage_two_manifest_sha256={source_manifest_sha256}",
        f"stage_two_batch_id={batch_id}",
        "status=prepared_not_launched",
    ]
    return "\n".join(fields) + "\n"


def clean_current_adapter_design_receipt(batch_id: int,
                                         source_manifest_sha256: str,
                                         case: dict) -> str:
    """Describe one clean-current adapter probe without authorizing calibration."""
    if case.get("batch_id") != batch_id:
        raise ValueError("clean-current adapter probe batch does not match its receipt")
    text = clean_current_stage_two_design_receipt(batch_id, source_manifest_sha256)
    text = text.replace("stage_two_status=authorized_by_external_go_record",
                        "stage_two_status=adapter_qualification_only_no_final_go")
    text = text.replace("calibration_claim=true", "calibration_claim=false")
    text = text.replace("status=prepared_not_launched",
                        "adapter_qualification_only=true\n"
                        f"qualification_local_index={case['local_index']}\n"
                        f"qualification_stage_two_index={case['stage_two_index']}\n"
                        "status=prepared_not_launched")
    return text


def _source_overlay_registry_map(entries: list[dict[str, str]],
                                 source_overlay: Path) -> tuple[
                                     dict[Path, dict[str, str]], list[dict[str, str]]]:
    """Validate an overlay and map source pins plus its new helper pin."""
    package_pins = [entry for entry in entries
                    if Path(entry["path"]).as_posix().endswith("R/drmTMB.R")]
    if len(package_pins) != 1:
        raise ValueError("source overlay registry must pin exactly one R/drmTMB.R")
    package_source = Path(package_pins[0]["path"]).resolve(strict=True)
    source_root = package_source.parent.parent
    overlay_root = Path(source_overlay).resolve(strict=True)
    if not overlay_root.is_dir():
        raise ValueError("source overlay must be an existing directory")
    if (overlay_root == source_root or source_root in overlay_root.parents
            or overlay_root in source_root.parents):
        raise ValueError("source overlay must be separate from the sealed source tree")

    override_suffixes = {
        "native-calibration/worker-095.R": BASE / "worker-095.R",
        "native-calibration-stage-two/stage-two-rules.R": HERE / "stage-two-rules.R",
    }
    clean_helper = HERE / "clean_current_stage_two.py"
    override_sources: dict[Path, Path] = {}
    override_relatives: dict[Path, Path] = {}
    for suffix, replacement in override_suffixes.items():
        matches = [entry for entry in entries
                   if Path(entry["path"]).as_posix().endswith(suffix)]
        if len(matches) != 1:
            raise ValueError(f"source overlay registry must pin exactly one {suffix}")
        if not replacement.is_file():
            raise ValueError(f"source overlay replacement is missing: {replacement}")
        original = Path(matches[0]["path"]).resolve(strict=True)
        try:
            relative = original.relative_to(source_root)
        except ValueError as exc:
            raise ValueError(f"source overlay pin must be inside the package source tree: {suffix}") from exc
        override_sources[original] = replacement
        override_relatives[original] = relative

    rules_original = next(path for path, relative in override_relatives.items()
                          if relative.as_posix().endswith(
                              "native-calibration-stage-two/stage-two-rules.R"))
    helper_relative = override_relatives[rules_original].with_name(clean_helper.name)
    clean_helper_suffix = helper_relative.as_posix()
    by_source: dict[Path, dict[str, str]] = {}
    clean_helper_pins = [entry for entry in entries
                         if Path(entry["path"]).as_posix().endswith(clean_helper_suffix)]
    if len(clean_helper_pins) > 1:
        raise ValueError("source overlay registry must pin at most one clean-current helper")
    if clean_helper_pins:
        helper_source = Path(clean_helper_pins[0]["path"]).resolve(strict=True)
        try:
            helper_source.relative_to(source_root)
        except ValueError as exc:
            raise ValueError(
                "source overlay clean-current helper must be inside the package source tree"
            ) from exc
    clean_helper_target = (overlay_root / clean_helper_suffix).resolve(strict=True)
    if (not clean_helper_target.is_relative_to(overlay_root)
            or not clean_helper_target.is_file()
            or sha256(clean_helper_target) != sha256(clean_helper)):
        raise ValueError("source overlay clean-current helper differs from the current adapter")

    for entry in entries:
        original = Path(entry["path"]).resolve(strict=True)
        if original in {Path(pin["path"]).resolve(strict=True)
                        for pin in clean_helper_pins}:
            if sha256(original) != entry["sha256"]:
                raise ValueError(f"sealed source helper changed before remapping: {original}")
            by_source[original] = {"path": str(clean_helper_target),
                                  "sha256": sha256(clean_helper_target)}
            continue
        try:
            relative = original.relative_to(source_root)
        except ValueError:
            continue
        if not original.is_file() or sha256(original) != entry["sha256"]:
            raise ValueError(f"sealed source artifact changed before overlay remapping: {original}")
        target = overlay_root / relative
        resolved_target = target.resolve(strict=True)
        if not resolved_target.is_relative_to(overlay_root):
            raise ValueError(f"source overlay artifact escapes its root: {target}")
        expected_sha = entry["sha256"]
        replacement = override_sources.get(original)
        if replacement is not None:
            expected_sha = sha256(replacement)
        if not resolved_target.is_file() or sha256(resolved_target) != expected_sha:
            raise ValueError(f"source overlay artifact hash mismatch: {target}")
        if original in by_source:
            raise ValueError(f"source overlay registry contains a duplicate source pin: {original}")
        by_source[original] = {"path": str(resolved_target), "sha256": expected_sha}
    for suffix in override_suffixes:
        matches = [Path(entry["path"]).resolve(strict=True) for entry in entries
                   if Path(entry["path"]).as_posix().endswith(suffix)]
        if len(matches) != 1 or matches[0] not in by_source:
            raise ValueError(f"source overlay pin must be inside the package source tree: {suffix}")
    additions = ([] if clean_helper_pins else
                 [{"path": str(clean_helper_target), "sha256": sha256(clean_helper_target)}])
    return by_source, additions


def write_registry(out: Path, source_registry: Path, source_root: Path,
                   runtime_library: Path, manifest: Path,
                   source_manifest: Path | None = None,
                   source_overlay: Path | None = None) -> str:
    """Copy the Bernoulli registry, replacing only its manifest pin."""
    entries = read_csv(source_registry)
    rows = []
    old_manifest = 0
    if source_manifest is not None:
        source_manifest = source_manifest.resolve(strict=True)
        source_manifest_sha = sha256(source_manifest)
        for entry in entries:
            if (Path(entry["path"]).name == source_manifest.name
                    and entry["sha256"] != source_manifest_sha):
                raise ValueError("source registry has a conflicting frozen stage-two manifest pin")
    else:
        source_manifest_sha = None
    profile_worker = (BASE / "worker-095.R").resolve()
    worker_rows = [e for e in entries if Path(e["path"]).name == profile_worker.name]
    overlay_map, overlay_additions = (
        _source_overlay_registry_map(entries, source_overlay)
        if source_overlay is not None else ({}, []))
    if (len(worker_rows) != 1 or not profile_worker.is_file()
            or (source_overlay is None
                and worker_rows[0]["sha256"] != sha256(profile_worker))):
        raise ValueError("first-look source registry must pin the 95% profile worker")
    for e in entries:
        p = Path(e["path"])
        if source_manifest is not None and p.name == source_manifest.name:
            # The input registry can contain multiple mirrored copies of the
            # same frozen source. Keep one canonical path in the batch registry
            # so the runner can resolve the source identity unambiguously.
            continue
        if p.name == "design-receipt.txt":
            if not p.is_file() or sha256(p) != e["sha256"]:
                raise ValueError(f"Bernoulli source registry artifact changed: {p}")
            # The original design is bound by the first-look registry. A
            # second-look batch must carry only its own design contract.
            continue
        if p.name == "manifest.csv":
            old_manifest += 1
            rows.append({"path": str(manifest.resolve()), "sha256": sha256(manifest)})
        else:
            if not p.is_file() or sha256(p) != e["sha256"]:
                raise ValueError(f"Bernoulli source registry artifact changed: {p}")
            rows.append(overlay_map.get(p.resolve(), e))
    if old_manifest != 1:
        raise ValueError("source registry must pin exactly one original manifest")
    rows.extend(overlay_additions)
    if source_manifest is not None:
        rows.append({"path": str(source_manifest), "sha256": source_manifest_sha})
    # Bind the adapter and its installed Bernoulli runtime. Existing registry
    # pins are retained; no current Poisson source or binary may be substituted.
    extra = [HERE / "stage_two.py", HERE / "prepare-stage-two.py",
             HERE / "run-stage-two.py", HERE / "combine-stage-two.R",
             HERE / "prepare-adapter-qualification.py",
             HERE / "run-adapter-qualification.py",
             HERE / "stage-two-rules.R", HERE / "verify-first-look.R",
             HERE / "test-stage-two-rules.R",
             HERE / "verify-prior-seeds.R", HERE / "test-prior-seeds.R",
             HERE / "README.md", HERE / "clean_current_stage_two.py",
             HERE / "test_stage_two.py", out / "design-receipt.txt",
             out / "conversion-receipt.json"]
    missing = [p for p in extra if not p.is_file()]
    if missing:
        raise ValueError("mandatory adapter artifacts are missing: " + ", ".join(map(str, missing)))
    adapter_rules = out / "adapter-stage-two-rules.R"
    if adapter_rules.exists():
        raise FileExistsError(f"refusing to overwrite {adapter_rules}")
    shutil.copyfile(HERE / "stage-two-rules.R", adapter_rules)
    extra = [adapter_rules if p == HERE / "stage-two-rules.R" else p for p in extra]
    clean_helper_pins = [row for row in rows
                         if Path(row["path"]).as_posix().endswith(
                             "native-calibration-stage-two/clean_current_stage_two.py")]
    if len(clean_helper_pins) > 1:
        raise ValueError("source registry must pin at most one clean-current adapter helper")
    if clean_helper_pins:
        adapter_clean_helper = out / "adapter-clean-current-stage-two.py"
        if adapter_clean_helper.exists():
            raise FileExistsError(f"refusing to overwrite {adapter_clean_helper}")
        shutil.copyfile(HERE / "clean_current_stage_two.py", adapter_clean_helper)
        extra = [adapter_clean_helper if p == HERE / "clean_current_stage_two.py" else p
                 for p in extra]
    for p in extra:
        rows.append({"path": str(p.resolve()), "sha256": sha256(p)})
    out_hashes = out / "source-hashes.csv"
    if out_hashes.exists():
        raise FileExistsError(f"refusing to overwrite {out_hashes}")
    with out_hashes.open("x", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["path", "sha256"])
        w.writeheader(); w.writerows(rows)
    verify_registry(out)
    return sha256(out_hashes)


def run_batches(prepared: Path, external_seals: Path, external_seals_sha256: str,
                library: Path, outer_timeout: float) -> None:
    """Sequentially run the frozen supervisor for the three sealed batches."""
    if (not math.isfinite(outer_timeout) or outer_timeout <= 0
            or outer_timeout > CAPS["outer_timeout_seconds"]):
        raise ValueError("outer timeout must be finite and within frozen 10,500-second cap")
    started = time.monotonic()
    started_epoch = time.time()
    deadline_epoch = started_epoch + outer_timeout
    if sha256(external_seals) != external_seals_sha256:
        raise ValueError("externally retained seal digest mismatch")
    seals = json.loads(external_seals.read_text())
    go_path = Path(seals["go_record_path"]).resolve(strict=True)
    go_sha = sha256(go_path)
    if go_sha != seals.get("go_record_sha256"):
        raise ValueError("external GO-record digest mismatch")
    go = json.loads(go_path.read_text())
    first_seal_path = Path(seals["first_look_seal_path"]).resolve(strict=True)
    if sha256(first_seal_path) != seals.get("first_look_seal_sha256"):
        raise ValueError("external first-look seal digest mismatch")
    first_seal = json.loads(first_seal_path.read_text())
    validate_go(go, go_sha, first_seal, go_path, sha256(first_seal_path))
    validate_binary_receipt(first_seal, library)
    from integrity import verify as verify_first
    first_root = Path(seals["first_look_root"]).resolve(strict=True)
    verify_first(first_root)
    first_registry = first_root / "source-hashes.csv"
    first_decision = Path(seals["first_look_decision_path"]).resolve(strict=True)
    if sha256(first_registry) != first_seal.get("registry_sha256") or sha256(first_decision) != first_seal.get("decision_sha256"):
        raise ValueError("retained first-look registry or decision changed")
    if attempt_digest(first_root, expected_results=3000) != first_seal.get("attempts_sha256"):
        raise ValueError("first-look raw attempt digest differs from its external seal")
    if "look2_required" not in first_decision.read_text(errors="replace"):
        raise ValueError("first-look decision no longer records look2_required")
    root_receipt = prepared / "root-preparation-receipt.json"
    if sha256(root_receipt) != seals.get("root_preparation_receipt_sha256"):
        raise ValueError("external root preparation receipt digest mismatch")
    root_doc = json.loads(root_receipt.read_text())
    if root_doc.get("status") != "prepared_not_launched" or root_doc.get("no_fits_launched") is not True:
        raise ValueError("prepared-root receipt is not an unlaunched stage-two capsule")
    standardized = prepared / "first-look-standardized.csv"
    replay_receipt = prepared / "first-look-replay-receipt.json"
    if (sha256(standardized) != root_doc.get("first_look_standardized_sha256")
            or sha256(replay_receipt) != root_doc.get("first_look_replay_receipt_sha256")):
        raise ValueError("prepared first-look replay artifacts differ from the sealed root receipt")
    current_source_sha = _clean_current_adapter().EXPECTED_SHA256
    source_sha = root_doc.get("source_manifest_sha256")
    if source_sha not in {SEED_SHA, current_source_sha}:
        raise ValueError("prepared root is not bound to a supported frozen stage-two source")
    clean_current = source_sha == current_source_sha
    if (root_doc.get("go_record_sha256") != go_sha
            or root_doc.get("first_look_registry_sha256") != first_seal.get("registry_sha256")
            or root_doc.get("first_look_decision_sha256") != first_seal.get("decision_sha256")
            or root_doc.get("first_look_seal_sha256") != seals.get("first_look_seal_sha256")
            or root_doc.get("harness_archive_sha256") != first_seal.get("harness_archive_sha256")
            or root_doc.get("matched_original_native_artifacts") != first_seal.get("matched_original_native_artifacts")):
        raise ValueError("prepared-root receipt does not bind this GO and frozen source")
    rscript = str(seals.get("rscript", "Rscript"))
    with tempfile.TemporaryDirectory(prefix="native-sd-stage-two-prelaunch-") as tmp:
        replay_csv = Path(tmp) / "first-look-standardized.csv"
        replay_verifier = sealed_reconstruction_file(first_seal, "verify-first-look.R")
        replay_cmd = [rscript, str(replay_verifier), str(first_root),
                      str(first_seal_path), str(replay_csv)]
        replay = subprocess.run(replay_cmd, capture_output=True, text=True, timeout=120)
        replay_receipt_tmp = Path(str(replay_csv) + ".receipt.json")
        if (replay.returncode != 0 or not replay_csv.is_file()
                or sha256(replay_csv) != root_doc["first_look_standardized_sha256"]
                or not replay_receipt_tmp.is_file()
                or sha256(replay_receipt_tmp) != root_doc["first_look_replay_receipt_sha256"]):
            raise RuntimeError("first-look raw replay failed immediately before stage-two launch: " + replay.stderr[-2000:])
    root_registries = {str(x["batch_id"]): x["registry_sha256"] for x in root_doc["batches"]}
    if root_registries != seals.get("batch_registry_sha256"):
        raise ValueError("external batch seals differ from root preparation receipt")
    from run import supervise
    run_rows = []
    target = prepared / "stage-two-run-receipt.json"
    if target.exists():
        raise FileExistsError(f"refusing to overwrite {target}; stage-two retries are forbidden")

    def save_run_receipt(status: str) -> None:
        payload = {"status": status, "no_retries": True,
                   "external_seals_sha256": external_seals_sha256,
                   "started_epoch": started_epoch, "deadline_epoch": deadline_epoch,
                   "elapsed_seconds": time.monotonic() - started,
                   "go_record_sha256": go_sha,
                   "root_preparation_receipt_sha256": sha256(root_receipt),
                   "batches": run_rows}
        tmp = target.with_suffix(".json.tmp")
        tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
        tmp.replace(target)
    for b in (1, 2, 3):
        if time.monotonic() - started >= outer_timeout:
            raise TimeoutError("outer stage-two cap reached before batch launch")
        d = prepared / f"batch-{b}"
        verify_registry(d)
        registry_sha = sha256(d / "source-hashes.csv")
        expected = seals["batch_registry_sha256"][str(b)]
        if registry_sha != expected:
            raise ValueError(f"external registry seal mismatch for batch {b}")
        rows = read_csv(d / "manifest.csv")
        registry_rows = read_csv(d / "source-hashes.csv")
        worker = resolve_registered_profile_worker(registry_rows)
        source_path, source_is_clean = resolve_stage_two_source(
            registry_rows, source_sha
        )
        if source_is_clean != clean_current:
            raise ValueError("prepared-root mode differs from its pinned source manifest")
        source_rows = read_csv(source_path)
        validate_source(source_rows, source_path, set())
        validate_batch_manifest(rows, source_rows, b)
        remain = outer_timeout - (time.monotonic() - started)
        cap = min(CAPS["batch_timeout_seconds"], remain)
        if cap < 1:
            raise TimeoutError("outer stage-two cap exhausted")
        env = {"DRMTMB_SD_TEST_LIBRARY": worker_library_search_path(library),
               "DRMTMB_SD_REGISTRY_SHA256": registry_sha}
        try:
            supervise(list(range(1, 3001)), lambda i: [rscript, str(worker), str(d), str(i)],
                      d, workers=CAPS["workers"], case_timeout=CAPS["case_timeout_seconds"],
                      campaign_timeout=cap, env=env, registry_sha256=registry_sha,
                      design_mode=("clean_current_stage_two" if clean_current else "production"))
            verify_registry(d)
            batch_receipt = validate_batch_receipt(d, registry_sha, sha256(d / "manifest.csv"))
        except Exception:
            save_run_receipt(f"batch_{b}_incomplete")
            raise
        run_rows.append({"batch_id": b, "registry_sha256": registry_sha,
                         "manifest_sha256": sha256(d / "manifest.csv"),
                         "supervisor_sha256": sha256(d / "supervisor-receipt.json"),
                         "attempts_sha256": attempt_digest(
                             d, expected_indices=[int(x["index"]) for x in batch_receipt["cases"]
                                                  if x["status"] == "completed"],
                             allowed_indices=list(range(1, ROWS_PER_BATCH + 1))),
                         "status_counts": {s: sum(x["status"] == s for x in batch_receipt["cases"])
                                           for s in ("completed", "error", "timeout")}})
        save_run_receipt("running")
    if time.monotonic() - started >= outer_timeout:
        save_run_receipt("all_batches_terminal_deadline_exceeded")
        raise TimeoutError("whole stage-two execution exceeded its bounded deadline")
    save_run_receipt("all_batches_terminal")

