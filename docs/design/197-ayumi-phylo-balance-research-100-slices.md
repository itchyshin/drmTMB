# Ayumi Phylo Balance Research And 100-Slice Plan

## Purpose

This plan prepares the next Ayumi-facing arc after the current R/Julia
100-slice finish run. The question is not just whether `phylo()` is
"implemented"; it is whether the implementation is balanced across location
and scale axes, across estimators, and across the native R/TMB and Julia/DRM
routes.

The direct Ayumi issue URL was not readable from this session: the GitHub app
and public web request both returned 404 for
`Ayumi-495/LS_ecogeographical-rules#2`. The plan therefore uses the user's
supplied description of Ayumi's concern plus local evidence in this repository,
the connected internal GitHub issues, and the public location-scale tutorial.

## Research Findings

Ayumi's concern is valid because the support surface is estimator- and
route-specific:

- Native TMB ML can fit univariate Gaussian `phylo()` on `mu`, on `sigma`, and
  on matched `mu` plus `sigma`.
- Native TMB REML currently admits the exact-Gaussian mean-side phylogenetic row
  only; it rejects scale-side structured effects.
- The R-to-Julia bridge admits Gaussian sigma-phylo and bivariate q4 REML only
  when routed to a suitable DRM.jl engine, but that bridge remains experimental
  until direct DRM.jl, native R, and R-via-Julia parity agree row by row.
- Bivariate q4 native ML can fit all four axes (`mu1`, `mu2`, `sigma1`,
  `sigma2`) as diagnostic point/status evidence, but native q4 REML is still
  unsupported.
- The big Ayumi blockers are not one thing: `drmTMB#555` tracks the q4
  10,440-tip status/speed/bridge harness, `drmTMB#570` tracks the beak
  sigma-phylo native failure, `DRM.jl#291` tracks q4 Gaussian REML acceleration,
  and `DRM.jl#293` tracks the Julia ML `-Inf` ladder after 100 tips.

So the "strange" part is real: the package can run a balanced native ML
univariate location-scale phylo model, while native REML is asymmetric. That is
not a user-facing scientific principle; it is a current estimator boundary.

## Execution Update: A001-A020

The first two waves are now validator-owned mission-control state rather than
chat-only planning. The dashboard has three Ayumi-specific tables:

- `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv` records all 100
  slices and marks A001-A020 as banked.
- `docs/dev-log/dashboard/ayumi-phylo-balance-vocabulary.tsv` defines
  univariate balance, q4 balance, partial native REML, experimental bridge
  support, diagnostic point fits, MAP wording, the reply gate, and the issue
  access boundary.
- `docs/dev-log/dashboard/ayumi-phylo-balance-trackers.tsv` records the live
  tracker split across the unreadable external Ayumi issue and the internal
  drmTMB/DRM.jl blockers.

One important nuance emerged during tracker rehydration: `drmTMB#555` says a
reply was posted to `Ayumi-495/LS_ecogeographical-rules#2` on 2026-06-15 after
bootstrap diagnostics landed. This session still cannot read that external
thread, so the reply existence is tracker evidence only. Do not quote or revise
that reply until the issue is directly readable or the maintainer supplies the
text.

## Execution Update: A021-A025

The native ML wave has begun. `tests/testthat/test-phylo-gaussian.R` now
asserts that the univariate mean-only, sigma-only, and matched mean-plus-sigma
Gaussian phylo ML cells expose direct, profile-ready target rows. A separate
fast error test checks that matched univariate location-scale phylogenetic
terms reject mismatched grouping variables, tree objects, and covariance-block
labels before fitting.

A026 adds a `skip_on_cran()` bootstrap-accounting smoke for native ML
mean-side and scale-side univariate phylo targets. It checks requested and
successful refit counts plus the `"bootstrap.diagnostics"` rows. This is
plumbing evidence only, not interval coverage.

