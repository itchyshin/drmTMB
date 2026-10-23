# win-builder R-release result — `5153ae7e…` predecessor

**Result received:** 2026-08-18 09:48 MDT (15:48 UTC), as shown in the
maintainer-supplied mailbox screenshot  
**Result URL:** <https://win-builder.r-project.org/qOBUstEvxol1>  
**Platform:** R 4.6.1 (2026-06-24 ucrt), Windows Server 2022 x64  
**Check start:** 2026-08-18 15:26:28 UTC  
**Installation time:** 297 seconds  
**Check time:** 1,318 seconds  
**Status:** 1 NOTE

The NOTE is the expected incoming-feasibility note for a new submission plus
the three recorded DESCRIPTION spelling candidates. The raw test output ends
with:

```text
[ FAIL 0 | WARN 53 | SKIP 143 | PASS 11379 ]
```

This `PASS 11379` signature distinguishes the result from the current-main
candidate, whose R-release result reports `PASS 11403`. Together with the
hash-verified upload receipt, it supports classifying this result as evidence
for predecessor candidate
`5153ae7ea7dc2e4ec518dfd6549b4245566b598f97422592d0c3210246023787`
(10,098,642 bytes). The result server does not attest the uploaded source
tarball's hash, so this association remains a **client-side chain of custody**,
not server attestation.

## Preserved evidence

| File | SHA-256 |
| --- | --- |
| `winbuilder-release-result-index.html` | `4d5e155a3453749fa69562fa47cf51a039176d09d05d8e75c56f2d59cb4acb09` |
| `winbuilder-release-00check.log` | `263492739a2d843b7e498e6a086901d4d12e614c7c1de4cfe7015d35b1a38d4c` |
| `winbuilder-release-testthat.Rout` | `96109a2717ece70afe77081099d7ae4d37abfa80ea3ea29aa2feffd754750680` |
| `winbuilder-mailbox-thread-screenshot.png` | `72a6421f6de87ae1b7124fcc4c64a9f21641b4aa96946ca0a3a8920b49c27f9d` |

The screenshot is an email-view receipt, not the raw MIME message. The raw MIME
and canonical email headers remain provenance debt.

## Disposition

Useful predecessor / Julia-hard-stop evidence only. This result does not certify
the current-main candidate, does not earn `platform-clean`, does not authorize a
release-ledger or `cran-comments.md` rewrite, and does not authorize CRAN
submission.
