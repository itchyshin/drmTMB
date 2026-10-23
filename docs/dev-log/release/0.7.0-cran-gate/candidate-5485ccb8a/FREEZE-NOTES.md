# drmTMB 0.7.0 replacement candidate freeze — `5485ccb8a`

Date: 2026-08-18

Source commit: `5485ccb8aeca404412fd346a3a538d0e57808c79`

Candidate SHA-256: `6b45164ba1221538de5dbf01eb15d83d77fae8b4e3e15de557f2b39372eedc62`

Candidate size: 4,367,799 bytes

Archive entries: 945

## Status

This is the immutable replacement 0.7.0 candidate built after PR #1074 repaired
the release identity, reader surfaces, installed-documentation budget, and image
provenance problems that caused Gate 7 to reject candidate `e9c5556d…`.

The exact bytes have completed the local CRAN-lane check and all three
win-builder arms. The exact source commit has completed the GitHub 3-OS matrix
and R-hub diagnostics. These records are sufficient to test a `platform-clean`
ledger claim. They do not themselves authorize `submission-ready`, CRAN upload,
or submission.

No `submit_cran()` call is authorized. No submission will be made on
2026-08-19. PR #1033 and `_julia_skip2_artifacts/` remain protected and
untouched.

## Exact-byte identity

- The tarball was built with `R CMD build --no-manual` from a clean detached
  checkout of the source commit above.
- The candidate was made read-only after hashing and inventory.
- The inventory contains 945 entries and no forbidden path, including no
  `.git`, `.Rproj.user`, object/shared-library, log, or
  `_julia_skip2_artifacts/` entry.
- `R_PROFILE_USER=/dev/null` was used throughout the release lane.

## Exact-byte local check

With `NOT_CRAN=false`, the candidate completed:

```sh
R CMD check --as-cran --run-donttest --no-manual drmTMB_0.7.0.tar.gz
```

Result: 0 errors, 0 warnings, 1 expected `New submission` NOTE. The raw
testthat transcript reports `FAIL 0 · WARN 52 · SKIP 145 · PASS 11403`.

## External platform evidence

- GitHub Actions run `32190182651` checked the exact source commit on macOS,
  Windows, and Ubuntu; all three jobs succeeded. This is same-source evidence,
  not server attestation of the tarball hash.
- R-hub run `32190185592` checked the exact source commit. clang-ASAN,
  clang-UBSAN, and GCC-ASAN succeeded. `rchk` remains red with findings confined
  to installed TMB headers and no protection finding in `drmTMB.cpp`; it is
  preserved as a failure and adjudicated, not called a pass.
- The R-devel, R-release 4.6.1, and R-oldrelease 4.5.3 win-builder results each
  end at 1 expected NOTE and `PASS 11403`. Their upload receipts link these
  results to the frozen hash and size only by client-side chain of custody;
  win-builder provides no server-side hash attestation.

## Reader and policy checks

A fresh pkgdown site build from the exact source commit succeeded. The rendered
homepage, introductory article, formula guide, and NEWS page were preserved and
inspected. They identify 0.7.0 consistently; the formula guide lists the
implemented logit, probit, and complementary log-log binomial links. Historical
0.5.0/0.6.0 entries remain only where explicitly labelled as release history.

The tarball is below CRAN's preferred 10 MB source size. Installed documentation
measures 4,939,776 bytes, below the general 5 MB documentation guideline. The
Windows test stage remains material at 14 minutes on R-release/R-devel and must
be adjudicated by Grace before any `submission-ready` claim.

## Provenance boundary

The two earlier candidates remain historical only:

- `5153ae7e…` is predecessor / Julia-hard-stop evidence and cannot certify these
  bytes.
- `e9c5556d…` is a rejected, tarball-clean predecessor whose reader and rights
  defects motivated PR #1074.

The R-oldrelease notification was supplied as a result URL rather than a raw
email or screenshot. Its public result page, complete `00check.log`, raw test
output, upload trace, timestamp, hash, and size are archived. The missing raw
mail is provenance debt, not silently claimed evidence.

