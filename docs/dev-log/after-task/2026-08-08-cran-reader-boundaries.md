# After Task: CRAN reader boundaries and current-main preflight (2026-08-08)

## 1. Goal

Replace the public roadmap with a reader-first, ledger-backed explanation of
what users can fit and report; verify that surface live; then build and check
one exact current-main `0.6.0` tarball without advancing beyond
`tarball-clean`.

## 2. Implemented

M1 added **Can I fit and report this model?** at the stable
`articles/capability-and-limits.html` URL. It gives separate answers for fit,
point reporting, a named interval, exact tested scope, and a concrete fallback.
The page consumes a generated capability-ledger summary, defines the public
terms at first use, and keeps internal cell/evidence vocabulary below the
decision surface. The root roadmap moved verbatim to
`docs/dev-log/internal-roadmap.md`; the former public URL now redirects one hop
to the capability page. Navigation, homepage, getting-started, current design
pointers, and guards were updated.

M2 froze source commit
`ad475cc39f62f47a346c77aa17c3d20bf3fc9bae`, built one exact
`drmTMB_0.6.0.tar.gz`, ran the local CRAN-shaped check, independently verified
its identity and tarball-only article rendering, and refreshed only
build-excluded release governance. No installed package byte changed after the
freeze.

## 3a. Decisions and Rejected Alternatives

The public surface reports permissions instead of exposing internal evidence
tiers as the decision rule. Selected exact scopes are bound to canonical-ledger
fingerprints; hand-maintained public census counts were rejected because they
would drift. A one-hop redirect was chosen instead of retaining a duplicate
public roadmap body. A current `0.6.0` preflight was chosen instead of a
disposable platform campaign because the later real `0.7.0` candidate would be
a different installed artifact.

No likelihood, estimator, parameterization, formula grammar, public R API, or
simulation changed. `mu`, `sigma`, `nu`, `rho12`, `sd(group)`, `phylo()`,
`spatial()`, and `meta_V(V = V)` retain their established meanings;
`meta_known_V(V = V)` appears only as a deprecated alias. Advancing to
`platform-clean`, bumping DESCRIPTION, and uploading were explicitly rejected
as unauthorized and unsupported by exact-artifact evidence.

## 4. Files Touched

- Public source: `_pkgdown.yml`, `README.md`,
  `vignettes/capability-and-limits.Rmd`, the getting-started and neighboring
  reader articles, and current learning-path/design pointers.
- Generated/guarded source: `tools/capability_ledger.py`, its tests,
  `vignettes/includes/capability-ledger-summary.md`, roadmap/path guards, and
  `.Rbuildignore`.
- Roadmap: root `ROADMAP.md` removed; content preserved at
  `docs/dev-log/internal-roadmap.md`; old public URL redirect generated through
  pkgdown infrastructure.
- Governance: release ledger, exact check logs, inventory, hash, size, freeze
  note, check log, this report, plan-vs-actual reconciliation, and handover.

## 5. Checks Run

- Capability generator `--check`: PASS, 31 outputs.
- Capability-ledger unit suite: PASS, 64 tests; focused canonical
  claim-boundary mutation fails closed.
- Full `devtools::test()`: PASS, 0 failures; 25 expected skips and 72 expected
  warnings.
- Source-installed non-lazy pkgdown build and `pkgdown::check_pkgdown()`: PASS.
- Q-series public-claim guard: PASS.
- Clean extracted-source capability render: PASS without `docs/dev-log`,
  `tools`, scratch paths, or checkout-only generation.
- Pat: PASS for inference-ready, recovery-only, unsupported, and `meta_V()`
  reader journeys in no more than two clicks.
- Florence: PASS for desktop/mobile navigation, hierarchy, tables, caveats,
  anchors, and overflow.
- Grace: PASS for selected canonical-ledger agreement, freshness, redirect,
  installed-source rendering, and package boundary.
- Rose: PASS after stale counts, terminology, fallbacks, exact-scope wording,
  current internal pointers, and contributor links were repaired.
- PR #948 CI: Ubuntu R-CMD-check run `31264733439` PASS. Post-merge main
  R-CMD-check run `31266713858` PASS. Pkgdown/Pages run `31268615909` PASS.
- Live byte and visual audit: homepage links capability; capability title is
  present; `ROADMAP.html` has exactly one refresh/canonical hop; search and
  sitemap contain capability and no roadmap body; operational snapshots return
  404.
- Exact tarball SHA-256
  `2e5234bd4bf819663e9ef95f10a1944d51c90ce64ffd5dd7a9641b69fa50c5ea`,
  size 9,831,204 bytes, 922 entries.
- Exact `R CMD check --as-cran --run-donttest`: 0 ERROR, 0 WARNING, 1 NOTE
  (`New submission` only). Installation, examples, tests, vignette rebuild,
  PDF/HTML manuals, and cleanup passed.
- CRAN release-gate validator: `READY FOR CLAIMED RUNG` at
  **`tarball-clean`**.

