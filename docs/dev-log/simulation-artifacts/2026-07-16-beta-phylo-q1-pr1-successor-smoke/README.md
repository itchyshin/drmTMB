# Beta phylogenetic q1 successor recovery smoke

**Status:** mechanical smoke only; not recovery evidence

This two-fit Totoro smoke ran from clean pushed head
`da1a2fcc93f32d544b060344ac0f5e680301e2bf` before the certification. It used
one independently seeded attempt in each frozen high-information cell:
`g = 512, m = 4` and `g = 1024, m = 4`.

Both fits returned convergence code zero, `pdHess = TRUE`, finite estimates,
zero warnings, and no boundary flag. Runtime was 11.3 seconds at `g = 512`
and 25.3 seconds at `g = 1024`. The one-replicate bias and promotion fields
are deliberately non-evidential; only the 800-fit certification adjudicates
recovery.

The smoke master seed was `2026071640`. Its two seeds are unique and disjoint
from every prior campaign and the certification design. The raw file SHA-256
is `cb6c946f8c7a9e21dcb9823d6cd017ddfe5f0752631afb99ab7c7e1f5bbf8971`;
the run-provenance SHA-256 is
`0563d2b3e58ed3a21b0be6f5d94d7ed3340825e377545f4226c8b14cf2d06bba`.
