# After-Task: Ayumi Data Readiness A061-A070

## Goal

Bank the Ayumi-data wave without rerunning large models from a missing raw
bundle or turning persisted diagnostics into fresh support claims.

## Changes

- Added `docs/design/202-ayumi-data-readiness-summary.md`.
- Marked A061-A070 as banked in
  `docs/dev-log/dashboard/ayumi-phylo-balance-100-slices.tsv`.

## Checks Run

```sh
ls -la /tmp/ayumi-ls-ecogeo/for_test 2>/dev/null || true
find . -path ./.git -prune -o \( -iname '*.rds' -o -iname '*birds*tarsus*' -o -iname '*ayumi*q4*' \) -print
/usr/local/bin/Rscript --vanilla -e 'for (p in c("inst/sim/run/ayumi_model_a_plus_evidence.R", "tools/ayumi-q4-status-harness.R", "tools/ayumi-convergence-stress.R", "tools/ayumi-mass-beak-pv2-rerun.R")) { parse(p); cat("parse ok:", p, "\n") }'
/usr/local/bin/Rscript --vanilla -e 'files <- c("docs/dev-log/ayumi-convergence/slices-1189-1208/mass-beak-current/fits.rds", "docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-q4-main/fits.rds"); for (p in files) { x <- readRDS(p); cat("rds ok:", p, "class=", paste(class(x), collapse = "/"), "\n") }'
```

Result: the expected `/tmp/ayumi-ls-ecogeo/for_test` raw bundle was absent in
this session. The run-now scripts parsed, and the persisted Mass+Beak current
and q4-main fit RDS artifacts read cleanly.

## Evidence Used

- Model A+ full-data evidence:
  `docs/dev-log/after-task/2026-06-16-ayumi-model-a-plus-evidence.md`.
- Current Mass+Beak convergence/profile artifacts:
  `docs/dev-log/ayumi-convergence/slices-1189-1208/`.
- q4 main artifact:
  `docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-q4-main/`.
- q4 status harness:
  `docs/dev-log/after-task/2026-06-15-ayumi-q4-status-harness.md`.
- q4 profile-budget status:
  `docs/dev-log/after-task/2026-06-15-endpoint-profile-budget-status.md`.

## Boundary

A061-A070 do not rerun the raw Ayumi bundle, do not claim fresh real-data
validation, do not promote q4 native ML inference, do not run a large Julia q4
ladder, do not claim interval coverage, and do not draft or post an Ayumi reply.

## Next

Proceed to A071-A080, the inference gap wave. Keep Wald, profile, bootstrap,
coverage, and boundary status as separate ledgers.
