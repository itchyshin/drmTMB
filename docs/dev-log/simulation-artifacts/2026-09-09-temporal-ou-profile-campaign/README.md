# Temporal OU fixed-`mu` profile campaign summary (2026-09-09)

`temporal-ou-profile-campaign-summary.csv` is the 9-row durable summary
(cells U1--U3 x three fixed `mu` coefficients, 1,000 data sets each) behind
the qualified OU profile-interval claim. It was recomputed from the 60
immutable Fir array `58908599` shard archives by
`tools/summarize-temporal-ou-profile-campaign.R` at source commit
`e57ed8c10ea7a715e58b4513ae17484d01b049a8`.

- SHA-256: `e303d8c3c688baf5ea3655a459d8f8215d8e85326eb6db86aa5dfb353b191cc5`
  (matches the hash recorded in
  `docs/dev-log/after-task/2026-09-09-temporal-ou-complete.md`).
- Copied verbatim on 2026-10-01 from Totoro
  `~/hsq_work/temporal-ou-profile-fir-e57ed8c1-campaign/`, where the 60 shard
  archives remain (they are not in git).

The summary qualifies fixed-`mu` profile intervals in these exact cells only;
it is not a general temporal coverage claim.
