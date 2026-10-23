# win-builder R-devel result — `5153ae7e…` predecessor

**Result URL:** <https://win-builder.r-project.org/MunJ44aZB7BQ>  
**Platform:** R Under development (unstable), 2026-08-17 r90424 ucrt  
**Check start:** 2026-08-18 14:56:31 UTC  
**Email:** displayed at 2026-08-18 09:20 GMT-06 (`15:20 UTC`)  
**Status:** 1 NOTE

The client uploaded the immutable 10,098,642-byte tarball with SHA-256
`5153ae7ea7dc2e4ec518dfd6549b4245566b598f97422592d0c3210246023787`
to the R-devel endpoint at 2026-08-18T00:43Z and received `226 Transfer
complete`. The returned page identifies drmTMB 0.7.0 and the expected R-devel
arm. This is a client-side chain of custody, not a win-builder server-side hash
attestation.

`00check.log` records 0 errors, 0 warnings, and 1 NOTE. The NOTE is the expected
first-submission incoming-feasibility note plus the three intentional
DESCRIPTION terms `centile`, `misspecification`, and `uncalibrated`. Examples,
tests, vignette rebuilding, and both manuals completed successfully. The test
stage took 14 minutes and raw testthat output ended with
`FAIL 0 | WARN 99 | SKIP 143 | PASS 11403`.

This closes the previously missing R-devel filing for the predecessor bytes.
It is useful Julia-hard-stop and historical Windows evidence only; it does not
certify candidate `1d6445db…` and is not used to claim the current candidate's
platform rung.

## Archived evidence and SHA-256

- `winbuilder-devel-result-index.html` — `9185458c2bd38aeae7eddba2d862430cb9506bb6a93fb555fe67717290979e49`;
- `winbuilder-devel-00check.log` — `3bafab0ac503b6468fcd01ff3681923c72930ba7876c26fd18cdb113ccbf0650`;
- `winbuilder-devel-examples-index.html` — `4cee1344a69458128a080c416aac25473f50591d2eaca43d4798fef5db2cbd5e`;
- `winbuilder-devel-tests-index.html` — `d7fbfd7ac9c317d44de74884064097e1237323572da2dc8d2686c014c9187da8`;
- `winbuilder-devel-testthat.Rout` — `e3d9e84cd2048c637a2f7a1acee2c1fe17a31cbc2d6055a180053b37c88674e8`;
- `winbuilder-mailbox-thread-screenshot.png` — visual email evidence; included
  in the final evidence manifest.
