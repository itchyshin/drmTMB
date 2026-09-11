# Plan versus actual: phylogenetic-temporal OU parser/layout

## Planned

Admit the explicit `phylo()` plus same-ID OU pair, reject all wider formula and
metadata shapes, and preserve raw and retained-data checks.

## Actual

The existing native provider already accepts both independent latent blocks once
the old generic structured-effect exclusion is replaced by the narrow paired
contract. The parser slice therefore changed only R layout and validation code.
It added a named paired-layout flag and stronger raw/retained support checks.

## Difference and decision

No native source was edited. A successful point fit is retained as a parser
integration check only; it does not discharge the independent oracle or
likelihood gates.
