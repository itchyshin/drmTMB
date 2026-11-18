"""Freeze the exact local source and bounded Beta q1 test evidence."""
import csv
import hashlib
import json
import re
import subprocess
import tarfile
from pathlib import Path

root = Path.cwd()
evidence = Path("docs/dev-log/general-sd-regression/evidence/native-beta-structured-intercept-q1-sd-20261028")


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


files = [Path(x) for x in ("DESCRIPTION", "LICENSE", "NAMESPACE")]
for pattern in ("R/*.R", "src/*.cpp", "src/*.hpp", "src/*.h", "tests/testthat/helper*.R"):
    files.extend(Path(".").glob(pattern))
files.extend(Path(x) for x in (
    "src/drmTMB.so",
    "tests/testthat/test-beta-structured-intercept-q1-sd-regression.R",
    "tests/testthat/test-beta-relmat-q2-sd-regression.R",
    "tests/testthat/test-beta-spatial-q2-sd-regression.R",
    "inst/examples/beta-structured-intercept-q1-sd.R",
    "inst/examples/beta-relmat-q2-sd.R",
    "inst/examples/beta-spatial-q2-sd.R",
    "docs/dev-log/after-task/2026-10-28-native-beta-structured-intercept-q1-sd.md",
    "docs/dev-log/general-sd-regression/evidence/native-beta-structured-intercept-q1-sd-20261028/pre-fit-alignment.md",
    "docs/dev-log/general-sd-regression/evidence/native-beta-structured-intercept-q1-sd-20261028/check-log.md",
))
files = sorted(set(Path(x) for x in files), key=str)
assert all(x.is_file() for x in files)
prior = Path("/tmp/drmtmb-beta-q1-before.R")
assert sha(prior) == "d050b5801e0a027845e68c5be7049325fc39929b7ea6bb6d2616db6bba91cc16"
capsule = evidence / "source-capsule.tar.gz"
with tarfile.open(capsule, "w:gz") as out:
    for path in files:
        out.add(path, arcname=str(path))
    out.add(prior, arcname="before/drmTMB.R")
entries = [dict(path=str(path), sha256=sha(path), bytes=path.stat().st_size) for path in files]
manifest = evidence / "source-manifest.json"
manifest.write_text(json.dumps(dict(
    base_head=subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(),
    source_state="dirty local worktree; scoped Beta q1 slice; no commit or public promotion",
    source_capsule_path=str(capsule), source_capsule_sha256=sha(capsule),
    prior_builder_source_sha256=sha(prior),
    files=entries,
), indent=2) + "\n")

log = (evidence / "targeted.log").read_text()
assert "══ DONE ══" in log and "real 129.80" in log
assert not re.search(r"^══ (FAILURES|ERRORS|WARNINGS|SKIPS) ═", log, re.M)
marker_counts = {}
for name in ("beta-relmat-q2-sd-regression", "beta-spatial-q2-sd-regression",
             "beta-structured-intercept-q1-sd-regression"):
    match = re.search(rf"^{name}: ([.]+)", log, re.M)
    assert match, name
    marker_counts[name] = len(match.group(1))
# testthat continued the relmat markers after a one-time simulate() notice.
assert "\n..\n" in log
marker_counts["beta-relmat-q2-sd-regression"] += 2
assert marker_counts == {
    "beta-relmat-q2-sd-regression": 64,
    "beta-spatial-q2-sd-regression": 47,
    "beta-structured-intercept-q1-sd-regression": 56,
}

with Path("docs/dev-log/general-sd-regression/required-rows.tsv").open() as stream:
    rows = list(csv.DictReader(stream, delimiter="\t"))
candidate = [row["row_key"] for row in rows
             if row["engine"] == "native" and row["family_route"] == "beta"
             and row["endpoint"] == "mu" and row["target_member"] == "mu:I"
             and ((row["mechanism_id"] == "relmat_intercept"
                   and row["provider_input"] in ("K_covariance", "Q_precision"))
                  or (row["mechanism_id"] == "spatial_coordinate_intercept"
                      and row["provider_input"] == "coordinates"))]
assert len(candidate) == 3

previous = json.loads(Path(
    "docs/dev-log/general-sd-regression/evidence/native-beta-spatial-q2-sd-20261028/source-manifest.json"
).read_text())
old_hash = {entry["path"]: entry["sha256"] for entry in previous["files"]}
assert all(sha(path) == old_hash[path] for path in ("src/drmTMB.cpp", "src/drmTMB.so"))

receipt = evidence / "receipt.json"
receipt.write_text(json.dumps(dict(
    slice="native Beta predictor-dependent SD for one relmat K/Q or coordinate-spatial intercept",
    date="2026-10-28", worktree=str(root),
    base_head=json.loads(manifest.read_text())["base_head"],
    source_manifest_path=str(manifest), source_manifest_sha256=sha(manifest),
    candidate_row_keys=candidate,
    test=dict(
        focused_seconds=53.34, focused_estimate_seconds=100,
        targeted_seconds=129.80, targeted_estimate_seconds=240,
        targeted_success_markers=sum(marker_counts.values()),
        by_file_success_markers=marker_counts,
        failed=0, errors=0, warnings=0, skipped=0,
        count_method="testthat summary reporter markers and zero failure/error/warning/skip sections; process exit 0",
        julia_live_tests=0,
    ),
    example=dict(convergence=0, sd_slope=0.5086127, truth_slope=0.5,
                 seconds=10.76, qualification="single-seed point-fit smoke"),
    numerical_acceptance=dict(
        oracle="independent scalar Beta score/Hessian and Gaussian/Laplace constants",
        nll_eta_absolute_error="<1e-4 passed",
        latent_gradient="<1e-5 passed",
        finite_difference_score_hessian="<1e-4 and <2e-4 passed",
        K_Q_coordinate_order_constant_base="<1e-4 passed",
    ),
    red_provenance=dict(
        reconstructed_before="reconstructed-before.log: isolated evaluation of verified extracted prior builder; both q1 formulas rejected",
        carried_red="red.log is retrospective narrative, not raw stdout",
        prior_builder_sha256=sha(prior),
    ),
    implementation="two R admission predicate/advice hunks; prior q2 support preserved; no C++ or DLL change",
    interval_coverage="deferred", julia_parity="not run", shared_ledger_modified=False,
    row_scope="three exact native Beta mu q1 rows only",
    supporting_artifacts={str(path): sha(path) for path in sorted(evidence.iterdir())
                          if path.is_file() and path.name != "receipt.json"},
), indent=2) + "\n")

lookup = {entry["path"]: entry["sha256"] for entry in entries}
assert all(sha(path) == digest for path, digest in lookup.items())
with tarfile.open(capsule) as archive:
    members = [item for item in archive.getmembers() if item.isfile()]
    assert len(members) == len(files) + 1
    for member in members:
        expected = sha(prior) if member.name == "before/drmTMB.R" else lookup[member.name]
        assert hashlib.sha256(archive.extractfile(member).read()).hexdigest() == expected
print("VERIFIED", len(entries), "source hashes", len(members), "capsule members",
      sum(marker_counts.values()), "success markers")
