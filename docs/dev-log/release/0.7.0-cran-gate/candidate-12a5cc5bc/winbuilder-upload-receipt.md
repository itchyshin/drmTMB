# win-builder upload receipt — candidate `12a5cc5bc`

Date: 2026-08-18

These uploads use the immutable tarball at
`/Users/z3437171/drmTMB-release-artifacts/0.7.0-12a5cc5bc/drmTMB_0.7.0.tar.gz`.
They are win-builder uploads, **not** CRAN submission.

| Field | Value |
| --- | --- |
| Source commit | `12a5cc5bcc36ed1b83d969e5147e29bc98aaadf6` |
| Candidate SHA-256 | `e9c5556ddf09707f1020099d5d87c6cf419d64f14d00c81ccd4931708d4d485b` |
| Candidate size | 10,090,216 bytes |
| R-release | upload 2026-08-18T14:45:35Z–14:45:39Z; FTP `226 Transfer complete`; listing contains `drmTMB_0.7.0.tar.gz` |
| R-devel | upload 2026-08-18T14:45:52Z–14:45:55Z; FTP `226 Transfer complete`; listing contains `drmTMB_0.7.0.tar.gz` |
| R-oldrelease | upload 2026-08-18T14:46:08Z–14:46:11Z; FTP `226 Transfer complete`; listing contains `drmTMB_0.7.0.tar.gz` |

The SHA-256 and size were recomputed locally immediately before every upload. The FTP service
confirmed receipt of a file with the expected name and byte transfer. This is a **client-side chain
of custody**, not server-side hash attestation: win-builder does not report a SHA-256 for the
received file.

No platform result is implied by an upload receipt. The R-release and R-devel results were
subsequently filed at https://win-builder.r-project.org/hL8Z46XFZfTk and
https://win-builder.r-project.org/MunJ44aZB7BQ, respectively. Each reports `Status: 1 NOTE`, and
each has a preserved `00check.log` and raw `testthat.Rout`; see
`winbuilder-R-release-result.md` and `winbuilder-R-devel-result.md`. The user-pasted R-release
transcript and R-devel mailbox screenshot are preserved as email-view evidence, while both raw
MIME messages remain owed. R-oldrelease remains independently pending until its Ligges message,
result URL, `00check.log`, and raw test output are archived. `platform-clean` is not claimed.

The upload logs preserve the complete FTP exchanges, including the server's `226` response and
post-upload directory listing.
