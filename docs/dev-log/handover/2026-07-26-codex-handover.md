# Session Handoff: the `sd()` / scale-and-intervals lane → Codex

**Meta:** 2026-07-26 · from **Claude** → **Codex** · cross-tool, so this doc stands alone.
You will not see the authoring chat.

> ## ⚠ TWO LANES. THIS IS **NOT** THE ASSOCIATION LANE.
>
> `drmTMB` currently runs **two independent lanes**. Shinichi split them explicitly on
> 2026-07-26 because they kept bleeding into each other.
>
> | Lane | Subject | Owner | Live artifacts |
> | --- | --- | --- | --- |
> | **A — ASSOCIATION** | bivariate `y1`/`y2` dependence, Arc 6, staged-eta, the private latent-normal **sandwich** engine | **Codex (the existing lane)** | merged #846, #844 |
> | **B — `sd()` SCALE & INTERVALS** *(this doc)* | `sd(group) ~ x` regressions, scale clamps, profile endpoints, random-effect **coverage** | **Codex (this NEW independent lane)** | merged #842/#843/#845/#848/#849; open #851 |
>
> **Do not merge these lanes.** Do not touch Arc 6 / association / the sandwich engine from
> here, and do not expose #846's engine through `vcov()`, `confint()`, profiles, or docs.
> Conversely, the association lane must not touch `sd()` clamps or Arc D.
>
> Recorded as brain decision **`D-87`**: the "one platform at a time per repo" rule was
> violated overnight 2026-07-25/26 — both tools worked this repo concurrently and
> independently wrote an Arc D plan within an hour. The rule was already written down and
> was violated anyway. **At orient, check `gh pr list` and recent `origin/main` commits for
> the other lane's activity.** Nothing warns you automatically.

---

## Mission (the durable why)

`drmTMB` is univariate and bivariate distributional regression on TMB — you model *how
variable* a response is, not just its mean. **`0.7.0` is the first CRAN submission; `0.6` is
the dev cycle and is never submitted** (Shinichi 2026-07-25, brain `D-86`, mirroring
gllvmTMB's `D-66`). That runway is what licensed sequencing **defects before capability**.

This lane's subject: the **`sd(group) ~ x` regression** — a modelled random-effect scale —
and whether the intervals we report for it mean anything.

---

## What was accomplished (all merged to `main`)

| PR | What |
| --- | --- |
| **#842** Arc B | C++/numerical audit: five standing conformance suites, **eight findings reported, none repaired** (an audit observes) |
| **#843** Arc A1 | `simulate.drmTMB()` reused the fitted MAP `û` every replicate, so `confint(method="bootstrap")` was **anticonservative for every RE model**. Gains `re.form`; `NULL` (marginal) is the new default |
| **#845** Arc C | Repaired **A5** (beta `mi()` clamp ordering) and **A7** (19 rotted citations made rot-proof); **REVERTED F5** |
| **#848** | Coverage evidence for A1 — see below, it is the headline |
| **#849** Arc A2 | `phylo_interaction` gains marginal `re.form` support at `q = 1` |

### The headline number

A 72,000-row Totoro campaign measured what A1 actually bought, for the **random-effect SD**
at nominal **0.95**:

| | coverage |
| --- | --- |
| conditional (the pre-A1 behaviour) | **0.5092** |
| marginal (the current default) | **0.8714** |

By `n_groups` 10 / 25 / 50 → marginal 0.810 / 0.889 / 0.915. Residual `sigma` is unmoved
(0.9319 vs 0.9320) and the fixed effect moves 0.008 — so the defect was confined to the
between-group variance component exactly as diagnosed.

**A1 was necessary and large. A1 is NOT sufficient.** `confint(method = "bootstrap")` must
**not** be described as inference-ready for random-effect SDs. No ledger cell is promoted by
this; it is coverage evidence pointing *down*. Nothing is retracted — `bootstrap_R = 0`
across all 151 evidence artifacts.
Full record: `docs/design/246-marginal-bootstrap-coverage.md`.

---

## Current working state

**Working / merged:** everything in the table above. `main` at `af664798` or later.

**BLOCKED — and this is the important one.** **Arc D cannot proceed without a written
decision from Shinichi.** PR **#851** (`docs/design/247-arc-d-clamp-profile-contract-d1.md`)
delivers D0 (inventory) and D1 (three costed designs) and **stops**. Both Arc D plans — this
one and Codex's #847 — fence implementation until a contract is chosen.

**Open PRs:** #851 (ready, this lane) · #847 (draft, the *other* lane's Arc D plan, kept for
its fences) · #836 (draft, an old handover awaiting Shinichi's disposition).

---

## The Arc D question, stated so you can act on it

`sd(group) ~ x` predicts a log-SD, which is exponentiated. **Nine C++ sites do that with no
bound**, while the residual `log_sigma` **is** soft-clamped by default. Arc C applied the
same clamp there and **reverted it**, because:

