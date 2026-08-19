# Exact-source GitHub Actions 3-OS result

Run <https://github.com/itchyshin/drmTMB/actions/runs/32207379448> completed
successfully against source commit
`6170fbeeea65f22444d7b0934f4e808c40744d22`, the exact source used to build
candidate `1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`.
This is same-source evidence; GitHub Actions did not check the immutable
win-builder upload bytes.

| Platform | Job | Conclusion | Check result | Full-suite testthat summary |
| --- | --- | --- | --- | --- |
| macOS release | `95933144391` | success | 1 NOTE: full test stage, 23 minutes | `FAIL 0 / WARN 71 / SKIP 314 / PASS 21012` |
| Ubuntu release | `95933144402` | success | 2 NOTEs: full test stage, 40 minutes wall / 25 minutes CPU; Julia temporary directories `jl_9CFgf4hGBc` and `jl_weHr1k` | `FAIL 0 / WARN 67 / SKIP 314 / PASS 21012` |
| Windows release | `95933144396` | success | 1 NOTE: full test stage, 43 minutes | `FAIL 0 / WARN 72 / SKIP 321 / PASS 20967` |

Examples, `donttest` examples, and vignette rebuilds completed successfully on
all three platforms. These jobs intentionally used the complete
`NOT_CRAN=true` developer suite, so their duration and Ubuntu Julia-temporary-
directory NOTE are recorded rather than presented as evidence about the
bounded CRAN lane. Exact-byte win-builder R-devel, R-release, and R-oldrelease
results remain the Windows CRAN-lane gate.

Archived evidence and SHA-256:

- `gha-3os-run.json`: `e426eb2a517123cf273d15c42076684180ece4bf0ec6f547e7ebb5dbfc529c1b`
- `gha-macos-job.log`: `fd8d536763d90570bb384aac773f03f5fdd48d384605329e6993d6392199c4e6`
- `gha-ubuntu-job.log`: `87ef3c0f67f5aa522a9177dc4477bd47ec0fd545f16e933c5e1e9ea7c3095113`
- `gha-windows-job.log`: `f55d6f544323a75be893014defd1470f4cc8651f176ae034b9de2d760d1d620b`

This result closes the exact-source 3-OS item. It does not by itself establish
`platform-clean` or `submission-ready`.
