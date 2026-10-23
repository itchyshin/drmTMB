#!/usr/bin/env python3
"""A10 pre-run receipt: read reps/*.json (written on Totoro by prerun_r.R and
prerun_jl.jl), enforce the G2 same-optimum gate, write prerun-receipt.json.

Usage: python3 make_receipt.py [REPS_DIR] [OUT_JSON]
Exit 1 (and no receipt) if either engine failed to converge on any rep or the
timed-rep logLik gap exceeds 1e-4 -- a speed number over non-matching optima is
not a benchmark, so the receipt refuses to exist in that case.
"""
import json, statistics, sys, os

reps = sys.argv[1] if len(sys.argv) > 1 else "reps"
out = sys.argv[2] if len(sys.argv) > 2 else "prerun-receipt.json"
LOGLIK_TOL = 1e-4

def load(name):
    with open(os.path.join(reps, name)) as fh:
        return json.load(fh)

r = [load(f"r-rep{i}.json") for i in range(4)]
j = [load(f"jl-rep{i}.json") for i in range(4)]
r_env, j_env = load("r-env.json"), load("jl-env.json")

problems = []
for x in r + j:
    if not x["converged"]:
        problems.append(f"{x['engine']} rep {x['rep']} did not converge")
gap = abs(r[1]["loglik"] - j[1]["loglik"])
if gap > LOGLIK_TOL:
    problems.append(f"logLik gap {gap:.4e} > {LOGLIK_TOL:g}: optimum mismatch, do not time")
if len({x["loglik"] for x in r}) != 1 or len({x["loglik"] for x in j}) != 1:
    problems.append("logLik differs between reps of the same engine (non-deterministic fit)")
if problems:
    print("G2 FAILED -- no receipt written:\n  " + "\n  ".join(problems))
    sys.exit(1)

rc = r[1]["coef"]
r_named = {"mu1_(Intercept)": rc["mu1"][0], "mu1_x": rc["mu1"][1],
           "mu2_(Intercept)": rc["mu2"][0], "mu2_x": rc["mu2"][1],
           "sigma1_(Intercept)": rc["sigma1"], "sigma2_(Intercept)": rc["sigma2"],
           "rho12_(Intercept)": rc["rho12"]}
j_named = j[1]["coef"]
d_coef = {k: abs(r_named[k] - j_named[k]) for k in r_named}

def timed(xs, key):
    return [x[key] for x in xs[1:]]

summary = {}
for tag, xs in (("drmTMB_native_tmb", r), ("DRM_jl_native", j)):
    summary[tag] = {
        "warmup_wall_s_DISCARDED": xs[0]["wall_s"],
        "timed_wall_s": timed(xs, "wall_s"),
        "timed_cpu_s": timed(xs, "cpu_s"),
        "median_wall_s": statistics.median(timed(xs, "wall_s")),
        "median_cpu_s": statistics.median(timed(xs, "cpu_s")),
        "converged": [x["converged"] for x in xs],
        "loglik": xs[1]["loglik"],
    }
ratio_wall = summary["DRM_jl_native"]["median_wall_s"] / summary["drmTMB_native_tmb"]["median_wall_s"]
ratio_cpu = summary["DRM_jl_native"]["median_cpu_s"] / summary["drmTMB_native_tmb"]["median_cpu_s"]

receipt = {
    "leaf": "A10-prerun (P4 warm-workflow PRE-RUN; the FULL GRID WAS NOT RUN)",
    "design": "1 fixture cell (biv-q4-phylo-reml) x 2 NATIVE engines x (1 warm-up discarded + 3 timed reps), one process per engine, single core",
    "host": {"name": r_env["host"], "R": r_env["R_version"], "platform": r_env["platform"],
             "julia": j_env["julia_version"], "OPENBLAS_NUM_THREADS": r_env["OPENBLAS_NUM_THREADS"],
             "JULIA_NUM_THREADS": j_env["JULIA_NUM_THREADS"], "BLAS_threads_julia": j_env["BLAS_threads"]},
    "packages": {"drmTMB": {"version": r_env["drmTMB_version"], "sha": r_env["drmTMB_RemoteSha"],
                            "ref": r_env["drmTMB_RemoteRef"], "built": r_env["drmTMB_Built"],
                            "TMB": r_env["TMB_version"]},
                 "DRM.jl": {"sha": j_env["DRM_jl_sha"]}},
    "fixture": "DRM.jl test/parity/q4-reml/biv-q4-phylo-reml (data.csv + tree.newick, n = 128, 16 tips), biv_gaussian, REML",
    "g2_same_optimum": {"loglik_drmTMB": r[1]["loglik"], "loglik_DRM_jl": j[1]["loglik"],
                        "abs_gap": gap, "tolerance": LOGLIK_TOL,
                        "coef_abs_diff": d_coef, "max_coef_abs_diff": max(d_coef.values())},
    "timings": summary,
    "ratio_DRM_jl_over_drmTMB": {"median_wall": ratio_wall, "median_cpu": ratio_cpu},
    "caveats": [
        "Julia 1.12.6 on Totoro (DRM.jl #629 reports 1.12 vs 1.10 timing differences); no 1.10 measurement here.",
        "drmTMB's fit includes its default TMB::sdreport(); DRM.jl was called with q4_vcov = false (the fixture test's and the bridge's default for this route; its Wald vcov is fenced, #495). The Julia number therefore excludes an uncertainty step the R number includes.",
        "Timings are for one tiny cell (n = 128, 7 fixed effects); they say nothing about scaling.",
        "Thread pins were by environment variable (OPENBLAS/OMP/JULIA_NUM_THREADS = 1), not CPU affinity; /usr/bin/time reported 99-100% CPU for both processes.",
        "Another lane's Pkg.test() (~/s7b_work, one core) was running on the 384-core host; load average ~1.0.",
        "The FULL GRID WAS NOT RUN. It is the owner's D-139 gate.",
    ],
}
with open(out, "w") as fh:
    json.dump(receipt, fh, indent=2)
print(f"receipt written: {out}")
print(f"logLik gap {gap:.4e} <= {LOGLIK_TOL:g}; max |d_coef| {max(d_coef.values()):.4e}")
print(f"median wall R {summary['drmTMB_native_tmb']['median_wall_s']:.3f} s, Julia {summary['DRM_jl_native']['median_wall_s']:.3f} s; ratio Julia/R {ratio_wall:.3f} (cpu {ratio_cpu:.3f})")
