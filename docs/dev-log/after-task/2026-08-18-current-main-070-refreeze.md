# After Task: drmTMB 0.7.0 current-main candidate re-freeze

## 1. Goal

Replace the obsolete `5153ae7e…` release candidate with a clean, immutable candidate built from
current `main`, then collect the self-serve release evidence without submitting to CRAN or claiming
an unearned release rung.

## 2. Implemented

PR #1073 was allowed to merge only after its real Ubuntu package-check job passed. Source commit
`12a5cc5bcc36ed1b83d969e5147e29bc98aaadf6` was then built from a clean checkout as drmTMB 0.7.0.
The immutable tarball has SHA-256
`e9c5556ddf09707f1020099d5d87c6cf419d64f14d00c81ccd4931708d4d485b`, size 10,090,216 bytes,
and 962 archive entries. It earned `tarball-clean`, then failed the cumulative
Gate 7 review and is now retained as a rejected historical candidate.

The candidate was uploaded independently to win-builder R-release, R-devel, and R-oldrelease.
Every transfer returned FTP `226`; these are client-side chain-of-custody receipts, not server-side
hash attestations. The R-devel result is now filed at `Status: 1 NOTE`, with its result URL,
`00check.log`, raw `testthat.Rout`, and a maintainer-mailbox screenshot. The screenshot is an
email-view receipt rather than raw MIME. The R-release 4.6.1 result is also filed at
`Status: 1 NOTE`, with its result URL, `00check.log`, raw `testthat.Rout`, and the
maintainer-supplied email transcript. The R-oldrelease 4.5.3 result is now also filed at
`Status: 1 NOTE`, with its result URL, `00check.log`, raw `testthat.Rout`, and the complete visible
email preserved in a mailbox screenshot. All three arms report `PASS 11403`.

## 3. Mathematical Contract

No model, likelihood, parameterization, estimand, or fitted-package behaviour
changed. The formula-grammar vignette was corrected to describe already
callable 0.7.0 binomial links and ordinary correlated-slope cells.

## 4. Files Touched

The candidate evidence directory under
`docs/dev-log/release/0.7.0-cran-gate/candidate-12a5cc5bc/` records the freeze, local checks,
tarball inventory, URL adjudication, upload receipts, raw CI logs, and a machine-readable evidence
manifest. The predecessor directory
`docs/dev-log/release/0.7.0-cran-gate/candidate-julia-skip-2/` now also contains the newly recovered
R-release result packet, raw R-oldrelease test output, and mailbox-thread screenshot.

The rejected-candidate release ledger and Gate 7 panel report were added.
The Gate 7 repair aligns `DESCRIPTION`, `NEWS.md`, `README.md`,
`_pkgdown.yml`, `inst/COPYRIGHTS`, the introductory/capability/formula
vignettes, and their cross-links. Six heavy reader pages moved under
`vignettes/articles/` as development articles that pkgdown renders but `R CMD
build` does not compile or install. The unverified cheatsheet PNG was removed
from the current tree (and remains recoverable from Git history), and
`tests/testthat/test-release-identity.R` now guards the corrected release
contract.
`cran-comments.md`, PR #1033, and `_julia_skip2_artifacts/` were not changed.
`docs/dev-log/check-log.md` was also left unchanged because file-level lane preflight found active
foreign-ref work on that shared path; this report supplies the repo-visible record without creating
a conflict.

## 5. Checks Run

- A fresh `git fetch origin main` on 2026-08-18 confirmed live `main` remains exactly
  `12a5cc5bcc36ed1b83d969e5147e29bc98aaadf6`; no later source or package-byte drift exists.
- `devtools::document()` produced no source diff; `R CMD build --no-manual` succeeded from a clean
  checkout.
- Exact-byte `R CMD check --as-cran --run-donttest --no-manual`, with
  `R_PROFILE_USER=/dev/null` and `NOT_CRAN=false`, completed with 0 errors, 0 warnings, and the
  expected `New submission` NOTE. testthat reported `FAIL 0 · WARN 52 · SKIP 143 · PASS 11403`.
- A separate same-byte `NOT_CRAN=true` diagnostic completed its larger test surface with
  `FAIL 0 · WARN 70 · SKIP 304 · PASS 21109`; its second NOTE is the expected spelling-output
  comparison from running the non-CRAN spelling path inside `--as-cran`.
- `pkgdown::check_pkgdown()` reported `No problems found.`
- The live URL check returned two publisher/bot-blocked DOI redirects; Crossref independently
  confirmed both DOI registrations.
- GitHub Actions run `32150173003` completed successfully on Windows, Ubuntu, and macOS. The raw
  logs preserve the elapsed-time NOTEs and Ubuntu's Julia temporary-directory NOTE. This is
  same-source evidence, not exact-byte attestation.
- R-hub run `32150223826` is terminal: clang-ASAN, clang-UBSAN, and GCC-ASAN succeeded. `rchk`
  failed with the pre-existing signature: four protection-stack findings confined to installed
  TMB headers, plus analyzer state explosion, and zero protection findings in `drmTMB.cpp`. All
  four raw job logs and the terminal-run screenshot are preserved; the run-level conclusion stays
  failure.
