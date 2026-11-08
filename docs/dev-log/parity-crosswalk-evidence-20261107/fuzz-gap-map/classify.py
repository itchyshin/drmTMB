#!/usr/bin/env python3
"""Classify the refusal-gap map.  Usage: python3 -I classify.py <rawdir_with_r_and_julia_out> <outdir>
Reads raw/<engine>/*.out (S/R lines), cells.tsv; writes gap_map.tsv and the derived tables."""
import os, sys, re, glob, json, collections, itertools

here = os.path.dirname(os.path.abspath(__file__))
raw, outdir = sys.argv[1], sys.argv[2]
os.makedirs(outdir, exist_ok=True)

COLS = ["status", "etype", "msg", "msgfull", "ll", "conv", "extra", "secs", "warn"]

def load_engine(eng):
    res = {}
    for f in sorted(glob.glob(os.path.join(raw, eng, "*.out"))):
        for l in open(f, errors="replace"):
            p = l.rstrip("\n").split("\t")
            if p[0] == "R" and len(p) >= 12:
                res[p[2]] = dict(zip(COLS, p[3:12]))
    return res

R = load_engine("r"); J = load_engine("julia")
# Second Julia pass for kind=spatial with `coords` passed as a G x 2 matrix (some routes accept only one coords format).
J2 = load_engine("julia_matcoords") if os.path.isdir(os.path.join(raw, "julia_matcoords")) else {}
JVAR = {}
for cid, x2 in J2.items():
    if J.get(cid, {}).get("status") != "FITS" and x2["status"] == "FITS":
        J[cid] = x2; JVAR[cid] = "matrix-coords"
J2OUT = {cid: x2["status"] for cid, x2 in J2.items()}
cells = []
_lines = open(os.path.join(here, "cells.tsv")).read().splitlines()[1:]
for _extra in ("cells_indep.tsv", "cells_slope.tsv"):
    if os.path.exists(os.path.join(here, _extra)):
        _lines += open(os.path.join(here, _extra)).read().splitlines()[1:]
for l in _lines:
    p = l.split("\t")
    cells.append(dict(cell_id=p[0], family=p[1], kind=p[2], lab=int(p[3]), q=int(p[4]), pat=p[5], cm=int(p[6]), est=p[7]))

# ---- outcome classification -------------------------------------------------------------------
NUMERIC = re.compile(r"(not positive definite|PosDef|NaN|non-?finite|Cholesky|singular|did not converge|line search|LAPACK|overflow|DomainError|sqrt will only)", re.I)
CRASH_TYPES = {"MethodError", "BoundsError", "KeyError", "DimensionMismatch", "UndefVarError", "UndefRefError", "TypeError",
               "InexactError", "AssertionError", "PosDefException", "SingularException", "LAPACKException", "DomainError",
               "OverflowError", "StackOverflowError", "DivideError", "OutOfMemoryError", "BoundsError", "InvalidStateException",
               "ErrorException:internal"}

def outcome(eng, r):
    """returns (outcome, subtype)"""
    s = r["status"]
    if s in ("FITS", "NONCONVERGED", "TIMEOUT"):
        return s, ""
    if s == "PROCESS_DIED":
        return "ERRORS", "process-died"
    if s == "RUNNER_ERROR":
        return "RUNNER_ERROR", r["etype"]
    et = r["etype"]; msg = r["msgfull"] or r["msg"]
    if eng == "r":
        if et.startswith("abort:"):
            return ("ERRORS", "numeric-abort") if NUMERIC.search(msg) else ("REFUSES", "cli_abort")
        return "ERRORS", "base-error"
    # julia
    if et == "MethodError":
        return "ERRORS", ("kwarg-MethodError" if "keyword call" in msg else "MethodError")
    if et in ("ArgumentError", "ErrorException"):
        if NUMERIC.search(msg): return "ERRORS", "numeric-" + et
        return "REFUSES", et
    return "ERRORS", et

def sig(eng, r):
    m = r["msgfull"] or r["msg"]
    if not m: return ""
    m = re.sub(r"\x1b\[[0-9;]*m", "", m)
    m = re.sub(r"^ArgumentError:\s*", "", m)
    if eng == "r":
        m = re.split(r" [✖ℹ] ", m)[0]
    m = re.sub(r"`[^`]*`", "`T`", m)
    m = re.sub(r"\"[^\"]*\"", "\"S\"", m)
    m = re.sub(r"\d+(\.\d+)*", "N", m)
    m = re.sub(r"\(\s*:\w+(, :\w+)*\)", "(kw)", m) if "keyword call" in m else m
    return m[:170].strip()

