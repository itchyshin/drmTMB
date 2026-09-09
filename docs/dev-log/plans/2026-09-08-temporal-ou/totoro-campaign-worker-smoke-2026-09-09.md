# Totoro temporal OU campaign-worker smoke

The first archived-source smoke omitted `.git`, so its worker record could not
fingerprint the source. That smoke is diagnostic only. The worker now requires
`DRMTMB_TEMPORAL_OU_SOURCE_COMMIT` in campaign mode.

The corrected smoke ran campaign task 1 on Totoro from archived source
`0e3c792cb5d96ccf0b0b83f422c937712765158e`, with one BLAS thread and a
10-minute hard timeout. It emitted `TEMPORAL_OU_PROFILE_CAMPAIGN_TASK_PASS` and
retained two optimizer starts. Its provenance record has the source commit,
runner MD5 `b29f2cf56bb077c48c9c36b619a55bfa`, campaign mode, task `1`, one
data set, and two attempts.

This verifies source staging and the fail-closed worker contract. It is not a
Fir result, a coverage denominator, or a replacement for the authorized
3,000-task DRAC retained campaign.
