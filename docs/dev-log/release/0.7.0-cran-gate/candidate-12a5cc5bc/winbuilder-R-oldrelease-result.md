# win-builder R-oldrelease result — candidate `12a5cc5bc`

Date filed: 2026-08-18

Result URL: https://win-builder.r-project.org/EEeKbEEvb3o8

This result follows the 2026-08-18T14:46:08Z–14:46:11Z R-oldrelease upload
of the immutable candidate with client-side SHA-256
`e9c5556ddf09707f1020099d5d87c6cf419d64f14d00c81ccd4931708d4d485b`
and size 10,090,216 bytes. The hash association is a client-side chain of
custody, not server-side attestation: Ligges identifies the package name and
version but does not report the received archive's digest.

## Result

- Platform: R 4.5.3 (2026-03-11 UCRT), Windows Server 2022 x64.
- Result email displayed at 09:06 MDT (15:06 UTC) on 2026-08-18.
- Installation time: 203 seconds.
- Check time: 946 seconds.
- Verdict: `Status: 1 NOTE`.
- The only check NOTE is the expected CRAN incoming/new-submission note,
  including the package's spelling-review word list.
- Examples, tests, vignette rebuilding, and PDF/HTML manual creation completed
  `OK`.
- Raw test summary: `FAIL 0 | WARN 53 | SKIP 143 | PASS 11403`; elapsed 558.21
  seconds.

## Preserved evidence

| File | SHA-256 |
| --- | --- |
| `winbuilder-R-oldrelease-email-screenshot.png` | `7ff6839d777181178526cb188e501c0ab3dcdf23488d19a455cdd7b7d29c9e49` |
| `winbuilder-R-oldrelease-result-index.html` | `c81488f26499c24fcf40643d12f59612b8250ea703e5e0f94c950b2db1a74541` |
| `winbuilder-R-oldrelease-00check.log` | `caa3c1b4b60a8d640ef2dd4af2dc6ac9b5c7c16f3c25f37cd59bb5999eb24ab1` |
| `winbuilder-R-oldrelease-testthat.Rout` | `77ddacccaafdbe3275ac0fdfc64b84b752a8734ad522b56cee583f1cd6ed381c` |

The screenshot preserves the complete visible email body and result URL. It is
an email-view receipt rather than raw MIME. Raw MIME is useful provenance debt,
but it is not treated as a release gate once the upload receipt, result page,
complete `00check.log`, and raw test output are preserved.

This result completes the three-arm current-candidate win-builder packet. It
does not by itself establish `platform-clean`; the executable ledger and fresh
Grace/Rose/Pat review remain separate gates.