rows = []
for c in cells:
    r = R.get(c["cell_id"]); j = J.get(c["cell_id"])
    row = dict(c)
    for eng, x in (("r", r), ("j", j)):
        if x is None:
            row[eng + "_outcome"] = "MISSING"; row[eng + "_sub"] = ""; row[eng + "_ll"] = ""; row[eng + "_conv"] = ""
            row[eng + "_secs"] = ""; row[eng + "_msg"] = ""; row[eng + "_sig"] = ""; row[eng + "_extra"] = ""; row[eng + "_etype"] = ""; row[eng + "_warn"] = ""
            continue
        o, sub = outcome("r" if eng == "r" else "julia", x)
        row[eng + "_outcome"] = o; row[eng + "_sub"] = sub; row[eng + "_ll"] = x["ll"]; row[eng + "_conv"] = x["conv"]
        row[eng + "_secs"] = x["secs"]; row[eng + "_msg"] = x["msg"] if o != "FITS" else ""
        row[eng + "_sig"] = sig("r" if eng == "r" else "julia", x) if o in ("REFUSES", "ERRORS") else ""
        row[eng + "_extra"] = x["extra"]; row[eng + "_etype"] = x["etype"]; row[eng + "_warn"] = x["warn"]
    ro, jo = row["r_outcome"], row["j_outcome"]
    crash = "+".join(s for s, o in (("R", ro), ("Julia", jo)) if o == "ERRORS") or "none"
    row["crash_side"] = crash
    row["j_variant"] = JVAR.get(c["cell_id"], "")
    row["j_matrix_coords_status"] = J2OUT.get(c["cell_id"], "")
    qf = []
    if ro == "FITS":
        if "pdHess=FALSE" in row["r_extra"]: qf.append("R:pdHess=FALSE")
        if "is_converged=FALSE" in row["r_extra"]: qf.append("R:is_converged=FALSE")
    if jo == "FITS" and "se_finite=false" in row["j_extra"]: qf.append("Julia:se_nonfinite")
    if jo == "FITS" and row["j_ll"] and float(row["j_ll"]) < -1e17: qf.append("Julia:sentinel_ll")
    row["quality_flag"] = ";".join(qf)
    row["ll_diff"] = ""; row["ll_flag"] = ""
    if ro == "FITS" and jo == "FITS":
        row["class"] = "both-fit"
        d = abs(float(row["r_ll"]) - float(row["j_ll"])); row["ll_diff"] = "%.3e" % d
        row["ll_flag"] = "DISAGREE" if d > 1e-4 else "ok"
    elif "ERRORS" in (ro, jo):
        row["class"] = "crash-" + {"R": "R", "Julia": "Julia", "R+Julia": "both"}[crash]
    elif "TIMEOUT" in (ro, jo) or "MISSING" in (ro, jo) or "RUNNER_ERROR" in (ro, jo):
        row["class"] = "inconclusive"
    elif "NONCONVERGED" in (ro, jo):
        row["class"] = "nonconverged"
    elif ro == "FITS" and jo == "REFUSES":
        row["class"] = "R-only"
    elif jo == "FITS" and ro == "REFUSES":
        row["class"] = "Julia-only"
    elif ro == "REFUSES" and jo == "REFUSES":
        row["class"] = "both-refuse"
    else:
        row["class"] = "other"
    # detail for the combined "Julia behind" view
    if ro == "FITS" and jo != "FITS":
        row["julia_behind"] = {"REFUSES": "refuses", "ERRORS": "crashes", "NONCONVERGED": "nonconverged", "TIMEOUT": "timeout"}.get(jo, jo)
    else:
        row["julia_behind"] = ""
    row["r_behind"] = ({"REFUSES": "refuses", "ERRORS": "crashes", "NONCONVERGED": "nonconverged", "TIMEOUT": "timeout"}.get(ro, ro)) if (jo == "FITS" and ro != "FITS") else ""
    rows.append(row)