| `logsigma_clamp` | profile for `sd(study):z_study`, dense K=12 meta-V cell |
| --- | --- |
| `c(-12, 12)` (clamp active) | **finite** `[-4.1428, 27.7859]`, `conf.status = profile` |
| `c(-200, 200)` (clamp off) | **`profile_failed`**, `NA` |

The clamp converted a genuinely **non-identified** parameter into a finite, vacuous interval
whose endpoint *was the bound*. That is worse than the `[0, Inf]` it replaced, because it
passes any check asking only "is the interval finite?".

**The measurement that removed the expensive risk.** `mc-0017` is the **only** ledger cell
with certified interval evidence on a `sd(...) ~ x` path
(`inference_ready_with_caveats`, brain `D-62`, certified on **profile** coverage of
`sd_phylo(spp_id) ~ x_tau`). Measured on an `mc-0017`-shaped fit: worst `|log-SD|` across
its whole profile box is **2.629**, leaving **9.371** of margin to the `c(-12,12)` band. The
soft clamp is **exactly** identity inside the band — so **no design can move `mc-0017`'s
endpoints, and no certified cell is at risk.** Script retained at
`docs/dev-log/simulation-artifacts/2026-07-26-arc-d-mc0017-clamp-margin/`.

**The principle that falls out:** a clamp on the `sd()` path is **identity where the
parameter is identified and binds only where it is not**. It is effectively a
*non-identification detector*. So the real question is not "should we bound the exponential"
but **"may a clamped endpoint be reported as a real one?"** — a statement about what our
intervals mean, which is why it is Shinichi's call.

### Three D0 facts any implementation must respect

1. **A TENTH surface, outside the nine C++ sites.** `R/drmTMB.R:20181`
   `sd_mu_group_values()` and `:20193` `sd_phylo_group_values()` **independently re-derive
   `exp(eta)` in R** from `par$beta_sd_mu` — *not* from `obj$report()` — feeding
   `mu_sd_by_random_effect()`, `biv_phylo_node_sd_values()`, and simulate/ranef. **A
   C++-only clamp would not cover them and would silently make C++ and R disagree.**
2. **`model_type` 6 (poisson) and 7 (nbinom2) never REPORT `sd_mu_group`**
   (`src/drmTMB.cpp:3271-3415`, `:3478-3682`), so a REPORT-reading detector is blind to them.
3. **The profiled quantity is `beta_sd_mu` — the coefficient, pre-`exp()`** — with
   `transformation = "linear_predictor"`, for which `profile_interval_diagnostics()`
   (`R/profile.R:3407-3430`) has **no boundary check at all**. An endpoint check would live
   at `R/profile.R:2825-2900`.

The nine sites: `src/drmTMB.cpp` `:831 :921 :2279 :2826 :3282 :3490 :4017 :4119 :4514`.

---

## Next immediate steps

**1. Do NOT implement Arc D.** Read `docs/design/247-...` and #851; if Shinichi has since
chosen a contract, implement that and nothing more. Otherwise leave it fenced.

**2. The genuinely unblocked, high-value work — diagnose the 0.871 shortfall.** This is
live-toolchain and compute work, which is your strength, and it is **not** blocked on Arc D.
Why does the marginal bootstrap reach only 0.871 rather than ~0.95? Three **separable**
candidates:
   - percentile intervals are poor for a boundary-adjacent variance parameter;
   - `R = 199` is small for a tail quantile;
   - the Laplace refit is itself biased at low group counts.
   Separate them. A first cut: re-run the existing harness at `R = 999` on a subset of cells
   — if coverage moves materially, candidate 2 dominates. Only percentile intervals are
   implemented; BCa or bootstrap-t would be a real contribution.

