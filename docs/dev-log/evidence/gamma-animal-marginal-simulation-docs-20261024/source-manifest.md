# Julia Gamma animal marginal-simulation documentation receipt

This receipt records the current candidate sources used by the focused test
rerun. The working tree was dirty and shared with other implementation work;
these hashes identify the exact files, not a release artifact.

Native candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`  
Julia candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`

| File | SHA-256 |
|---|---|
| `R/methods.R` | `3eb2f7e5e04c8c963fe6c1777a9adfcdffd875a3c64d19d040e0ff07420263f2` |
| `R/julia-simulate.R` | `28e9b6cc0433b4534b658aae4a47e667242eeec49105a54d8d4baf2080d2bdb8` |
| `man/simulate.drmTMB.Rd` | `f4fe6ef3fedd47c9635f4155fc495b3dc4e77c24a1e9b85a8bed7d50ea983f46` |
| `vignettes/julia-engine.Rmd` | `225532b0b39c376043f586baca6ab66aab32514526706514e423f0fd8ddebc2d` |
| `tests/testthat/test-julia-gamma-animal-intercept-simulation.R` | `46cd833146eb56e9beeac2238d1e51fb4b53853953bd88cd811839390d2dee15` |
| `tests/testthat/test-gamma-animal-q2-cross-engine-sd.R` | `6c124c5ce8f3669472c6349e50807ee9aedf07c2be054c52ac3c8617b661269a` |
| Paired Julia `src/gamma.jl` | `a3065b51bdaae48cd6862274145052c3700829cd1c4ae208dde91b95f88ace19` |
| Paired Julia `src/sparse_laplace_glmm.jl` | `cc1d5354ad8758ef3fb5e3e9cba1ba14cc1bfaadde101ffb626e96b243bc325b` |
| Paired Julia `test/test_gamma_animal_intercept_slope_sd.jl` | `1f7bd590b37dd46b79b9426a5f8dd9931731b480df8c913bc4e5c92b94b5b12b` |

The captured focused test console is in `test-console.log`. Four live Julia
tests passed: combined-target fit/parity, non-unit-kernel fit parity, corrected
non-unit-kernel q2 simulation, and q1 intercept simulation.
