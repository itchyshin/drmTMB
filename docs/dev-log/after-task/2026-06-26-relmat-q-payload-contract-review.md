# After Task: Relmat Q Payload Contract Review

## 1. Goal

Turn the relmat `Q` precision bridge next-gate from an unreviewed payload
marshalling requirement into a checked contract-review sidecar. The goal was to
fix the exact Q-specific payload identity, level, coefficient, provenance, and
fail-closed policies before any direct DRM.jl or R-via-Julia bridge transport
work.

## 2. Implemented

The implemented claim is deliberately narrow: the relmat `Q` payload contract
has been reviewed for six exact one-slope cells, but relmat `Q` bridge
implementation remains unsupported.

- Added `docs/dev-log/dashboard/structured-re-relmat-q-payload-contract-review.tsv`
  with six rows matching the relmat `K/Q` bridge-boundary and
  payload-marshalling gate cells.
- Regenerated
  `docs/dev-log/dashboard/structured-re-relmat-q-payload-marshalling-gate.tsv`
  so the gate now points to the reviewed contract sidecar and stays blocked on
  exact Q transport.
- Added generator helpers in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R` and the runner
  `tools/run-structured-re-relmat-q-payload-contract-review.R`.
- Updated mission-control validation and dashboard contract tests so the
  contract rows, gate rows, bridge-boundary rows, and q-series support cells
  remain synchronized.
- Updated `docs/dev-log/dashboard/README.md`,
  `docs/design/218-structured-q-series-completion-map.md`, and
  `docs/dev-log/check-log.md`.

## 3. Mathematical Contract

No likelihood, TMB parameterization, formula grammar, estimator, interval
method, or runtime bridge behavior changed. The reviewed contract is a payload
identity and provenance contract:

```text
Q precision input
  -> stable payload id
  -> digest of the user-supplied precision matrix without inversion
  -> observed-level alignment and fail-closed missing-level policy
  -> endpoint/member coefficient order
  -> provenance for formula cell, input scale, levels, digest, branch, and head
```

The contract rejects implicit `Q -> K` conversion in the R bridge payload.
Native R/TMB K/Q same-target parity remains runtime evidence only, not bridge
implementation evidence.

## 3a. Decisions and Rejected Alternatives

The accepted route was to bank the reviewed contract before implementing any
transport code.

Rejected alternatives:

- Do not treat the reviewed contract as direct DRM.jl, R-via-Julia, or R bridge
  `Q` support.
- Do not treat native `Q` point-fit parity as bridge implementation.
- Do not promote broad bridge support, public support, interval reliability,
  interval coverage, REML, AI-REML, q4 REML, native-TMB q4 REML, HSquared
  AI-REML, non-Gaussian REML, or broader q8 support.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-relmat-q-payload-contract-review.tsv`
- `docs/dev-log/dashboard/structured-re-relmat-q-payload-marshalling-gate.tsv`
- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tools/run-structured-re-relmat-q-payload-contract-review.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-26-relmat-q-payload-contract-review.md`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-relmat-q-payload-contract-review.R`
  passed and wrote six payload-contract rows plus six updated
  payload-marshalling gate rows.
- `air format inst/sim/R/sim_structured_re_bridge_fixtures.R tools/run-structured-re-relmat-q-payload-contract-review.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `git diff --check` passed.
- `python3 tools/validate-mission-control.py` passed and reported 6 relmat `Q`
  payload-contract review rows.
- `Rscript --vanilla -e 'source("inst/sim/R/sim_structured_re_bridge_fixtures.R"); contract <- phase18_structured_re_relmat_q_payload_contract_review(); gate <- phase18_structured_re_relmat_q_payload_marshalling_gate(); stopifnot(nrow(contract) == 6L, nrow(gate) == 6L, identical(gate$gate_id, contract$gate_id), all(contract$payload_schema_status == "contract_reviewed"), all(contract$payload_review_status == "reviewed_not_implemented"), all(contract$bridge_q_status == "unsupported"), all(contract$acceptance_status == "blocked_pending_exact_q_transport"))'`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  could not run because `devtools` is absent from the local R library.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"`
  could not run because `testthat` is absent from the local R library.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-relmat-q-payload-contract-review.md')"`
  passed.