A027-A028 add broad known-truth recovery smokes for the sigma-only and matched
mean-plus-scale native ML cells. They use factor-scale tolerances and a
single-replicate design, so they support "the route moves in the right
direction" rather than a bias, RMSE, MCSE, or coverage claim.

A029-A030 close the native ML wave by rechecking the scale-side diagnostic
surface and adding `docs/design/198-ayumi-native-ml-balance-summary.md`. The
honest native ML conclusion is now explicit: univariate Gaussian native ML is
balanced across mean-only, scale-only, and matched mean-plus-scale `phylo()`
layouts, while native REML and interval-coverage claims remain separate.

## Execution Update: A031-A040

The native REML wave is now banked. Focused tests reconfirm that native
exact-Gaussian REML matches the hand restricted-likelihood reference for the
mean-side phylogenetic location model, while scale-side and matched
`mu`/`sigma` phylogenetic REML requests reject early. The bivariate REML test
continues to reject random or structured mean effects in this slice, so q2 and
q4 phylogenetic native REML remain unsupported.

`docs/design/199-native-reml-phylo-asymmetry-gap.md` records the key
interpretation: this is an implementation and validation boundary, not a
scientific claim that scale-side phylogenetic variation is impossible. Native
ML is balanced for the univariate Gaussian `phylo()` layouts; native REML is
mean-side-only until a separate restricted-likelihood design, score/information
checks, failure-mode plan, and simulation evidence exist.

The public wording in `docs/design/01-formula-grammar.md` and
`docs/dev-log/known-limitations.md` now carries the ML-versus-REML distinction,
and the A040 guard scan found only negative guard wording in the new diff.

## Execution Update: A041-A050

The Julia bridge wave is now banked as experimental evidence. Pure R gate tests
confirm that Gaussian REML forwarding is row-specific: fixed-effect Gaussian
location-scale models and Gaussian cells with `phylo()` on `sigma` forward
`method = "REML"`, while mean-only phylogenetic Gaussian and non-Gaussian
phylogenetic bridge cells warn and fit ML. With
`DRM_JL_PHYLO_PATH=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`,
the live matched sigma-phylo REML bridge smoke passed.

The direct DRM.jl location-only diagnostic helper also ran and reported four
simulation-status rows with `coverage_status = :not_evaluated` and
`ai_reml_ready = false`. That helper stays internal diagnostic evidence, not a
public direct route and not an R bridge promotion.

`docs/dev-log/dashboard/bridge-parity-smoke-status.tsv` now has three Ayumi
bridge balance rows for mean-only, sigma-side, and matched `mu` plus `sigma`
phylo REML. All three keep parity blocked or unsupported until native R,
direct DRM.jl, and R-via-Julia evidence align under one row-specific contract.
The bridge summary is in
`docs/design/200-ayumi-julia-bridge-balance-readiness.md`.

## Execution Update: A051-A060

The bivariate q4 wave is now banked. The focused phylogenetic Gaussian tests
reconfirm native TMB ML q4 point/status behavior: four endpoint SDs, six
derived phylogenetic correlations, q2-plus-q2 block-diagonal separation,
partial q4 early rejection, and broad recovery diagnostics. The q4 correlation
rows remain derived targets and are not direct profile-ready intervals.

The q4 target inventory now includes the 250-tip endpoint profile-budget smoke
as a status row. Together with the existing bootstrap accounting table, the
size-specific native evidence is separated as 30-tip bootstrap plumbing
success, 100-tip bootstrap negative evidence, and 250-tip profile-budget
status. None of these rows claims calibrated uncertainty or Ayumi-scale
practicality.

`docs/design/201-ayumi-bivariate-q4-truth.md` summarizes the honest q4 state:
native ML diagnostic support, native REML unsupported, q2-plus-q2 not full q4,
derived q4 correlations without intervals, and Julia q4 REML bridge evidence
remaining experimental.

## Execution Update: A061-A070