OUTCOLS = ["cell_id", "family", "kind", "lab", "q", "pat", "cm", "est", "class", "crash_side", "quality_flag", "j_variant", "j_matrix_coords_status", "julia_behind", "r_behind",
           "r_outcome", "r_sub", "r_ll", "r_conv", "r_secs", "r_msg", "j_outcome", "j_sub", "j_ll", "j_conv", "j_secs", "j_msg",
           "ll_diff", "ll_flag", "r_sig", "j_sig", "r_extra", "j_extra", "r_warn", "j_warn"]
def w(name, rs, cols):
    with open(os.path.join(outdir, name), "w") as f:
        f.write("\t".join(cols) + "\n")
        for r in rs: f.write("\t".join(str(r.get(c, "")).replace("\t", " ").replace("\n", " ") for c in cols) + "\n")
w("gap_map.tsv", rows, OUTCOLS)

summ = {}
summ["n_cells"] = len(rows)
summ["class_counts"] = collections.Counter(r["class"] for r in rows)
summ["r_outcomes"] = collections.Counter(r["r_outcome"] for r in rows)
summ["j_outcomes"] = collections.Counter(r["j_outcome"] for r in rows)
summ["crash_sides"] = collections.Counter(r["crash_side"] for r in rows)
summ["julia_behind"] = collections.Counter(r["julia_behind"] for r in rows if r["julia_behind"])
summ["r_behind"] = collections.Counter(r["r_behind"] for r in rows if r["r_behind"])
summ["j_sub"] = collections.Counter((r["j_outcome"], r["j_sub"]) for r in rows if r["j_outcome"] in ("ERRORS", "REFUSES"))
summ["r_sub"] = collections.Counter((r["r_outcome"], r["r_sub"]) for r in rows if r["r_outcome"] in ("ERRORS", "REFUSES"))

# ---- crash cells ----------------------------------------------------------------------------
crash = [r for r in rows if r["crash_side"] != "none"]
w("crash_cells.tsv", crash, OUTCOLS)
cs = collections.defaultdict(list)
for r in crash:
    for side, pre in (("R", "r"), ("Julia", "j")):
        if r[pre + "_outcome"] == "ERRORS":
            cs[(side, r[pre + "_sub"], r[pre + "_etype"], r[pre + "_sig"])].append(r)

# ---- Julia-behind work list, ranked ---------------------------------------------------------
behind = [r for r in rows if r["julia_behind"]]
byid = {r["cell_id"]: r for r in rows}
coords = ["family", "kind", "lab", "q", "pat", "cm", "est"]
behind_ids = set(r["cell_id"] for r in behind)
key = lambda r: tuple(r[c] for c in coords)
index = {key(r): r for r in rows}
domains = {c: sorted(set(r[c] for r in rows), key=str) for c in coords}
for r in behind:
    n = 0
    for c in coords:
        for v in domains[c]:
            if v == r[c]: continue
            k2 = list(key(r)); k2[coords.index(c)] = v
            o = index.get(tuple(k2))
            if o is not None and o["cell_id"] in behind_ids: n += 1
    r["behind_neighbours"] = n
sigcount = collections.Counter((r["julia_behind"], r["j_sig"]) for r in behind)
for r in behind:
    r["unlocks"] = sigcount[(r["julia_behind"], r["j_sig"])]
behind.sort(key=lambda r: (-r["unlocks"], -r["behind_neighbours"], r["cell_id"]))
w("julia_behind_ranked.tsv", behind, ["cell_id", "unlocks", "behind_neighbours", "julia_behind", "class", "j_outcome", "j_sub", "j_sig", "j_msg", "r_ll", "r_extra", "family", "kind", "lab", "q", "pat", "cm", "est"])
groups = collections.OrderedDict()
for r in behind:
    g = groups.setdefault((r["julia_behind"], r["j_sig"]), dict(cells=[], fam=collections.Counter(), kind=collections.Counter(), q=collections.Counter(), est=collections.Counter()))
    g["cells"].append(r["cell_id"]); g["fam"][r["family"]] += 1; g["kind"][r["kind"]] += 1; g["q"][r["q"]] += 1; g["est"][r["est"]] += 1
with open(os.path.join(outdir, "julia_behind_groups.tsv"), "w") as f:
    f.write("rank\tcells_unlocked\tjulia_mode\tfamilies\tkinds\tq\test\tjulia_signature\texample_cell\n")
    for i, ((mode, s), g) in enumerate(sorted(groups.items(), key=lambda kv: -len(kv[1]["cells"])), 1):
        f.write("%d\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (i, len(g["cells"]), mode,
            ",".join("%s:%d" % kv for kv in g["fam"].most_common()), ",".join("%s:%d" % kv for kv in g["kind"].most_common()),
            ",".join("%s:%d" % kv for kv in sorted(g["q"].items())), ",".join("%s:%d" % kv for kv in g["est"].most_common()), s, g["cells"][0]))

