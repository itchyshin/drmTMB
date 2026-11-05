# 2026-10-20: Student random-effect SD builder default

The ordinary Student SD builder now supplies the empty phylogenetic SD
descriptor that shared TMB data assembly reads for every Student model. Before
the fix, the Student SD assembly tests failed because
`random_scale$phylo$n_models` was absent. The builder test and the actual fit
and recovery tests now pass. A neighbouring legacy test now expects the
actionable no-matching-random-effect message for `sd(id)` when the location
formula has no random effect.

Checks: `student-sd-regression` 25/25; `student-sd-integration` 30/30;
`missing-predictor-student-response` 17/17; the
focused native family sweep 233/233; ordinary and zero-inflated Poisson SD
assembly/integration 100/100. The corresponding Julia Beta, Gamma, NB2,
Poisson, and Student SD suites passed 204/204. These are functional and
recovery checks, not interval-coverage evidence. Current native source SHA-256:
`c2e552595fecd12742574d38ed7fc9183539cd2e1128d691e5823c55205ff3eb`.
The worktree HEADs were drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`
and DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

