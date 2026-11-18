# Bernoulli pilot compatibility and adapter qualification

The prior-stream validator now admits the exact frozen six-row pilot without an
explicit row ID while still checking its deterministic seed and truth ordering.
Qualification and production manifests still require explicit IDs. Python and
R negative controls pass, including a corrupted truth value in the legacy pilot.

The current-source adapter passed three selected Totoro fits in 32.725 seconds.
All converged, produced valid profile intervals, and passed the independent
Laplace oracle. The preparation and qualification receipts and three result
files are preserved under
`docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-qualification-20261019-v3/`.
The qualification receipt says `campaign_complete=false` and
`calibration_claim=false`. This does not complete the 9,000-fit campaign or
establish uncertainty calibration. Full programme gates G0-G8 remain open.

An independent inference review confirmed that each selected fit converged,
had a positive-definite Hessian and small maximum gradient, produced a valid
non-boundary profile interval, and passed the likelihood oracle. A follow-up
remote-to-local SHA-256 comparison now binds all six health and interval RDS
files. The RDS manifest SHA-256 is
`eebe30853d0c7f357145423fd771fc23f7ef95aee774f9d8d256eb7e1da1b679`.
