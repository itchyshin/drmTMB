# After-task: fam-zi-poisson — zero-inflated Poisson through `engine = "julia"`

Date: 2026-09-05
Branch: `claude/parity-fam-zi-poisson` (drmTMB) · `claude/parity-fam-zi-poisson-drmjl` (DRM.jl, PR #661)
DRM.jl pin: `430ef64ccca5642c5abebd72194e00895314dfc2`
Ledger: `.unlazy/parity/gates/leaf-fam-zi-poisson.md`

## 1. What was asked, and why the brief was wrong

The leaf was dispatched to (a) add a `_bridge_family` case to DRM.jl for
`zi_poisson`, and (b) add a drmTMB registry row plus payload and coefficient-label
code for it. The brief's premise — "drmTMB fits zero-inflated Poisson natively
(family_type `zi_poisson`, 17 occurrences in `R/`)" — conflates two different
things, and the leaf tested it before writing any code.

**Measured, not assumed.** `drm_family_type()` (`R/drmTMB.R`) has 18
`return("...")` values; all were read, and **none of them is `"zi_poisson"`**:

```
gaussian, gamma, poisson, binomial, nbinom2, tweedie, truncated_nbinom2, beta,
zero_one_beta, beta_binomial, cumulative_logit, biv_lognormal, biv_student,
biv_gaussian, student, skew_normal, lognormal, biv_gaussian
```

A zero-inflated Poisson is spelled `family = poisson()` plus a `zi ~` formula
part. `"zi_poisson"` is drmTMB's **post-fit `model_type`** (`R/drmTMB.R:8305`,
`model_type = if (has_zi) "zi_poisson" else "poisson"`), set *after* the fit and
never sent to Julia. Measured live: the family tag the bridge actually forwards
for a ZIP is `"poisson"`.

DRM.jl spells it the same way: `zi` is already in its bridge dpar vocabulary
(`mu, sigma, nu, zi, hu, zoi, coi`, `src/bridge.jl`), and

```
drm_bridge(; formula = Dict("mu" => "y ~ x", "zi" => "zi ~ x"),
             family = "poisson", data = ...)
```

**fits at the pin** and returns coefficients equal to the native
`drm(bf(@formula(y ~ x), @formula(zi ~ x)), Poisson())` fit.

So the route is admitted **today**, by the `poisson` registry row plus the `zi`
dpar vocabulary, and it carries a banked receipt (`capability_id zi_poisson`,
`r_bridge_status = "partial"`). **No registry row was added and no
`_bridge_family` alias was added.** Both would have been wrong:

* A registry row keyed `zi_poisson` would admit a family tag drmTMB never emits
  — dead code.
* `_bridge_family("zi_poisson") -> Poisson()` would be a **silent trap**: a
  caller passing that tag without a `zi ~` formula part would receive a plain
  Poisson fit, with no error. A loud refusal is the correct behaviour.

## 2. What was genuinely missing

Design 168's four limbs of "covered" are implementation, focused tests, public
documentation, and diagnostic/interval evidence. For this capability three were
present and **the focused-test limb was absent on both sides**:

| Side | Before | Measured how |
|---|---|---|
| drmTMB | no test drove `zi ~` through `engine = "julia"` | of the `tests/testthat` files matching `engine = "julia"`, none also matched `zi ~` |
| DRM.jl | no test drove `zi`/`hu` through `drm_bridge` (only native `drm`, `test_zi.jl`) | `grep -rl drm_bridge test/ \| xargs grep -l '"zi"'` returned nothing |

Plus one factual defect: `R/julia-family-registry.R` listed `zi_poisson`,
`zi_nbinom2` and `hurdle_nbinom2` under "Julia bridge has NO case yet".

## 3. Receipts — measured in this run, on the merged bytes

Fixture: `bf(count ~ x, zi ~ z)`, `family = poisson(link = "log")`, `n = 600`,
seed 20260905 (the ZIP shape of `tests/testthat/test-zi-poisson.R`). Comparison
code taken verbatim from the pin's own tools — `tools/parity_numeric.R`
(`parity_numeric()`, tol `1e-4`) and `tools/parity_se.R` (`se_of()`, the
`agree()` rule at rtol `1e-3` / atol `1e-8`, and its negative control).

