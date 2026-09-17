# Dinnage Arc3 Coordinator Checkpoint

Updated: **2026-09-17** · **`main` @ `538302d9c`** · **Wave C IN PROGRESS** (`cursor/dinnage-arc3-wave-c`)

## Current scope

**Wave A/B: CLOSED.** **Wave C:** [#1339](https://github.com/itchyshin/drmTMB/issues/1339), [#1340](https://github.com/itchyshin/drmTMB/issues/1340) on branch `cursor/dinnage-arc3-wave-c` (Cursor/Composer). PR pending push.

## Wave C deliverables (in flight)

| Issue | Change |
| --- | --- |
| #1339 Mi-1 | Export `beta_family()`; stop exporting `beta()`; deprecated unexported `drmTMB::beta()` alias; tests + NEWS |
| #1340 Mi-2 | `importFrom`/`export` `nlme::fixef` and `nlme::ranef`; drop drmTMB-owned generics; acceptance test with glmmTMB attach order |

## Resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor
git checkout cursor/dinnage-arc3-wave-c
Rscript -e 'testthat::test_file("tests/testthat/test-dinnage-audit-wave4c.R")'
```
