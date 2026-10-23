# After Task: Capability Reader Boundaries

## 1. Goal

Turn the public capability page into a plain guide to what a reader can fit,
report, and use instead when a requested model lies outside the current
boundary. Keep the technical availability and limitations accurate without
showing development identifiers, process labels, generated-table machinery, or
internal paths.

## 2. Implemented

Replaced the internal-status summary, historical tables, generated technical
maps, and process-oriented prose with a reader-first reporting guide. The page
now starts with four reporting questions and uses four plain permissions: point
estimate and interval, point estimate only, feasibility only, and not
available. It retains concrete advice for fixed effects, ordinary slopes,
Gaussian structured models, point-only structured models, REML, association,
and missing data.

The new missing-predictor table states the current Gaussian, negative-binomial,
and one-binary-predictor family boundaries. It also corrects the prior page's
understatement of negative-binomial missing-predictor support: one Gaussian
missing predictor is available as well as one binary predictor.

## 3a. Decisions and Rejected Alternatives

The page no longer embeds generated capability summary and map fragments. They
are internal maintenance surfaces and made the public page read like a
development report. A compact, hand-written support guide was chosen instead,
with family-specific boundaries and fallbacks retained in prose.

Reintroducing the phrase required by a legacy test, `Supported (legacy ledger
label)`, was rejected because it would restore precisely the internal jargon
removed from the rendered reader page. Updating that test was also rejected:
file-specific lane preflight found active work on its file in 22 non-main refs.

## 4. Files Touched

- `vignettes/capability-and-limits.Rmd`
- `docs/dev-log/after-task/2026-09-18-capability-reader-boundaries.md`

## 5. Checks Run

- Isolated worktree created from `origin/main` on
  `codex/capability-reader-boundaries-20260918`: PASS.
- Lane lease for the vignette and this receipt: GRANTED.
- `Rscript -e 'rmarkdown::render(...)'`: PASS in 2.2 seconds; output written
  outside the repository under `/private/tmp/`.
- Parsed rendered HTML and required section-heading check: PASS.
- Rendered-HTML scan for internal identifiers, campaign/stage/ledger language,
  repository paths, machine labels, and issue references: PASS; matches were
  stylesheet tokens only, not reader text.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/check-reader-contracts.R`: PASS (`Reader vignette contract: OK`).
- `git diff --check`: PASS.

## 6. Tests of the Tests

The focused source assertion
`CapabilityLedgerTests.test_capability_article_has_reporting_rule_and_stable_terms`
was run. It fails only at `tools/tests/test_capability_ledger.py:1398`, which
requires the removed internal phrase `Supported (legacy ledger label)`. The
rendered-page heading assertion and reader-contract linter independently show
that the replacement page exists and remains a reader vignette. The contested
test file was not edited because preflight found overlapping work.

## 7a. Issue Ledger

No issue, pull request, commit, push, merge, release, or deployment was
created. GitHub's API was unavailable during the initial collision check, so
the named PRs could not be independently inspected from this lane. Local refs
contained no heads for those PR numbers; the newest local vignette change was
an unrelated older `beta_family()` naming edit.

## 8. Consistency Audit

The rewrite retains concrete public boundaries rather than deleting them:

- fixed-effect binomial, Poisson, negative-binomial, strict beta, and Gaussian
  support, including the strict-beta-to-zero-one-beta fallback;
- profile-only, maximum-likelihood independent slopes for the named
  non-Gaussian families;
- Gaussian structured and exact spatial/animal/relatedness REML forms;
- point-only structured Poisson and negative-binomial mean effects;
- fit-specific association and `rho12` interval limitations; and
- response masking and the narrowed missing-predictor surface.

No package API, likelihood, estimator, generated include, source code, test,
workflow, release note, bridge implementation, or Pages artefact changed.

## 9. What Did Not Go Smoothly

The capability test was written against a now-removed internal label. Its
single failed assertion is not a rendering or reader-contract failure, but its
file has active overlapping work, so a scoped expectation update is unsafe in
this lane. The GitHub API also failed during the requested PR collision check;
local-ref and diff inspection were used instead.

## 10. Known Residuals

The one stale source assertion remains red until its owning lane can update the
expected reader-facing phrase. The page is locally rendered and inspected but
has not been committed, pushed, built as a full site, or deployed. No public
capability claim is widened by this rewrite.

## 11. Team Learning

Reader-facing capability pages should state the available model and the
reporting boundary in the same sentence. Internal classification names and
generated inventory tables belong in maintenance material; they obscure the
decision an applied reader actually needs to make. When such a cleanup exposes
a stale test, file-level preflight must decide whether a one-line test repair is
safe before editing it.

Memory receipt: `route.py` was run for drmTMB but found no LOAD-FIRST manifest;
the DRM.jl operating contract, lane preflight, lane lease, and reader-contract
guard shaped this work. The route result and local repository sources, rather
than unverified recollection, were used for the capability statements.

Golden Set: not in scope. This source-only documentation slice changed neither
model behaviour nor a known-mistake code path; the reader-contract linter and
rendered-text scan were the relevant guards.

## 12. Cross-Product Coverage

This documentation slice covers ✓ the public source vignette, its local HTML
render, and its reader-contract scan. It does NOT cover package behaviour,
family implementations, likelihoods, estimators, formula syntax, generated
capability includes, Julia bridge implementation, tests owned by another lane,
CI, release status, Pages deployment, commits, pushes, pull requests, or
merges.
