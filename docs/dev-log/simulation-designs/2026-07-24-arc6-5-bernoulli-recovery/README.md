# Arc 6.5 Bernoulli × Bernoulli recovery specification

**Authority:** the owner explicitly approved Arc 6.5 execution and a Totoro simulation in thread `019f9041-2a97-7850-b8d5-79ebe96a2aa9`. This is point-estimate recovery, not interval or coverage work.

The all-attempt ledger crosses sample sizes 120, 300, and 600; balanced and asymmetric prevalence designs; and latent associations -0.5, 0, and 0.5. The gate requires every interior attempt to return an estimate and each cell's absolute mean bias to be no larger than 0.10. Rare `p1≈0.04` high-association cases remain `hold` rows in the raw ledger and cannot pass the recovery gate. The runner refits both logit margins and then estimates the association, so it reports plug-in two-stage point recovery and retains stage-1/stage-2 failures.