## 6. Tests of the Tests

The dashboard contract test checks the six reviewed contract rows against the
payload-marshalling gate, relmat `K/Q` bridge-boundary sidecar, and q-series
support-cell table. It also locks each coefficient-order policy:

- q1 `mu`: `mu:(Intercept);mu:x`
- q1 `sigma`: `sigma:(Intercept);sigma:x`
- matched q1 `mu+sigma`: `mu:(Intercept);mu:x;sigma:(Intercept);sigma:x`
- q2 `mu1+mu2`: `mu1:x;mu2:x`
- q4 location `mu1+mu2`: `mu1:(Intercept);mu1:x;mu2:(Intercept);mu2:x`
- q8-shaped all-four:
  `mu1:(Intercept);mu1:x;mu2:(Intercept);mu2:x;sigma1:(Intercept);sigma1:x;sigma2:(Intercept);sigma2:x`

The mission-control validator repeats the same checks and additionally locks
the exact Q payload policy strings. This makes the sidecar fail closed if a
future edit moves a relmat `Q` bridge status without implementing and testing
the exact transport.

## 7a. Issue Ledger

Open issue searches used:

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "relmat Q payload contract" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "relmat Q payload marshalling" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "structured random effect relmat Q" --limit 20 --json number,title,state,url,labels
```

The first two searches returned no dedicated relmat `Q` payload issue. The
third search returned the broader open structured-effect umbrellas, including
#147 and #33. I did not post a new issue comment because this draft PR is a
contract-review slice and does not change public support.

## 8. Consistency Audit

Status-inventory and stale-claim scans used:

```sh
rg -n "relmat Q.*(bridge support|supported|inference-ready|coverage-ready)|direct DRM\\.jl Q.*(supported|available)|R-via-Julia Q.*(supported|available)|payload.*(interval reliability|coverage accepted|q4 REML|AI-REML)|bridge_q_status\\s*.*supported|direct_drmjl_q_status\\s*.*supported|r_via_julia_q_status\\s*.*supported" README.md ROADMAP.md NEWS.md docs vignettes R tests
rg -n "bridge_q_status\\s*.*\\bsupported\\b|direct_drmjl_q_status\\s*.*\\bsupported\\b|r_via_julia_q_status\\s*.*\\bsupported\\b|relmat Q.*\\bbridge support\\b|relmat Q.*\\bsupported\\b|direct DRM\\.jl Q.*\\bavailable\\b|R-via-Julia Q.*\\bavailable\\b|payload.*\\bcoverage accepted\\b" README.md ROADMAP.md NEWS.md docs vignettes R tests
```

The broad scan mostly found intended `unsupported` and boundary text. The
tighter word-boundary scan found existing negative or historical boundary
contexts, including NEWS, prior PR-stack snapshots, and dashboard text. It did
not reveal a new positive relmat `Q` bridge support, interval coverage, REML,
AI-REML, or public-support claim from this slice.

## 9. What Did Not Go Smoothly

The main care point was separating three adjacent facts: native R/TMB K/Q
runtime parity exists for these cells, the payload contract is now reviewed,
and relmat `Q` bridge implementation is still unsupported.

## 10. Known Residuals

This task does not implement relmat `Q` payload transport, direct DRM.jl `Q`
export, R-via-Julia `Q` transport, broad bridge support, public support,
interval reliability, interval coverage, q4 REML, native-TMB q4 REML, q4
AI-REML, HSquared AI-REML, non-Gaussian REML, broader q8 support, DRAC/Totoro
execution, SR150 coverage readiness, PR undrafting/merging, or an Ayumi-facing
reply.

## 11. Team Learning

For provider variants where runtime parity and bridge transport can be
confused, review the payload contract as its own support-cell companion before
writing transport code. This keeps the next implementation slice small and
prevents runtime evidence from leaking into bridge-support language.

## 12. Next Actions

After this slice is banked, implement exact relmat `Q` payload transport only
against the reviewed contract: Q precision source, matrix digest, level
alignment, missing-level policy, coefficient order, and provenance. Keep direct
DRM.jl and R-via-Julia `Q` status unsupported until that code and its tests are
present.
