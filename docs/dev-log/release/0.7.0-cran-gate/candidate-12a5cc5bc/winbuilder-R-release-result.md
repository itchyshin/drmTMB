# win-builder R-release result — candidate `12a5cc5bc`

Date filed: 2026-08-18

Result URL: https://win-builder.r-project.org/hL8Z46XFZfTk

This result follows the 2026-08-18T14:45:35Z–14:45:39Z R-release upload of the
immutable candidate with client-side SHA-256
`e9c5556ddf09707f1020099d5d87c6cf419d64f14d00c81ccd4931708d4d485b` and
size 10,090,216 bytes. The hash association is a client-side chain of custody,
not server-side attestation: Ligges identifies the package name and version but
does not report the received archive's digest.

## Result

- Platform: R 4.6.1 (2026-06-24 UCRT), Windows Server 2022 x64.
- Check start recorded by `00check.log`: 2026-08-18 17:34:13 UTC.
- Installation time: 297 seconds.
- Check time: 1,322 seconds.
- Verdict: `Status: 1 NOTE`.
- The only check NOTE is the expected CRAN incoming/new-submission note, including
  the package's spelling-review word list.
- Examples, tests, vignette rebuilding, and PDF/HTML manual creation completed `OK`.
- Raw test summary: `FAIL 0 | WARN 53 | SKIP 143 | PASS 11403`; elapsed 799.43
  seconds.

## Preserved evidence

- `winbuilder-R-release-email-transcript.md`: maintainer-supplied message transcript
  containing the sender, result URL, and timings. It is not a raw MIME message.
- `winbuilder-R-release-result-index.html`: downloaded Ligges result-page index.
- `winbuilder-R-release-00check.log`: downloaded complete package-check log.
- `winbuilder-R-release-testthat.Rout`: downloaded raw testthat output.

The strict raw-email requirement remains open until the maintainer supplies the
message as `.eml` or equivalent complete headers and body. This R-release result
does not alone establish `platform-clean`; R-devel and R-oldrelease are now also
filed, and the executable ledger remains the gate.