| Quantity | Value |
|---|---|
| coefficient parity | `PARITY_PASS`, max abs diff **`5.776934e-12`**, 4/4 matched by name |
| logLik | **`-786.1016601045`** on both engines, diff **`1.136868e-12`** |
| Wald SE | `SE_PASS`, **`1.317571e-08`** abs / **`2.373401e-07`** rel, 4 SEs |
| negative control | `NEGATIVE_CONTROL_OK` at rel **`9.090911e-02`** |
| estimator | `ML` on both |
| family tag sent to Julia | `"poisson"` |
| coefficient labels | `mu_(Intercept)`, `mu_x`, `zi_(Intercept)`, `zi_z` — identical on both engines |

Re-run after `git merge origin/main` (which moved `R/drmTMB.R`): **identical to
every digit**.

## 4. Changes

**DRM.jl (PR #661, opened first)**

* `test/test_bridge_zi.jl` (new, `45 pass / 45 total`): bridge-vs-native for ZIP
  and ZINB, compared by name per dpar block (coef `< 1e-8`, logLik `1e-8`), plus
  a plain-Poisson contrast proving the `zi` entry is not dropped in marshalling.
* `src/bridge.jl`: `_bridge_mixture_family_hint` — a `zi_*` / `zero_inflated_*`
  / `hurdle_*` tag on a **count** family now gets an actionable refusal naming
  `family = "poisson"` (or `"nbinom2"`) plus the `zi`/`hu` formula entry. Still
  an `ArgumentError`, still a refusal, **not an alias**.
* `test/runtests.jl` (one `_shard_include` line), `NEWS.md`.

**drmTMB (this PR)**

* `tests/testthat/test-julia-zi-poisson.R` (new, `[ FAIL 0 | WARN 0 | SKIP 0 |
  PASS 39 ]`, 1 live test ran).
* `R/julia-family-registry.R`: the false comment corrected. No `spec()` row added.
* `R/julia-bridge.R`: the `zi_poisson` row's `next_action` records the closed
  limb and this run's numbers. `r_bridge_status` **unchanged** at `partial`.
* `inst/extdata/julia-capabilities.tsv` + `docs/dev-log/dashboard/julia-capabilities.tsv`
  regenerated via `tools/write-julia-capability-comparison.R` (25 rows,
  byte-identical on two consecutive runs), never hand-edited.
* `NEWS.md`, this report.

## 5. Red controls

**DRM.jl.** `git show HEAD:src/bridge.jl > src/bridge.jl` (sha256
`3a1abd2504a745527197240ce9dc77bb36e18b1dbf4b26eed5d890e403856f63`), same test
re-run: **`38 passed, 7 failed`**, e.g. verbatim

```
Evaluated: occursin("`zi` entry", "ArgumentError: drm_bridge: unsupported family `zi_poisson`")
```

Restored from a scratchpad copy; sha256 back to
`ae541e8dbe4747b9ed1bbf4df18511287d96c67ac8c088466a0fbe6873f63253`.

**drmTMB.** Removed `"zi"` from `julia_bridge_supported_dpars()`
(`R/julia-bridge.R`), same test file re-run:
**`[ FAIL 4 | WARN 0 | SKIP 0 | PASS 11 ]`**, verbatim

```
Error in `drm_julia_formula_spec(...)`: `engine = "julia"` cannot marshal formula parameter: "zi".
```

— including the **live** test, which failed rather than skipping. Restored with
`git show HEAD:R/julia-bridge.R > R/julia-bridge.R`; sha256 before and after
both `aee6ca3a1fbea33533ae31024129e9f9bdc9edae4521777f028d93ccf3a409f3`, and
`git status --short` clean apart from the intended new file.

A third red control is built into the drmTMB test file itself: the tag
`"zi_poisson"` is asserted to be **refused** by `drm_julia_family_tag()`, so if a
future change made `drm_family_type()` emit it, the fence catches it rather than
forwarding a tag DRM.jl also refuses.

## 6. Other checks

* `tests/testthat/test-julia-family-registry.R` + gate/ledger consistency tests:
  `[ FAIL 0 | WARN 0 | SKIP 2 | PASS 294 ]` (both skips pre-existing and
  unrelated — PR #1184 unmerged; `DRM_JL_PATH` unset in that invocation).
* `python3 tools/capability_ledger.py --check` → `capability-ledger: OK (31 generated outputs)`.
* `Rscript tools/check-capability-runtime.R` → `capability-runtime: OK (18 routes; G0=0 G1=0 G2=0; verified=18)`.
* `python3 tools/validate-mission-control.py` → **19 errors on this branch, 19 on
  a freshly fetched clean `origin/main` probe: zero new errors**.
* ASCII scan of the added lines in `R/*.R` and `tests/testthat/*.R`: clean.
* `git merge origin/main` (10 commits, incl. PR #1200 / #1206) applied with no
  conflicts; all measurements above re-certified against the merged bytes.

## 7. NOT COVERED — stated plainly

* **This leaf added no fitting capability.** Both the R and Julia routes already
  worked. It closed a test limb, corrected a false comment, and made one refusal
  actionable. 25 of the 45 DRM.jl assertions pass on the reverted source too —
  they are new coverage of existing behaviour, not red-then-green.
* **Fixed effects only.** One draw (`n = 600`, seed 20260905). No random effects,
  no `phylo()`/`relmat()`/`animal()`/`spatial()` markers, no offsets, no weights.
* **No interval or coverage claim.** SE agreement between two engines is not
  interval coverage. `interval_status` untouched; `r_bridge_status` stays
  `partial` pending a bridge-side inference (G3) receipt.
* **Hurdle (`hu`)** is covered only by the refusal-message assertions in
  DRM.jl #661, not as a bridge-vs-native fit. `zi_nbinom2` is covered on the
  DRM.jl side but has **no** new drmTMB focused test — its capability row still
  lacks the same limb this leaf closed for `zi_poisson`.
* **The `zi_nbinom2` and `hurdle_nbinom2` registry comment** is corrected, but
  neither row got a focused drmTMB test. That is the obvious follow-up.

## 8. Blockers and defects found, NOT fixed

* **DRM.jl `test/runtests.jl` includes nine bridge test files twice** — once as
  a plain `include(...)` (lines ~289–296) and again as `_shard_include(...)`
  (~299–307). Verified pre-existing on `origin/main`
  (`grep -c '^include("test_bridge_formula_translation.jl")'` = 1 **and**
  `grep -c '^_shard_include(...)'` = 1). This is exactly the duplication the
  file's own MAINTENANCE NOTE predicts from a hand-merged conflict. Out of this
  leaf's OWNS; worth its own issue.
* The drmTMB gate depending on DRM.jl #661 is **BLOCKED-on-DRM.jl-PR-661**, not
  unmet: nothing in this drmTMB PR requires #661 to merge (the R route already
  works at the pin), so the two PRs are independent and can merge in either
  order.

## 9. Mistakes I made

* I initially asserted that `bf(count ~ x, zi ~ z, corpair ~ 1)` would be refused
  by the dpar-vocabulary gate. It is not: `bf()` normalises an unrecognised LHS
  into a **`mu`** entry, so the formula parsed as `mu, zi, mu` and the gate never
  fired. The test failed, I diagnosed it rather than deleting the assertion, and
  replaced it with a white-box probe on `phylocov` (the case `R/julia-bridge.R`
  names as deliberately absent) — noting in the file itself why the mutation is
  white-box.
* My first Julia probe used `Poisson` unqualified with `Distributions` also
  loaded, and hit `UndefVarError`. Cost one run; no conclusion was drawn from it.
* My first ledger gate `G10` grepped for `spec("zi_poisson"`, which my own
  corrected **comment** then contained — the check would have failed on prose.
  I reworded the comment rather than loosening the check.
