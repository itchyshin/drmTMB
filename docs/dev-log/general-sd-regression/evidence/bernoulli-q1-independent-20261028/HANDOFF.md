# Bernoulli q1 evidence handoff — 2026-10-28

**CARRIED-OVER:** branch `codex/general-sd-regression`, worktree `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression`. The new q1 evidence, runner, report and check fragment are untracked in the parent-owned dirty worktree. No commit or push was authorised for this bounded lane. The read-only broad handoff gate was stopped after about three minutes of foreign-branch enumeration (exit 143); landing and aggregate acceptance remain inconclusive. Resume from this exact worktree, preserving all foreign changes.

Scoped result: one strict Bernoulli selected-SD candidate test passed (53 expectations, zero skips/failures, 87 seconds). Native Laplace and Julia AGHQ5 NLLs matched their own independent references within predeclared tolerances. Profile level .80 and bootstrap `R=3` requested returned finite ordered intervals; successful bootstrap refit count and coverage calibration were not established. Current Julia `main` lacks this route. See `receipt.json` and `live-test.log` here for exact values and limitations.

Resume commands from the worktree:

```sh
python3 tools/general-sd-regression/bernoulli-q1-evidence/pin.py | cmp - docs/dev-log/general-sd-regression/evidence/bernoulli-q1-independent-20261028/sources-before.sha256
python3 -m json.tool docs/dev-log/general-sd-regression/evidence/bernoulli-q1-independent-20261028/receipt.json >/dev/null
python3 ~/shinichi-brain/tools/closeout.py check '/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/docs/dev-log/after-task/2026-10-28-bernoulli-q1-independent.md'
```

The exact tested source archive is `source-capsule.tar.gz` (SHA-256 `c15b9f44b2c8a4fe25a5d10c53a18ff30a91516df0e1fa151cb2f33960c63e21`) with 186 source files plus its manifest. The live log SHA-256 is `412eb3dd27834c29e50d9a2b3093b8cebf802d5b2ffe13fdb78e0ca8cf9813cc`. The report and check fragment are outside the source capsule because they were written after the fit. Parent integration should retain the candidate-only boundary and avoid duplicate fitting.
