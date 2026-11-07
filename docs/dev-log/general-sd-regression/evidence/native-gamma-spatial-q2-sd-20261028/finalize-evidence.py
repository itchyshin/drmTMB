import csv,hashlib,json,tarfile
from pathlib import Path
p=Path("docs/dev-log/general-sd-regression/evidence/native-gamma-spatial-q2-sd-20261028")
h=lambda b:hashlib.sha256(b).hexdigest()
files=[Path(x) for x in ["DESCRIPTION","LICENSE","NAMESPACE"]]+sorted(Path("R").glob("*.R"))+sorted(Path("src").glob("*.cpp"))+sorted(Path("src").glob("*.hpp"))+sorted(Path("src").glob("*.h"))+sorted(Path("tests/testthat").glob("helper*.R"))
tests=["gamma-spatial-q2-sd-regression","gamma-spatial-sd-regression","gamma-phylo-q2-sd-regression","gamma-phylo-sd-regression","gamma-relmat-q2-sd-regression","gamma-relmat-sd-regression","gamma-animal-slope-sd-regression","gamma-sd-regression","gamma-sigma-sd-regression"]
files += [Path("tests/testthat/test-"+x+".R") for x in tests]
files += [Path("inst/examples/gamma-spatial-q2-sd.R"),Path("docs/dev-log/after-task/2026-10-28-native-gamma-spatial-q2-sd.md"),Path("docs/dev-log/check-log.d/2026-10-28-native-gamma-spatial-q2-sd.md"),p/"pre-fit-alignment.md"]
files=sorted(set(files));capsule=p/"source-capsule.tar.gz"
with tarfile.open(capsule,"w:gz") as t:
 for f in files:t.add(f,arcname=str(f))
files.append(Path("src/drmTMB.so"))
entries=[dict(path=str(f),sha256=h(f.read_bytes()),bytes=f.stat().st_size) for f in files]
m=dict(base_head="425bee81572c625a634b2b083050c5c57c1dc1f1",source_state="dirty candidate; scoped R-only change; compiled source unchanged",source_capsule_scope="Actual current R/native source, metadata, test helpers, affected tests, example and report; not a release source tarball; DLL hashed separately",source_capsule_path=str(capsule),source_capsule_sha256=h(capsule.read_bytes()),files=entries)
manifest=p/"source-manifest.json";manifest.write_text(json.dumps(m,indent=2)+"\n")
prior=json.loads(Path("docs/dev-log/general-sd-regression/evidence/native-gamma-phylo-q2-sd-20261027/source-manifest.json").read_text());old={e["path"]:e["sha256"] for e in prior["files"]}
for f in ["src/drmTMB.cpp","src/drmTMB.so"]:assert h(Path(f).read_bytes())==old[f],f
rows=list(csv.DictReader((p/"candidate-rows.tsv").open(),delimiter="\t"))
r=dict(slice="native Gamma coordinate-spatial independent intercept and numeric-slope SD",date="2026-10-28",worktree=str(Path.cwd()),base_head=m["base_head"],source_manifest_path=str(manifest),source_manifest_sha256=h(manifest.read_bytes()),implementation="R-only Gamma coords-specific opt-in and coefficient SD maps; no C++ or DLL change",test=dict(passed=229,failed=0,errors=0,warnings=0,skipped=1,seconds=73.126,estimate_seconds=180,new_file_checks=47,skipped_reason="Existing live Julia spatial comparator: engine path unavailable",initial_red_errors=2,initial_red_seconds=2.994,initial_focus_passed=41,initial_focus_errors=1,initial_focus_seconds=17.343,initial_error="New lognormal refusal matcher expected intercept-only, existing earlier provider surface correctly refused; matcher corrected without model change"),example=dict(convergence=0,seconds=2.950,sd_slopes=[0.4861302,-0.3155446],truth=[0.5,-0.5],qualification="One fixed-seed point-fit smoke only"),numerical_acceptance=dict(kernel="Independent Euclidean median-positive-distance exponential kernel plus 1e-6 I; raw diagonal retained",laplace_nll_absolute_error="<1e-4 passed",eta_max_absolute_error="<1e-4 passed",reorder_constant_base_error="<1e-4 passed",derivatives="Analytic score/Hessian with finite differences passed"),candidate_row_keys=[x["row_key"] for x in rows],row_scope="native Gamma mu coordinates only; one independent intercept plus numeric slope; no whole-domain admission",shared_ledger_modified=False,interval_coverage="deferred",julia_parity="Not run or established; existing live comparator skipped",aggregate_acceptance_gate="UNKNOWN: existing runner unavailable",review="Parent coordinator and independent read-only scout found no P0/P1 in scoped code/math; shared validator unchanged after removing intended additions",limitations=["Fixed range, not estimated spatial range","No duplicate-coordinate fallback-jitter validation","No unseen-site, mesh, weighted or missing-data fits","No label/correlation/multiple-slope or extra random layers","No new-data SD prediction/profile/bootstrap validation","No fresh two-field marginal simulation","No coverage, live Julia parity, full package or release checks"],supporting_artifacts={str(f):h(f.read_bytes()) for f in sorted(p.iterdir()) if f.is_file() and f.name!="receipt.json"})
(p/"receipt.json").write_text(json.dumps(r,indent=2)+"\n")
for e in entries:assert h(Path(e["path"]).read_bytes())==e["sha256"]
lookup={e["path"]:e["sha256"] for e in entries}
with tarfile.open(capsule) as t:
 members=[x for x in t.getmembers() if x.isfile()]
 for x in members:assert h(t.extractfile(x).read())==lookup[x.name]
print("VERIFIED",len(entries),"source hashes",len(members),"capsule members")