The Ayumi-data wave is now banked from persisted artifacts. The expected
temporary raw bundle was absent from this session, so no fresh large model was
run. The run-now scripts parse, and the stored Mass+Beak current and q4-main
RDS artifacts read cleanly.

`docs/design/202-ayumi-data-readiness-summary.md` records the practical split:
Model A+ remains the clean full-data anchor, with full-data evidence already
banked in `docs/dev-log/after-task/2026-06-16-ayumi-model-a-plus-evidence.md`.
The current Mass+Beak q4/fallback artifacts remain diagnostic because they show
false convergence, non-positive Hessians or skipped Hessian status, large
fixed-gradient diagnostics, and q4 boundary warnings. The q4 status harness and
Model A+ script are the correct rerun entry points when the private raw bundle
is supplied.

## Hard Boundaries

- Do not draft or post an Ayumi reply until the reply wave is reached.
- Do not relabel native q4 Patterson-Thompson REML as HSquared AI-REML.
- Do not claim non-Gaussian REML.
- Do not turn profile-target readiness into interval coverage.
- Do not promote R-to-Julia bridge support without row-specific parity.
- Do not call penalized/MAP fits ML or REML.
- Do not claim 10,440-tip sigma-phylo intervals until the evidence exists.

## Source Anchors

- `docs/dev-log/dashboard/phylo-balance-inventory.tsv`
- `docs/design/182-univariate-phylo-balance-inventory.md`
- `docs/design/181-q4-target-estimator-inventory.md`
- `docs/design/183-phylo-q2-q4-target-map.md`
- `docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md`
- `docs/design/171-scale-side-phylo-identifiability-model-a.md`
- `docs/design/172-phylo-penalized-map.md`
- `docs/design/173-phylo-penalty-model-e-rescue.md`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/test-reml-phylo-location.R`
- `tests/testthat/test-julia-sigma-phylo-reml.R`
- GitHub: `itchyshin/drmTMB#555`, `itchyshin/drmTMB#570`,
  `itchyshin/DRM.jl#291`, `itchyshin/DRM.jl#293`
- Public tutorial:
  `https://ayumi-495.github.io/Eco_location-scale_model/`

## 100 Slices

