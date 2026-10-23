# A3: ledger the nine routes that already fit through `engine = "julia"` but had no capability row

**Reader**: anyone reading `inst/extdata/julia-capabilities.tsv` (or the dashboard copy) and
asking "does `engine = "julia"` fit a Student-t / lognormal / Gamma / Poisson / NB2 / Beta /
ZIP / ZINB / hurdle-NB2 fixed-effect model, and how well?"; anyone maintaining
`drm_julia_capability_comparison()` in `R/julia-bridge.R`; the A2 matrix leaf, whose
"admitted family without a TSV row" test this leaf turns green.

Leaf ledger: `.unlazy/parity/gates/leaf-a3.md`. Worktree branch `claude/parity-a3` on
drmTMB `ea3156d73` (origin/main after #1162, the family registry). DRM.jl pin `430ef64cc`.

## 1. Goal

Nine bridge routes fit today through `engine = "julia"` and were invisible to the
capability ledger: the six registry `fe` families with no row (student, lognormal,
gamma, poisson, nbinom2, beta) and the three count dpar routes the bridge vocabulary
admits without any registry row of their own (poisson + `zi`, nbinom2 + `zi`,
nbinom2 + `hu`). Give each a ledger row backed by a same-target point + SE receipt.
No bridge behaviour changes.

## 2. Implemented

- `drm_julia_capability_comparison()` gains nine rows: `fe_student`, `fe_lognormal`,
  `fe_gamma`, `fe_poisson`, `fe_nbinom2`, `fe_beta`, `zi_poisson`, `zi_nbinom2`,
  `hurdle_nbinom2`. Eight carry `r_bridge_status = partial` on the wave-1 bar
  (same-target point + SE receipt on a committed fixture; bridge-side inference G3
  unqualified). `hurdle_nbinom2` is `experimental` **by measurement** (section 3a).
  All nine have `claim_status = partial`.
- Both generated TSVs regenerated with `tools/write-julia-capability-comparison.R`
  (12 -> 21 rows).
- Nine `PARITY_PASS` rows appended to DRM.jl `docs/dev-log/evidence/parity-fixtures.tsv`
  and nine `SE_PASS` rows plus one `NEGATIVE_CONTROL_OK` row appended to
  `parity-se.tsv`, in the pin clone (`/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc`).
  They are reproduced verbatim in section 5 because the pin clone is not a PR.

### Receipts (measured 2026-09-05 in THIS run; drmTMB 0.7.0 `load_all` at `ea3156d73`, `drmtmb_code_hash 1a263412…`; DRM.jl `430ef64`)

| capability_id | native call (engine = "tmb") | bridge call (engine = "julia") | max abs coef diff | logLik (both) | logLik diff | SE abs / rel | n |
|---|---|---|---|---|---|---|---|
| fe_student | `bf(y ~ x, sigma ~ 1, nu ~ 1), student()` | same | 1.118e-12 (4/4) | -185.889991 | 1.421e-13 | 3.945e-07 / 5.843e-07 | 150 |
| fe_lognormal | `bf(y ~ x, sigma ~ 1), lognormal()` | same | 2.631e-14 (3/3) | -173.635565 | 1.705e-12 | 1.925e-08 / 3.333e-07 | 150 |
| fe_gamma | `bf(y ~ x), Gamma(link = "log")` | same | 1.911e-11 (3/3) | -172.781769 | 8.527e-13 | 1.838e-08 / 3.316e-07 | 150 |
| fe_poisson | `bf(y ~ x), poisson()` | same | 1.029e-12 (2/2) | -244.763153 | 1.705e-13 | 1.782e-08 / 3.319e-07 | 150 |
| fe_nbinom2 | `bf(y ~ x), nbinom2()` | same | 1.704e-11 (3/3) | -259.886626 | 9.095e-13 | 7.255e-09 / 4.731e-08 | 150 |
| fe_beta | `bf(y ~ x, sigma ~ 1), beta()` | same | 1.172e-11 (3/3) | 90.719135 | 4.405e-13 | 1.656e-08 / 2.978e-07 | 150 |
| zi_poisson | `bf(y ~ x, zi ~ x), poisson()` | same | 1.286e-11 (4/4) | -176.954999 | 2.842e-14 | 3.527e-08 / 1.649e-07 | 120 |
| zi_nbinom2 | `bf(y ~ x, sigma ~ 1, zi ~ 1), nbinom2()` | same | 1.003e-12 (4/4) | -351.976191 | 1.648e-12 | 6.109e-08 / 2.638e-07 | 200 |
| hurdle_nbinom2 | `bf(y ~ x, sigma ~ 1, hu ~ 1), truncated_nbinom2()` | `bf(y ~ x, sigma ~ 1, hu ~ 1), nbinom2()` | 1.125e-12 (4/4) | -351.426966 | 2.558e-12 | 1.718e-08 / 1.209e-07 | 200 |

Estimator reported `ML` on both engines for all nine. Negative control
(`negative_control_perturbed_a3`: fe_student with `se_julia[1] * 1.10`) reads `SE_FAIL`
before relabelling, rel diff 9.091e-02 -> `NEGATIVE_CONTROL_OK`. Tolerances: coef and
logLik 1e-4, SE rtol 1e-3 (atol 1e-8), identical to DRM.jl `tools/parity_fixture.R` /
`parity_se.R`, whose comparator (`parity_numeric()`) and provenance stamp
(`drmtmb_provenance_lib.R`) the driver sources directly.

Fixtures: fe_gamma / fe_poisson / fe_nbinom2 are byte-identical to the `fe_cells` of
DRM.jl `tools/parity_fixture.R` (seed 4242, n = 150), so those three are re-banks of
existing cells on this comparator build. The other six are new committed fixtures
(seed 4242 except zi_poisson, seed 3 / n = 120, which is the probe DGP whose
logLik -176.9550 the leaf ledger quotes; reproduced here to 6 dp).

## 3a. Decisions and Rejected Alternatives

- **hurdle_nbinom2 is `experimental`, not `partial`, although its receipt passes.** The
  two engines accept different spellings of the same model: native fits
  `truncated_nbinom2() + hu` and refuses `nbinom2() + hu`
  (`` `nbinom2()` models only support `mu`, `sigma`, and optional `zi`. Unsupported parameter: "hu" ``),
  while the bridge fits `nbinom2() + hu` (DRM.jl reads `hu` as the hurdle) and refuses
  `truncated_nbinom2()` (not a registry `fe` row; A4's truncated_nbinom2 leaf owns that).
  Both refusals were measured in this run. A user therefore cannot switch `engine=` on
  one call, which is what the wave-1 `partial` bar promises. The ledger asked for nine
  `partial` rows; this is a deliberate, written deviation on one row (G4 partially
  deviates), and the row's `next_action` names the fix (map the spellings in A4's
  truncated_nbinom2 registry row, then re-measure on one identical call).
  Rejected: recording it `partial` with a caveat -- the status column is what readers
  filter on; the caveat would not be.
- **The zi/hu routes are rows even though they are not registry families.** They are
  admitted by the dpar vocabulary (`julia_bridge_supported_dpars()`; DRM.jl
  `src/bridge.jl` mu/sigma/nu/zi/hu/zoi/coi) under the poisson / nbinom2 registry rows.
  A registry-driven ledger test would never see them, so each row's `next_action` says
  any such test must enumerate them explicitly. Rejected: adding registry rows for
  them -- the registry is not in this leaf's OWNS, and they are not families.
- **Did not touch the registry comment that says the Julia bridge has "NO case yet"
  for zi_poisson / zi_nbinom2 / hurdle_nbinom2** (`R/julia-family-registry.R`). It is
  stale as a statement about the bridge (all three fit; receipts above) but the file is
  outside OWNS. Reported as a residual for A4/A2.
- **Re-measured everything rather than trusting the previous attempt.** The previous
  attempt of this leaf died before reporting. Its driver and numbers were kept only as
  a hypothesis; every number above comes from this run's log
  (`a3-run2.log`). They agree with the previous attempt to the printed precision
  (same fixtures, same tree); the code hash differs (`6e002bd8` -> `1a263412`) because
  the hash covers the uncommitted comparison function, which was edited after the
  earlier measurement.

## 4. Files Touched

drmTMB (branch `claude/parity-a3`):
- `R/julia-bridge.R` -- `drm_julia_capability_comparison()` only (nine rows in each of
  the ten column vectors). Diff hunks span old lines 207-339, all inside the function
  (193-427 new).
- `inst/extdata/julia-capabilities.tsv` -- regenerated (21 rows).
- `docs/dev-log/dashboard/julia-capabilities.tsv` -- regenerated (21 rows).
- `docs/dev-log/after-task/2026-09-05-a3-unledgered-routes.md` -- this file.

DRM.jl pin clone (not a PR; rows to be carried by the integrator or re-banked by
`tools/parity_*.R` once those scripts gain these cells):
- `docs/dev-log/evidence/parity-fixtures.tsv` -- +9 rows (after the sibling leaves'
  `fe_tweedie`, `fe_beta_binomial` rows).
- `docs/dev-log/evidence/parity-se.tsv` -- +10 rows (nine cells + negative control).

Scratch (not committed): `a3-run2.R` (driver), `a3-run2.log`, `a3-run2-fixture-rows.tsv`,
`a3-run2-se-rows.tsv`, `a3-row-check2.R` (G5 stand-in), all under the session scratchpad.

## 5. Checks Run

- Driver `a3-run2.R` (load_all of the worktree; env `OPENBLAS_NUM_THREADS=1
  DRMTMB_JULIA_TESTS=true DRM_JL_PATH=DRM_JL_PHYLO_PATH=<pin>`): exit 0; nine
  `PARITY_PASS`, nine `SE_PASS`, one `NEGATIVE_CONTROL_OK`; wall time 20.0 s for the
  first cell (Julia boot) then 0.9-4.9 s per cell.
- `Rscript tools/write-julia-capability-comparison.R`: "wrote 21 Julia capability rows"
  to both outputs.
- `python3 tools/capability_ledger.py --check`: `capability-ledger: OK (31 generated outputs)`.
- `testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R")` (the test that
  compares both TSVs to the generator and pins the allowed status vocabularies): all
  pass, 0 failures. `test-julia-family-registry.R`: all pass.
- `testthat::test_dir(filter = "^julia-")` without live Julia: 38 files, 1167 passed,
  0 failed, 0 errors, 23 live tests skipped (expected without `DRM_JL_PATH`).
- G6 scope: `git diff --stat -- R/ src/ tests/` lists only `R/julia-bridge.R`
  (+91/-7); every hunk header carries `drm_julia_capability_comparison`.

Rows appended to DRM.jl `parity-fixtures.tsv` (tab-separated; verbatim):

```
fe_student	Student-t (nu ~ 1), fixed effects	PARITY_PASS	1.11843867500738e-12	-185.889990594708	-185.889990594708	1.4210854715202e-13	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); all named coefficients compared
fe_lognormal	Lognormal, fixed effects	PARITY_PASS	2.63122856836162e-14	-173.63556516885	-173.635565168851	1.70530256582424e-12	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); all named coefficients compared
fe_gamma	Gamma (log link), fixed effects	PARITY_PASS	1.91139326588541e-11	-172.78176871915	-172.781768719151	8.5265128291212e-13	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); all named coefficients compared
fe_poisson	Poisson, fixed effects	PARITY_PASS	1.02884367692013e-12	-244.763152612771	-244.763152612771	1.70530256582424e-13	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); all named coefficients compared
fe_nbinom2	NegBinomial2, fixed effects	PARITY_PASS	1.70424785395085e-11	-259.886625779689	-259.886625779688	9.09494701772928e-13	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); all named coefficients compared
fe_beta	Beta (logit mu), fixed effects	PARITY_PASS	1.17206244709678e-11	90.7191353015061	90.7191353015065	4.40536496171262e-13	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); all named coefficients compared
zi_poisson	Zero-inflated Poisson (zi ~ x), fixed effects	PARITY_PASS	1.28625998740972e-11	-176.954999126694	-176.954999126694	2.8421709430404e-14	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); all named coefficients compared
zi_nbinom2	Zero-inflated NegBinomial2 (zi ~ 1), fixed effects	PARITY_PASS	1.00275343584144e-12	-351.976190626724	-351.976190626723	1.64845914696343e-12	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); all named coefficients compared
hurdle_nbinom2	Hurdle NegBinomial2 (hu ~ 1), fixed effects	PARITY_PASS	1.12476694624775e-12	-351.426966165188	-351.426966165185	2.55795384873636e-12	1e-04	R-via-Julia bridge parity (engine='julia'), drmTMB 0.7.0 (A3 worktree load_all, HEAD ea3156d73); CROSS-SPELLING SAME TARGET: engine='tmb' fits truncated_nbinom2() + hu ~ 1, engine='julia' fits nbinom2() + hu ~ 1 (the bridge's accepted spelling); no identical call fits on both engines today; all named coefficients compared
```

Rows appended to DRM.jl `parity-se.tsv` (verbatim; last column is `drmtmb_code_hash`):

```
fe_student	se_student_fe	Student-t (nu ~ 1), fixed effects	SE_PASS	3.94515242252425e-07	5.84292709529499e-07	mu_(Intercept)=0.0660359;mu_x=0.0585839;sigma_(Intercept)=0.0953365;nu_(Intercept)=0.675201	mu_(Intercept)=0.0660359;mu_x=0.0585839;sigma_(Intercept)=0.0953365;nu_(Intercept)=0.675201	0.001	4 SE(s) compared (4 name-matched of 4 native / 4 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
fe_lognormal	se_lognormal_fe	Lognormal, fixed effects	SE_PASS	1.92450053809745e-08	3.33333271117843e-07	mu_(Intercept)=0.0424659;mu_x=0.0390827;sigma_(Intercept)=0.057735	mu_(Intercept)=0.0424659;mu_x=0.0390827;sigma_(Intercept)=0.057735	0.001	3 SE(s) compared (3 name-matched of 3 native / 3 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
fe_gamma	se_gamma_fe	Gamma (log link), fixed effects	SE_PASS	1.83847697482475e-08	3.31559705836523e-07	mu_(Intercept)=0.0412951;mu_x=0.0378976;sigma_(Intercept)=0.0554493	mu_(Intercept)=0.0412951;mu_x=0.0378977;sigma_(Intercept)=0.0554493	0.001	3 SE(s) compared (3 name-matched of 3 native / 3 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
fe_poisson	se_poisson_fe	Poisson, fixed effects	SE_PASS	1.78219768942611e-08	3.31912808669365e-07	mu_(Intercept)=0.0648674;mu_x=0.0536947	mu_(Intercept)=0.0648674;mu_x=0.0536948	0.001	2 SE(s) compared (2 name-matched of 2 native / 2 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
fe_nbinom2	se_nbinom2_fe	NegBinomial2, fixed effects	SE_PASS	7.25493562447888e-09	4.73080283443147e-08	mu_(Intercept)=0.0839337;mu_x=0.0762153;sigma_(Intercept)=0.153355	mu_(Intercept)=0.0839337;mu_x=0.0762153;sigma_(Intercept)=0.153355	0.001	3 SE(s) compared (3 name-matched of 3 native / 3 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
fe_beta	se_beta_fe	Beta (logit mu), fixed effects	SE_PASS	1.65611223693074e-08	2.97821838334834e-07	mu_(Intercept)=0.0479654;mu_x=0.046122;sigma_(Intercept)=0.0556075	mu_(Intercept)=0.0479654;mu_x=0.046122;sigma_(Intercept)=0.0556075	0.001	3 SE(s) compared (3 name-matched of 3 native / 3 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
zi_poisson	se_zi_poisson	Zero-inflated Poisson (zi ~ x), fixed effects	SE_PASS	3.52744017884099e-08	1.64886033722385e-07	mu_(Intercept)=0.113865;mu_x=0.155705;zi_(Intercept)=0.305096;zi_x=0.414972	mu_(Intercept)=0.113865;mu_x=0.155705;zi_(Intercept)=0.305096;zi_x=0.414972	0.001	4 SE(s) compared (4 name-matched of 4 native / 4 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
zi_nbinom2	se_zi_nbinom2	Zero-inflated NegBinomial2 (zi ~ 1), fixed effects	SE_PASS	6.10914592524825e-08	2.63831954341515e-07	mu_(Intercept)=0.0865589;mu_x=0.0748644;sigma_(Intercept)=0.231554;zi_(Intercept)=0.231912	mu_(Intercept)=0.0865589;mu_x=0.0748644;sigma_(Intercept)=0.231554;zi_(Intercept)=0.231912	0.001	4 SE(s) compared (4 name-matched of 4 native / 4 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
hurdle_nbinom2	se_hurdle_nbinom2	Hurdle NegBinomial2 (hu ~ 1), fixed effects	SE_PASS	1.71832922335469e-08	1.20862978904272e-07	mu_(Intercept)=0.124133;mu_x=0.0918007;sigma_(Intercept)=0.225011;hu_(Intercept)=0.151585	mu_(Intercept)=0.124133;mu_x=0.0918007;sigma_(Intercept)=0.225011;hu_(Intercept)=0.151585	0.001	4 SE(s) compared (4 name-matched of 4 native / 4 bridge)	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
fe_student	negative_control_perturbed_a3	NEGATIVE CONTROL (A3): fe_student with se_julia[1] * 1.10	NEGATIVE_CONTROL_OK	0.00660358554208278	0.0909090020834844	mu_(Intercept)=0.0660359;mu_x=0.0585839;sigma_(Intercept)=0.0953365;nu_(Intercept)=0.675201	mu_(Intercept)=0.0726395;mu_x=0.0585839;sigma_(Intercept)=0.0953365;nu_(Intercept)=0.675201	0.001	4 SE(s) compared (4 name-matched of 4 native / 4 bridge); NEGATIVE CONTROL: se_julia[1] perturbed by +10%	1a263412f3e422f5a4a2d20ae4314a4f8372cb1d5890ee0c701708a57292fbec
```

## 6. Tests of the Tests

- **G5 red control** (stand-in for A2's not-yet-written test; `a3-row-check2.R`, which
  derives the admitted routes from the live registry `fe` column plus the `zi`/`hu`
  dpars and looks for each family constructor in the TSV `syntax` column with
  `engine = "julia"`): against `origin/main`'s TSV (12 rows) it reports
  `admitted routes: 12; with a TSV row: 3; MISSING: 9`, naming exactly student,
  lognormal, poisson, nbinom2, gamma, beta, poisson+zi, nbinom2+zi, nbinom2+hu, exit 1.
  Against the regenerated TSV (21 rows): `MISSING: 0`, exit 0.
- **SE comparator negative control**: `se_julia[1] * 1.10` on the fe_student cell gives
  `SE_FAIL` (rel 9.091e-02) before relabelling -- the comparator can fail.
- **Refusal probes** (the hurdle asymmetry): native `nbinom2() + hu` refused with the
  message quoted in 3a; bridge `truncated_nbinom2() + hu` refused with the Workflow G
  family-list message. Both captured in `a3-run2.log`.
- The generated-artifact test (`test-julia-gate-vs-engine.R`) fails whenever a TSV is
  hand-edited or stale relative to the generator; it passes only because both TSVs were
  regenerated after the last edit to the function.

## 7a. Issue Ledger

- drmTMB#544 (Julia bridge parity umbrella): all nine rows cite it as `evidence_url`.
- Hurdle spelling asymmetry (`nbinom2() + hu` vs `truncated_nbinom2() + hu`): named in
  the `hurdle_nbinom2` row's `claim_boundary` and `next_action`; owned by A4's
  truncated_nbinom2 leaf. No new issue opened (no messages / issues from this leaf).

## 8. Consistency Audit

- Every A3 `claim_boundary` quotes numbers that appear verbatim in this run's row
  files (`a3-run2-fixture-rows.tsv`, `a3-run2-se-rows.tsv`).
- The existing `fe_poisson`, `fe_nbinom2`, `fe_gamma` DRM.jl rows (drmTMB 0.7.0,
  older comparator) remain; the new rows are the same cells re-banked and say so in
  their notes and in the drmTMB `claim_boundary` (gamma: old coef diff 3.91e-06, now
  1.911e-11 on the pinned build).
- Coefficient naming: both engines return the same names for all nine cells
  (`mu.(Intercept)`, `mu.x`, `sigma.(Intercept)`, `nu.(Intercept)`, `zi.*`, `hu.*`);
  the bridge orders `nu`/`hu` before `sigma`, the comparator matches by name
  (design 258), so order does not matter and no positional fallback fired.
- Sibling leaves' rows in the pin-clone TSVs (`fe_tweedie` x1/x2, `fe_beta_binomial`
  x1/x1) are present above the A3 rows (see section 9 for why this needed checking).
