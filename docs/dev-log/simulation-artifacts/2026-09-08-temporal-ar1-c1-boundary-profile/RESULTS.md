# C1 fixed-residual-SD likelihood profile

This diagnostic fixes the residual SD over a predeclared grid and re-optimizes all other AR1 model parameters from both signed persistence starts. It uses the immutable C1 seed 2026091002 and does not alter the pilot or start a campaign.

The CSV files retain both starts and the selected objective at each fixed residual SD. `delta_nll` is relative to the smallest selected objective on this finite grid. Conditional Hessian status applies only to the model with residual SD fixed; it is not a Wald qualification for the original free-sigma model.
