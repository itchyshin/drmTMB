# win-builder upload custody — candidate `1d6445db…`

Frozen artifact:

- path: `/Users/z3437171/drmTMB-release-artifacts/0.7.0-6170fbeee/drmTMB_0.7.0.tar.gz`
- source commit: `6170fbeeea65f22444d7b0934f4e808c40744d22`
- SHA-256: `1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`
- size: 4,368,396 bytes
- local mode at upload: `-r--r--r--`

The official win-builder page was read immediately before upload. It specifies passive anonymous binary FTP to `R-devel`, `R-release`, and `R-oldrelease`. The client recomputed the SHA-256 and size inside each upload command before transferring the immutable path.

| Arm | UTC start | UTC end | Bytes sent | FTP result | Trace |
| --- | --- | --- | ---: | --- | --- |
| R-devel | 2026-08-19T01:51:53Z | 2026-08-19T01:51:56Z | 4,368,396 | `226 Transfer complete` | `winbuilder-R-devel-upload.trace` |
| R-release | 2026-08-19T01:51:53Z | 2026-08-19T01:51:57Z | 4,368,396 | `226 Transfer complete` | `winbuilder-R-release-upload.trace` |
| R-oldrelease | 2026-08-19T01:51:57Z | 2026-08-19T01:52:00Z | 4,368,396 | `226 Transfer complete` | `winbuilder-R-oldrelease-upload.trace` |

This is a client-side chain of custody only. win-builder does not attest the uploaded server-side hash. Each result must therefore be linked to these bytes by the client rehash, destination, timestamp, transfer completion, package/version in the result, and the returned random URL. Result emails, indexes, `00check.log`, raw test output, timings, and hashes will be archived when available.

No CRAN submission occurred.
