# R-hub diagnostic result — source `5485ccb8a`

Date: 2026-08-18

Run: https://github.com/itchyshin/drmTMB/actions/runs/32190185592

The workflow checked source commit
`5485ccb8aeca404412fd346a3a538d0e57808c79`, the exact commit used to build
candidate SHA-256
`6b45164ba1221538de5dbf01eb15d83d77fae8b4e3e15de557f2b39372eedc62`.
This is same-source diagnostic evidence, not exact-tarball or server hash
attestation.

## Terminal results

| Job | Job ID | Conclusion | Evidence verdict |
| --- | ---: | --- | --- |
| clang-ASAN | `95882650078` | success | `Status: OK`; `FAIL 0 · WARN 96 · SKIP 145 · PASS 11403`; no AddressSanitizer report |
| clang-UBSAN | `95882649966` | success | `Status: OK`; `FAIL 0 · WARN 96 · SKIP 145 · PASS 11403`; no undefined-behaviour runtime report |
| GCC-ASAN | `95882649840` | success | `Status: OK`; `FAIL 0 · WARN 55 · SKIP 145 · PASS 11403`; no AddressSanitizer report |
| rchk | `95882650057` | failure | same pre-existing TMB-header protection-stack signature; no protection finding in `drmTMB.cpp` |

The rchk job reports state-space explosion followed by negative-depth,
over-unprotect, and possible protection-stack findings only in installed
`TMB/include/tmb_core.hpp` at lines 1241–1243, 1512–1515, and 2275–2277. This
exactly reproduces the earlier dependency/framework signature. The job remains
red and must not be called a pass; no drmTMB code or workflow change is
warranted to conceal it.

The overall workflow conclusion is failure solely because rchk is red. The
three independent sanitizer jobs are successful.

## Archived evidence and SHA-256

- `rhub-run.json` — `ac69fe2d8c2cd0607488858010f8651ecdfef2aa92cb6b9b27f1a030b2768240`;
- `rhub-clang-asan-job.log` — `a65eb64bda17b701f24d756c43d9c3e7f32afbf863b7dacda0eaed63e5e11f10`;
- `rhub-clang-ubsan-job.log` — `85da6d69a24292b64c59e27fdbdc4855d85e962f4a18c20fd9fda5f613faf5dc`;
- `rhub-gcc-asan-job.log` — `980af0dac855bef39c073d4a3bae1b9c57538163624d22bc1e03c3c79ddb333d`;
- `rhub-rchk-job.log` — `063bec84ca5dbeb7c5fd60c0550bf47b667fa3914e01a2083118a7ec0ff76678`.
