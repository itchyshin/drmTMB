# After Task: Lane-B E0 interval campaign readiness

## 1. Goal

Prepare the Lane-B `sd()`/interval campaign as a reproducible, local-only,
fail-closed packet after Arc D Designs 1 and 2, and stop before any
DRAC/Totoro pregrid or array.

## 2. Implemented

The internal readiness module freezes the 159-row model-surface census,
requires reviewed cell × target × DGP bindings before scheduling, retains
K=12 as unavailable negative evidence, records local technical smoke outcomes,
and always reports `pregrid_authorized = FALSE` for the current partial packet.

## 3a. Decisions and Rejected Alternatives

The primary channel is a direct profile-likelihood interval for the named
target. Coverage is `covered / all scheduled attempts`; unavailable statuses
(`profile_failed`, `clamp_limited`, `trace_incomplete`, and
`nonfinite_interval`) are non-covering. K=12 is only the `mc-0260m` meta-V
control, not a structured `q12` block, and a finite K=12 profile is an error.
No likelihood, formula grammar, or public inference contract changed.

## 4. Files Touched

- `inst/sim/R/sim_interval_campaign_readiness.R`: manifest, contracts,
  binding/receipt provenance, all-attempt reducer, and packet writer.
- `tests/testthat/test-interval-campaign-readiness.R`: frozen-cohort,
  malformed-provenance, unknown-status, K=12, and packet-boundary tests.
- `docs/dev-log/interval-campaign-bindings/`: reviewed partial bindings and
  retained local smoke receipts.
- `tools/verify-lane-b-e0-readiness.R`: one-command local mechanical check.
- `docs/dev-log/2026-07-27-lane-b-e0-*.md`: prerequisite and readiness
  receipts plus binding-recovery narrative.

## 5. Checks Run

- GitHub prerequisites: [PR #856](https://github.com/itchyshin/drmTMB/pull/856)
  and [PR #857](https://github.com/itchyshin/drmTMB/pull/857) are merged; both
  Ubuntu release checks succeeded.
- `Rscript tools/verify-lane-b-e0-readiness.R`:
  158 Lane-B target cells, 62 recovered target bindings, 2 K=12 target rows,
  97 unresolved cells, and `pregrid_authorized=FALSE`.
- `devtools::test(filter = "(interval-campaign-readiness|arc-d-profile-trace|arc-d-sd-overflow-guard)")`:
  passed.
- `git diff --check`: passed.

The full package suite and site build were not rerun: this is an internal
readiness/plumbing change with no R API, roxygen, vignette, or reader-surface
change. Focused tests cover the touched code paths and explicit failure paths.

## 6. Tests of the Tests

The targeted suite rejects a substituted frozen ID, a blank binding source,
an invented successful smoke target, a malformed finite receipt, an unknown
attempt status, a trace-incomplete inconsistency, a finite K=12 attempt, and
a direct packet-writer call that bypasses a blank-provenance partial table.

## 8. Consistency Audit

Ran:

```sh
rg -n 'pregrid_authorized|K=12|K12|clamp_limited|trace_incomplete|interval campaign|coverage campaign' \
  README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes _pkgdown.yml
git diff --name-only origin/main...HEAD
```

The results show existing historical coverage/design records, including the
Arc D K=12 contract; none conflicts with E0's internal, no-compute claim.
The branch diff is limited to E0 plumbing, tests, internal receipts/bindings,
and its verifier. No association, bootstrap, missing-response, capability
ledger, public/default, or compute change occurred.

## 7a. Issue Ledger

Inspected open interval/profile/clamp issues. Existing #59 (simulation
framework), #682 (profile-likelihood method), #710 (numerical guards), and
#802 (association coverage) cover the surrounding work; E0 creates no new
user-facing defect or campaign result, so no duplicate issue or comment was
opened.

## 9. What Did Not Go Smoothly

The initial receipt validator checked only cohort membership and a namespaced
ID, allowing an invented successful target/DGP; the packet writer also had a
raw-partial-binding provenance bypass. Independent Fisher/Rose review caught
both. The final shared validator now closes both paths and the tests reproduce
the former bypasses as errors.

## 11. Team Learning

For campaign plumbing, a receipt is evidence only when it is joined to a
reviewed cell × target × DGP binding. Status labels also need a closed
vocabulary, retained reason, and trace-completeness field; otherwise an
all-attempt denominator can preserve the count while losing the diagnosis.

## 10. Known Residuals

This is not compute-ready. The packet has 62 recovered target bindings and
97 cells without an exact replayable DGP/profile contract. All 21 exact
estimand strata remain `pregrid_eligible = FALSE`; no coverage, availability,
or capability conclusion follows from the local smokes. K=12 remains negative
evidence.

## 12. Cross-Product Coverage

This arc does NOT cover association (`rho12`), bootstrap, missing response,
capability-ledger changes, public/default behavior, or any remote compute. It
does NOT make profile intervals coverage-calibrated, nor does it transfer a
recovered target across family, estimator, provider, q, endpoint, slope, or
information rung. It covers only the internal campaign plumbing, receipts,
and local technical-smoke schema. Stop here. A future request must first
review/complete the remaining exact
bindings, then present a separate DRAC/Totoro pregrid packet with source SHA,
manifest/contract hashes, 150-attempt schedule, resources, output location,
validation command, and the no-ledger boundary. Remote compute requires
Shinichi's explicit approval.
