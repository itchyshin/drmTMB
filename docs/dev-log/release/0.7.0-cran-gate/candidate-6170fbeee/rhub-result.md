# R-hub diagnostic result — source `6170fbeee`

Date: 2026-08-19 UTC

Run: <https://github.com/itchyshin/drmTMB/actions/runs/32205509997>

The workflow checked source commit
`6170fbeeea65f22444d7b0934f4e808c40744d22`, the exact clean commit used to
build candidate SHA-256
`1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`.
This is same-source diagnostic evidence, not an exact-tarball or server-hash
attestation.

## Terminal results

| Job | Job ID | Conclusion | Evidence verdict |
| --- | ---: | --- | --- |
| clang-ASAN | `95927932156` | success | `Status: OK`; `FAIL 0 · WARN 63 · SKIP 30 · PASS 3501`; no AddressSanitizer report |
| clang-UBSAN | `95927932139` | success | `Status: OK`; `FAIL 0 · WARN 63 · SKIP 30 · PASS 3501`; no undefined-behaviour runtime report |
| GCC-ASAN | `95927932244` | success | `Status: OK`; `FAIL 0 · WARN 18 · SKIP 30 · PASS 3501`; no AddressSanitizer report |
| rchk | `95927932172` | failure | protection-stack findings cite installed TMB headers; no protection finding cites `drmTMB.cpp` |

The rchk job reports state-space explosion followed by negative-depth,
over-unprotect, and possible protection-stack findings only in installed
`TMB/include/tmb_core.hpp` at lines 1241–1243, 1512–1515, and 2275–2277. It
also emits twelve compiler warnings for unused local `sigma_i` variables in
`drmTMB.cpp`; those are visible cleanup debt, not the protection-stack finding
that fails the job.

The rchk job remains red and is not called a pass. The overall workflow
conclusion is therefore `failure`; the three independent sanitizer jobs are
successful. No package or workflow change is made to conceal or relabel the
failed diagnostic.

## Archived evidence and SHA-256

- `rhub-run.json` — `a583b60354d2652269c30a59592f72ef6a70a7f4afd3f2c61e40325e6dacbf6d`;
- `rhub-clang-ubsan-job.log` — `3a5b3acd56b71cf4ae9a595e922c35fcab3401ea9d3655262dd864deaef2b5bb`;
- `rhub-clang-asan-job.log` — `f766b25ee915db989dd632e7420b5360b9f8d86ed48e358e907928a2013cbbab`;
- `rhub-gcc-asan-job.log` — `1710fc28ce253f1d143f11989d6d28580c30a3088057616ec3b9acb763a1f34a`;
- `rhub-rchk-job.log` — `1f6c85f4c08f1f505a4344c787348b3ab77ce6bea357646ab94d153556b1f081`.
