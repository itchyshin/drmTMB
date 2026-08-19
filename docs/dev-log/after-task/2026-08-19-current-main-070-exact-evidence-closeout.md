# After Task: Current-main 0.7.0 exact-evidence closeout

## 1. Goal

Replace predecessor candidate evidence with one immutable 0.7.0 tarball from
the selected current-main source, complete the exact-artifact platform ladder,
run a fresh Grace/Rose/Pat gate, and stop before submission.

## 2. Implemented

The final candidate is source
`6170fbeeea65f22444d7b0934f4e808c40744d22`, SHA-256
`1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`,
4,368,396 bytes, with 946 entries. The complete checksummed packet is tracked
under `candidate-6170fbeee/` and copied beside the read-only artifact. The three
`5153ae7e…` Ligges arms and later rejected candidates remain predecessor
evidence. The ledger now proves `submission-ready` after unanimous Grace,
Rose, and Pat votes. No CRAN submission was made.

## 3a. Decisions and Rejected Alternatives

No likelihood, parameterization, formula grammar, estimator, or inferential
claim changed in this closeout. The candidate's mathematical contract is the
one already tested at source `6170fbeee`; this task only collected and
classified evidence for those immutable bytes.

The team rejected `5153ae7e…` and `6b45164b…` as final candidates rather than
borrowing their platform results. It also rejected a last-minute C++ cleanup of
the unused `sigma_i` locals because that would change and invalidate the frozen
bytes without correcting observed behavior. The win-builder PNG NOTE was
adjudicated with a clean exact-byte recheck rather than guessed away or repaired
in source where the URL does not exist.

## 4. Files Touched

- `cran-comments.md` now identifies the final artifact and distinguishes
  exact-byte checks from exact-source CI.
- `docs/dev-log/release/0.7.0-cran-gate/candidate-6170fbeee/` contains local,
  win-builder, 3-OS, sanitizer, rchk, inventory, custody, timing, rights, site,
  and stale-URL receipts.
- `docs/dev-log/release-audits/2026-08-19-070-cran-release-ledger-1d6445db.json`
  is the executable release ledger.
- `docs/dev-log/release-audits/2026-08-19-070-gate7-panel-1d6445db.md` records
  both panel rounds.
- `AGENTS.md`, the coordination board, active-lane split, and dated Ligges
  handover now point to the final candidate and preserve protected boundaries.
- Predecessor packets and the final owed `5153ae7e…` R-devel result were filed
  without changing their historical classification.

## 5. Checks Run

- Exact artifact rehash: `1d6445db…` matched; size 4,368,396; 946 entries.
- Local exact-byte `R CMD check --as-cran --run-donttest --no-manual`: 0 ERROR,
  0 WARNING, 1 expected New submission NOTE; tests 45 seconds.
- Exact-byte win-builder R-devel, R-release 4.6.1, and R-oldrelease 4.5.3:
  0 ERROR, 0 WARNING, 1 NOTE each; 3,501 tests pass; 110–152 seconds.
- Exact-source 3-OS CI: macOS, Ubuntu, and Windows pass with `NOT_CRAN=true`.
- R-hub: clang-ASAN, clang-UBSAN, and GCC-ASAN pass. `rchk` remains red with
  findings confined to installed TMB headers and none citing `drmTMB.cpp`.
- Evidence integrity: all 69 manifest entries pass in both repository and
  durable copies and compare byte-identically.
- Executable release gate at `submission-ready`: `READY FOR CLAIMED RUNG`.
- Fresh panel: Grace READY; Rose READY after governance/durability repair; Pat
  READY after exact-tarball install and a 1.4-second first-workflow fit.
- PR #1076's real Ubuntu release job is the final landing check; its result is
  recorded before merge.

## 6. Tests of the Tests

The gate self-test includes a negative control that withholds higher rungs when
required evidence or panel votes are absent. This task also exercised the
negative path directly: the ledger remained at `platform-clean` with Rose
`NOT_READY`, then promoted only after her fresh second audit. Pat tested an
unsupported Poisson `REML = TRUE` request and received the intended actionable
error rather than only exercising a successful fit.

## 8. Consistency Audit