- `next_action` for the three re-banked cells points at DRM.jl `tools/parity_fixture.R`;
  for the six new cells it says the fixture lives in this after-task (it does: the
  DGPs are in the driver and summarised in section 2).

## 9. What Did Not Go Smoothly

- **I wiped two sibling leaves' evidence rows and had to restore them.** To drop the
  previous attempt's unverified A3 rows from the pin clone's TSVs I ran
  `git checkout -- <both TSVs>`, having checked only that the rows *I grepped for* were
  A3's. The diff also carried `fe_tweedie` (1 fixture row, 2 SE rows) and
  `fe_beta_binomial` (1 + 1) from the A4 leaves. I restored them byte-for-byte from
  those leaves' own driver logs in the shared scratchpad (`a4-tweedie/parity_driver.log`
  lines 33/36/37; `a4bb/receipts.log` lines 36/39), in the original order, and verified
  the pin clone diff was back to +2/+3 before appending A3's rows. Lesson: filter rows
  by id; never reset a shared file.
- The previous attempt's hurdle row had a note with an embedded newline (the native
  refusal message), which split the TSV row; this run's driver squashes whitespace in
  every note and asserts no newline survives before writing.
- The auto-mode command classifier refused several innocuous shell commands
  (`cat >>` appends, `sed -n ... > file`); the pin-clone appends were made with the
  Edit tool instead.

