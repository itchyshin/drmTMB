# Platform matrix — candidate `1d6445db…`

## Exact-byte checks

| Platform | Result | Testthat | Chain of custody |
| --- | --- | --- | --- |
| local macOS, R 4.6.0 | 0 errors, 0 warnings, 1 expected NOTE | 3,501 pass | direct local hash/file check |
| win-builder R-devel r90424 | 1 NOTE; no errors or warnings | 3,501 pass | client upload hash/size + FTP 226 + `ltSumbZi569n` |
| win-builder R-release 4.6.1 | 1 NOTE; no errors or warnings | 3,501 pass | client upload hash/size + FTP 226 + `fyFu1tPBAw5y` |
| win-builder R-oldrelease 4.5.3 | 1 NOTE; no errors or warnings | 3,501 pass | client upload hash/size + FTP 226 + `S2uf1uo65N7E` |

The three uploads each sent exactly 4,368,396 bytes and returned FTP `226
Transfer complete` at 2026-08-19 01:51–01:52 UTC. This is client-side chain of
custody, not server-side hash attestation. A supplied result is admissible only
if its random URL was generated after those uploads and its package/version,
R arm, log, tests, and notification timing agree with that upload event.

## Exact-source checks

GitHub Actions run <https://github.com/itchyshin/drmTMB/actions/runs/32207379448>
checked source commit `6170fbeee…` on macOS, Ubuntu, and Windows. All three jobs
succeeded with no test failures. Full-suite duration and Ubuntu Julia temporary
directory NOTEs are retained in `gha-3os-result.md`; this is same-source rather
than exact-server-byte evidence.

R-hub run <https://github.com/itchyshin/drmTMB/actions/runs/32205509997>
checked the same source. clang-ASAN, clang-UBSAN, and GCC-ASAN succeeded with
3,501 passes. The rchk job remains visibly red: protection findings are confined
to installed TMB headers and no protection finding cites `drmTMB.cpp`.

## Honest maximum

The current evidence supports `platform-clean`: exact bytes pass locally and
on all three Windows R arms, and exact source passes three operating systems
plus three sanitizers. R-devel/release repeat a stale PNG URL finding that is
absent from the candidate and non-reproducible in a clean exact-byte check; see
`winbuilder-stale-url-adjudication.md`. `submission-ready` additionally
requires the final ledger/gate and fresh Grace/Rose/Pat review.
