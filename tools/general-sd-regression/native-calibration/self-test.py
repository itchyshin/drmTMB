#!/usr/bin/env python3
"""Synthetic integrity, generator, summary, and supervisor contract tests."""
import csv
import hashlib
import importlib.util
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
sys.path.insert(0, str(HERE))
import integrity
spec = importlib.util.spec_from_file_location("sd_campaign_runner", HERE / "run.py")
runner = importlib.util.module_from_spec(spec); spec.loader.exec_module(runner)
RSCRIPT = os.environ.get("RSCRIPT", "Rscript")


def sha(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for b in iter(lambda: f.read(1024 * 1024), b""): h.update(b)
    return h.hexdigest()


def test_generator():
    subprocess.run([RSCRIPT, "-e", f'source("{HERE / "generator.R"}"); sd_regression_generator_self_test()'],
                   check=True, capture_output=True, text=True, timeout=20)


def test_stage_two_manifest():
    producer = HERE / "stage-two-seeds.R"
    manifest = ROOT / "docs/dev-log/general-sd-regression/stage-two-manifest.csv"
    assert sha(manifest) == "8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96"
    code = (f'source("{producer}"); x <- native_sd_stage_two_manifest(); '
            f'y <- read.csv("{manifest}", stringsAsFactors=FALSE); '
            'stopifnot(identical(names(x), names(y)), nrow(y)==9000L); '
            'nc <- names(x)[vapply(x,is.numeric,logical(1))]; cc <- setdiff(names(x),nc); '
            'stopifnot(all(vapply(cc,function(n) identical(as.character(x[[n]]),as.character(y[[n]])),logical(1)))); '
            'stopifnot(all(vapply(nc,function(n) max(abs(x[[n]]-y[[n]]),na.rm=TRUE)<=1e-14,logical(1))))')
    subprocess.run([RSCRIPT, "-e", code], check=True, capture_output=True, text=True, timeout=30)


def test_staged_analyzer():
    subprocess.run([RSCRIPT, "-e", f'library(testthat); test_file("{HERE / "test-staged-decision.R"}")'],
                   check=True, capture_output=True, text=True, timeout=30)


def test_supervisor():
    with tempfile.TemporaryDirectory(prefix="sd-supervisor-test-") as tmp:
        out = Path(tmp); fake = out / "fake_worker.py"
        fake.write_text("import sys,time\ni=int(sys.argv[1])\nif i==3: time.sleep(2)\nif i==4: raise SystemExit(7)\nprint(i)\n")
        states = runner.supervise([1,2,3,4], lambda i:[sys.executable,str(fake),str(i)],out,
                                  workers=2,case_timeout=.3,campaign_timeout=4)
        assert [states[i]["status"] for i in range(1,5)] == ["completed","completed","timeout","error"]
    with tempfile.TemporaryDirectory(prefix="sd-launch-error-") as tmp:
        out=Path(tmp)
        states=runner.supervise([9],lambda i:[str(out/"missing-executable")],out,workers=1,case_timeout=1,campaign_timeout=2)
        assert states[9]["status"] == "launch_error"
        assert json.loads((out/"supervisor-receipt.json").read_text())["cases"][0]["status"] == "launch_error"


def test_contention():
    subprocess.run([sys.executable, str(HERE / "test-contention.py")],
                   check=True, capture_output=True, text=True, timeout=20)


def required_artifacts(out):
    source_paths = [ROOT / p for p in [
        "R/drmTMB.R","R/methods.R","R/profile.R","src/drmTMB.cpp",
        "tests/testthat/helper-binomial-sd-regression.R",
        "tools/general-sd-regression/native-calibration/prepare.R",
        "tools/general-sd-regression/native-calibration/worker.R",
        "tools/general-sd-regression/native-calibration/generator.R",
        "tools/general-sd-regression/native-calibration/run.py",
        "tools/general-sd-regression/native-calibration/integrity.py",
        "tools/general-sd-regression/native-calibration/summarize.R",
        "tools/general-sd-regression/native-calibration/self-test.py",
        "tools/general-sd-regression/native-calibration/staged-decision.R",
        "tools/general-sd-regression/native-calibration/test-staged-decision.R",
        "tools/general-sd-regression/native-calibration/stage-two-seeds.R",
        "tools/general-sd-regression/native-calibration/contention.py",
        "tools/general-sd-regression/native-calibration/test-contention.py",
        "docs/dev-log/general-sd-regression/stage-two-manifest.csv",
        "docs/dev-log/general-sd-regression/staged-calibration-contract.md",
        "docs/dev-log/general-sd-regression/native-calibration-design.md"]]
    # These disposable files exercise required installed-library identity slots.
    fake = out / "library" / "drmTMB"
    for subdir in ("R", "Meta", "libs"): (fake/subdir).mkdir(parents=True,exist_ok=True)
    paths = source_paths + [fake / "DESCRIPTION", fake / "NAMESPACE", fake / "Meta/package.rds",
                            fake / "R/drmTMB.rdb", fake / "R/drmTMB.rdx", fake / "libs/drmTMB.so"]
    fixture_source=out/"source-fixture.R";fixture_source.write_text("source fixture")
    paths.append(fixture_source)
    for path in paths[len(source_paths):]: path.write_text("synthetic fixture")
    rbin = subprocess.check_output([RSCRIPT,"-e","cat(file.path(R.home(),'bin','R'))"],text=True).strip()
    paths.append(Path(rbin))
    return paths


def write_manifest(out):
    fields=["index","a","replicate","seed","groups","repeats","beta0","beta1","alpha0","design_mode","master_seed"]
    with (out/"manifest.csv").open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader()
        for i in range(1,3001):
            a=(-.5,0,.5)[(i-1)//1000];rep=(i-1)%1000+1
            w.writerow(dict(index=i,a=a,replicate=rep,seed=i,groups=160,repeats=16,beta0=-.3,beta1=.6,alpha0=-.22314355131420976,design_mode="production",master_seed=2026101703))


def write_hash_registry(out):
    paths=required_artifacts(out)+[out/"manifest.csv"]
    with (out/"source-hashes.csv").open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=["path","sha256"]);w.writeheader()
        for p in paths:w.writerow({"path":str(p.resolve()),"sha256":sha(p)})


def row_for(i,a,rep,seed,valid=True):
    return dict(index=i,a=a,replicate=rep,seed=seed,state="completed",estimate=a,se=.1,convergence=0,
        pdHess="TRUE",max_abs_gradient=0,clamp_at_optimum="ok",lower=a-.1,upper=a+.1,
        interval_status="profile",profile_boundary="FALSE",profile_message="",valid_interval=str(valid).upper(),
        laplace_oracle_error=0,oracle_pass="TRUE",oracle_tolerance=1e-6,warnings="",error="",elapsed=1)


def write_result(out,i,row):
    path=out/f"result-{i:04d}.csv"
    with path.open("w",newline="") as f:
        w=csv.DictWriter(f,fieldnames=list(row));w.writeheader();w.writerow(row)


def write_receipt(out,indices,statuses=None,codes=None):
    indices=list(indices)
    statuses=statuses or {};codes=codes or {}
    cases=[dict(index=i,status=statuses.get(i,"completed"),returncode=codes.get(i,0),started_at=1,finished_at=2)
           for i in indices]
    states=[c["status"] for c in cases]
    subset_complete=all(s in {"completed","error","timeout"} for s in states)
    production=all(r["design_mode"]=="production" for r in csv.DictReader((out/"manifest.csv").open()))
    full=indices==list(range(1,3001))
    (out/"supervisor-receipt.json").write_text(json.dumps({"started_at":1,"finished_at":2,"planned_indices":indices,
        "manifest_sha256":sha(out/"manifest.csv"),"registry_sha256":sha(out/"source-hashes.csv"),
        "design_mode":"production" if production else "qualification","interrupted":any(s=="interrupted" for s in states),
        "subset_complete":subset_complete,"campaign_complete":production and full and subset_complete,
        "cases":cases}))


def summarize(out,expected=0):
    p=subprocess.run([RSCRIPT,str(HERE/"summarize.R"),str(out),sha(out/"source-hashes.csv")],capture_output=True,text=True,timeout=120)
    if expected==0 and p.returncode: raise AssertionError(p.stdout+p.stderr)
    if expected and p.returncode==0: raise AssertionError("Expected summary integrity rejection")
    return p


def fixture(indices):
    tmp=tempfile.TemporaryDirectory(prefix="sd-summary-test-");out=Path(tmp.name)
    write_manifest(out)
    (out/"design-receipt.txt").write_text("design_mode=production\nmaster_seed=2026101703\nstatus=prepared_not_launched\n")
    for i in indices:
        a=(-.5,0,.5)[(i-1)//1000];rep=(i-1)%1000+1
        write_result(out,i,row_for(i,a,rep,i))
    write_hash_registry(out);write_receipt(out,indices);integrity.verify(out)
    return tmp,out


def test_subset_copy():
    tmp,source=fixture([1,1001,2001])
    try:
        indices=[1,1001,2001]
        out=runner.make_subset(source,source/"subset-copy",indices)
        runner.verify(out)
        receipt=json.loads((out/"subset-receipt.json").read_text())
        assert receipt["planned_indices"]==indices and receipt["planned_subset"]==3
        assert (out/"source-hashes.csv").read_bytes()==(source/"source-hashes.csv").read_bytes()
        assert len(list(csv.DictReader((out/"manifest.csv").open())))==3000
        # Match the real runner's path layout: hashes pin the prepared source
        # manifest, while the subset directory holds a byte-identical copy.
        for i in indices: shutil.copy2(source/f"result-{i:04d}.csv",out/f"result-{i:04d}.csv")
        receipt.update(registry_sha256=sha(out/"source-hashes.csv"),design_mode="production",master_seed=2026101703)
        (out/"subset-receipt.json").write_text(json.dumps(receipt))
        write_receipt(out,indices)
        summarize(out)
        with (out/"summary.csv").open(newline="") as f: rows=list(csv.DictReader(f))
        assert all(r["planned"]=="1" and r["campaign_complete"]=="FALSE" for r in rows)

        # A changed copied manifest or forged source-directory identity fails
        # closed even though the external registry file itself is unchanged.
        (out/"manifest.csv").write_text((out/"manifest.csv").read_text()+"\n")
        summarize(out,expected=1)
        shutil.copy2(source/"manifest.csv",out/"manifest.csv")
        receipt["source_directory"]=str(out)
        (out/"subset-receipt.json").write_text(json.dumps(receipt))
        summarize(out,expected=1)
        shutil.rmtree(out)
    finally: tmp.cleanup()


def test_summary_and_identity_controls():
    # Full handcrafted denominator: known 950/1000 coverage and 50/1000 null FP.
    tmp,out=fixture(range(1,3001))
    try:
        for aidx,a in enumerate((-.5,0,.5)):
            for rep in range(1,1001):
                i=aidx*1000+rep
                if rep<=50:
                    lo,hi=((.2,.4) if a==0 else (a+.2,a+.4))
                    write_result(out,i,row_for(i,a,rep,i))
                    # Replace interval for known failure/non-null FP counts.
                    p=out/f"result-{i:04d}.csv"
                    with p.open(newline="") as f:r=next(csv.DictReader(f))
                    r["lower"],r["upper"]=lo,hi
                    with p.open("w",newline="") as f:w=csv.DictWriter(f,fieldnames=list(r));w.writeheader();w.writerow(r)
        write_hash_registry(out);write_receipt(out,range(1,3001));summarize(out)
        with (out/"summary.csv").open(newline="") as f:s=list(csv.DictReader(f))
        assert all(r["planned"]=="1000" and r["coverage_all_success"]=="950" for r in s)
        assert s[1]["false_positive_success"]=="50" and all(r["valid_fraction_threshold"]=="TRUE" for r in s)
        assert all(r["campaign_complete"]=="TRUE" and r["overall_qualified"]=="TRUE" for r in s)
        assert all(r["bias_diagnostics_only"]=="TRUE" for r in s)
        assert "logsd_bias_threshold" not in s[0] and "ratio_bias_threshold" not in s[0]
        assert all(r["staged_decision"]=="accept" for r in s)
        metrics=list(csv.DictReader((out/"staged-metrics.csv").open()))
        coverage=next(m for m in metrics if m["truth"]=="-0.5" and m["metric"]=="coverage")
        assert abs(float(coverage["ci_lower"])-float(s[0]["coverage_all_lo"])) < 1e-12
        # A near-complete 950/1000 study with five unstarted rows has useful
        # planned and attempted descriptives but can never qualify.
        for i in range(1,6): (out/f"result-{i:04d}.csv").unlink()
        status={i:"not_started" for i in range(1,6)}
        write_receipt(out,range(1,3001),status)
        summarize(out)
        with (out/"summary.csv").open(newline="") as f: stopped=list(csv.DictReader(f))
        assert stopped[0]["coverage_all_n"]=="1000" and stopped[0]["coverage_attempted_n"]=="995"
        assert stopped[0]["coverage_all_success"]=="950" and stopped[0]["campaign_complete"]=="FALSE"
        assert all(r["overall_qualified"]=="FALSE" and r["coverage_threshold"]=="FALSE" for r in stopped)
        # Interrupted runs are likewise descriptive only, even when almost all
        # nominal intervals are present.
        for i in range(1,6):
            a=(-.5,0,.5)[(i-1)//1000];rep=(i-1)%1000+1
            write_result(out,i,row_for(i,a,rep,i,valid=(i != 1)))
        write_receipt(out,range(1,3001),{1:"interrupted"})
        summarize(out)
        with (out/"summary.csv").open(newline="") as f: interrupted=list(csv.DictReader(f))
        assert all(r["campaign_complete"]=="FALSE" and r["overall_qualified"]=="FALSE" for r in interrupted)
    finally: tmp.cleanup()

    for mode in ("duplicate","swapped_seed","wrong_condition","missing_receipt_case","missing_result","bad_source","bad_manifest","bad_hash","registry_resealed"):
        tmp,out=fixture([1,1001,2001])
        try:
            if mode=="duplicate": shutil.copy2(out/"result-0001.csv",out/"result-1001.csv")
            elif mode=="swapped_seed":
                p=out/"result-0001.csv";r=next(csv.DictReader(p.open()));r["seed"]="2"
                with p.open("w",newline="") as f:w=csv.DictWriter(f,fieldnames=list(r));w.writeheader();w.writerow(r)
                write_hash_registry(out)
            elif mode=="wrong_condition":
                p=out/"result-0001.csv";r=next(csv.DictReader(p.open()));r["a"]="0"
                with p.open("w",newline="") as f:w=csv.DictWriter(f,fieldnames=list(r));w.writeheader();w.writerow(r)
                write_hash_registry(out)
            elif mode=="missing_receipt_case": write_receipt(out,[1,1001])
            elif mode=="missing_result": (out/"result-0001.csv").unlink()
            elif mode=="bad_source": (out/"source-fixture.R").write_text("changed source")
            elif mode=="bad_manifest": (out/"manifest.csv").write_text((out/"manifest.csv").read_text()+"\n")
            elif mode=="bad_hash": (out/"library/drmTMB/R/drmTMB.rdb").write_text("changed fixture")
            elif mode=="registry_resealed": (out/"source-hashes.csv").write_text((out/"source-hashes.csv").read_text()+"\n")
            summarize(out,expected=1)
        finally: tmp.cleanup()


def test_conditional_false_positive_denominator():
    tmp,out=fixture([1001,1002,1003,1004])
    try:
        # Two valid null intervals exclude zero; two invalid intervals are
        # excluded from conditional FP, but remain non-FP planned attempts.
        for i,valid in zip((1001,1002,1003,1004),(True,True,False,False)):
            row=row_for(i,0,(i-1000),i,valid=valid)
            if i <= 1002: row["lower"],row["upper"]=.2,.4
            write_result(out,i,row)
        write_hash_registry(out);write_receipt(out,[1001,1002,1003,1004])
        summarize(out)
        with (out/"summary.csv").open(newline="") as f: rows=list(csv.DictReader(f))
        null=rows[1]
        assert null["false_positive_success"]=="2" and null["false_positive_n"]=="4"
        assert null["false_positive_conditional_success"]=="2" and null["false_positive_conditional_n"]=="2"
        assert null["false_positive_conditional_rate"]=="1"
    finally: tmp.cleanup()


def test_failure_states_and_signal_cleanup():
    tmp,out=fixture([1,1001,2001])
    try:
        write_receipt(out,[1,1001,2001],{1:"error",1001:"timeout",2001:"not_started"},{1:7})
        (out/"result-2001.csv").unlink()
        for i,status in ((1,"completed"),(1001,"profiling")):
            a=(-.5,0,.5)[(i-1)//1000];rep=(i-1)%1000+1
            row=row_for(i,a,rep,i,valid=False);row["state"]=status
            write_result(out,i,row)
        write_hash_registry(out);summarize(out)
        with (out/"summary.csv").open(newline="") as f:s=list(csv.DictReader(f))
        assert s[0]["valid_intervals"]=="0" and s[0]["worker_errors"]=="1"
        assert s[1]["valid_intervals"]=="0" and s[1]["timeouts"]=="1"
        assert s[2]["nonstarted"]=="1" and s[2]["valid_intervals"]=="0"
        assert all(r["campaign_complete"]=="FALSE" and r["overall_qualified"]=="FALSE" for r in s)
    finally: tmp.cleanup()


def test_worker_validity_and_campaign_receipt_integrity():
    # A worker cannot label an interval valid when the supervisor says the
    # attempt errored or timed out. Those attempts remain denominator failures
    # only when the worker correctly records an invalid interval.
    for status,code in (("error",7),("timeout",124)):
        tmp,out=fixture([1,1001,2001])
        try:
            write_receipt(out,[1,1001,2001],{1:status},{1:code})
            row=row_for(1,-.5,1,1,valid=True)
            write_result(out,1,row)
            write_hash_registry(out)
            summarize(out,expected=1)
        finally: tmp.cleanup()

    # A receipt cannot assert campaign completion with an unresolved case or
    # its interrupted flag, even if the planned subset is otherwise valid.
    for status in ("not_started","interrupted","campaign_timeout","launch_error"):
        tmp,out=fixture([1,1001,2001])
        try:
            write_receipt(out,[1,1001,2001],{1:status})
            if status in {"not_started","launch_error"}:
                (out/"result-0001.csv").unlink()
            receipt=json.loads((out/"supervisor-receipt.json").read_text())
            receipt["campaign_complete"]=True
            (out/"supervisor-receipt.json").write_text(json.dumps(receipt))
            write_hash_registry(out)
            summarize(out,expected=1)
        finally: tmp.cleanup()

    tmp,out=fixture([1,1001,2001])
    try:
        receipt=json.loads((out/"supervisor-receipt.json").read_text())
        receipt["campaign_complete"]=True
        receipt["interrupted"]=True
        (out/"supervisor-receipt.json").write_text(json.dumps(receipt))
        write_hash_registry(out)
        summarize(out,expected=1)
    finally: tmp.cleanup()
    with tempfile.TemporaryDirectory(prefix="sd-signal-test-") as tmpdir:
        out=Path(tmpdir); script=out/"supervise_child.py"
        script.write_text("import sys,time; print('child',flush=True); time.sleep(20)")
        code=("import importlib.util,sys; p=sys.argv[1]; s=importlib.util.spec_from_file_location('r',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);from pathlib import Path;m.supervise([1],lambda i:[sys.executable,sys.argv[2]],Path(sys.argv[3]),workers=1,case_timeout=30,campaign_timeout=50)")
        proc=subprocess.Popen([sys.executable,"-c",code,str(HERE/"run.py"),str(script),str(out)])
        time.sleep(.5);proc.send_signal(signal.SIGTERM);proc.wait(timeout=5)
        receipt=json.loads((out/"supervisor-receipt.json").read_text())
        assert receipt["interrupted"] is True and receipt["cases"][0]["status"]=="interrupted"
        pid=receipt["cases"][0]["pid"]
        if pid:
            try: os.kill(pid,0)
            except ProcessLookupError: pass
            else: raise AssertionError("Owned child survived supervisor SIGTERM")


def test_qualification_manifest_and_cli_signal_exit():
    tmp,source=fixture([1,1001,2001])
    try:
        manifest=list(csv.DictReader((source/"manifest.csv").open()))
        for row in manifest:
            row["design_mode"]="qualification";row["master_seed"]="2026101704"
        with (source/"manifest.csv").open("w",newline="") as f:
            w=csv.DictWriter(f,fieldnames=list(manifest[0]));w.writeheader();w.writerows(manifest)
        (source/"design-receipt.txt").write_text("design_mode=qualification\nmaster_seed=2026101704\nstatus=prepared_not_launched\n")
        write_hash_registry(source);write_receipt(source,[1,1001,2001])
        (source/"subset-receipt.json").write_text(json.dumps({"planned_indices":[1,1001,2001],"registry_sha256":sha(source/"source-hashes.csv"),"design_mode":"qualification","master_seed":2026101704}))
        summarize(source)
        with (source/"summary.csv").open(newline="") as f: rows=list(csv.DictReader(f))
        assert all(r["design_mode"]=="qualification" and r["qualification_eligible"]=="FALSE" and r["overall_qualified"]=="FALSE" for r in rows)
        assert all(r["coverage_threshold"]=="FALSE" for r in rows)

        fake=source/"fake-rscript"
        fake.write_text("#!/usr/bin/env python3\nimport time\ntime.sleep(30)\n")
        fake.chmod(0o755)
        output=source/"cli-subset"
        command=[sys.executable,str(HERE/"run.py"),str(source),"--indices","1,1001,2001",
                 "--subset-output",str(output),"--workers","3","--campaign-timeout","120",
                 "--registry-sha256",sha(source/"source-hashes.csv")]
        env=os.environ.copy();env["RSCRIPT"]=str(fake);env["DRMTMB_SD_TEST_LIBRARY"]="/synthetic-library"
        proc=subprocess.Popen(command,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        time.sleep(.6);proc.send_signal(signal.SIGTERM);proc.communicate(timeout=6)
        assert proc.returncode==2
        receipt=json.loads((output/"supervisor-receipt.json").read_text())
        assert receipt["interrupted"] is True and receipt["subset_complete"] is False
    finally: tmp.cleanup()


if __name__=="__main__":
    test_generator();test_stage_two_manifest();test_staged_analyzer();test_supervisor();test_contention();test_subset_copy();test_summary_and_identity_controls();test_conditional_false_positive_denominator();test_failure_states_and_signal_cleanup();test_worker_validity_and_campaign_receipt_integrity();test_qualification_manifest_and_cli_signal_exit()
    print("NATIVE_CALIBRATION_SELF_TEST_PASS integrity=pass dgp=pass identities=pass supervisor_cleanup=pass")
