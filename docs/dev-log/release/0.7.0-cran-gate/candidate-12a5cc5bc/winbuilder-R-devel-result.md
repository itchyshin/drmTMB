# win-builder R-devel result — candidate `12a5cc5bc`

Date filed: 2026-08-18

Result URL: https://win-builder.r-project.org/MunJ44aZB7BQ

This result follows the 2026-08-18T14:45:52Z–14:45:55Z R-devel upload of the
immutable candidate with client-side SHA-256
`e9c5556ddf09707f1020099d5d87c6cf419d64f14d00c81ccd4931708d4d485b` and
size 10,090,216 bytes. The hash association is a client-side chain of custody,
not server-side attestation: Ligges identifies the package name and version but
does not report the received archive's digest.

## Result

- Platform: R Under development (unstable), 2026-08-17 r90424 UCRT, Windows
  Server 2022 x64.
- Check start recorded by `00check.log`: 2026-08-18 14:56:31 UTC.
- Installation time: 295 seconds.
- Check time: 1,411 seconds.
- Verdict: `Status: 1 NOTE`.
- The only check NOTE is the expected CRAN incoming/new-submission note, including
  the package's spelling-review word list.
- Examples, tests, vignette rebuilding, and PDF manual creation completed `OK`.
- Raw test summary: `FAIL 0 | WARN 99 | SKIP 143 | PASS 11403`; elapsed 816.53
  seconds.

## Preserved evidence

- `winbuilder-R-devel-email-screenshot.png`: maintainer-mailbox screenshot showing
  the sender, result URL, timings, status, and R-devel version. It is an email-view
  receipt, not a raw MIME message. The same screenshot shows a second win-builder
  message in the thread at 09:06, but that message is collapsed: its R arm, result
  URL, status, and body are not visible, so it is not counted as result evidence.
- `winbuilder-R-devel-result-index.html`: downloaded Ligges result-page index.
- `winbuilder-R-devel-00check.log`: downloaded complete package-check log.
- `winbuilder-R-devel-testthat.Rout`: downloaded raw testthat output.

The strict raw-email requirement remains open until the maintainer supplies the
message as `.eml` or equivalent complete headers and body. This R-devel result
does not establish `platform-clean`; R-release and R-oldrelease exact-candidate
results remain independently owed. Expanding or exporting the visible 09:06
message is the first mailbox action because it may resolve one of those arms.
