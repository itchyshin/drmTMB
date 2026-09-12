# Fixed-tree true-covariance GLS diagnostic receipt

This no-fit diagnostic independently regenerated the same 15 fixed-tree datasets
used in the retained profile pilot and computed ordinary Gaussian GLS intervals
from their known generating covariance matrices. It ran locally in 1.76 seconds
(single process, thread limits one); it did not launch `drmTMB()` or alter a G12
archive.

For the five pilot draws per cell, exact-covariance GLS intercept coverage was
4/5, 5/5, and 5/5 in P1--P3, compared with default-profile coverage of 3/5,
4/5, and 5/5. This small diagnostic cannot estimate coverage. It does establish
that the generating covariance calculation yields wider mean intercept intervals
than the profile in P1 and P2 (1.370 versus 1.253; 2.438 versus 1.983), while
P3's profile interval is wider (1.601 versus 1.235). Together with the
fast/default and dense-profile checks, this makes covariance-parameter
estimation the leading remaining explanation, not a demonstrated cause.

The verified output files have SHA-256 values:

- `RESULTS.md`: `b45bb62a8fadac0f9bc2c5b0cd55cf8802bb0fbd0197fdfeee2b93763821c25c`
- `summary.csv`: `eb92ba2bcacaa048fc0189f3cc52d7076198b926f363faed02d7e222d6633ca2`
- `replicates.csv`: `9d82fc87cfaa3f342b93bf6f5c2b310551fd5de04c6d08efcf4db5aa3a9e5d70`

Totoro retains the byte-matched output under
`/home/snakagaw/drmtmb-campaigns/phylo-ou-g12-384048d7-20260910/2026-09-10-phylo-temporal-ou-g13-fixed-tree-truth-gls-r2`.