| Slice | Wave | Repo | Task | Acceptance |
| --- | --- | --- | --- | --- |
| A001 | Rehydrate | drmTMB | Capture Ayumi issue access status and user-supplied constraint. | Note says issue URL inaccessible here and records the quoted balance concern. |
| A002 | Rehydrate | drmTMB | Re-read Ayumi closeout handover and current issue trackers. | `#555`, `#570`, `DRM.jl#291`, and `DRM.jl#293` boundaries summarized. |
| A003 | Rehydrate | drmTMB | Freeze forbidden wording for the Ayumi balance arc. | Scan covers AI-REML, non-Gaussian REML, q4 REML, 10k intervals, and bridge promotion. |
| A004 | Rehydrate | drmTMB | Snapshot current `phylo-balance-inventory.tsv`. | Row counts and statuses recorded before edits. |
| A005 | Rehydrate | drmTMB | Snapshot q2/q4 target-map and extractor-status tables. | q2, q4, and q2-plus-q2 targets are separated. |
| A006 | Rehydrate | DRM.jl | Snapshot q4 REML and ML issue states. | Direct DRM.jl evidence stays separate from R bridge evidence. |
| A007 | Rehydrate | drmTMB | Locate all Ayumi-specific local artifacts and parked drafts. | Parked drafts stay untouched. |
| A008 | Rehydrate | drmTMB | Rebuild a one-page capability-state sketch. | Native ML, native REML, Julia bridge, direct DRM.jl rows are distinct. |
| A009 | Rehydrate | drmTMB | Define the reply acceptance criteria before implementation. | Reply requires evidence rows, not intentions. |
| A010 | Rehydrate | drmTMB | Write an after-research checkpoint. | Next agent can restart from the balance plan. |
| A011 | Semantics | drmTMB | Define "balanced" for univariate phylo. | `mu`, `sigma`, and matched `mu+sigma` rows have explicit estimator columns. |
| A012 | Semantics | drmTMB | Define "balanced" for bivariate q4 phylo. | `mu1`, `mu2`, `sigma1`, `sigma2`, and six correlations named. |
| A013 | Semantics | drmTMB | Define "partial" versus "unsupported" for REML. | Mean-only native REML is not described as balanced support. |
| A014 | Semantics | drmTMB | Define "experimental bridge" versus "supported bridge". | R-via-Julia needs native/direct/bridge parity. |
| A015 | Semantics | drmTMB | Define "diagnostic point fit" versus "interpretable inference". | `pdHess`, profile, bootstrap, and status rows separated. |
| A016 | Semantics | drmTMB | Define "MAP" vocabulary for penalized phylo fits. | Penalized fits cannot be called ML/REML. |
| A017 | Semantics | drmTMB | Add a balance vocabulary TSV draft. | Validator checks terms and evidence links. |
| A018 | Semantics | drmTMB | Add issue-link fields to balance rows. | Rows point to `#555`, `#570`, `DRM.jl#291`, or `DRM.jl#293`. |
| A019 | Semantics | drmTMB | Add route fields for native R, bridge, direct Julia. | No row collapses the three routes. |
| A020 | Semantics | drmTMB | Add a reader-facing balance summary. | Pat can tell which model to try next. |
| A021 | Native ML | drmTMB | Re-run focused univariate `mu`-only phylo ML test. | Convergence, SD target, and no interval claim recorded. |
| A022 | Native ML | drmTMB | Re-run focused univariate `sigma`-only phylo ML test. | `sd:sigma:phylo` target and diagnostics recorded. |
| A023 | Native ML | drmTMB | Re-run matched univariate `mu+sigma` phylo ML test. | Mean-scale correlation row visible and point-only status explicit. |
| A024 | Native ML | drmTMB | Add malformed-mismatch tests for univariate matched terms. | Same source/group/label errors are clear. |
| A025 | Native ML | drmTMB | Add univariate profile-target status rows for `mu`, `sigma`, and correlation. | Target readiness is not interval coverage. |
| A026 | Native ML | drmTMB | Add univariate bootstrap plumbing smoke for supported ML rows. | Refit counts and failure reasons captured. |
| A027 | Native ML | drmTMB | Add small known-truth recovery smoke for `sigma`-only phylo ML. | Bias/RMSE diagnostic, no coverage claim. |
| A028 | Native ML | drmTMB | Add small known-truth recovery smoke for matched `mu+sigma` ML. | Correlation boundary status recorded. |
| A029 | Native ML | drmTMB | Add scale-side clamp diagnostic row to the balance table. | Clamp-active warning cannot imply support. |
| A030 | Native ML | drmTMB | Summarize native ML balance for Ayumi. | Native ML balance is clear but inference caveats remain. |
| A031 | Native REML | drmTMB | Re-run native mean-side phylo REML hand-reference test. | Exact-Gaussian mean-side REML remains covered. |
| A032 | Native REML | drmTMB | Re-run native sigma-side REML rejection test. | Error says current native REML is mean-side only. |
| A033 | Native REML | drmTMB | Re-run matched `mu+sigma` REML rejection test. | Balanced native REML remains unsupported. |
| A034 | Native REML | drmTMB | Add q2/q4 REML rejection status rows. | Native bivariate phylo REML stays unsupported. |
| A035 | Native REML | drmTMB | Write the native REML derivation gap note. | Explains why mean-side-only is current implementation, not scientific principle. |
| A036 | Native REML | drmTMB | Scout exact native REML design for scale-side Gaussian structured effects. | Feasibility note lists required math and tests. |
| A037 | Native REML | drmTMB | Prototype no-code estimator contract for native balanced REML. | Parameters, objective, score/information, and failure modes named. |
| A038 | Native REML | drmTMB | Decide whether native balanced REML is near-term or deferred. | Status row is `planned` or `deferred` with reason. |
| A039 | Native REML | drmTMB | Update public docs to avoid asymmetric REML surprise. | User sees ML balanced, REML mean-side only. |
| A040 | Native REML | drmTMB | Add REML balance guard scan. | Public docs cannot imply balanced native REML. |
| A041 | Julia Bridge | drmTMB | Re-run pure-R Julia REML gate tests. | Sigma-phylo and q4 REML admission matrix passes. |
| A042 | Julia Bridge | drmTMB | Re-run live sigma-phylo REML bridge smoke if engine available. | Finite SDs and estimator flags captured or guarded skip recorded. |
| A043 | Julia Bridge | drmTMB | Add mean-only Julia REML bridge status row. | Current gate remains unsupported unless direct engine changes. |
| A044 | Julia Bridge | DRM.jl | Inspect direct DRM.jl location-only REML helper status. | Internal diagnostic versus public route distinction recorded. |
| A045 | Julia Bridge | DRM.jl | Decide whether direct loc-only REML should become a public DRM.jl route. | Separate design issue or deferred note created. |
| A046 | Julia Bridge | drmTMB | Add bridge parity matrix for univariate `mu`, `sigma`, `mu+sigma`. | No parity row is promoted until all three routes align. |
| A047 | Julia Bridge | drmTMB | Add bridge payload schema for balance-specific rows. | Estimator, target, source, and status fields included. |
| A048 | Julia Bridge | drmTMB | Add bridge reconstruction checks for balance rows. | `sdpars`, `corpars`, `profile_targets`, and `corpairs` preserved. |
| A049 | Julia Bridge | drmTMB | Add intentional error guidance for unsupported balance bridge cells. | Users get native TMB or Julia-direct alternatives. |
| A050 | Julia Bridge | drmTMB | Summarize bridge balance readiness. | Experimental bridge evidence remains clearly labelled. |
| A051 | Bivariate q4 | drmTMB | Re-run native q4 ML focused test. | Four SDs, six correlations, point/status rows visible. |
| A052 | Bivariate q4 | drmTMB | Re-run block-diagonal q2-plus-q2 test. | It is not counted as full q4 support. |
| A053 | Bivariate q4 | drmTMB | Re-run partial q4 rejection tests. | Partial all-four blocks reject clearly. |
| A054 | Bivariate q4 | drmTMB | Add q4 derived-correlation target audit. | Derived correlations remain not profile-ready. |
| A055 | Bivariate q4 | drmTMB | Add q4 SD direct-target audit. | SD targets separated from correlation targets. |
| A056 | Bivariate q4 | drmTMB | Add q4 covariance summary status rows. | Summary covariance remains point/status unless intervals exist. |
| A057 | Bivariate q4 | drmTMB | Add q4 profile endpoint timeout/status smoke. | Long profiles return row status, not hangs. |
| A058 | Bivariate q4 | drmTMB | Add q4 bootstrap diagnostics smoke. | Per-refit diagnostics are attached. |
| A059 | Bivariate q4 | drmTMB | Add q4 same-formula reduced-size harness row. | 30/100/250-size evidence captured. |
| A060 | Bivariate q4 | drmTMB | Summarize q4 balance truth. | Native ML diagnostic, native REML unsupported, Julia REML experimental. |
| A061 | Ayumi Data | drmTMB | Locate or confirm availability of Ayumi benchmark bundle. | If absent, plan uses synthetic/previous artifacts only. |
| A062 | Ayumi Data | drmTMB | Re-run no-sigma-phylo Model A status if data available. | Clean point-fit status recorded. |
| A063 | Ayumi Data | drmTMB | Re-run univariate full `mu+sigma` beak status if data available. | Starting-like basin or rescue status captured. |
| A064 | Ayumi Data | drmTMB | Re-run mass/tarsus/lightness univariate profile status if data available. | Finite intervals versus boundary rows separated. |
| A065 | Ayumi Data | drmTMB | Re-run q4 exact formula native ML status ladder if data available. | Fit/status rows for selected sizes captured. |
| A066 | Ayumi Data | drmTMB | Re-run native q4 REML rejection on same data. | Early rejection row captured. |
| A067 | Ayumi Data | drmTMB | Re-run Julia q4 point ladder only after direct DRM.jl readiness check. | No large run if direct path still fails small gates. |
| A068 | Ayumi Data | drmTMB | Add data-provenance and dirty-state metadata rows. | Every artifact names SHAs, versions, threads, and dirty flags. |
| A069 | Ayumi Data | drmTMB | Add "what Ayumi can run today" script wrapper. | Script prints supported, rejected, point-only, and failed rows. |
| A070 | Ayumi Data | drmTMB | Summarize real-data balance readiness. | Answer separates model validity from inferential usability. |
| A071 | Inference | drmTMB | Audit Wald status for all balance rows. | `pdHess = FALSE` means Wald unsafe, not point-fit impossible. |
| A072 | Inference | drmTMB | Audit profile status for all direct SD rows. | Finite, failed, timeout, and not-ready statuses distinct. |
| A073 | Inference | drmTMB | Audit bootstrap diagnostics for all q4 SD rows. | Refit counts and messages visible. |
| A074 | Inference | drmTMB | Add coverage ledger for balance rows. | Most rows stay `not_evaluated`. |
| A075 | Inference | drmTMB | Add boundary-status ledger for correlations and SDs. | Boundary fits cannot be promoted silently. |
| A076 | Inference | drmTMB | Add profile timeout hardening issue if still missing. | Large profile cannot hang without status. |
| A077 | Inference | drmTMB | Add bootstrap retry/rescue design note. | Public retry policy waits for tests. |
| A078 | Inference | DRM.jl | Check direct Julia q4 profile/bootstrap status. | Direct engine interval status separated from bridge. |
| A079 | Inference | drmTMB | Add inference parity requirements for promotion. | Point, logLik, profile/bootstrap status, and diagnostics must agree. |
| A080 | Inference | drmTMB | Summarize inference gaps for Ayumi. | Reply has enough caveats to be useful. |
| A081 | Literature | drmTMB | Summarize location-scale model motivation from public tutorial. | User-facing narrative connects location and variability. |
| A082 | Literature | drmTMB | Summarize brms/glmmTMB contrast for random effects in scale. | Avoids promising parity with Bayesian route. |
| A083 | Literature | drmTMB | Re-check PLSM references used in docs 170-173. | Citations support weak-identifiability language. |
| A084 | Literature | drmTMB | Re-check PC-prior/MAP references. | Penalized route language is citation-backed. |
| A085 | Literature | drmTMB | Add "data design" note on one observation per tip. | Replication recommendation is explicit. |
| A086 | Docs | drmTMB | Update formula grammar balance paragraph. | ML versus REML distinction visible. |
| A087 | Docs | drmTMB | Update README current-status row if needed. | Public prose does not imply balanced REML. |
| A088 | Docs | drmTMB | Update known limitations. | Scale-side phylo inference caveat visible. |
| A089 | Docs | drmTMB | Add short applied-user vignette stub for balance choices. | Shows Model A, ML matched phylo, and q4 routes without overclaiming. |
| A090 | Docs | drmTMB | Add dashboard balance panel plan. | Local dashboard can show Ayumi readiness without reply drafting. |
| A091 | Reply Prep | drmTMB | Draft a private Ayumi answer outline. | Thanks, validates concern, gives table, no post. |
| A092 | Reply Prep | drmTMB | Add "what changed since last reply" section. | Avoids contradicting previous comment. |
| A093 | Reply Prep | drmTMB | Add "what is still not solved" section. | q4 REML, 10k intervals, Julia speed, beak failure named. |
| A094 | Reply Prep | drmTMB | Add "what to run now" section. | One or two recommended formulas with status. |
| A095 | Reply Prep | drmTMB | Rose audit for overclaiming. | Forbidden wording scan passes. |
| A096 | Reply Prep | drmTMB | Pat audit for applied readability. | Ayumi can tell which result is usable. |
| A097 | Reply Prep | drmTMB | Gauss/Fisher audit for statistical correctness. | Identifiability and inference claims are defensible. |
| A098 | Reply Prep | drmTMB | Maintainer approval gate. | No issue comment without explicit approval. |
| A099 | Reply Prep | drmTMB | If approved, post concise issue reply. | Reply links evidence rows and caveats. |
| A100 | Closeout | drmTMB | Write after-arc report and checkpoint. | Next arc starts from a clean evidence packet. |

