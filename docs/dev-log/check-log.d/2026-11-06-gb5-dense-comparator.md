# 2026-11-06: Gaussian dense comparator retry

Issue #1678 tracks this failure. The macOS full check at `4acdff376e17c5c7ba4d90c203cfd618ecc083e2` reported
L-BFGS-B code 52 in the independent GB5 phylogenetic slope comparator. Its
existing likelihood comparison passed, but the failing optimizer's parameters
and gradient were not recorded.

The test-only comparator retains `factr = 1e3`, the same objective and bounds,
and the original 1e-5 log-likelihood comparison. A nonzero primary result is
retried with bounded `nlminb`; a failed retry remains a failure and prints both
attempts and final-point diagnostics. Eight controls passed, including rejection
of a forced failed retry. A forced primary code 1 exercises retry mechanics and
is not a reproduction of the GitHub code 52.

On the local Mac, the targeted phylogenetic test passed 13 expectations and the
full GB5 file with `NOT_CRAN=true` passed 111 expectations with two held-route
skips. Exact-head macOS CI remains required.
