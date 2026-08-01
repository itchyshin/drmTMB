# Z4a local runner history

The first source-bound run on `a7922e417` retained all four attempts and
correctly returned `BLOCKED_LOCAL_FIXTURE`: the fixture calculated separate
per-group zero/one support after simulation, but its DGP had not enforced the
predeclared minimum. It is a fixture-contract failure, not point-recovery
evidence, and its four records are retained in this directory's Git history.

The corrected runner conditions the frozen local DGP on at least two zeros and
two ones in every group, records `dgp_draw`, and reruns all four seeds plus the
fixed-SD diagnostic from its own committed source. No earlier passing result is
used for promotion.