## First 10 To Run When The Ayumi Arc Starts

Start with A001-A010. Do not jump straight to a reply. The first pass should
repair the evidence map, not the public story.

## Expected Answer Shape

The likely honest answer after A001-A030 is:

> Native ML is balanced for univariate Gaussian phylo location and scale
> intercepts, but native REML is not balanced today. The Julia route has
> experimental balanced REML cells for sigma-phylo/q4, but it is not yet a
> promoted bridge answer. For Ayumi's one-observation-per-tip data, scale-side
> phylogenetic random fields are weakly identified, so Model A or a
> sensitivity-checked MAP route may be scientifically better than forcing a
> fully coupled q4 ML/REML model.

That wording must be revised only after the slice evidence is refreshed.

## Execution Update: A071-A080

A071-A080 are banked in
`docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`. The inference wave
adds `docs/dev-log/dashboard/ayumi-inference-coverage-ledger.tsv` and
`docs/dev-log/dashboard/ayumi-boundary-status-ledger.tsv`, summarized in
`docs/design/203-ayumi-inference-gap-ledger.md`.

The current inference answer is stricter than the fit answer. Native ML exposes
several direct phylogenetic SD targets, but most coverage statuses remain
`not_evaluated`. Native q4 ML remains diagnostic: 30-tip bootstrap is plumbing,
100-tip bootstrap is negative, and 250-tip profile-budget evidence is a returned
failure status. Direct DRM.jl has q4 profile/bootstrap machinery, but prior
direct bootstrap evidence records scale-axis undercoverage, and no R bridge
promotion follows from direct Julia source availability.

