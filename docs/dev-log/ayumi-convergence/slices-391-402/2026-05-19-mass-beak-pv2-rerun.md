# Mass-Beak PV2 Rerun And Bootstrap Prototype

Date: 2026-05-19

Branch: `codex/slices-363-full-ayumi-starts`

## Scope Correction

Ada reran the Ayumi feasibility check on the correct Issue #1 target:
body mass plus beak length, with beak length conditioned on body mass. The
earlier full-species lightness stress artifacts are useful for a separate
identifiability fixture, but they are not the Mass + Beak PV2 replication.

The rerun scripts now split the two body-mass roles explicitly:

- `Mass_z` is response 1;
- `Mass_cov_z` is the fixed allometric covariate used in the Beak location and
  scale submodels.

On the observed data `Mass_z` and `Mass_cov_z` are identical, so the fitted
PV2 locphylo estimates match the original issue report. During bootstrap they
must stay distinct, because replacing the simulated response should not
silently rewrite the fixed allometric covariate unless the bootstrap design is
explicitly conditional on simulated body size.

## Artifacts

Scripts:

- `tools/ayumi-mass-beak-pv2-rerun.R`
- `tools/ayumi-parametric-bootstrap-prototype.R`

Main rerun artifacts:

- `docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-rerun/`
- `docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-pv2-q4-main/`
- `docs/dev-log/ayumi-convergence/slices-391-402/mass-beak-bootstrap-4core/`

## Design Diagnostics

The ordinary fixed-effect design is not badly collinear:

| Diagnostic | Value |
| --- | ---: |
| Species | 6,196 |
| `cor(Mass_z, Beak_z)` | 0.816 |
| Condition number, Beak location design | 5.017 |
| VIF, `Mass_cov_z` | 1.011 |
| Beak-on-Mass allometric slope in fixed design | 0.815 |
| Beak fixed-design R2 | 0.683 |

The issue is therefore not ordinary predictor VIF. It is model-geometry
confounding: Mass is a response, an allometric conditioning variable for Beak,
a phylogenetically structured trait, and strongly correlated with Beak.
Residual `rho12`, phylogenetic `mu1`-`mu2` correlation, and q4
location-scale correlations can all try to explain overlapping structure.

## PV2 Locphylo Anchor

The corrected locphylo rerun used phylogenetic effects in `mu1` and `mu2` only,
with Beak conditioned on `Mass_cov_z` in `mu2` and `sigma2`.

| Model | Seconds | Convergence | `pdHess` | logLik | AIC | Residual `rho12` | Phylo `mu1`-`mu2` |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: |
| `PV2_locphylo` | 123.4 | 0 | TRUE | -4226.204 | 8504.407 | -0.789 | -0.841 |

This reproduces the stable signal from the bergmann issue: strong negative
residual coupling and strong negative phylogenetic location-location coupling
after climate, phylogeny, and allometric conditioning.

## PV2 Fallback Gap

The prereg fallback still aborts at parse time:

```text
Matched phylogenetic q=4 location-scale terms need the same block, group, and tree.
Blocks: "pl", "pl", "ps", and "ps".
```

This is the package gap the next implementation should close. Ordinary
bivariate random-effect blocks already support different labels as separate q2
blocks. The phylogenetic structured path still uses one `phylo_mu` structure,
so the equivalent phylogenetic block-diagonal q2 fallback needs a real
representation change, not only a softer parser message.

## PV2 Main Q4 No-SE Rerun

The full q4 model was rerun with `drm_control(se = FALSE)` to skip Hessian
standard errors and capture the selected optimizer state. It took about
20 minutes.

| Model | Seconds | Convergence | Hessian | logLik | AIC | Residual `rho12` |
| --- | ---: | ---: | --- | ---: | ---: | ---: |
| `PV2_main_q4` | 1197.3 | 1 | skipped | -4156.271 | 8378.543 | -0.984 |

The lower objective does not make the q4 fit interpretable. `check_drm()`
reported false convergence, a fixed-gradient warning with maximum component
`log_sd_phylo[2] = 123.1`, boundary residual `rho12`, and near-boundary q4
phylogenetic correlations. The largest absolute q4 correlation was 0.998.

Selected q4 correlation estimates:

| Correlation | Estimate |
| --- | ---: |
| phylo `mu1`-`mu2` | -0.993 |
| phylo `mu1`-`sigma1` | 0.984 |
| phylo `mu2`-`sigma1` | -0.998 |
| phylo `sigma1`-`sigma2` | -0.717 |
| residual `rho12` | -0.984 |

This supports Fisher's interpretation: q4 is not merely "hard Hessian"; it is
currently a boundary/identifiability problem for this model geometry.

## Bootstrap Prototype

Ada added a developer-only conditional parametric bootstrap prototype. It:

1. loads a source fit;
2. simulates bivariate Gaussian responses with `simulate()`;
3. keeps `Mass_cov_z` fixed as the allometric covariate;
4. replaces only response columns `Mass_z` and `Beak_z`;
5. refits with `drm_control(se = FALSE)`;
6. writes convergence, objective, residual `rho12`, phylogenetic `mu1`-`mu2`,
   and the Beak-on-Mass allometric coefficient.

Parallel controls are environment variables:

```sh
DRMTMB_BOOT_R=100
DRMTMB_BOOT_CORES=20
DRMTMB_BOOT_BACKEND=multicore   # one of none, multicore, psock
DRMTMB_BOOT_ITER_MAX=1000
DRMTMB_BOOT_EVAL_MAX=1000
```

The first interpretable smoke used 4 bootstrap replicates on 4 cores with a
1000/1000 optimizer budget. All four refits converged with code 0.

| Quantity | Bootstrap range |
| --- | ---: |
| Seconds for all 4 refits | 113.8 |
| Per-refit elapsed seconds | 97.5 to 113.7 |
| Residual `rho12` | -0.822 to -0.767 |
| Phylo `mu1`-`mu2` | -0.889 to -0.881 |
| Beak-on-Mass coefficient | 2.083 to 2.116 |

This is not a final uncertainty estimate. Four replicates are only a mechanics
check. It does show that bootstrap can give stable refits for the locphylo
anchor when the allometric covariate role is fixed explicitly.

## Decisions

- Parametric bootstrap is a sensible fallback when the Hessian fails, but only
  when the selected optimum is a defensible estimand.
- For q4 PV2-main, bootstrap should be used as an instability diagnostic before
  it is used as an uncertainty interval. False convergence, large gradients,
  and boundary correlations make q4 bootstrap intervals scientifically risky.
- The first real bootstrap target should be `PV2_locphylo`, not q4.
- Profile CI and bootstrap share the same repeated-refit structure. A future
  package-level refit backend should support serial and parallel execution,
  bounded worker counts, deterministic seed streams, and explicit failure
  ledgers.

## Next Work

1. Implement the phylogenetic block-diagonal fallback: one q2 location block
   and one q2 scale block with no location-scale cross-correlation.
2. Add a public or semi-public bootstrap design only after the refit backend,
   seed contract, and failure reporting are stable.
3. Extend `check_drm()` with a q4-specific recommendation when q4 correlations,
   residual `rho12`, and gradients hit the boundary together.
