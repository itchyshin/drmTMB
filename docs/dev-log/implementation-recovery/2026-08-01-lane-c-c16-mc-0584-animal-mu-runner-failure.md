# C16 `mc-0584` animal recovery runner failure

On source `f59d43f0d0d18f9443555cf084d438ad114f617c`, the strengthened recovery
runner was invoked for the planned four-seed rerun. It stopped before writing
attempt rows because `ranef(... )` returned an unnamed mode vector and the
runner indexed it by the simulated species names:

```text
Error in stats::cor(mode[names(sim$u)], sim$u) :
  supply both 'x' and 'y' or a matrix-like 'x'
```

This is a runner-accounting failure, not a fitted-model result. The first
repair named the fitted vector from
`fit$model$structured$phylo_mu$node_labels`; a second rerun showed that the
simulator also had to return its named true field. The succeeding rerun must
retain all four resulting rows and keep both runner events in the C16 audit
trail.
