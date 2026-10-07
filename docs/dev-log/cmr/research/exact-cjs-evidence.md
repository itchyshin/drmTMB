# CMR M0: exact fixed-effects CJS evidence

**Status:** local primary-source synthesis, 6 October 2026. The frozen programme contract is at [`../contract.md`](../contract.md). NotebookLM account: `itchyshin@gmail.com`, selected visibly in the separate Chrome profile. Exact-CJS notebook: `834503ae-aa6c-4e4a-a3fd-b57b01f69724`, “CMR M0: Exact CJS conditioning and likelihood”.

## Findings

The ordinary Cormack–Jolly–Seber likelihood is conditional on an individual's first capture. It models the observed suffix after that capture, not the probability that an animal entered the marked sample. The official Stan guide says histories with no captures are irrelevant to this conditional likelihood and that an individual first captured on the final occasion supplies no information. This aligns with the plan's exclusion of abundance, entry, and unseen-animal augmentation from the first CJS slice.

For complete, consecutive occasions, write (f_i) for the first capture and (l_i) for the last. Let \(\phi_t\) be apparent survival from occasion \(t\) to \(t+1\), and \(p_t\) be detection at occasion \(t\). The conditional contribution is

\[
L_i = \left\{\prod_{t=f_i}^{l_i-1} \phi_t\,p_{t+1}^{y_{i,t+1}}(1-p_{t+1})^{1-y_{i,t+1}}\right\}\chi_{l_i},
\quad \chi_T=1,
\quad \chi_t=(1-\phi_t)+\phi_t(1-p_{t+1})\chi_{t+1}.
\]

The product accounts for required survival and the observed capture or noncapture through the last capture. The tail \(\chi_{l_i}\) sums every possible future path that produces no further capture: death before the next occasion, or survival followed by nondetection and another no-capture tail. This recursion is a collapsed two-state alive/dead calculation. Direct finite-state summation and this recursion are two representations of the same observed-history probability, provided they use the same conditioning and endpoints. Giménez and Choquet derive this CJS contribution and recursion, and Stan gives both the recursion and the corresponding latent-state interpretation.

When terminal survival \(\phi_{T-1}\) and detection \(p_T\) are free, independent time-specific parameters, the standard CJS likelihood identifies their product, not the pair separately. This does not imply that coefficients shared across periods are unidentifiable: cross-period constraints can identify shared coefficients using information from other periods, subject to the design. A final-first history has an empty conditional suffix and contributes one. The plan is therefore right to reject an unrestricted terminal pair or require a documented identifying constraint. Do not report the terminal product as separate estimates of survival and detection.

The standard history notation treats a recorded zero as a surveyed non-detection. A skipped survey is different: its emission is unobserved and contributes no detection/non-detection factor, although survival transitions across elapsed intervals remain. That mask rule follows from the observation model, but it was not directly established by the retrieved CJS passages. The fixed-effects implementation should state it explicitly and test it against enumeration, including the limiting check that inserting an unsurveyed occasion leaves the likelihood unchanged when the same survival interval is represented. Treating a skipped occasion as zero changes the model.

Likewise, \(s^\Delta\) for a positive interval length \(\Delta\) is an added constant per-unit survival assumption. It agrees with repeated independent unit-interval survival when \(\Delta\) is an integer. It is not a consequence of conditioning on first capture. Define the time unit and admissible interval scale; test composition numerically. A time-varying survival predictor must be constant over the interval or the interval must be segmented, as the contract says.

The sources do not establish inference quality for random-effect variances, adequacy of Laplace approximation, a predictor-dependent random-effect SD, selection correction, or performance of either package implementation. Those require their own evidence and gates. The NotebookLM answer became ready after this synthesis was drafted. It agrees on conditioning, first/last capture roles, and the chi tail, but explicitly says terminal parameter identifiability is absent from Giménez and Choquet (2010); that claim is instead supported by the official Stan guide.

## Source record

| Source | Primary status and readable claim | Notebook import |
|---|---|---|
| Stan, *Stan User's Guide*, §7.3 [2.31 CJS guide](https://mc-stan.org/docs/2_31/stan-users-guide/mark-recapture-models.html) | Official software guide. Directly documents first-capture conditioning, latent alive/dead state, \(\chi\) recursion, final-first noninformation, and terminal product identifiability. | Attempted in exact-CJS notebook; UI showed **Error info**. Content was independently read through the official guide search result. |
| Giménez & Choquet (2010), “Individual heterogeneity in studies on marked animals using numerical integration: capture–recapture mixed models,” *Ecology* 91:951–957, [doi:10.1890/09-1903.1](https://doi.org/10.1890/09-1903.1), [author-hosted full PDF](https://oliviergimenez.github.io/pubs/Gimenez%26Choquet2010Ecology.pdf) | Primary article. Its CJS section states the likelihood conditional on first capture, defines first and last capture, gives the no-future-capture recursion, and extends the model to individual random effects integrated by Gaussian-Hermite quadrature. Full author PDF was imported and reached ready state. | Ready. Notebook query for a cited synthesis was submitted; response completed with source-linked sections and correctly marked terminal identifiability absent from the paper. |
| Laake et al. (2013), “marked: an R package for maximum likelihood and Markov Chain Monte Carlo analysis of capture–recapture data,” [doi:10.1111/2041-210X.12065](https://doi.org/10.1111/2041-210X.12065); [CRAN manual PDF](https://stat.ethz.ch/CRAN/web/packages/marked/marked.pdf) | Primary package paper plus official manual. Paper describes encounter histories and conditioning on initial release; manual documents CJS data processing and positive `time.intervals`. | Manual PDF was still **processing** at last check. |

## Contract check

No mathematical conflict found in the fixed-effects CJS core: the conditional target, final-first zero information, exact alive/dead marginalization, and terminal identifiability agree with the primary sources. The stated support for survey masks and interval-powered unit survival is a model specification that extends the standard sources, so it needs visible documentation and independent tests rather than a claim of literature-established behavior. Parent clarification resolves the apparent selection boundary: individual-only reference selection is allowed in M5; selection with shared site/year effects is deferred.

## Limitations and next evidence

This is not a software parity result. The Stan page did not import into the notebook; primary-source evidence here comes from the official guide viewed directly and the readable author manuscript. The official `marked` manual import later reached an available source row; readiness still needs a fresh check. The notebook contains three submitted source rows, including one failed; do not count all three as readable evidence.
