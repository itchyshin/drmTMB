# Platform matrix — candidate `6b45164b…`

## Exact-byte checks

| Platform | Result | Testthat | Chain of custody |
| --- | --- | --- | --- |
| local macOS, R 4.6.0 | 0 errors, 0 warnings, 1 expected NOTE | 11,403 pass | direct local hash/file check |
| win-builder R-devel | 1 expected NOTE | 11,403 pass | client upload hash/size + FTP 226 + result URL |
| win-builder R-release 4.6.1 | 1 expected NOTE | 11,403 pass | client upload hash/size + FTP 226 + result URL |
| win-builder R-oldrelease 4.5.3 | 1 expected NOTE | 11,403 pass | client upload hash/size + FTP 226 + result URL |

The win-builder relationship is client-side chain of custody, not server-side
hash attestation. Complete `00check.log`, raw test output, result indices,
upload traces, URLs, timestamps, source commit, hash, and size are preserved.
The R-oldrelease raw notification message was not supplied and is not claimed.

## Exact-source checks

GitHub Actions run <https://github.com/itchyshin/drmTMB/actions/runs/32190182651>
checked source commit `5485ccb8…` on macOS, Windows, and Ubuntu. All three jobs
succeeded with no test failures. This proves the exact source state on three
operating systems, not the tarball's server-side hash.

R-hub run <https://github.com/itchyshin/drmTMB/actions/runs/32190185592>
checked the same source commit. clang-ASAN, clang-UBSAN, and GCC-ASAN succeeded.
The rchk job failed with the known installed-TMB-header protection signature;
no protection finding cites `drmTMB.cpp`. The overall red run remains visible.

## Honest maximum

This matrix supplies the external evidence for a `platform-clean` ledger claim.
It does not alone establish `submission-ready`; current policy, timing, reader,
and fresh Grace/Rose/Pat review remain cumulative requirements.