- The current-candidate R-devel Ligges result completed at `Status: 1 NOTE`; raw test output reports
  `FAIL 0 · WARN 99 · SKIP 143 · PASS 11403`. Its expected new-submission NOTE, platform details,
  timings, result index, and mailbox screenshot are preserved.
- The current-candidate R-release 4.6.1 Ligges result completed at `Status: 1 NOTE`; raw test
  output reports `FAIL 0 · WARN 53 · SKIP 143 · PASS 11403`. Its expected new-submission NOTE,
  platform details, timings, result index, and maintainer-supplied email transcript are preserved.
- The current-candidate R-oldrelease 4.5.3 Ligges result completed at `Status: 1 NOTE`; raw test
  output reports `FAIL 0 · WARN 53 · SKIP 143 · PASS 11403`. Its expected new-submission NOTE,
  platform details, timings, result index, and complete visible email screenshot are preserved.
- The predecessor R-release 4.6.1 result at `qOBUstEvxol1` completed at `Status: 1 NOTE`; its raw
  test output reports `FAIL 0 · WARN 53 · SKIP 143 · PASS 11379`. The predecessor R-oldrelease
  raw test output independently reports the same `PASS 11379` signature. These are predecessor
  / Julia-hard-stop evidence only, joined to `5153ae7e…` by client-side chain of custody.
- The archived raw GitHub job logs contain no obvious GitHub token pattern.
- The manifest has 11 fields on every row, every referenced evidence file rehashes to its recorded
  SHA-256, and the immutable tarball rehashes to the frozen digest and size.
- A final repaired-tree probe built successfully at 4,367,966 bytes with
  SHA-256 `e93538606b5b54232d4fcbf0dadb95b87917152754bde88e028401fde346dfd1`;
  it contains 945 archive entries and excludes the six development articles
  from the installed vignette set. An earlier repaired-source probe's exact
  `--as-cran --run-donttest --no-manual` check completed with 0 errors, 0
  warnings, and the expected new-submission NOTE. Installed documentation fell
  from 11.6 MB to 4.7 MB. This is pre-merge repair evidence, not the next
  immutable release candidate.
- A fresh full `pkgdown::build_articles()` rendered the six development
  articles and the standard vignette set successfully. Reader inspection found
  the 0.7.0 banner and corrected formula boundaries in the rendered HTML, and
  `pkgdown::check_pkgdown()` passed afterward.
- A final exact-artifact `--as-cran` rerun installed the package, passed code,
  documentation, examples, and the complete test suite (`FAIL 0 · WARN 52 ·
  SKIP 145 · PASS 11403`). It exceeded its declared seven-minute ceiling while
  re-building vignettes, so it was deliberately terminated and is not recorded
  as a terminal clean check. The earlier exact repaired-source probe remains the
  terminal 0-error/0-warning/1-note local receipt; CI is the next gate for the
  final source layout.
- The release-identity guard passed 10 expectations. A CRAN-mode focused run
  confirmed the existing release filter; a misleading source-mode slow-test
  probe was stopped after exceeding its 6-minute estimate and did not justify
  additional test suppression.

## 6. Tests of the Tests

The new release-identity regression test deliberately reads the independent
DESCRIPTION, README, NEWS, pkgdown, vignette, and development-article surfaces.
It passed 10 expectations on the repaired source tree, including the negative
guard that the unverified PNG is absent. In the installed-package check its two
source-only tests skip explicitly, while the rest of the package suite passes.
The historical exact-byte CRAN lane and the
larger `NOT_CRAN=true` lane exercised the rejected artifact under complementary
skip policies; the 3-OS workflow independently rebuilt and checked that older
package source.

## 8. Consistency Audit

The evidence language was checked for four distinctions: predecessor versus candidate,
same-source versus same-bytes, upload versus result, and `tarball-clean` versus `platform-clean`.
`FREEZE-NOTES.md`, the upload receipt, the machine-readable manifest, the 3-OS receipt, and this
report use those terms consistently. The earlier `5153ae7e…` results remain predecessor and
Julia-hard-stop evidence only.

The initial evidence slice changed no source capability or public
documentation. Gate 7 then found shipped release-identity and formula-guide
contradictions, so a separate source-repair slice now aligns README, NEWS,
DESCRIPTION, the introductory vignette, formula grammar, capability guidance,
and pkgdown navigation before a replacement freeze.

## 3a. Decisions and Rejected Alternatives

The mandatory Rose audit of the inherited Ligges handover classified the release state as follows:

- **DONE:** PR #1072 merged; the `5153ae7e…` upload receipt and R-oldrelease log were filed; the
  predecessor upload has a client-side hash/size chain of custody.
- **OWED at audit time:** predecessor R-release 4.6.1 and R-devel messages; raw test output for any
  precise predecessor pass-count claim; all three current-candidate win-builder result packets.
