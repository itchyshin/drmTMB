# First-look replay contract correction checks

- Archive audit: 3,000 result CSVs and 3,000 interval RDS files; all 3,000 result headers lack profile_level.
- Source comparison: archived hashes differ for R/drmTMB.R, R/methods.R, R/profile.R, and src/drmTMB.cpp; archived worker.R hash matches current worker.R.
- git diff --check: PASS.
- After-task validator: PASS.
- Prose checker: FINDINGS: 0.
- No fits or campaigns ran. The no-fit stage-two combiner regression passed with the expected legacy-replay rejection marker in about two minutes.
- Fresh current-source first-look replay remains outstanding.
