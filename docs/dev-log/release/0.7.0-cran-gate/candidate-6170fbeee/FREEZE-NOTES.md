# drmTMB 0.7.0 exact current-main freeze

## Identity

- Source commit: `6170fbeeea65f22444d7b0934f4e808c40744d22`
- Generating checkout: `/private/tmp/drmtmb-070-final-6170fbeee`
- Generating checkout status: empty `git status --porcelain=v1` at freeze and on recheck
- Immutable artifact: `/Users/z3437171/drmTMB-release-artifacts/0.7.0-6170fbeee/drmTMB_0.7.0.tar.gz`
- SHA-256: `1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`
- Size: 4,368,396 bytes
- Inventory entries: 946
- Frozen mode: `-r--r--r--`
- Build time recorded by the filesystem: `2026-08-18T19:24:40Z`

The artifact was built after PR #1075 merged and `main` resolved exactly to the source commit above. It replaces candidates `5153ae7e…` and `6b45164b…`; all results for those hashes are predecessor evidence only.

## Tarball boundary

`tar-inventory.txt` is a complete `tar -tvzf` listing. A fresh filename scan found no `.git`, `.Rproj.user`, compiled object/shared-library residue, check logs, or `_julia_skip2_artifacts/`. The protected PR #1033 path was not touched and no submission action occurred.

## Exact local CRAN lane

The immutable artifact was checked with:

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=false \
  R CMD check --as-cran --run-donttest --no-manual \
  /Users/z3437171/drmTMB-release-artifacts/0.7.0-6170fbeee/drmTMB_0.7.0.tar.gz
```

Result: 0 errors, 0 warnings, 1 expected first-submission NOTE (`New submission`). Examples, compiled-code checks, tests, and vignette rebuilds are `OK`. The CRAN-lane test stage completed in 45 seconds elapsed / 54 seconds reported, with testthat summary `FAIL 0 | WARN 19 | SKIP 30 | PASS 3501`. The warnings are expected testthat warnings exercised by the selected tests; they are not `R CMD check` warnings.

Archived local evidence:

- `local-as-cran-00check.log`
- `local-as-cran-terminal.txt`
- `local-as-cran-testthat.Rout`
- `local-spelling.Rout`
- `tar-inventory.txt`

## External evidence state

- Exact-source R-hub run: <https://github.com/itchyshin/drmTMB/actions/runs/32205509997>, head SHA `6170fbeee…`; clang-ASAN, clang-UBSAN, and GCC-ASAN succeeded. The rchk job remains visibly red with protection findings confined to installed TMB headers; see `rhub-result.md`.
- Exact-source routine Ubuntu run: <https://github.com/itchyshin/drmTMB/actions/runs/32204506090>, head SHA `6170fbeee…`; succeeded with the full `NOT_CRAN=true` suite. It is supporting source evidence rather than the selected 3-OS matrix.
- Exact-source full 3-OS run: <https://github.com/itchyshin/drmTMB/actions/runs/32207379448>, head SHA `6170fbeee…`; macOS, Ubuntu, and Windows all succeeded. The full `NOT_CRAN=true` suite produced only recorded duration and Ubuntu Julia-temp-directory NOTEs; see `gha-3os-result.md`.
- Exact bytes were uploaded to win-builder R-devel, R-release, and R-oldrelease with client-side rehash/size checks and three FTP `226 Transfer complete` responses. All three returned 1 NOTE with no errors or warnings and `PASS 3501`; see the per-arm result receipts. The R-devel/release stale PNG finding is absent from candidate content and does not reproduce in a clean network-enabled exact-byte check; see `winbuilder-stale-url-adjudication.md`.
- Exact-source pkgdown built and was visually inspected after deployment sanitizers; see `rendered-site-inspection.md` and the three screenshots under `rendered-site/`.

## Claim boundary

This freeze now supports `platform-clean`: candidate identity, exact local CRAN-lane evidence, exact-byte three-arm win-builder results, exact-source 3-OS CI, and sanitizer diagnostics are complete. It does not yet prove `submission-ready`; that requires the final release ledger, executable gate, `cran-comments.md`, and fresh Grace/Rose/Pat panel.

No `submit_cran()` or CRAN upload is authorized or performed.