## Execution Update: A081-A090

A081-A090 are banked in
`docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`. The literature and
docs wave added `docs/design/204-ayumi-literature-docs-summary.md`, synchronized
the formula grammar, README current-boundary prose, and known-limitations note,
and kept the applied-user guidance local rather than adding a public vignette.

The external motivation check used the public location-scale tutorial as a
reader map only. It does not turn `brms` posterior workflows or PC-prior/MAP
references into drmTMB interval evidence. The concrete data-design point is
unchanged: one observation per tip makes scale-side phylogenetic fields weakly
identified, so Model A+ remains the run-now analysis while q4 and direct Julia
interval machinery stay diagnostic or experimental.

## Execution Update: A091-A099

A091-A099 are banked or blocked in
`docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`. The reply-prep
wave added `docs/design/205-ayumi-reply-readiness-gate.md` instead of a reply
draft. A091-A098 are banked as evidence sections, unresolved blockers, run-now
choices, review audits, and the maintainer approval gate. A099 remains blocked
because this lane forbids drafting or posting an Ayumi issue reply without
explicit approval.

## Execution Update: A100

A100 is banked in
`docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`. The closeout report
is `docs/dev-log/after-task/2026-06-22-ayumi-phylo-balance-100-closeout.md`.
The next action is not a public reply; it is either maintainer review/commit
packaging or an explicitly approved Ayumi reply task.
