# rchk adjudication — drmTMB 0.7 platform-clean (2026-08-07)

**Run:** https://github.com/itchyshin/drmTMB/actions/runs/31195195196/job/92921626073  
**Ref:** `main` @ `744b9fbe`  
**Job conclusion:** failure (exit 1 from R-hub's `Fail for rchk errors` gate)

## Verdict: NOISE — TMB framework / abstraction limits (not a drmTMB-owned defect)

Matches the 0.5.0 independent readiness note: rchk findings confined to TMB headers;
`too many states (abstraction error?)` also fires on R internals (`bcEval_loop`,
`strptime_internal`, `RunGenCollect`) and on TMB's templated
`objective_function<double>::operator()` — expected for large TMB packages.

### Findings (all paths under TMB or R internals)

```
==== rchk bcheck =========================================
ERROR: too many states (abstraction error?) in function strptime_internal
ERROR: too many states (abstraction error?) in function bcEval_loop
ERROR: too many states (abstraction error?) in function RunGenCollect
ERROR: too many states (abstraction error?) in function objective_function<double>::operator()()
ERROR: too many states (abstraction error?) in function objective_function<double>::operator()()

Function MakeADFunObject
  [UP] ignoring variable info as it has address taken, results will be incomplete 
  [PB] has negative depth /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1512
  [UP] attempt to unprotect more items (4) than protected (3), results will be incomplete /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1512
  [PB] has possible protection stack imbalance /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1515

Function MakeADGradObject
  [PB] has negative depth /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:2275
  [UP] attempt to unprotect more items (3) than protected (2), results will be incomplete /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:2275
  [PB] has possible protection stack imbalance /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:2277

Function SEXPREC* EvalADFunObjectTemplate<CppAD::ADFun<double> >(SEXPREC*, SEXPREC*, SEXPREC*)
  [PB] has negative depth /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1241
  [UP] attempt to unprotect more items (4) than protected (3), results will be incomplete /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1241
  [PB] has possible protection stack imbalance /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1243

Function SEXPREC* EvalADFunObjectTemplate<parallelADFun<double> >(SEXPREC*, SEXPREC*, SEXPREC*)
  [PB] has negative depth /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1241
  [UP] attempt to unprotect more items (4) than protected (3), results will be incomplete /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1241
  [PB] has possible protection stack imbalance /github/home/R/x86_64-pc-linux-gnu-library/4.7/TMB/include/tmb_core.hpp:1243

Function memory_manager_struct::CallCFinalizer(SEXPREC*)
  [UP] ignoring variable x as it has address taken, results will be incomplete 

Function memory_manager_struct::RegisterCFinalizer(SEXPREC*)
  [UP] ignoring variable x as it has address taken, results will be incomplete 
Analyzed 26605 functions, traversed 3115377 states.
------------------------------------------------------
##[end-action id=__r-hub_actions_4.__run_6;outcome=success;conclusion=success;duration_ms=310533]
##[start-action display=Check for rchk
```

**Package-owned C/C++ paths:** only unused-variable `sigma_i` warnings in
`drmTMB.cpp` during the wllvm compile (compile noise, not rchk protection bugs).

**Disposition for platform-clean:** document + retain; do not treat as a
submission blocker. Re-open only if a finding cites `drmTMB`/`src/*.c` package
code rather than `TMB/include/tmb_core.hpp`.
