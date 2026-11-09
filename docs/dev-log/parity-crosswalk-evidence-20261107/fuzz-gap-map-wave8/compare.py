#!/usr/bin/env python3
"""Compare gap maps. Usage: compare.py <orig_gap_map.tsv> <old_gap_map.tsv> <w8_gap_map.tsv> <outdir>
orig = the 2026-11-08 map at 759e58e4f (informational); old = rerun at fd5d6c0dc; w8 = rerun at 479bbf963."""
import sys, csv, collections, os
orig_f, old_f, w8_f, out = sys.argv[1:5]
os.makedirs(out, exist_ok=True)
def load(f):
    return {r["cell_id"]: r for r in csv.DictReader(open(f), delimiter="\t")}
O, OLD, W = load(orig_f), load(old_f), load(w8_f)
ids = list(W)
CLS = ["both-fit-agree", "both-fit-disagree", "R-only", "Julia-only", "both-refuse", "crash-Julia", "crash-R", "nonconverged", "inconclusive", "other"]
def cls(r):
    c = r["class"]
    if c == "both-fit": return "both-fit-agree" if r["ll_flag"] == "ok" else "both-fit-disagree"
    return c
def table(M):
    c = collections.Counter(cls(M[i]) for i in ids if i in M)
    return c
def jout(r): return r["j_outcome"]
res = {}
for name, M in (("orig(759e58e4f)", O), ("old(fd5d6c0dc)", OLD), ("wave8(479bbf963)", W)):
    res[name] = table(M)
with open(os.path.join(out, "outcome_table.tsv"), "w") as f:
    f.write("class\t" + "\t".join(res) + "\n")
    for c in CLS: f.write(c + "\t" + "\t".join(str(res[n].get(c, 0)) for n in res) + "\n")
    f.write("total\t" + "\t".join(str(sum(res[n].values())) for n in res) + "\n")
    f.write("R fits\t" + "\t".join(str(sum(1 for i in ids if i in M and M[i]["r_outcome"] == "FITS")) for M in (O, OLD, W)) + "\n")
    f.write("Julia fits\t" + "\t".join(str(sum(1 for i in ids if i in M and M[i]["j_outcome"] == "FITS")) for M in (O, OLD, W)) + "\n")
# Julia outcome by sub-mode
with open(os.path.join(out, "julia_modes.tsv"), "w") as f:
    keys = sorted(set((M[i]["j_outcome"], M[i]["j_sub"], M[i]["j_sub"]) for M in (OLD, W) for i in ids if i in M))
    f.write("j_outcome\tj_sub\tj_etype\told\twave8\n")
    for k in keys:
        a = sum(1 for i in ids if i in OLD and (OLD[i]["j_outcome"], OLD[i]["j_sub"], OLD[i]["j_sub"]) == k)
        b = sum(1 for i in ids if (W[i]["j_outcome"], W[i]["j_sub"], W[i]["j_sub"]) == k)
        f.write("%s\t%s\t%s\t%d\t%d\n" % (k + (a, b)))
def row(i, base):
    o, w = base[i], W[i]
    return dict(cell_id=i, old_class=cls(o), w8_class=cls(w), old_j=o["j_outcome"], old_j_sub=o["j_sub"], old_etype=o["j_sub"], w8_j=w["j_outcome"], w8_j_sub=w["j_sub"], w8_etype=w["j_sub"],
                r_outcome=w["r_outcome"], r_ll=w["r_ll"], old_j_ll=o["j_ll"], w8_j_ll=w["j_ll"], old_ll_diff=o["ll_diff"], w8_ll_diff=w["ll_diff"],
                old_sig=o["j_sig"], w8_sig=w["j_sig"], w8_msg=w["j_msg"], w8_extra=w["j_extra"], w8_quality=w["quality_flag"])
COLS = list(row(ids[0], OLD).keys())
def wr(name, rows):
    with open(os.path.join(out, name), "w") as f:
        f.write("\t".join(COLS) + "\n")
        for r in rows: f.write("\t".join(str(r[c]).replace("\t", " ") for c in COLS) + "\n")
# pre-registered flip / worse rules
flipped, worse, newcrash, newagree = [], [], [], []
for i in ids:
    o, w = OLD[i], W[i]
    if o["r_outcome"] == "FITS" and o["j_outcome"] != "FITS" and w["j_outcome"] == "FITS": flipped.append(row(i, OLD))
    if o["j_outcome"] == "FITS" and w["j_outcome"] != "FITS": worse.append(dict(row(i, OLD), why="Julia FITS -> not FITS"))
    elif cls(o) == "both-fit-agree" and cls(w) == "both-fit-disagree": worse.append(dict(row(i, OLD), why="agree -> disagree"))
    elif o["j_outcome"] == "REFUSES" and w["j_outcome"] == "ERRORS": worse.append(dict(row(i, OLD), why="refuse -> crash"))
    elif w["j_outcome"] == "ERRORS" and (o["j_outcome"] != "ERRORS" or o["j_sub"] != w["j_sub"]): worse.append(dict(row(i, OLD), why="new crash type"))
    if w["j_outcome"] == "ERRORS": newcrash.append(row(i, OLD))
    if cls(w) in ("both-fit-agree", "both-fit-disagree") and cls(o) not in ("both-fit-agree", "both-fit-disagree"): newagree.append(row(i, OLD))
COLS2 = COLS + ["why"]
def wr2(name, rows):
    with open(os.path.join(out, name), "w") as f:
        f.write("\t".join(COLS2) + "\n")
        for r in rows: f.write("\t".join(str(r.get(c, "")).replace("\t", " ") for c in COLS2) + "\n")
wr2("flipped_to_fit.tsv", flipped); wr2("got_worse.tsv", worse); wr2("remaining_crashes_wave8.tsv", newcrash); wr2("newly_both_fit.tsv", newagree)
# flip transition matrix
tm = collections.Counter((cls(OLD[i]), cls(W[i])) for i in ids)
with open(os.path.join(out, "transitions.tsv"), "w") as f:
    f.write("old_class\twave8_class\tcells\n")
    for (a, b), n in sorted(tm.items(), key=lambda kv: -kv[1]): f.write("%s\t%s\t%d\n" % (a, b, n))
# also vs the ORIGINAL map (different Julia commit, informational)
tm0 = collections.Counter((cls(O[i]), cls(W[i])) for i in ids if i in O)
with open(os.path.join(out, "transitions_vs_original.tsv"), "w") as f:
    f.write("original_class\twave8_class\tcells\n")
    for (a, b), n in sorted(tm0.items(), key=lambda kv: -kv[1]): f.write("%s\t%s\t%d\n" % (a, b, n))
# R reference stability
rdiff = [i for i in ids if i in O and (O[i]["r_outcome"] != W[i]["r_outcome"] or (O[i]["r_ll"] and W[i]["r_ll"] and abs(float(O[i]["r_ll"]) - float(W[i]["r_ll"])) > 1e-8))]
with open(os.path.join(out, "r_reference_stability.txt"), "w") as f:
    f.write("cells where R rerun differs from the original R run (outcome or logLik > 1e-8): %d\n" % len(rdiff))
    for i in rdiff[:50]: f.write(i + "\n")
print("flipped", len(flipped), "worse", len(worse), "crash", len(newcrash), "newly both-fit", len(newagree), "R unstable", len(rdiff))
