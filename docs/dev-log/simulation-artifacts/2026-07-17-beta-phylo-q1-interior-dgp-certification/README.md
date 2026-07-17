# Beta phylogenetic q1 interior-DGP certification receipt

The complete atomic output remains local on Totoro at
`/home/snakagaw/drmtmb_work/beta-phylo-q1-interior-evidence-863f7dab/certification-retry2`.
This tracked receipt records the authenticated, compact result rather than
copying a campaign into Git.

- Source: `863f7dab4059447510e9e5f10c1192c75f4c3e9a`.
- Runner SHA-256: `d91de29555ceea3a69841c1f225db33b10ecbcbb2abcd3ca1aa6e912c2853dc3`.
- Design SHA-256: `6d253e54c9f668b6009ab8e92e4af835e9d3b71b62557ef3e1ef75a45fc056a8`.
- DLL SHA-256: `91f9e92ec9de81050f4fc43775f220001fd91689aec177318f3e6e418f31c30a`.
- Completion-seal SHA-256: `4d54efa74dda3fd479bb9146a6fddfc6ad86e4d2289137ab151a45c7c8ab056c`.
- Contract: 12 cells x 400 retained attempts, 32 workers, pinned BLAS,
  L'Ecuyer-CMRG/Inversion/Rejection RNG.
- Decision: `PASS_EXACT_TWO_G1024_M4`. Both `g=1024,m=4` arms independently
  pass; all final generated responses are strictly interior and no cap was
  exhausted.
- Retained diagnostic: shared `g=256,m=2` has one warning and
  `pdHess=0.9975`; it is not a promotion arm and remains a stress-quality HOLD.

The stopped campaign is separate and remains immutable at `1c9bfd5f`; its
failed response-generation attempt is not part of this denominator.