- **RETRACTED:** the hung `8764b2fe…` upload as release evidence; the `os-matrix` fan-out selector
  as package-check proof; any predecessor-source platform evidence as certification of either
  `5153ae7e…` or the new current-main bytes.
- **PROTECTED:** PR #1033; `_julia_skip2_artifacts/`; submission; `platform-clean`; Gate 7; and any
  release-ledger or `cran-comments.md` rewrite before exact-byte results and a passing gate.

Rose also found that FTP transfer receipts and Ligges result pages must remain separate records,
and that exact test counts require preserved raw test output. Those safeguards are carried into
the new candidate manifest and pending-result checklist.

## 7a. Issue Ledger

No issue was opened, closed, or commented on. PR #1033 is explicitly protected from this lane and
was not inspected or modified.

## 9. What Did Not Go Smoothly

Two sandboxed local checks first failed before package evaluation: the CRAN incoming check could
not resolve external hosts, and the default check output directory was not writable. Both failed
attempts were retained; the real local check was rerun in a writable scratch directory with live
network access. A deliberate `NOT_CRAN=true` diagnostic also exposed a spelling-output NOTE, so the
true CRAN-lane result was rerun with `NOT_CRAN=false` and recorded separately.

The first after-task validation command used a repository-relative validator path that does not
exist, then the hub validator rejected the project template's unnumbered headings. The report was
aligned to the hub's exact 12-section contract and the structure check passed on rerun.

The connected Gmail account is `snakagaw@ualberta.ca`, while the Ligges messages are delivered to
the maintainer Gmail account. A fresh search returned no matching messages. The maintainer then
supplied a screenshot of the current R-devel message, so it is filed honestly as an email-view
receipt; the full raw message and its headers were not invented. The screenshot also contains a
collapsed 09:06 message in the same win-builder thread. Because its body, R arm, URL, and status are
hidden, it is recorded as an unclassified mailbox lead rather than promoted to evidence. The
maintainer later pasted the current R-release message received at 11:56; its visible body is
preserved as a transcript, while the raw MIME message and canonical headers remain absent.

The maintainer subsequently supplied a wider mailbox-thread screenshot. It exposed an R-release
4.6.1 result at `qOBUstEvxol1`. The preserved raw test output reports
`FAIL 0 · WARN 53 · SKIP 143 · PASS 11379`, which identifies it as the `5153ae7e…` predecessor
rather than the current candidate (`PASS 11403`). Its result page, `00check.log`, raw test output,
mailbox screenshot, timings, and hashes are now filed. The screenshot is still an email-view
receipt rather than raw MIME. The still-live predecessor R-oldrelease result page was also revisited
to preserve its missing raw test output; it independently reports the same `PASS 11379` signature.

The maintainer then expanded the 09:06 message. It identified the current-candidate R-oldrelease
result at `EEeKbEEvb3o8`; the downloaded raw output reports `PASS 11403`, decisively separating it
from the predecessor (`PASS 11379`). The maintainer could not recover the predecessor R-devel
message and directed the release lane to move forward. That missing message is therefore recorded
as unavailable, non-gating historical evidence: it cannot certify the current candidate and is
not required for the current artifact's release ladder.

## 11. Team Learning

This candidate uses one TSV manifest that joins its source commit, SHA-256, byte size, upload
window, result URL, raw-evidence path, evidence digest, and disposition. Reusing that structure
for future candidates would make client-side chain of custody inspectable while keeping it visibly
weaker than server attestation.

## 10. Known Residuals

The candidate remains a rejected historical `tarball-clean` artifact. The
executable validator accepted a provisional `platform-clean` ledger, but fresh
Grace, Rose, and Pat review returned three NOT READY votes; Rose identified
semantic defects that the slot-presence validator did not catch. The ledger is
therefore conservatively downgraded and renamed with `e9c5556d-rejected`.
All three Windows result packets remain useful evidence for these bytes only.
Raw MIME for the supplied email views remains provenance debt rather than a
platform gate.

No `submit_cran()` call was made, and no submission is authorized for 2026-08-19.

## 12. Cross-Product Coverage

This slice changed no R/TMB capability and no twin Julia repository. The new candidate includes
the Julia hard-abort already present on current `main`; the earlier `5153ae7e…` Windows result is
retained only as predecessor evidence that the JuliaCall hang was removed. Julia remains an
optional backend, and no claim is transferred to DRM.jl or another package.

This release-evidence slice **does NOT cover** a new fitting engine, family, formula route, REML
provider, penalty, missing-data policy, aggregation rule, estimator, interval, or simulation claim.
It also does NOT certify DRM.jl, gllvmTMB, or any downstream consumer; only drmTMB 0.7.0 source
commit `12a5cc5bc…` and the explicitly named candidate bytes are in scope.

## 13. Next Actions

1. Land the Gate 7 source repair through CI and merge it to `main`.
2. Build a new immutable candidate from that clean merged commit and rerun the
   complete exact-byte, rendered-site, 3-OS, R-hub, and win-builder ladder.
3. Run fresh Grace, Rose, and Pat review, then return the replacement evidence
   packet to Shinichi for a separate submission decision.