**3. Consider whether the shortfall extends to structured REs** now that `phylo_interaction`
has marginal support (#849).

**4. Ledger discipline.** Nothing here promotes a cell. The asymmetric tier fence stands:
correctness evidence may **never** promote, but **can** compel a demotion.

---

## The Totoro harness (ready to reuse)

The overnight campaign ran on **Totoro** (`snakagaw@totoro.biology.ualberta.ca`, 384 cores,
~1 TB). **No Duo is needed — key auth works directly**; an absent `~/.ssh/cm-*` socket does
*not* mean unreachable (I wrongly claimed it did). Shinichi authorised **up to 200 cores**.

```bash
ssh totoro                     # verify: nproc -> 384
cd ~/drm_work
Rscript a1_analyse.R           # re-print the campaign summary
# full re-run (~35 min at 200-way):
cat joblist.txt | xargs -P 200 -n 3 ~/drm_work/run_shard.sh
```

- Installed library: `~/drm_work/lib` (drmTMB built from `main`; **reinstall after your
  changes**). R 4.5.3, TMB 1.9.21, Matrix, lme4, numDeriv, statmod present;
  **`glmmTMB` and `metafor` are NOT installed** (comparators only — the frontier work does
  not need them).
- Always `export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1` before parallel runs.
- Committed copies of the scripts:
  `docs/dev-log/simulation-artifacts/2026-07-25-a1-marginal-bootstrap-coverage/`.
- **Raw per-replicate output is deliberately NOT in the repo** (`D-50`: campaign outputs stay
  local, never in Actions artifacts). Seeds are deterministic, so raw reproduces from the script.
- **Never run simulation/coverage/recovery on GitHub Actions.**

---

## Live-toolchain env (you run the real checks)

```bash
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
export NOT_CRAN=true            # WITH this, many suites run; WITHOUT it they skip_on_cran
export OPENBLAS_NUM_THREADS=1
# focused: Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/<f>.R")'
# full   : R CMD build --no-build-vignettes --no-manual . && \
#          _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-manual --ignore-vignettes drmTMB_0.6.0.tar.gz
```

Team mirror: `.codex/agents/*.toml` — **Rose's audit is mandatory** before any completion
claim, and the D-43 gate is 3 fresh agents under distinct lenses, default **NOT-DONE**,
with ≥2 NOT-DONE withholding the claim. It earned its keep this session: three separate
reviewers returned NOT-DONE and every one was right.

---

## Files created / modified by this lane

Merged to `main`: `src/drmTMB.cpp` (A5) · `R/methods.R`, `R/profile.R` (A1, A2) ·
`R/family-dpq.R` (A7) · `AGENTS.md`, `NEWS.md`, `README.md`, `ROADMAP.md` ·
`docs/design/243`, `245`, `246` · `docs/dev-log/after-task/2026-07-25-arc-c-...md` ·
`docs/dev-log/simulation-artifacts/2026-07-25-a1-marginal-bootstrap-coverage/` ·
`docs/dev-log/handover/2026-07-26-claude-handover.md` · several `tests/testthat/test-*.R`.

On open PR #851: `docs/design/247-arc-d-clamp-profile-contract-d1.md` ·
`docs/dev-log/simulation-artifacts/2026-07-26-arc-d-mc0017-clamp-margin/`.

This handover: this file + the `AGENTS.md` snapshot edit.

---

## Gotchas — paid for, do not re-learn

1. **Run BOTH gates, on the commit you are gating.** CI and the local suite disagreed in
   *opposite* directions on consecutive arcs. `test-estimator-surface-conformance.R` resolves
   `R/profile.R` from a source checkout, so it **does not evaluate under `R CMD check`** —
   CI passed green while a real defect was live.
2. **A gate result must name the commit it was measured on.** Violated three times here,
   once inside the document listing it as a lesson.
3. **A regression test is worthless until you have seen it FAIL on pre-repair source.** Three
   were written; two passed pre-repair. Tests that *fit a model* let the optimizer pick tame
   coefficients and never reach the defect — drive the compiled kernel at hand-set parameters.
4. **Never re-pin a negative control to make a suite green.** Classify first: stale
   assertion, real defect caught, or broken infrastructure. Here it was the second.
5. **Line-number anchors rot** — three times in one session. A7 converted them to
   `model_type == N` labels, which cannot.
6. **"Ahead of `main`" ≠ unmerged** (squash merges leave branches ahead forever); and
   local-only branches exist despite handovers claiming otherwise. Verify with `git ls-remote`.
7. **The root checkout is parked on a stale branch with ~65 untracked foreign files.** Work
   from a fresh worktree; stage explicit paths; never `git add -A`.
8. **Do not retry F5 by "reusing `drm_softclamp_log_sigma()` at the nine sites."** Falsified
   by the K=12 negative control.

---

## How to resume

Start Codex in the repo (it reads `AGENTS.md` natively) and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-26-codex-handover.md + the AGENTS.md snapshot,
then continue with the Next Immediate Steps. You are the sd()/scale/intervals lane, NOT the
Arc 6 association lane. Do not implement Arc D until Shinichi has chosen a contract in
writing; the unblocked work is diagnosing the 0.871 marginal-bootstrap coverage shortfall.
```

## Mission control

| Lane / item | Branch / PR | State | Next leverage step |
| --- | --- | --- | --- |
| **This lane — `sd()` / intervals** | `main` @ `af664798`+ | A1/ArcB/ArcC/A2/coverage all merged | diagnose the 0.871 shortfall |
| Arc D contract | **#851** open | D0+D1 done, **plan-only** | **await Shinichi's written design choice** |
| Arc D plan (other lane) | #847 draft | superseded in substance; fences retained | close or fold in |
| **Association (Lane A)** | merged #846, #844 | **CODEX — not this lane** | hold public inference |
| Interval-grade campaign | not started | 177 `point_fit_recovery` cells, ~80% frontier | **blocked on Arc D** |
| Old handover | #836 draft | awaiting disposition | Shinichi's call |
