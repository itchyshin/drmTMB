# win-builder R-release result — candidate `6b45164b…`

Date collected: 2026-08-18

Result URL: https://win-builder.r-project.org/uCbpi6X2Ro3u/

The Gmail notification displayed `4:54 PM` in the maintainer's GMT-06 browser on
2026-08-18 (22:54 UTC). It reported installation time 293 seconds, check time
1360 seconds, `Status: 1 NOTE`, and R version `4.6.1 (2026-06-24 ucrt)`.

## Exact-candidate chain of custody

The upload client rechecked the frozen source archive before upload:

- source commit: `5485ccb8aeca404412fd346a3a538d0e57808c79`;
- SHA-256: `6b45164ba1221538de5dbf01eb15d83d77fae8b4e3e15de557f2b39372eedc62`;
- size: `4,367,799` bytes;
- upload completed at approximately `2026-08-18T21:56:24Z`;
- FTP response: `226 Transfer complete`;
- remote listing contained `drmTMB_0.7.0.tar.gz`.

This is a client-side chain of custody. win-builder does not provide a
server-side hash attestation, so this result must not be described as one.

## Result

`00check.log` identifies package `drmTMB` version `0.7.0`, Windows Server 2022
x64, and R `4.6.1 (2026-06-24 ucrt)`. It finishes:

```text
* DONE
Status: 1 NOTE
```

The sole NOTE is the expected first-submission incoming-feasibility note,
including the words `centile`, `misspecification`, and `uncalibrated` from
DESCRIPTION. All substantive checks are `OK`.

The raw testthat transcript finishes:

```text
[ FAIL 0 | WARN 53 | SKIP 145 | PASS 11403 ]
```

## Archived files and SHA-256

- `winbuilder-R-release-result-index.html` — `49539559d5a9008bdb6acdfc2c5a8af705483c6881fbcb82837f2f33add6e5d5`;
- `winbuilder-R-release-00check.log` — `525578cf830eb69a12343cc94cf82bd96fb8b2e39172be8382ad202b1bf88edb`;
- `winbuilder-R-release-testthat.Rout` — `1c343f88a65ea395b2238e314e786fc513540a8517bc46de08f5b1489fa5d9e7`;
- `winbuilder-R-release-examples-index.html` — `6bf6790174acecdf123f3b33448c9bafad9932e2c0e9b7c3d4014ba28230d020`;
- `winbuilder-R-release-tests-index.html` — `c7a4ec37ea9ee2643fbffd2161a779c64af9272160be90713e10b34a45e3b090`;
- `winbuilder-R-release-email-screenshot.png` — `8655f030da9b8c8df9e97d5d7d38ef8ce07ecd1c2ed70f578dd8e81f419297f5`.

The upload trace and listing remain archived beside these files.