# ---- R-behind (Julia-only) ------------------------------------------------------------------
rb = [r for r in rows if r["r_behind"]]
w("julia_only_cells.tsv", rb, OUTCOLS)

# ---- loglik disagreements -------------------------------------------------------------------
dis = [r for r in rows if r["ll_flag"] == "DISAGREE"]
dis.sort(key=lambda r: -float(r["ll_diff"]))
LAP = {}
lapdir = os.path.join(raw, "julia_laplace")
if os.path.isdir(lapdir):
    for f in glob.glob(os.path.join(lapdir, "*.out")):
        for l in open(f, errors="replace"):
            p = l.rstrip("\n").split("\t")
            if p[0] == "R" and len(p) >= 12: LAP[p[2]] = dict(zip(COLS, p[3:12]))
for r in dis:
    lp = LAP.get(r["cell_id"]); ex = []
    if lp and lp["status"] == "FITS":
        d = abs(float(lp["ll"]) - float(r["r_ll"]))
        ex.append("Julia marginal=:Laplace reproduces R to %.1e" % d if d < 1e-4 else "Julia marginal=:Laplace still differs by %.2e" % d)
    elif lp:
        ex.append("marginal=:Laplace not available on this Julia route (%s)" % (lp["msg"][:60] or lp["status"]))
    if r["quality_flag"]: ex.append("fit-quality flag " + r["quality_flag"])
    if r["family"] == "gaussian" and r["kind"] == "spatial" and r["pat"] == "none":
        ex.append("Julia estimates the spatial range when there is no SD formula (more parameters: %s vs %s)" % (r["j_extra"].split("npar=")[-1], r["r_extra"].split("npar=")[-1]))
    r["explanation"] = "; ".join(ex)
w("loglik_disagreements.tsv", dis, OUTCOLS + ["explanation"])
bf = [r for r in rows if r["class"] == "both-fit"]

# ---- signature tables -----------------------------------------------------------------------
for eng, pre in (("r", "r"), ("julia", "j")):
    cnt = collections.Counter((r[pre + "_outcome"], r[pre + "_sub"], r[pre + "_etype"], r[pre + "_sig"]) for r in rows if r[pre + "_outcome"] in ("REFUSES", "ERRORS"))
    with open(os.path.join(outdir, "signatures_%s.tsv" % eng), "w") as f:
        f.write("cells\toutcome\tsubtype\texception_type\tnormalised_message\n")
        for k, n in cnt.most_common(): f.write("%d\t%s\t%s\t%s\t%s\n" % (n, *k))

# ---- by-family / kind breakdown -------------------------------------------------------------
with open(os.path.join(outdir, "breakdown_family_kind.tsv"), "w") as f:
    f.write("family\tkind\tn\tboth-fit\tR-only\tJulia-only\tboth-refuse\tcrash\tnonconverged\tinconclusive\tR_fits\tJulia_fits\n")
    for fam in domains["family"]:
        for kd in domains["kind"]:
            sub = [r for r in rows if r["family"] == fam and r["kind"] == kd]
            if not sub: continue
            cc = collections.Counter(r["class"] for r in sub)
            crashn = sum(v for k, v in cc.items() if k.startswith("crash"))
            f.write("\t".join(map(str, [fam, kd, len(sub), cc["both-fit"], cc["R-only"], cc["Julia-only"], cc["both-refuse"], crashn, cc["nonconverged"], cc["inconclusive"],
                    sum(r["r_outcome"] == "FITS" for r in sub), sum(r["j_outcome"] == "FITS" for r in sub)])) + "\n")

# ---- matrix claim cross-check -----------------------------------------------------------------
def sel(family=None, kind=None, lab=None, q=None, pat=None, cm=0, est="ML"):
    out = []
    for r in rows:
        if family and r["family"] not in ([family] if isinstance(family, str) else family): continue
        if kind and r["kind"] not in ([kind] if isinstance(kind, str) else kind): continue
        if lab is not None and r["lab"] != lab: continue
        if q is not None and r["q"] not in ([q] if isinstance(q, int) else q): continue
        if pat and r["pat"] not in ([pat] if isinstance(pat, str) else pat): continue
        if cm is not None and r["cm"] != cm: continue
        if est and r["est"] != est: continue
        out.append(r)
    return out

