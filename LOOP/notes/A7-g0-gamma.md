# A7 G0 — first family is Gamma, not Poisson or nbinom2×Gaussian

Locked 2026-08-27 when Shinichi said start A7 and allowed
"likely Poisson or document the choice."

**Shipped first cell:** `mp-gamma-bernoulli` — Gamma response × one
Bernoulli `mi()` predictor. #962's first unwired family.

**Not first (documented):**

| Alternative | Why later |
|---|---|
| Poisson | Already wired (`mp-poisson-bernoulli`). Not a #962 family. |
| nbinom2 × Gaussian predictor | Valuable SEM cell (abundance ~ incomplete continuous parent). That expands an *already gated* family beyond binary. See `A7-family-matrix.md`. Not the #962 greenfield list. Do it after Gamma (or as a parallel later slice). |
| Lognormal | **Next #962 family** after this PR. |

Do not treat `A7-family-matrix.md` as the live G0. It is recon.
