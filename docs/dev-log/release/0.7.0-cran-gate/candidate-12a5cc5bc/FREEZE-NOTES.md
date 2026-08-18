# drmTMB 0.7.0 current-main candidate freeze — `12a5cc5bc`

Date: 2026-08-18

Source commit: `12a5cc5bcc36ed1b83d969e5147e29bc98aaadf6`

Candidate SHA-256: `e9c5556ddf09707f1020099d5d87c6cf419d64f14d00c81ccd4931708d4d485b`

Candidate size: 10,090,216 bytes

Archive entries: 962

## Status

This is the intended current-`main` 0.7.0 source candidate. It has earned the local
`tarball-clean` rung only. It has **not** earned `platform-clean`, CRAN-ready, or submission
status. No `submit_cran()` call is authorized, and no submission is planned for 2026-08-19.

The earlier `5153ae7ea7dc2e4ec518dfd6549b4245566b598f97422592d0c3210246023787`
tarball remains useful predecessor and Julia-hard-stop evidence only. Its Ligges results cannot
certify these bytes. The still-owed R-release 4.6.1 and R-devel messages for that predecessor must
be archived as predecessor evidence when available, with any SHA association described as
client-side chain of custody rather than server attestation.

## Source and build integrity

- PR #1073 merged only after its real `ubuntu-latest (release)` job passed (run `32140363228`,
  job `95721328849`, 47m56s). The merge contained only `AGENTS.md` and three `docs/` files, all
  excluded from the built package.
- Post-merge `main` at the exact source commit passed its own Ubuntu release job (run
  `32145054709`, job `95736728435`, 44m36s).
- `devtools::document()` completed with zero tracked or untracked diff.
- The source worktree was clean before and after `R CMD build --no-manual`.
- The tarball inventory contains 962 entries and zero forbidden-path hits, including no `.log`,
  object/shared-library, `.git`, `.Rproj.user`, or `_julia_skip2_artifacts/` entry.
- `pkgdown::check_pkgdown()` reported `No problems found.`

GitHub Actions evidence is same-source evidence, not server attestation of this tarball hash.

## Exact-byte local checks

The true CRAN-lane command set `R_PROFILE_USER=/dev/null`, `NOT_CRAN=false`, and
`_R_CHECK_CRAN_INCOMING_=true`, then ran:

```sh
R CMD check --as-cran --run-donttest --no-manual drmTMB_0.7.0.tar.gz
```

Result: **0 errors, 0 warnings, 1 NOTE (`New submission`)**. The testthat summary was
`FAIL 0 | WARN 52 | SKIP 143 | PASS 11403`; package tests were `[202s/233s]` and vignette
rebuilding was `[94s/111s]`.

A separate same-byte diagnostic retained `NOT_CRAN=true` as required by the handover environment.
It completed `FAIL 0 | WARN 70 | SKIP 304 | PASS 21109`, but `R CMD check` reported 2 NOTEs: the
expected `New submission` NOTE plus an output-comparison NOTE from the report-only spelling test.
That second NOTE is caused by deliberately running the non-CRAN spelling path inside an
`--as-cran` check; it is not presented as the CRAN-lane verdict.

## URL check

The live URL check returned two DOI redirect 403s. Both DOI registrations were independently
resolved through Crossref; see `urlchecker-adjudication.md`. They are evidenced publisher/bot
blocking, not missing DOI registrations.

## External evidence collected

- Fresh 3-OS GitHub Actions completed successfully on Windows, Ubuntu, and macOS. This is
  same-source evidence only; see `gha-3os-matrix.md`.
- R-hub completed with clang-ASAN, clang-UBSAN, and GCC-ASAN successful. `rchk` failed with the
  pre-existing signature confined to installed TMB headers plus analyzer state explosion; the
  failure is preserved rather than called a pass. See `rhub-sanitizer-adjudication.md`.
- The exact-candidate R-devel Ligges result is filed at `Status: 1 NOTE`, with `00check.log` and raw
  test output. See `winbuilder-R-devel-result.md`. The raw MIME email remains owed.
- The exact-candidate R-release 4.6.1 Ligges result is filed at `Status: 1 NOTE`, with
  `00check.log`, raw test output, and the maintainer-supplied email transcript. See
  `winbuilder-R-release-result.md`. The raw MIME email remains owed.

## Remaining exact-source ladder

Before any ledger repointing or release claim, these exact-source or exact-byte gates remain:

1. the win-builder R-oldrelease result for this exact tarball, plus raw MIME copies of the filed
   R-release and R-devel result emails;
2. fresh Grace, Rose, and Pat review;
3. fail-closed release-gate validation at the claimed rung.

The release ledger and `cran-comments.md` remain unchanged until those results exist and the gate
passes. PR #1033 and `_julia_skip2_artifacts/` remain protected and untouched.
