GOAL: see GOAL.md.   STATE: lognormal has_mi tests green (14/0).
ARCS DONE (verified):
- A7 Gamma `mp-gamma-bernoulli` MERGED (#1088 `6e5538797`)
- A7.L1 C++ lognormal leaf + model_type 4 has_mi — compile clean
- A7.L2 R spec + gate — drm_build_lognormal_ls_spec(impute=)
- A7.L3 tests — 14/0/0 in test-missing-predictor-lognormal-response.R
  (logLik 1e-6; MCAR 0.15; MAR 0.20)
- A7.L4 ledger row mp-lognormal-bernoulli appended
ARC IN PROGRESS: A7.L5 push + PR
NEXT: commit explicit paths; push cursor/lane-s6-family-gate; open PR.
OPEN GATES (need human): merge if CI green (pre-authorised).
TRUTH LIVES IN: ~/local-scratch/lanes/drmTMB-s6-family-gate
on cursor/lane-s6-family-gate from origin/main @ b49619a7c.
RESUME: A7 lognormal has_mi. Tests already green. Do not redo C++.
Push/PR next. Next family is beta_binomial (student waits on nu).
Do not claim covered / FIML / impute_joint.
