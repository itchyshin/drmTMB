Final numerical validation covers R source `8998056d75b9e1fe9d66264cb4ae35e025535e21` and Julia source `727ac08590749aef2165337e1e6391b0894f6d6c`.

The Mac reference host reproduced all three C17 summary values exactly at tolerance zero. All 12 attempts passed their original cell criteria, the recertification wrapper exited successfully, and all 92 ledger unit tests passed. Both prior and incoming main receipt histories were preserved before this fresh recertification.

On Totoro, the optimized R installation passed 517 expectations across 96 targeted tests, with zero failures or errors, one boundary warning and one explicit development-mode skip. The six R negative controls rejected all prescribed mutations. Julia passed all 82 focused prior assertions, including the independent ridge oracle.

The five live R–Julia fixtures passed the original pair checker. Maximum observed differences were 4.30e-11 for coefficients, 1.07e-12 for data log likelihood, 1.07e-12 for the prior contribution, 7.11e-15 for the total objective, and 1.08e-12 for the prior gradient. The verifier checked 999 R code/test blobs and 950 Julia Project/source/test blobs against the declared commits, then rejected both prescribed mutated pair receipts. The committed original checker and its remote copy have Git blob `840c71572c61bfede7bff00d7f6e229f1f65c942`, unchanged from the earlier candidate.

Two live-pair attempts exited 139 during JuliaCall initialization, before model fitting. The successful repeat used the previously documented launch-only preload of Julia 1.10.10's bundled libunwind. Both failures and the qualified command are retained in `totoro/`; this does not establish out-of-box bridge startup on other hosts.

The per-host summaries and raw logs define the scope of these checks. Final PR CI, post-merge release checks and publication are still pending. These fixtures do not establish calibration, broader family support or general package equivalence.
