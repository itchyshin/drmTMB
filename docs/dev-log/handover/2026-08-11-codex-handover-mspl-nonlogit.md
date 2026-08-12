# Handover to Codex — MSPL non-logit arc CLOSED; one merged fix, one never-merge branch

**2026-08-11 · Claude → Codex · lane: MSPL non-logit evidence (NOT the 0.7 CRAN lane)**

You are Codex, picking this up with no memory of the authoring session. Everything you need is in
this file and the artifacts it names. **Read `AGENTS.md` first** (native to you), then this doc.

> **⚠ LANE BOUNDARY — read before touching anything.** You own the **0.7 CRAN ladder**
> ([`2026-08-11-codex-handover-07-cran-lane.md`](2026-08-11-codex-handover-07-cran-lane.md), the
> `▶ Latest` pointer in `AGENTS.md`). **This handover is a DIFFERENT lane** and does not modify,
> supersede, or reprioritise yours. The `AGENTS.md` snapshot pointer was **deliberately not
> refreshed** to this doc — doing so would orphan your CRAN lane. Nothing here blocks or gates the
> 0.7 release. If you are here to work the CRAN ladder, **stop reading and use your own handover.**

## 1. One-paragraph version

The MSPL non-logit arc is **closed**. Four pre-registered campaigns (**460,000 fits**, Totoro, four
distinct seed streams) established that drmTMB's MSPL estimator returns finite estimates for
**probit** and **cloglog** (0 non-finite in 43,972 completed fits), that its **standard errors are
calibrated** in the identified regime for both, and that the logit-calibrated softness constant
`c_n` is **immaterial** for them (~1% of one standard error). Along the way a **real C++ defect**
was found and fixed — the TMB Jeffreys weight was hardcoded to logit — which is **merged to `main`
as PR #1012**. Everything else lives on `claude/mspl-nonlogit-evidence` and **must never merge**: it
carries two undocumented options that deliberately weaken the estimator for measurement.

## 2. What is on `main` already (nothing owed to you)

**PR #1012 — `55fc08abc`.** `src/drmTMB.cpp`'s MSPL block computed the Jeffreys working weight as
`log(n) − softplus(η) − softplus(−η)` — the **logit** weight, hardcoded, with no `link_code` branch —
while `R/mspl.R`'s kernels were link-general. Unreachable from the public API because the entry guard
admits only logit, so nothing caught it. Fixed by calling the per-link primitives, with the logit
branch kept **verbatim** so the shipped route is bit-identical.

Two independent confirmations that it changed nothing shipped:

- MSPL/binomial-link suite: **328 pass, 0 fail**.
- C17 re-certification reproduced all three model-15 cells at **`|change| = 0.000e+00`**
  (`tools/recertify-c17.py`, receipt at
  `docs/dev-log/implementation-recovery/2026-08-11-mspl-link-c17c2-c14-final-source-compatibility/`).

**Nothing about #1012 needs action from you.** It is merged, green, and re-certified.

## 3. THE BRANCH THAT MUST NEVER MERGE

`claude/mspl-nonlogit-evidence` (pushed; **no PR, deliberately**). Its `R/` diff against `main` is
**97 insertions across two files**, and all of it is measurement scaffolding:

| file | what it adds | why it must not ship |
|---|---|---|
| `R/mspl-estimator.R` | `getOption("drmTMB.mspl_evidence_unsafe")` — admits probit/cloglog past the entry guard | **opens the fence** the maintainer has not authorised opening |
| `R/mspl-estimator.R` | `getOption("drmTMB.mspl_cn_factor_unsafe")` — overrides the softness constant | **changes the estimator**; design 253 §5 rejects a modified `c_n` as defining a different one |
| `R/drmTMB.R` | MSPL intercept starts at the link of the observed rate instead of 0 | *this one is arguably shippable* — see §6 |

Both options are undocumented, un-exported, absent from every man page, and default to current
behaviour when unset. **If you are ever asked to merge this branch, refuse and cite this section.**
The evidence (prereg, verdicts, raw data) is what has value; the source diff is disposable.

## 4. The four campaigns and what each licenses