## 6. Tests of the Tests

Grace mutated a selected canonical ledger cell's claim boundary in memory; the
public projection rejected it as stale. Unsupported public rows are required to
carry concrete fallbacks, and every displayed route must populate all five
reader fields. The first strict Luna tarball-render audit was deliberately
read-only and therefore failed when it could not create an extraction directory;
that FAIL was retained. A second verifier received write access only under
`/private/tmp`, extracted the tarball afresh, and rendered the article from its
packaged inputs. The resulting HTML SHA-256 was
`0cff046d1211e5b0c9baf442653d88e3854573643579ba9d27b469f571d9edbc`.

## 7a. Issue Ledger

- #948: reader-boundary implementation, reviewed, green, merged, and deployed.
- #858, #937, #947: out of scope and untouched.
- Introduced stale counts, terminology, contributor links, and roadmap-path
  references: found during review and repaired before merge.
- Mission Control's 17 inherited DRM.jl/evidence failures: disclosed and
  deferred; no roadmap-path regression remains.
- The first sandbox-DNS check attempt and strict-read-only extraction attempt:
  retained as failed attempts; resolved by narrower permissions without
  changing the artifact.

## 8. Consistency Audit

The deployed navigation order, article index, redirect, search index, sitemap,
and first-screen schema agree with the locked plan. The internal roadmap move
is byte-identical. Public mutable capability counts and dates were removed or
generated. The tarball includes the capability article and generated summary
and excludes the internal roadmap, `docs/dev-log`, tools, scratch paths,
pkgdown-site, VCS metadata, AGENTS, and CLAUDE.

Mission Control validation still reports 17 inherited DRM.jl/evidence-count
failures; the roadmap-path and README regressions introduced during this work
are resolved. These inherited failures neither changed package bytes nor
support a higher release claim.

Memory receipt: the routed drmTMB manifest, exact-artifact release discipline,
reader-first prose rules, validation-harness discipline, and CRAN release gate
shaped this work. Memory recall supplied the frozen-artifact and exact-candidate
requirements.

Golden Set: no known-mistake class required a Golden Set run; the scoped
canonical-ledger mutation test served as the relevant test-of-test. No brain
vault write was authorized or made.

The dirty primary `claude/handover-freshness-0718` checkout and all foreign
worktrees/stashes were preserved.

## 9. What Did Not Go Smoothly

`origin/main` advanced after planning, so the clean reader lane was rebased onto
the current base before implementation. The first exact check attempt was
blocked before installation by sandbox DNS; it was preserved, then the exact
same tarball was checked with network access. A harmless unsupported
`--check-subdir` option was supplied on the successful rerun; R ignored it and
the recorded effective options were `--as-cran --run-donttest`. The build timing
wrapper exited after a successful build because sandboxed macOS denied
`sysctl kern.clockrate`; artifact creation and identity were verified directly.

Two full Ubuntu checks each took about 46 minutes. The visual audit also needed
a live deployment because the first local browser endpoint was not listening.

## 10. Known Residuals

This exact tarball has no same-artifact Windows, sanitizer, R-hub, or 3-OS
platform campaign. Earlier Windows/platform results are predecessor evidence
only. The historical 29–30 minute Windows test behavior remains a risk for the
future real candidate. The single NOTE is expected for a new submission but
must still be addressed in future submission paperwork. DESCRIPTION remains
0.6.0.

Stop here. Highest proven rung is **`tarball-clean`** for exact artifact
`2e5234bd…`. The next unproven rung is **`platform-clean`**, deliberately
deferred until Shinichi authorizes a real `0.7.0` candidate. Start a fresh task
for that milestone; ask before changing DESCRIPTION or writing
`platform-clean`. Do not finalize `cran-comments.md` or upload without separate
explicit authorization.

## 11. Team Learning

A reader-facing capability surface needs permissions, not merely a compact copy
of internal evidence tiers. Binding each selected scope to a canonical-ledger
fingerprint provides an economical freshness guard while keeping the public
cards readable. A one-hop redirect is preferable to retaining a second public
roadmap body, and extracted-tarball rendering is the decisive proof that a
vignette does not depend on checkout-only governance.

## 12. Cross-Product Coverage

- Covers ✓ the public capability page, homepage and getting-started routes,
  navbar/article index, old-roadmap redirect, search, sitemap, packaged vignette
  inputs, and build-excluded release receipt.
- Covers ✓ the displayed inference-ready, recovery-only, unsupported,
  `meta_V(V = V)`, and `rho12` reader journeys against selected canonical cells.
- This task **does NOT cover** new families, estimators, likelihoods, formula
  grammar, simulations, recovery/coverage evidence, AGHQ, REML, or package API.
- This task **does NOT cover** same-artifact Windows, sanitizer, R-hub, or 3-OS
  platform evidence; therefore it does not establish `platform-clean`.
- This task **does NOT cover** DESCRIPTION 0.7.0, final `cran-comments.md`, D-43,
  submission readiness, or CRAN upload.
