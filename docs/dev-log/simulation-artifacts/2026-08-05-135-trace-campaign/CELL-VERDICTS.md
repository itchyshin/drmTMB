# 135-trace cell verdicts (mechanical ten-clause)

Source SHA: `6618e4b30303f7815b272f709ac2c8d09089132d`.
Receipts: 135 under `totoro-receipts/`.
Clause 10 (Fisher location review) is recorded separately before promotion.

| cell | n | pass seeds | mean|max rel_err | clamp | boundary | LR fail | unimodal fail | verdict | notes |
|---|---:|---:|---|---|---|---|---|---|---|
| mc-0568 | 5 | 5/5 | 0.112|0.162 | FALSE | FALSE | FALSE | FALSE | **PASS** |  |
| mc-0576 | 5 | 5/5 | 0.101|0.251 | FALSE | FALSE | FALSE | FALSE | **PASS** |  |
| mc-0593 | 5 | 4/5 | 0.241|0.287 | FALSE | FALSE | TRUE | TRUE | **WITHHOLD** | c2_seed_count_or_fail,c3_status,c5_boundary_clamp,c6_lr_unimodal,c8_truth |
| mc-0594 | 5 | 4/5 | 0.192|0.406 | FALSE | FALSE | FALSE | FALSE | **WITHHOLD** | c1_rel_err,c2_seed_count_or_fail,c8_truth |
| mc-0595 | 5 | 5/5 | 0.102|0.234 | FALSE | FALSE | FALSE | FALSE | **PASS** |  |
| mc-0596 | 5 | 5/5 | 0.087|0.308 | FALSE | FALSE | FALSE | FALSE | **PASS** |  |
| mc-0597 | 5 | 0/5 | 0.906|1.000 | FALSE | TRUE | TRUE | TRUE | **WITHHOLD** | c1_rel_err,c2_seed_count_or_fail,c3_status,c5_boundary_clamp,c6_lr_unimodal,c8_truth |
| mc-0418 | 18 | 6/18 | 0.739|3.000 | FALSE | TRUE | TRUE | TRUE | **WITHHOLD** | c1_rel_err,c2_seed_count_or_fail,c3_status,c5_boundary_clamp,c6_lr_unimodal,c8_truth |
| mc-0436 | 18 | 5/18 | 0.554|1.585 | FALSE | TRUE | TRUE | TRUE | **WITHHOLD** | c1_rel_err,c2_seed_count_or_fail,c3_status,c4_fit,c5_boundary_clamp,c6_lr_unimodal,c8_truth |
| mc-0446 | 18 | 8/18 | 0.519|1.000 | FALSE | TRUE | TRUE | TRUE | **WITHHOLD** | c1_rel_err,c2_seed_count_or_fail,c3_status,c5_boundary_clamp,c6_lr_unimodal,c8_truth |
| mc-0450 | 18 | 12/18 | 0.323|0.928 | FALSE | TRUE | TRUE | FALSE | **WITHHOLD** | c1_rel_err,c2_seed_count_or_fail,c3_status,c5_boundary_clamp,c6_lr_unimodal,c8_truth |
| mc-0454 | 18 | 9/18 | 0.363|0.997 | FALSE | TRUE | TRUE | TRUE | **WITHHOLD** | c1_rel_err,c2_seed_count_or_fail,c3_status,c5_boundary_clamp,c6_lr_unimodal,c8_truth |
| mc-0425 | 5 | 4/5 | 0.226|0.355 | FALSE | FALSE | FALSE | FALSE | **WITHHOLD** | c1_rel_err,c2_seed_count_or_fail |
| mc-0653 | 5 | 5/5 | 0.094|0.127 | FALSE | FALSE | FALSE | FALSE | **PASS** |  |
