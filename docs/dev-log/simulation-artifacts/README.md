# Simulation artifacts — what a campaign leaves behind

Campaigns run on **Totoro or DRAC**, never GitHub Actions, and their outputs stay **local and in this
dev-log** (D-50). This note records what a campaign directory should contain and why.

## Keep the raw replicate-level data in the repo

**Decision, Shinichi, 2026-08-10.** A campaign commits its **raw per-replicate table**, not only the
summaries it was scored on.

The reason is a case in this repo. The 2026-08-09 SE-calibration campaign kept summaries only
(`R_summary.tsv`, 24 KB for 60,000 fits). Its first headline — *"zero anti-conservative failures;
deep separation is conservative, harmless"* — was **retracted**: the "conservative" reading was
estimator collapse, since at `η_d = −10` some 996 of 1000 replicates take essentially one value, so
`sd(β̂)` was measuring atom-hopping rather than sampling variability. That was **caught by going back
to the raw replicates**. A summary cannot show it — by construction, the statistic that hides the
collapse is the one being summarised.

So the raw table is not bulk, it is the part a reviewer needs in order to disagree with the author.

**Practically:**

- Commit the raw per-replicate TSV under `<campaign>/data/`, plus the per-cell scores.
- Size is acceptable at this scale: 20,000 fits × 21 fields ≈ 3.2 MB uncompressed.
- If a campaign's raw table would exceed roughly **50 MB**, compress it (`.tsv.gz` reads directly via
  `read.delim(gzfile(...))`) rather than dropping it. Raise it before dropping raw entirely.
- Never store campaign outputs as GitHub Actions artifacts (D-50: hard 2 GB/month cap).

## The rest of the directory

| file | purpose |
|---|---|
| `PREREGISTRATION.md` | grid, seeds, endpoints, decision rule, abort rules — **committed before any replicate** |
| `<name>_runner.R` | the exact runner; its hash goes in the provenance |
| `analyse.R` | the scorer. Every threshold **quoted from the prereg**, none chosen after seeing output |
| `data/*.tsv` | raw per-replicate table + per-cell scores |
| `VERDICT.md` | the graded result, including what it does **not** establish |

## Two rules that exist because they were paid for

**Absent or non-finite values are scored as FAILURES, never dropped.** The E1 probe's first scorer
filtered with `is.finite()` and removed precisely the values that constituted the evidence.

**A control failure voids the run.** If the comparator does not misbehave where the design says it
must, the harness is wrong and no result from that run may be interpreted — not explained away. E1
halted on exactly this and was right to.

## A format caveat worth knowing

TSV shatters if a field contains a tab or newline. R's multi-line `cli` messages written with
`write.table(quote = FALSE)` turned 20,000 F1 fits into **25,887 lines**, with message text appearing
in the `estimator` column. Flatten whitespace in any free-text field before writing, and check row
count *and* field-count uniformity before analysing — not after.