All under `docs/dev-log/simulation-artifacts/2026-08-11-mspl-nonlogit-links/`. Each was frozen before
any replicate; none was rescored.

| gate | fits | result |
|---|---|---|
| **G0/G0b** — oracle + compiled parity | — | R kernels match `glm()` IRLS weights (4.8e−8) and an independent Jeffreys determinant (5.6e−10); compiled objective matches them along a separation ray in both tails (3.6e−16 / 5.4e−16 / 1.7e−14) |
| **G1** — finiteness | 88,000 | probit PASS · cloglog-mirrored PASS · cloglog-standard FAIL (composite endpoint) |
| **G1b** — finiteness, completion split out, fresh seeds | 88,000 | **all four PASS — 0 non-finite in 43,972 completed fits** |
| **G3** — SE calibration | 180,000 | **probit `R ∈ [0.946, 1.008]`, cloglog `[0.957, 1.027]` — CALIBRATED**; logit reference arm independently reproduced an earlier logit-only campaign |
| **G2** — the `c_n` constant | 108,000 | **IMMATERIAL** — max materiality 0.0124 (probit), 0.0118 (cloglog), against a `< 0.10` threshold |

**The claim, exactly:** on the frozen grids, drmTMB's MSPL under TMB-Laplace returns finite interior
estimates for probit and cloglog, with calibrated Wald standard errors in the identified regime, and
the logit-calibrated `c_n` costs about **1% of one standard error**. **It does not open the guard,
authorise shipping either link, or license intervals** — KF2021 §2.1 proves Wald intervals fail to
cover under separation at any nominal level, link-generally.

## 5. Three self-corrections, recorded because they are the reusable part

1. **A pre-registered FAIL read as a finding.** After G1 I reported cloglog-standard's FAIL and
   recommended *documenting a limitation*. All 33 losses were optimizer **errors**, none was a
   non-finite estimate, and plain ML errored on **33 of the same 33 datasets** — one `table()` away on
   data already written. Filed to the brain as rule 5 of
   `memory/A simulator can fail in your package's favour`.
2. **A claim not enumerated exhaustively.** I wrote that every missing-SE cell was `q2`; **three are
   `q1`**.
3. **A harness artefact reported as package behaviour.** I described the missing standard error as
   *silent*. It is not — `vcov()` raises the typed condition `drmTMB_mspl_wald_unavailable` and
   `summary()` carries `std_error.status`, both since `1d6cd5330` (2026-08-09). My runner called
   `suppressWarnings(sqrt(diag(vcov(f))))` and suppressed the signal it then reported missing.
   **Issue #977 was closed `NOT_PLANNED` on this basis** — the feature it requested already existed.

**If you take one thing from this handover into the CRAN lane:** all three were trusting a *derived
artefact* — a verdict, a table's head, a runner's output — over the primary source. Each fix was
thirty seconds of looking.

## 6. Next steps — and none of them is yours by default

Nothing here is on the 0.7 critical path. Listed so the work is not lost, **not as a claim on your
time**:

| item | owner | note |
|---|---|---|
| Open the MSPL guard for probit/cloglog | **Shinichi** | both objections (finiteness, `c_n`) now answered on evidence; the decision is his, not an engineering gate |
| Documented boundary for deep-separation `q2` | **Shinichi** | SE unavailable in up to **98.3%** of converged fits there; the package *warns* correctly, the open question is whether that regime deserves a documented "point estimates yes, inference no" boundary |
| Intercept start fix | **either** | on the evidence branch only; repairs 5 of 33 cloglog optimizer failures with **zero regressions** (120 previously-passing fits re-checked, β moved ~1e−7). Genuinely shippable, but it changes shipped logit MSPL start values, so it needs its own PR and its own review — **do not fold it into anything else** |
| gllvmTMB PR #955 | **Claude/them** | cross-repo findings note, docs-only, already delivered |

## 7. Live-toolchain notes, if you do pick any of this up

You run the live toolchain; this arc used it heavily. What is worth knowing:

