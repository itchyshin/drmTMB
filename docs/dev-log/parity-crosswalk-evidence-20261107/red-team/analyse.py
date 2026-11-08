#!/usr/bin/env python3
# usage: analyse.py OUTDIR [BEFORE_OUTDIR]  -> OUTDIR/table.tsv, OUTDIR/table.md
# OUTDIR holds R_all.tsv and J_*.tsv (later files override earlier ones for the same cell id).
import csv, sys, os, collections
RT = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]; BEFORE = sys.argv[2] if len(sys.argv) > 2 else None
cells = {r[0]: r for r in list(csv.reader(open(f"{RT}/cells.tsv"), delimiter="\t"))[1:]}
cols = ["id", "eng", "status", "cls", "conv", "ll", "nobs", "secs", "seok", "coef", "warn", "msg"]
def load(files):
    d = {}
    for f in files:
        if not os.path.exists(f): continue
        for l in open(f):
            p = l.rstrip("\n").split("\t"); p += [""] * (12 - len(p)); d[p[0]] = dict(zip(cols, p))
    return d
def jfiles(o): return sorted(f"{o}/{f}" for f in os.listdir(o) if f.startswith("J_") and f.endswith(".tsv") and "pilot" not in f)
R = load([f"{OUT}/R_all.tsv"]); J = load(jfiles(OUT)); JB = load(jfiles(BEFORE)) if BEFORE else {}
def fnum(x):
    try: return float(x)
    except: return float("nan")
def rclass(r):
    if r["status"] == "fit": return "fit" if r["conv"] in ("0", "") else "fit-nonconv"
    if r["status"] in ("hang", "crash"): return r["status"]
    return "refuse" if "rlang_error" in r["cls"] else "error"
def jclass(r):
    if r["status"] == "fit": return "fit" if r["conv"] == "true" else "fit-nonconv"
    if r["status"] in ("hang", "crash"): return r["status"]
    return "refuse" if r["cls"] in ("ArgumentError", "DimensionMismatch") else "error"
base_gap = {}
for cid, c in cells.items():
    if c[1] == "d00_baseline" and cid in R and cid in J:
        a, b = fnum(R[cid]["ll"]), fnum(J[cid]["ll"])
        if a == a and b == b: base_gap[(c[2], c[3])] = b - a
rows = []
for cid, c in cells.items():
    r, j = R.get(cid), J.get(cid)
    if r is None or j is None: continue
    rc, jc = rclass(r), jclass(j)
    llr, llj = fnum(r["ll"]), fnum(j["ll"])
    gap = llj - llr if (llr == llr and llj == llj) else float("nan")
    bg = base_gap.get((c[2], c[3]), float("nan"))
    flags = []
    rfit, jfit = rc in ("fit", "fit-nonconv"), jc in ("fit", "fit-nonconv")
    if rfit and jc == "error": flags.append("J-NON-ARGUMENTERROR(R fits)")
    if rc == "refuse" and jc == "error": flags.append("J-NON-ARGUMENTERROR(R refuses clearly)")
    if rc == "refuse" and jfit: flags.append("J-FITS-WHERE-R-REFUSES")
    if rfit and jc == "refuse": flags.append("J-REFUSES-WHERE-R-FITS")
    if jc == "hang": flags.append("J-HANG")
    if rc == "hang": flags.append("R-HANG")
    if jfit and llj <= -1e17: flags.append("J-SENTINEL-LL(-1e18)")
    if jfit and llj > 1e3: flags.append("J-ABSURD-POSITIVE-LL")
    if rfit and jfit and gap == gap:
        if abs(gap) <= 1e-4: pass
        elif bg == bg and abs(bg) > 1e-4 and abs(gap - bg) <= 0.05 and c[1] != "d00_baseline": flags.append("LL-BASELINE-METHOD-GAP")
        elif c[1] == "d00_baseline": flags.append("LL-BASELINE-GAP")
        else: flags.append("LL-DISAGREE(" + ("J higher" if gap > 0 else "R higher") + ")" + ("" if jc == "fit" and rc == "fit" else " [a fit is non-converged]"))
        if r["nobs"] and j["nobs"] and r["nobs"] != j["nobs"]: flags.append("NOBS-DIFFERS")
        if j["seok"] == "false": flags.append("J-NONFINITE-SE")
        if r["seok"] == "FALSE": flags.append("R-NONFINITE-SE")
    changed = ""
    if BEFORE and c[0] in JB and cid in JB:
        a, b = jclass(JB[cid]), jclass(j)
        if a != b or (JB[cid]["msg"] != j["msg"]): changed = f"{a} -> {b}"
    rows.append(dict(id=cid, ds=c[1], route=c[2], fam=c[3], R=rc, J=jc, ll_R=llr, ll_J=llj, gap=gap, base_gap=bg,
                     nobs_R=r["nobs"], nobs_J=j["nobs"], secs_R=r["secs"], secs_J=j["secs"], flags="; ".join(flags),
                     R_msg=(r["msg"] or r["warn"])[:240], J_exc=j["cls"], J_msg=(j["msg"] or "")[:240], J_warn=j["warn"][:240],
                     changed_by_fix=changed))
keys = list(rows[0].keys())
with open(f"{OUT}/table.tsv", "w") as f:
    f.write("\t".join(keys) + "\n")
    for r in rows: f.write("\t".join(str(r[k]).replace("\t", " ") for k in keys) + "\n")
with open(f"{OUT}/table.md", "w") as f:
    f.write("| id | dataset | route | family | R | Julia | logLik R | logLik Julia | J-R gap | flags | Julia message / R message |\n|---|---|---|---|---|---|---|---|---|---|---|\n")
    for r in rows:
        def n(x): return "" if x != x else (f"{x:.6g}" if isinstance(x, float) else str(x))
        msg = r["J_msg"] if r["J"] in ("refuse", "error") else (r["R_msg"] if r["R"] in ("refuse", "error") else "")
        if r["J"] in ("refuse", "error") and r["R"] in ("refuse", "error"): msg = "J: " + r["J_msg"][:110] + " / R: " + r["R_msg"][:110]
        f.write(f"| {r['id']} | {r['ds']} | {r['route']} | {r['fam']} | {r['R']} | {r['J']} | {n(r['ll_R'])} | {n(r['ll_J'])} | {n(r['gap'])} | {r['flags']} | {msg.replace('|', '/')} |\n")
cnt = collections.Counter((r["R"], r["J"]) for r in rows)
print("cells compared:", len(rows)); [print(k, v) for k, v in sorted(cnt.items())]
fc = collections.Counter(x.split(" [")[0] for r in rows for x in r["flags"].split("; ") if x); print(fc)
if BEFORE:
    print("changed by fix:"); [print(" ", r["id"], r["ds"], r["route"], r["fam"], r["changed_by_fix"]) for r in rows if r["changed_by_fix"]]
