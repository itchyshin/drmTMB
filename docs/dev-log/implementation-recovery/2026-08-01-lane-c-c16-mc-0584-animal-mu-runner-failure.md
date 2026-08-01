# C16 `mc-0584` animal recovery runner failure

On source `f59d43f0d0d18f9443555cf084d438ad114f617c`, the strengthened recovery
runner was invoked for the planned four-seed rerun. It stopped before writing
attempt rows because `ranef(... )` returned an unnamed mode vector and the
runner indexed it by the simulated species names:

```text
Error in stats::cor(mode[names(sim$u)], sim$u) :
  supply both 'x' and 'y' or a matrix-like 'x'
```

This is a runner-accounting failure, not a fitted-model result. The succeeding
rerun must name the vector from `fit$model$structured$phylo_mu$node_labels`,
retain all four resulting rows, and keep this event in the C16 audit trail.