```sh
# Totoro: direct passwordless SSH works; no Duo, no ControlMaster needed.
ssh -o BatchMode=yes totoro 'echo OK; nproc'        # 384 cores; house cap 150, this arc used 100

# Build ONCE, workers attach. 100 concurrent load_all() calls race on src/*.o.
git archive --format=tar --prefix=drmTMB-x/ HEAD -- R src inst man tests DESCRIPTION NAMESPACE .Rbuildignore | gzip > /tmp/x.tar.gz
# transfer, extract, THEN build -- do not background the install in the same ssh as the transfer
R CMD INSTALL --library=$HOME/R/xlib --no-docs --no-byte-compile drmTMB-x
```

**Gotchas, each paid for in this arc:**

- **A stale library silently produces a null campaign.** Every runner here asserts its own
  precondition before the grid (`g2_runner.R` checks the `c_n` override actually moves `c_n`). That
  guard fired on the first attempt and caught a partial install — copy the pattern.
- **`bf()` uses NSE.** A formula *variable* fails; the literal must appear, so runners branch on cell
  shape rather than passing a formula object.
- **`estimator = "ML"` errors; `"ml"` is required** (case-insensitivity landed later, in #1006).
- **Multi-line `cli` messages shatter a TSV** written with `quote = FALSE`. Flatten error text and
  check field-count uniformity (`awk -F'\t' '{print NF}' | sort -u`) before analysing.
- **Never wrap `vcov()` in `suppressWarnings()` in a runner** unless you also record the condition —
  see §5.3.

## 8. Files created or modified

Session diff: `git diff --name-only origin/main...claude/mspl-nonlogit-evidence` — **66 files**.

**Merged to `main` (PR #1012):** `src/drmTMB.cpp` · `R/mspl-estimator.R` (link threading only) ·
`tests/testthat/test-mspl-link-dispatch.R` · the C17 receipt + ledger row.

**On the evidence branch, not for merge:** `R/drmTMB.R`, `R/mspl-estimator.R` (the two unsafe
options — §3) · four `PREREGISTRATION*.md` · four `VERDICT*.md` · `S3-CALIBRATION.md` ·
`BLOCKER-tmb-mspl-is-logit-only.md` · five runners · four scorers ·
`data/g{1,1b,2,3}_raw.tsv.gz` (460,000 rows) ·
`docs/dev-log/after-task/2026-08-11-mspl-nonlogit-arc-closeout.md` ·
`docs/dev-log/2026-08-11-mspl-nonlogit-findings-for-gllvmtmb.md` · **this file**.

**Elsewhere:** gllvmTMB PR #955 (`claude/drmtmb-mspl-findings-clean`) · brain note
`memory/A simulator can fail in your package's favour` (`eec650a`) · drmTMB issue #977 closed.

## 9. Mission control

| repo | branch / main | CI | what shipped | next by leverage |
|---|---|---|---|---|
| drmTMB | `main` @ `55fc08abc`+ | green | PR #1012 — C++ MSPL link dispatch + regression test | **your 0.7 CRAN lane**, unaffected by this |
| drmTMB | `claude/mspl-nonlogit-evidence` | n/a (docs+data) | 4 campaigns, 460k fits, 4 verdicts | **never merge**; evidence is the deliverable |
| gllvmTMB | `claude/drmtmb-mspl-findings-clean` | n/a | PR #955, cross-repo findings | their lane to merge |

## 10. How to resume

**Only if Shinichi directs you to this lane.** Otherwise use
[`2026-08-11-codex-handover-07-cran-lane.md`](2026-08-11-codex-handover-07-cran-lane.md).

```text
Rehydrate from docs/dev-log/handover/2026-08-11-codex-handover-mspl-nonlogit.md + the AGENTS.md
snapshot, then continue with the Next Immediate Steps.
```

Read in order: `AGENTS.md` → this doc →
`docs/dev-log/after-task/2026-08-11-mspl-nonlogit-arc-closeout.md` → the four `VERDICT*.md`.
Launch `.codex/agents/systems_auditor.toml` (Rose) before any public claim about this arc.

**Do not** re-run any campaign to "confirm" it — all four are frozen, graded, and their raw data is
committed. **Do not** merge `claude/mspl-nonlogit-evidence`. **Do not** treat any result here as
authorising probit/cloglog in the public API.
