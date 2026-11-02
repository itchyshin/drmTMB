# Bernoulli q1 independent evidence plan (frozen before fitting)

This receipt concerns only the dirty R candidate at `425bee81572c625a634b2b083050c5c57c1dc1f1` and the dirty Julia SD candidate. Current `main` in Julia does not implement the selected SD route. The existing `test-julia-binomial-sd.R` expression named `public Julia Bernoulli SD outputs match the fitted target` is reused as an AST, including its 300-group, 12-repeat, seed-1701 Bernoulli fixture, unchanged recovery and agreement thresholds, and profile/bootstrap checks. A new expression at its end evaluates the references using the same two fit objects. No second scientific fit is added.

## Symbolic alignment

| Term | DGP and fitted syntax | Reference and extraction | Truth |
| --- | --- | --- | --- |
| `Y_ij` | `rbinom(size=1, prob=plogis(eta_ij))`; `bf(y ~ x + (1 | id), sd(id) ~ w)` | `dbinom(y, size=1, prob=plogis(eta))` | strict Bernoulli |
| `eta_ij = beta_0 + beta_x x_ij + b_i` | independent `x ~ N(0,1)`; random intercept `(1 | id)` | `coef(fit, "mu")` enters same fixed predictor; scalar `b` integrated per group | `(-0.3, 0.6)` |
| `b_i ~ N(0, tau_i^2)` | independent `rnorm(groups)` multiplied by `tau_i` | independent scalar `dnorm(b,0,tau_i,log=TRUE)` | conditional group SD |
| `log tau_i = alpha_0 + alpha_w w_i` | group-constant `w` evenly spans `[-1,1]`; `sd(id) ~ w` | `coef(fit, "sd(id)")` enters exponential | `(log(0.8), 0.5)` |

For each group define `f_i(b) = sum_j log Bernoulli(y_ij; logistic(beta_0 + beta_x*x_ij + b)) + log Normal(b;0,tau_i)`. Optimize it independently in R to obtain `bhat_i`; set `H_i=1/tau_i^2 + sum_j p_ij(1-p_ij)` at the mode. Native Laplace negative log likelihood is `-sum_i [f_i(bhat_i) + 0.5*log(2*pi) - 0.5*log(H_i)]`, using the already independent helper. Julia's default uses five physicists' Gauss-Hermite nodes and its negative log likelihood is `-sum_i [log(sqrt(2/H_i)) + logsumexp_k(log(w_k) + f_i(bhat_i + sqrt(2/H_i)*z_k) + z_k^2)]`. The new reference constructs the rule from a symmetric Jacobi eigensystem, separately from Julia. One-node quadrature must equal Laplace and Gaussian prior integration must equal one. Native versus its reference must differ by at most `1e-6` absolute NLL; Julia versus its five-node reference by at most `1e-5` absolute NLL. We do not impose equality of native and Julia NLLs.

## Execution boundary

1. Pin original test, helper (fixture and Laplace reference), new runner/reference, relevant R and C++ sources and actual loaded DLL, all Julia `src` files, Project/Manifest, runtime binaries, and source stability before/after. The old 2026-10-24 receipt stays immutable and remains unreviewed.
2. Review the math and runner independently before any scientific fit. A pure reference self-check is allowed first. Runtime setup pilot estimate: at most 3 minutes. The exact selected test, including profile and three bootstrap refits, estimate: at most 15 minutes, re-estimated from pilot. Stop and report if either exceeds its bound.
3. Use the native ARM Julia 1.10.12 binary and a separate scratch package with copied Project/Manifest and `src` symlink to the Julia SD candidate. Set an owned writable Julia depot first; the parity lane's private depot may be read-through second. Keep `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`, `JULIA_NUM_THREADS=1`. No source, dependency, or cache mutation in the other lane.
4. Retain raw logs, all warnings, skips, failures and attempts. A skip or a stale source hash is a failed evidence closeout. Report only this candidate case; no domain or global capability promotion and no interval coverage claim.