claims = [
 # source: WT = working-tree docs/design/168 at the path given (dirty, 809 commits behind origin/main); MAIN = origin/main (0.8.1 era)
 ("A1", "WT", "Header: native TMB fits Bernoulli ordinary independent-intercept SD regression (ordinary q=1, ~1 or ~z)", "R", sel("binomial", "ordinary", 0, 1, ["one", "z"])),
 ("A2", "WT", "Header: Bernoulli selected independent-slope SD regression (slope-only term (0 + x | g), sd ~ z)", "R", sel("binomial", "slope", 0, 1, "z")),
 ("A3", "WT", "Header: the separate Bernoulli animal q=2 SD route (animal(1 + x | g), one SD formula per coefficient)", "R", sel("binomial", "animal", 0, 2, ["z"])),
 ("A4", "WT", "Header: Poisson ordinary independent-intercept (q=1) and selected independent-slope (slope-only term) SD regression", "R", sel("poisson", "ordinary", 0, 1, ["one", "z"]) + sel("poisson", "slope", 0, 1, "z")),
 ("A5", "WT", "Header: NB2 ordinary independent-intercept (q=1) and selected independent-slope (slope-only term) SD regression", "R", sel("nb2", "ordinary", 0, 1, ["one", "z"]) + sel("nb2", "slope", 0, 1, "z")),
 ("A6", "WT", "Header: Gamma ordinary independent-intercept (q=1) and selected independent-slope (slope-only term) SD regression, sigma ~ 1", "R", sel("gamma", "ordinary", 0, 1, ["one", "z"]) + sel("gamma", "slope", 0, 1, "z")),
 ("A7", "WT", "Non-Gaussian row: selected independent-slope slices (slope-only term, sd ~ z) for Beta, lognormal, Student-t", "R", sel(["beta", "lognormal", "student"], "slope", 0, 1, "z")),
 ("A7b", "WT", "Same rows, other reading of 'independent': intercept and slope as separate terms (1|g)+(0+x|g) with SD on the slope only (info: shows which families R 0.8.1 fits in this shape)", "info", sel(["binomial", "poisson", "nb2", "gamma", "beta", "lognormal", "student"], "indep", 0, 2, "last")),
 ("A8", "WT", "Non-Gaussian row: selected slopes in unlabelled correlated q=2 blocks for Bernoulli, Beta, Poisson, NB2, Gamma, lognormal, Student-t (ordinary lab0 q=2, SD on one coefficient)", "R",
        sel(["binomial", "beta", "poisson", "nb2", "gamma", "lognormal", "student"], "ordinary", 0, 2, ["first", "last"])),
 ("A9", "WT", "Non-Gaussian row: direct-SD intercept slices for Bernoulli, Beta, Poisson, NB2, Gamma, lognormal, Student-t (ordinary q=1, ~z)", "R",
        sel(["binomial", "beta", "poisson", "nb2", "gamma", "lognormal", "student"], "ordinary", 0, 1, "z")),
 ("B1", "MAIN", "origin/main Bernoulli row: random effects and structured effects 'remain unavailable' for binomial (any binomial ML cell with a random effect that R fits contradicts it)", "Rnot",
        [r for r in sel("binomial", None, None, None, None, cm=None, est="ML")]),
 ("B2", "MAIN", "origin/main claim guard: 'Plain Bernoulli/binomial support means event-probability mu only ... not random-effect binomial' (same cells as B1)", "Rnot",
        [r for r in sel("binomial", None, None, None, None, cm=None, est="ML")]),
 ("C1", "BOTH", "Gaussian REML: mean-side phylo admitted (phylo q=1, no SD formula)", "R", sel("gaussian", "phylo", 0, 1, "none", est="REML")),
 ("C2", "BOTH", "Gaussian REML: direct-SD phylo (phylo q=1, sd ~ z)", "R", sel("gaussian", "phylo", 0, 1, "z", est="REML")),
 ("C3", "BOTH", "Gaussian REML: ordinary random effects admitted (ordinary q=1 and q=2 independent terms, no SD formula)", "R", sel("gaussian", ["ordinary", "indep"], 0, [1, 2], "none", est="REML")),
 ("C4", "BOTH", "Gaussian REML with direct ordinary SD regression: matrix lists 'ordinary sigma random effects' only; R itself refuses REML with direct ordinary sd() (expected NOT to fit)", "Rnot", sel("gaussian", "ordinary", 0, 1, "z", est="REML")),
 ("N1", "BOTH", "NOT COMPARABLE (bivariate wording): 'Q, animal(), slopes, q4+ ... do not inherit' the REML admission; the map is univariate. Univariate animal q=1 REML (no SD) outcome shown for information", "info", sel("gaussian", "animal", 0, 1, "none", est="REML")),
 ("N2", "BOTH", "NOT COMPARABLE (bivariate wording): 'bivariate mu-sigma RE correlations still gated'. The map's univariate labelled mu+sigma intercept block (1|p|g) in both formulas, Gaussian, ML", "info", sel("gaussian", "ordinary", 0, 1, "none", cm=1)),
 ("J1", "WT", "Matrix: 'Direct-SD Julia and R-bridge parity remain unestablished': both-fit cells with an SD formula (direct R vs Julia, not the bridge)", "info", [r for r in rows if r["class"] == "both-fit" and r["pat"] != "none"]),
]
cl_rows = []
for cid, src, text, mode, cs_ in claims:
    n = len(cs_)
    if mode == "R":
        ok = [r for r in cs_ if r["r_outcome"] == "FITS"]; bad = [r for r in cs_ if r["r_outcome"] != "FITS"]
        verdict = "CONSISTENT" if not bad else ("CONTRADICTED (%d/%d cells do not fit in R)" % (len(bad), n))
    elif mode == "Rnot":
        ok = [r for r in cs_ if r["r_outcome"] != "FITS"]; bad = [r for r in cs_ if r["r_outcome"] == "FITS"]
        verdict = "CONSISTENT" if not bad else ("CONTRADICTED (%d/%d cells fit in R although the matrix says they are not admitted)" % (len(bad), n))
    else:
        ok = cs_; bad = []; verdict = "INFO (%d cells)" % n
    cl_rows.append((cid, src, text, n, len(ok), len(bad), verdict, ";".join(r["cell_id"] for r in bad[:12])))
