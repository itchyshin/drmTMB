# win-builder R-oldrelease result — candidate `6b45164b…`

Date collected: 2026-08-18

Result URL: https://win-builder.r-project.org/U246pNXO3CGX/

The maintainer supplied the result URL directly in the Codex task. The public
result index timestamps the files `19.08.2026 00:20` in win-builder's displayed
server time. A screenshot or raw copy of the notification email has not yet
been supplied and must not be claimed as archived.

## Exact-candidate chain of custody

The upload client rechecked the frozen source archive before upload:

- source commit: `5485ccb8aeca404412fd346a3a538d0e57808c79`;
- SHA-256: `6b45164ba1221538de5dbf01eb15d83d77fae8b4e3e15de557f2b39372eedc62`;
- size: `4,367,799` bytes;
- upload completed at approximately `2026-08-18T21:56:27Z`;
- FTP response: `226 Transfer complete`;
- remote listing contained `drmTMB_0.7.0.tar.gz`.

This is a client-side chain of custody. win-builder does not provide a
server-side hash attestation, so this result must not be described as one.

## Result

`00check.log` identifies package `drmTMB` version `0.7.0`, Windows Server 2022
x64, and R `4.5.3 (2026-03-11 ucrt)`. It finishes:

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

- `winbuilder-R-oldrelease-result-index.html` — `5c794dbca0501a546b0dc75d22a76034a936e04287f82de1a9b0a1095b08b8ab`;
- `winbuilder-R-oldrelease-00check.log` — `316aabf5c1a3a660831f743506c371486bc3825b75cf9ee84e9e86db84dc54df`;
- `winbuilder-R-oldrelease-testthat.Rout` — `11e4fa083462ec948f97733798c159b4705c7b61d70ea23ebb92fa8e00418079`;
- `winbuilder-R-oldrelease-examples-index.html` — `216219e21138c36227bb96aef250e475abee4caeb084a8856eed7cd4696a462d`;
- `winbuilder-R-oldrelease-tests-index.html` — `4f147e3e8896f6aeb50f2deda710650881df30da3b6b105333fdc2593c473c1b`.

The upload trace and listing remain archived beside these files.
