GOAL: see GOAL.md.   STATE: Gamma has_mi landed locally; tests green.
ARCS DONE (verified):
- A7.0 lane + G0 (Gamma, not Poisson) — LOOP kit on this branch
- A7.1 C++ leaf + model_type 5 has_mi — compile clean
- A7.2 R spec + gate — drm_build_gamma_ls_spec(impute=)
- A7.3 tests — 14/0/0 in test-missing-predictor-gamma-response.R
  (logLik 1e-6; MCAR 0.15; MAR 0.20)
- A7.4 ledger row mp-gamma-bernoulli appended
ARC IN PROGRESS: A7.5 push + PR
NEXT: commit explicit paths; push cursor/lane-s6-family-gate; open PR.
OPEN GATES (need human): merge if CI green (pre-authorised).
TRUTH LIVES IN: ~/local-scratch/lanes/drmTMB-s6-family-gate
on cursor/lane-s6-family-gate from origin/main @ cc3ef1e8f.
RESUME: A7 Gamma has_mi. Tests already green. Do not redo C++.
Push/PR next. First family is Gamma. Next family is lognormal.
Do not claim covered / FIML / impute_joint.