with open(os.path.join(outdir, "matrix_crosscheck.tsv"), "w") as f:
    f.write("claim\tsource\ttext\tcells\tcells_matching\tcells_contradicting\tverdict\texample_contradicting_cells\n")
    for r in cl_rows: f.write("\t".join(map(str, r)) + "\n")

# Julia-side matrix statements: families where Julia fits SD-regression cells that the matrix lists as unestablished
jf = collections.Counter((r["family"], r["kind"]) for r in rows if r["j_outcome"] == "FITS" and r["pat"] != "none")
with open(os.path.join(outdir, "julia_sd_fit_counts.tsv"), "w") as f:
    f.write("family\tkind\tjulia_fits_with_sd_formula\tr_fits_with_sd_formula\n")
    rf = collections.Counter((r["family"], r["kind"]) for r in rows if r["r_outcome"] == "FITS" and r["pat"] != "none")
    for k in sorted(set(jf) | set(rf)): f.write("%s\t%s\t%d\t%d\n" % (k[0], k[1], jf[k], rf[k]))

summ_out = {k: (dict(v) if isinstance(v, collections.Counter) else v) for k, v in summ.items()}
summ_out["j_sub"] = {"%s/%s" % k: v for k, v in summ["j_sub"].items()}
summ_out["r_sub"] = {"%s/%s" % k: v for k, v in summ["r_sub"].items()}
summ_out["n_both_fit"] = len(bf); summ_out["n_ll_disagree"] = len(dis)
summ_out["ll_diffs_sorted"] = sorted(float(r["ll_diff"]) for r in bf)[-10:]
summ_out["crash_groups"] = ["%s | %s | %s | %s | n=%d" % (*k, len(v)) for k, v in sorted(cs.items(), key=lambda kv: -len(kv[1]))]
json.dump(summ_out, open(os.path.join(outdir, "summary.json"), "w"), indent=1, default=str)
print(json.dumps({k: summ_out[k] for k in ("n_cells", "class_counts", "r_outcomes", "j_outcomes", "crash_sides", "julia_behind", "r_behind", "n_both_fit", "n_ll_disagree")}, indent=1))
