# Retained negative startup pilot

`public-001.log` is a real R attempt, not a no-start shell artifact. JuliaCall
started Julia but its `install_dependency.jl` helper returned status 1; the
runner recorded `JULIA_LSS_BOOTSTRAP_PUBLIC_FAIL elapsed=8.875`. It produced no
fit, interval, or receipt and cannot support an inference claim.

The separate sandbox-wrapper `nice(5)` refusal occurred while supervising an
earlier background command. Keep it distinct from this JuliaCall startup
failure. Both are superseded operationally by the retained successful
`public-003` receipt; neither is deleted.
