# win-builder R-devel result — candidate `6b45164b…`

Date collected: 2026-08-18

Result URL: https://win-builder.r-project.org/418jnDxdX8gy/

The Gmail notification displayed `4:38 PM` in the maintainer's GMT-06 browser on
2026-08-18 (22:38 UTC). It reported installation time 300 seconds, check time
1422 seconds, `Status: 1 NOTE`, and R Under development (unstable)
`2026-08-17 r90424 ucrt`.

## Exact-candidate chain of custody

The upload client rechecked the frozen source archive before upload:

- source commit: `5485ccb8aeca404412fd346a3a538d0e57808c79`;
- SHA-256: `6b45164ba1221538de5dbf01eb15d83d77fae8b4e3e15de557f2b39372eedc62`;
- size: `4,367,799` bytes;
- upload completed at approximately `2026-08-18T21:56:28Z`;
- FTP response: `226 Transfer complete`;
- remote listing contained `drmTMB_0.7.0.tar.gz`.

This is a client-side chain of custody. win-builder does not provide a
server-side hash attestation, so this result must not be described as one.

## Result

`00check.log` identifies package `drmTMB` version `0.7.0`, Windows Server 2022
x64, and R-devel `2026-08-17 r90424 ucrt`. It finishes:

```text
* DONE
Status: 1 NOTE
```

The sole NOTE is the expected first-submission incoming-feasibility note,
including the words `centile`, `misspecification`, and `uncalibrated` from
DESCRIPTION. All substantive checks are `OK`.

The raw testthat transcript finishes:

```text
[ FAIL 0 | WARN 99 | SKIP 145 | PASS 11403 ]
```

## Archived files and SHA-256

- `winbuilder-R-devel-result-index.html` — `b77b32bb78dd483f8cd3b7f18de3e19501c879da2499e73f8e5ae50d8a24ad1b`;
- `winbuilder-R-devel-00check.log` — `bece57a37fa787b5d8c83a35c22b2d5491613387268a89ba77ea64765f99c3e4`;
- `winbuilder-R-devel-testthat.Rout` — `b39b5f1d55f4a23a96f822398f1843995c04a5dd788a42a407664ff9a7d66f4c`;
- `winbuilder-R-devel-examples-index.html` — `9b63cba5c1250a267df6f3b89fb2503d4b74779f512aea620ca4b596feadde97`;
- `winbuilder-R-devel-tests-index.html` — `d2622b4eac32f473620ca604c82c802f1c0801b67e60ca8c22f50b5e2b9626f8`;
- `winbuilder-R-devel-email-screenshot.png` — `be2a92be1e7251157ba1d392956355712211251ba2f78061cdd55cadf3777e4c`.

The upload trace and listing remain archived beside these files.
