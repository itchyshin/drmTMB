# GitHub 3-OS result — source `5485ccb8a`

Date: 2026-08-18

Run: https://github.com/itchyshin/drmTMB/actions/runs/32190182651

The workflow checked source commit
`5485ccb8aeca404412fd346a3a538d0e57808c79`, the exact commit used to build
candidate SHA-256
`6b45164ba1221538de5dbf01eb15d83d77fae8b4e3e15de557f2b39372eedc62`.
This is same-source evidence, not exact-tarball or server hash attestation.

## Terminal results

| Job | Job ID | Conclusion | Check evidence |
| --- | ---: | --- | --- |
| macOS release | `95882636556` | success | `Status: 1 NOTE`; `FAIL 0 · WARN 71 · SKIP 314 · PASS 20998` |
| Windows release | `95882636570` | success | `Status: 1 NOTE`; `FAIL 0 · WARN 72 · SKIP 321 · PASS 20953` |
| Ubuntu release | `95882636580` | success | `Status: 2 NOTEs`; `FAIL 0 · WARN 67 · SKIP 314 · PASS 20998` |

The cross-platform NOTE is the elapsed-time NOTE from the deliberately large
testthat suite. Ubuntu additionally reported two Julia temporary directories
under check-directory detritus. These observations remain visible and are not
described as a zero-NOTE check. There were no test failures and all three jobs
concluded successfully.

## Archived evidence and SHA-256

- `gha-3os-run.json` — `8d36aec1bbce0a848c83354771475f081d6ea68c03afe4c7a1c2fb9310c7441c`;
- `gha-macos-job.log` — `a57b6b940993a8db29f67bcab456cf7961dfdd3fc4f55aa6791277faacedf533`;
- `gha-windows-job.log` — `62a20972e9ee1f35256a9d6f16ac022ee05c5c2a46135df96d9df5298a7c5fe1`;
- `gha-ubuntu-job.log` — `f411f12f8cdd752158901afb9a8374e8f2b907526e02259e4fe1cb14cc54f293`.
