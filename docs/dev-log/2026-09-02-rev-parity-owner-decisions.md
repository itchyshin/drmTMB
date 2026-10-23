# Owner decisions — drmTMB reverse-parity lane (Shinichi, 2026-09-02)

Recorded by the Claude lane the same session they were taken, so no later session has to
re-ask. Vault mirror: `memory/DECISIONS.md` D-202. Plan that consumes them:
`~/.claude/plans/piped-dancing-floyd.md` (true-parity ultra-plan).

| # | question put to Shinichi | DECIDED | consequence |
|---|---|---|---|
| 1 | Push the 18 local `claude/rev-parity-*` branches? | **DECIDED: push all 18, no merge.** ("Push all 18 now") | Verified on the remote at the local heads the same hour; another session had pushed them, so nothing was force-pushed. |
| 2 | PR #1112 or this lane first? Both touch `drm_control()`. | **DECIDED: #1112 lands first.** | This lane rebases onto #1112, adds `start`/`multi_start` to the Julia rejection list (else silently ignored under `engine = "julia"`), then opens one PR. A4/A5 unblock after #1112. |
| 3a | `obj$he()` removed; Hessian conditioning read from `sdr$cov.fixed` (taken unattended because `he()` segfaulted on reloaded fits). | **DECIDED: confirmed.** | Stays as shipped on `claude/rev-parity-b2-check-conditioning`. |
| 3b | `objective_at()` reports the unpenalized `logLik()` convention, re-evaluating the penalty at the queried point. | **DECIDED: confirmed.** | Stays as shipped on `claude/rev-parity-a3-objective-at`. |
| 4 | Naming authority for coefficient names across R and Julia. | **DECIDED: base-R spelling.** drmTMB's `coefficient_labels()` is canonical; DRM.jl's fixtures translate. | Unblocks ARC C2–C4 (design 258). The producer contract is written as §7 of design 258. |

Also said in the same session: "keep going for me" (continue without further prompting);
"there is a lane for DRM.jl too" (DRM.jl is read-only for this lane; Julia items are handed
over, never edited).

Not decided (recorded so they are asked once): ultracode opt-in; Student-t `nu` start labels;
`vcov()` abort when `sdreport` fails; whether true parity is one- or two-directional
(see the decision map).