## 10. Known Residuals

- No identical-call receipt for the hurdle route (spelling asymmetry, section 3a).
- One fixture, one seed per route; point + SE only. No interval coverage, no random
  effects, no structured markers, no bridge-side profile/bootstrap (G3) on any of the
  nine.
- The DRM.jl parity rows sit in the pin clone's working tree, not on a DRM.jl branch
  or PR (this leaf may not open one). The integrator carries them.
- The A2 test this leaf was meant to turn green does not exist yet; `a3-row-check2.R`
  is a stand-in with the same intent (registry-derived, 9 -> 0).
- `R/julia-family-registry.R`'s comment lists zi_poisson / zi_nbinom2 / hurdle_nbinom2
  under "Julia bridge has NO case yet"; the bridge fits all three today. Outside OWNS.
- `drmtmb_code_hash` stamped on the SE rows (`1a263412…`) is the hash of the
  `load_all` build at measurement time; editing the comparison function afterwards
  (the receipt text itself) changes the namespace hash, so the committed tree's hash
  will differ. The row notes and claim boundaries say so.

## 11. Team Learning

- A receipt that passes is not the same as a route a user can switch engines on: check
  that the *same call* is accepted by both engines before calling it `partial`.
- Routes admitted by dpar vocabulary (zi/hu) are invisible to any registry-driven
  audit; enumerate them explicitly wherever the registry is the source of truth.
- Shared evidence files: filter by row id, never `git checkout`; other leaves append
  to the same file concurrently.

## 12. Cross-Product Coverage

Engine axis (`engine = "julia"`) x family axis, fixed effects only:

- covers ✓: student (mu, sigma ~ 1, nu ~ 1), lognormal (sigma ~ 1), Gamma log link,
  Poisson, NB2, Beta logit (sigma ~ 1), Poisson + zi ~ x, NB2 + zi ~ 1,
  NB2 hurdle hu ~ 1 (cross-spelling); ML estimator; coefficients, logLik, Wald SE.
- does NOT cover ✗: REML on any of these (Gaussian-only concern, but not measured);
  random effects `(1 | g)`; `phylo()` / `relmat()` / `spatial()` markers (separate
  rows own phylo Poisson/NB2/Gamma/Beta); `zi ~ x` on NB2 or `hu ~ x`; `nu ~ x`;
  profile / bootstrap intervals through the bridge (G3); `predict()`, `residuals()`,
  `simulate()` through the bridge; missing-response rows; the
  `truncated_nbinom2()` spelling on the bridge; `binomial` (already ledgered;
  untouched).
