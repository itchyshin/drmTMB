# Arcs — 135-trace Prong B

| id | status | gate | one-line |
|---|---|---|---|
| S0-scaffold | done | — | LOOP kit from approved ultra-plan |
| S1-runner | done | — | `tools/run-135-trace-campaign.R` + Totoro bash driver; 135 jobs |
| S2-c1-smoke | done | — | `mc-0568` tmbprofile PASS local + Totoro |
| S3-totoro | done | cleared | parallel -j64; 135/135 ok |
| S4-review | done | — | 5 PASS / 9 WITHHOLD + Fisher location |
| S5-promote | done | — | +5 IF (182→187); FROZEN 59→54; NEWS; claim_boundary |
| verify-close | done | — | ledger check, unittest, after-task, plan-vs-actual |
