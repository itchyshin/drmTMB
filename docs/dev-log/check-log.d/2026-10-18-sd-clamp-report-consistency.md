# Effective log-SD report consistency follow-up, 2026-10-18

Added a response-scale assertion to the ZIP clamp-active test, so reported
effective group SD is checked against both link and response prediction.
`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zi-poisson-sd")'`
passed 33 expectations (15 integration, 18 regression), with 0 failures,
warnings, or skips in 62.2 seconds. No live Julia tests ran. The shared
`src/drmTMB.cpp` comment correction remains owed because lane preflight found 61
refs with edits missing from this checkout. This does not establish familywide
consistency, uncertainty calibration, or programme completion.