The exact reader-surface searches were:

```sh
rg -n '0\.6\.0|v0\.5\.0|0\.7\.0\.9000|not in the frozen tarball|all (required )?dependencies.*CRAN|drmTMB.*CRAN' README.md NEWS.md _pkgdown.yml vignettes inst cran-comments.md
rg -n '5153ae7e|6b45164b|1d6445db|6170fbeee|platform-clean|submission-ready' AGENTS.md docs/dev-log/handover/2026-08-18-codex-handover.md docs/dev-log/coordination-board.md docs/dev-log/release-audits cran-comments.md
rg -n 'function-map-cheatsheet\.png|articles/function-map-cheatsheet' README.md NEWS.md _pkgdown.yml R src tests vignettes inst
```

Historical NEWS entries remain dated history. Current README, NEWS, trust
dossier, installed help, comments, ledger, and governance agree that 0.7.0 has
not been submitted or accepted. The stale PNG URL is absent from candidate
source, tarball, and returned binary; a clean network-enabled exact-byte recheck
while the URL returned 404 produced no URL NOTE. The inferred win-builder
workspace/cache mechanism is labelled inference, not server attestation.

No design document, formula grammar, roadmap, known-limitation, generated
documentation, or pkgdown source needed a behavior update. The rendered site
was inspected from the frozen installed artifact and is recorded in the packet.

## 7a. Issue Ledger

Open issue #61 is the existing CRAN-readiness umbrella. This closeout does not
close it because submission and acceptance remain separate external decisions.
No duplicate issue was opened. PR #1033 was not read, modified, commented on,
or merged.

## 9. What Did Not Go Smoothly

Two predecessor candidates reached strong platform evidence before reader or
timing contradictions forced another cut. Win-builder R-devel/release echoed a
stale PNG URL absent from the final candidate, requiring a clean network-enabled
recheck and careful non-attestation wording. The evidence manifest was briefly
read during regeneration, causing one transient mismatch; it passed twice once
frozen. Rose then caught that governance still described completed work as
future work and that the full packet was not yet durable. Raw server logs also
retain original trailing whitespace, so authored-file diff checks were run
separately rather than rewriting evidence bytes.

## 11. Team Learning

Release identity has four coupled surfaces: candidate bytes, the machine ledger,
the evidence packet, and governance entrypoints. A future submission-ready guard
should fail unless every current governance entrypoint names the source SHA,
artifact hash, and rung, and every ledger `repo_path` is tracked and included in
the evidence manifest. This would catch the repeated stale-pointer defect before
Rose's final audit.

## 10. Known Residuals

- No server-side hash attestation exists for win-builder; custody is the
  client's exact upload hash/size plus transfer and result receipts.
- The red rchk job and its TMB-header adjudication remain visible.
- Full Ligges notification bodies were not supplied for the final URLs; full
  server results, logs, raw tests, timestamps, upload traces, hash, and size are
  retained.
- Twelve unused `sigma_i` compiler warnings remain post-release cleanup debt.
- Installed documentation is close to, but below, CRAN's general 5 MB guidance.
- Pat noted non-blocking NEWS, README navigation, navbar wrap, and `beta`
  masking polish for a later development release.

## 12. Cross-Product Coverage

This closeout covers release identity, exact-byte local and Windows checks,
exact-source 3-OS and sanitizer checks, reader surfaces, rights, evidence
custody, governance pointers, and the machine-readable release gate for the
one frozen artifact. It does NOT cover a new likelihood or formula cell, any
new platform result for later bytes, post-acceptance CRAN checks, reverse
dependencies after publication, compiler-warning cleanup, Julia capability,
or the protected work in #1033 and `_julia_skip2_artifacts/`.

## 13. Next Actions

1. Require PR #1076's real Ubuntu release job to pass and merge the
   build-excluded evidence closeout.
2. Return the unanimous `submission-ready` verdict to Shinichi for a separate
   submission decision.
3. Do not call `submit_cran()` or submit on 19 August; keep #1033 and
   `_julia_skip2_artifacts/` protected.
4. Treat acceptance, CRAN check-page publication, and post-release housekeeping
   as later external-state gates, not consequences of this readiness verdict.
