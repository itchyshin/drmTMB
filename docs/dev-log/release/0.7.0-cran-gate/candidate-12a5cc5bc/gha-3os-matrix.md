# GitHub Actions 3-OS matrix — candidate `12a5cc5bc`

Date: 2026-08-18

Run: https://github.com/itchyshin/drmTMB/actions/runs/32150173003

The workflow ran at evidence commit `37c2bfe04bdaee542d4e881ea306b4f8827b858c`.
Its parent package source is the candidate source commit
`12a5cc5bcc36ed1b83d969e5147e29bc98aaadf6`; the intervening files are all under
`docs/`, which `.Rbuildignore` excludes. GitHub Actions built from that checkout, so this is
same-source package evidence, not server attestation of candidate SHA-256
`e9c5556ddf09707f1020099d5d87c6cf419d64f14d00c81ccd4931708d4d485b`.

| Job | Job ID | Conclusion | R CMD check status | testthat summary |
| --- | ---: | --- | --- | --- |
| Windows R-release | `95753817825` | success (55m14s) | 1 NOTE: elapsed-time threshold (`[37m]`) | `FAIL 0 · WARN 92 · SKIP 319 · PASS 20953` |
| Ubuntu R-release | `95753817855` | success (47m00s) | 2 NOTEs: elapsed-time threshold (`[34m/30m]`) and Julia temporary directories `jl_ChsZkr8lid`, `jl_aJ30OA` | `FAIL 0 · WARN 70 · SKIP 312 · PASS 20992` |
| macOS R-release | `95753817912` | success (36m28s) | 1 NOTE: elapsed-time threshold (`[23m/23m]`) | `FAIL 0 · WARN 71 · SKIP 312 · PASS 20998` |

The three job logs are preserved beside this receipt. Their SHA-256 digests are:

- Windows: `45c68ba6583fdaf6918905eb91a7d11e8f3c3559083652cf872b8de5ef7b2000`;
- Ubuntu: `7e3e0d6cee762ceb6d9c0f4bd86368a689f5376e5886a688e0e398160f5beccd`;
- macOS: `734379ad5b78c1db39347b0d7c582ac8016aa4b234f11fab3e3a7cb7f5fe51c9`.

This run supplies a fresh, successful three-platform source check. It does not establish
`platform-clean`: the exact-byte win-builder R-release and R-oldrelease results remain pending,
the filed R-devel result still lacks its raw MIME email, and the Ubuntu temporary-directory NOTE
is retained rather than erased by the successful job conclusion.
