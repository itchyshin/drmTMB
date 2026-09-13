# R4: geometry-aware OU recovery preflight

R2 showed poor recovery in one moderate 128-species design, while R3.3 showed
that its small-tree ordering is not merely a numerical-integration artefact.
R4 therefore compares two fixed simulation regimes with the same native
independent-OU location/scale fitter: a weak, moderate-signal pair
`(alpha_mu, alpha_sigma) = (0.7, 1.3)` with SDs `(0.45, 0.25)`, and a
separated-rate, larger-amplitude pair `(0.3, 2.5)` with SDs `(0.8, 0.5)`.

Each has 128 species, 12 observations per species, one fixed tree/field seed,
and three dispersed non-truth starts. The preflight records all starts and
compares qualified status, boundary flags, and log-rate error by regime. It is
a local design screen only; multi-seed recovery needs a separate campaign
decision.
