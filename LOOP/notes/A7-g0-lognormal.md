# A7 G0 — second family is lognormal × Bernoulli

Locked 2026-08-27 when Shinichi said **"lognormal and you can keep
going"** after Gamma (`mp-gamma-bernoulli`, #1088) merged.

**This cell:** `mp-lognormal-bernoulli` — lognormal response × one
Bernoulli `mi()` predictor. #962's next unwired family
(`model_type` 4). Identity log-location; C++ `has_mi` + leaf
**before** the allow-list.

**Not this slice**

| Alternative | Why later |
|---|---|
| Student | Leaf has no `nu` slot. L-scope. See `A7-post-lognormal-queue.md`. |
| nbinom2 × Gaussian | Expand-gated. Already on the allow-list. After #962 greenfield. |
| beta_binomial | **Next implementable #962 cell after this PR.** Clone, not a new derivation. |

Do not treat `A7-family-matrix.md` as the live G0. It is recon.
