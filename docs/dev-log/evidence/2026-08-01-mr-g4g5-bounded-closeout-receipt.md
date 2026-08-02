# MR-G4/G5 bounded campaign closeout receipt

## Scope

This receipt closes the R-only missing-response G4/G5 campaign at the user's approved bounded endpoint: the G4/G5 framework is ready, and completed G5 cohorts retain their exact calibration outcomes. It does not claim an all-route G5 campaign, a route-wide missing-response promotion, or a model inference-tier transition.

## Frozen inputs and G4 result

The frozen manifest at `~/g4g5/artifacts/target-manifests.rds` has SHA-256 `d3eea7eda9a67725189e6aef3e12a88fee5927d4b10a0bd6a915f0e5df392828`. It contains 18 route-specific G3 designs and 102 target definitions. The reconciled G4 ledger at `~/g4g5/artifacts/g4-reconciled-records.rds` has SHA-256 `233a5ea8c1029c7dad64658688f7e2231aff4361763d5d854017e302f92685ae`. It contains 306 route-target-rung records: 295 are G4-feasible and 11 retained records are not eligible for G5. Thus, G4 is ready as an audited feasibility framework for every route, not a claim that every target has a usable interval.

## Reconciled G5 cohorts

Seven durable reconciliation artifacts cover eight route-level cohorts because Gaussian and bivariate Gaussian share one 54-cell artifact. Each completed cell retains 1,200 planned attempts in its unconditional denominator.

| Cohort | Cells | Pass | Fail | Planned attempts | SHA-256 |
|---|---:|---:|---:|---:|---|
| Gaussian + bivariate Gaussian | 54 | 51 | 3 | 64,800 | `71417f94016763aa0a35871faf26e3cae85b9e6216e517076002080eb0f63c2a` |
| Binomial | 6 | 6 | 0 | 7,200 | `21f0cded7bee647d656738d95dd8e991ed4af9998374bbf530571bcac548bc55` |
| Poisson | 9 | 5 | 4 | 10,800 | `2dced5b75aa40486e16b23f941c81c2aeca89c8524c742ef6341089aea515d27` |
| Gamma | 15 | 12 | 3 | 18,000 | `eabd5525004678f92bb2af7f001705863a976e2e678ee725910c34b2931d57d5` |
| Lognormal | 15 | 11 | 4 | 18,000 | `279bd9cba7509e563c6600c5e48b7dd0a873ba20ff30198367d92b8b75228e45` |
| Student-t | 16 | 3 | 13 | 19,200 | `aec9ef64a7eac6a24bec06cf5445c4da219d8aaa7386421cb9ce5c7bad877fa9` |
| NB2 | 15 | 10 | 5 | 18,000 | `2856b3e66da9dc120b2d2603c106d045566f481b1019bda8176b8d81b5a146bc` |

Across these cohorts, 98 of 130 exact frozen route-by-target-by-information-rung cells pass `mr-g5-calibration-v1`; 32 fail and remain retained. The binomial cohort is the only completed cohort with every frozen cell passing. These are candidate-cell calibration results, not public route labels.

## Cancelled and unrun work

The Beta array, Rorqual job `18098606`, was cancelled by user instruction after two receipts had been written. The scheduler has no remaining array tasks. The two preserved but unreconciled receipts are `g5-beta-sd_mu__1___id_-0.5x.rds` (`4f02f19b2940627296462d6b1b479e3f31caa8501a3d61c56cc2c6132976d63d`) and `g5-beta-sd_mu__1___id_-1x.rds` (`1c85dee8107d2dcab3db29f8f8cf6becf8ac4daca9b462e920d04a2d3d0c99dc`). They receive no G5 verdict. No subsequent cohort was submitted.

Beta has no completed G5 result. The fully unrun routes are skew_normal, zero_one_beta, tweedie, cumulative_logit, beta_binomial, truncated_nbinom2, zi_poisson, zi_nbinom2, and hurdle_nbinom2. A later campaign must resume with a new explicit scope; it must not silently treat this bounded closeout as all-route G5 evidence.

## Claim boundary

All 18 public missing-response route badges remain G3. The supported public statement is that the framework freezes route-specific MCAR designs, records G4 interval feasibility, admits only G4-feasible cells to G5, and preserves all planned attempts and failures. It does not support a universal G4/G5, coverage-ready, or inference-ready missing-response claim.
