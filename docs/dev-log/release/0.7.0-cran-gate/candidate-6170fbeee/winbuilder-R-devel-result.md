# win-builder R-devel result — candidate `1d6445db…`

- URL: <https://win-builder.r-project.org/ltSumbZi569n/>
- Server listing timestamp: 19.08.2026 04:35 (server display)
- Check start recorded in `00check.log`: 2026-08-19 02:24:11 UTC
- R: Under development (unstable), 2026-08-17 r90424 ucrt
- Package: `drmTMB` 0.7.0
- Status: 1 NOTE; no errors or warnings
- Tests: 149 seconds; `FAIL 0 / WARN 64 / SKIP 30 / PASS 3501`
- Vignette rebuild: 153 seconds

The NOTE includes the expected first-submission and DESCRIPTION spelling
findings. It also repeats a stale `function-map-cheatsheet.png` 404 attributed
to `inst/doc/function-map-cheatsheet.html`; that file and URL are absent from
the candidate and the returned binary. A fresh network-enabled check of these
exact bytes while the URL returned 404 produced only `New submission`. See
`winbuilder-stale-url-adjudication.md`.

Client-side custody: exact 4,368,396-byte artifact, SHA-256
`1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`,
uploaded to R-devel at 2026-08-19 01:51:53–01:51:56 UTC with FTP `226
Transfer complete`. This is a client-side chain of custody, not server hash
attestation.

Key archived SHA-256 values:

- `winbuilder-R-devel-00check.log`: `fb2a2a20468a55e3111dda91babce3f78370564642b04425a72e9aeca435d2ef`
- `winbuilder-R-devel-testthat.Rout`: `fd60abb8db915418651d64c1521c4de5811371b0ae70cc1db2dc97726b1de3c8`
- `winbuilder-R-devel-result-index.html`: `ea95f8e233fa2f5745ddae601c1009f845514ddd9aabad265ba773c37691dc8b`

