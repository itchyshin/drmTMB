# DRAFT — note to Russell Dinnage with the response map

Status: POSTED 2026-09-15 as an issue in Russell's private repo (his instruction: "post it in his repo"): https://github.com/rdinnager/drmTMB_eval/issues/1
Not posted on #1306; no public @-mention (his repo is private, so the choice to go public stays his).
Register: EMAIL-VOICE (a) close collaborator. Links resolve on `main` as of 958d7c560.

---

Subject: drmTMB - what we did with your evaluation

Hi, Russell

Thank you for the evaluation. It was the most useful review the package has had, and I wanted to show you what came of it rather than just say thanks.

Every finding is now a GitHub issue with your name on it (label `audit-dinnage`, 55 issues, #1306 to #1360). The finding-by-finding map is here, with each item re-checked against the code rather than taken from the report:

https://github.com/itchyshin/drmTMB/blob/main/docs/dev-log/audits/2026-09-13-dinnage-independent-evaluation-response.md

Where things stand on `main`:

- The Critical (C1, the one-armed clamp detector) and nine of the ten Majors are addressed. The weights-inside-mi() bug (M1) was real at all twelve quadrature sites, not just the Bernoulli one; sigma(), predict() and friends now report the clamped scale the likelihood actually used (M2); simulate() no longer leaks the missing-response sentinel (M4); vcov(type = "robust") and AIC() with a foreign model now fail loudly instead of quietly (S4, S5).
- Two we handled differently, and the closing comments say so. The phylogenetic penalty (S3) stays as it is; we decided the fix was the help page, which now tells the truth about the log-scale MAP. The fixed_gradient false positives (M3) no longer reproduce after a Newton polish that landed for another reason, so we locked that with a test, but your sqrt(n) point about the absolute tolerance is unanswered and the issue comment says that.
- The bootstrap interval bias (S6) has a design note; the code is next.
- 17 issues are closed with an evidence comment each. 38 are open (the Moderates, Minors and UX items) and we will work through them; if a closing comment misreads your finding, reopen it.

One thing in your report we could not have produced ourselves: about 14.5% of `R/` was never read by any of your runs, including meta-vcov.R, penalty.R, mesh.R and sparse-fixed.R. If you ever run the swarm again, those are the files I would point it at.

Best wishes

Shinichi

P.S. - Still keen to talk about the TabPFN imputation package when you have a moment.
