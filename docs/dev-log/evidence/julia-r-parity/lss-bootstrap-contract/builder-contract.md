# Public Julia LSS bootstrap contract

This receipt exercises the public R `engine = "julia"` surface for one
well-conditioned 32-tip Gaussian location-scale-scale model under `REML = TRUE`.
It requests a small bootstrap (`B = 6`) for the fixed-effect target
`fixef:mu:x`; this is a dispatch and reconstruction check, never a coverage or
native-interval-parity experiment.

The direct DRM.jl comparison receives the bridge's sorted payload and identical
seed, and calls `bootstrap_result` with the same LSS fit method. The receipt
records attempted/used/failed refits, convergence, intervals, thread counts,
and a same-data direct REML refit. It also records the public target inventory:
an absent LSS `sd_phylo` target is an explicit result, not a reason to call a
private Julia primitive.

An optional `response = "include"` case uses `B = 4` and is retained even if
the current bootstrap route refuses it. The main fixed-effect case is the
receipt gate; the optional missing-response row is evidence only.

Before and after the run, the runner hashes recursive R/C++ source in drmTMB
and recursive Julia source, plus its own script. It records git heads/status
and any loaded native DLL hash. These are development worktrees and no output
asserts a clean head.

Expected runtime is below three minutes on one Julia thread and one BLAS thread;
the invoking shell must enforce a 180-second watchdog.
