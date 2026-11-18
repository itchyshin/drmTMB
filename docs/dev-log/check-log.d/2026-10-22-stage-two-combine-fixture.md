# Stage-two combine test fixture repair

- Root cause: 3,000 result-file links in the combine test pointed into a deleted `/private/tmp` directory.
- Replaced those external links with self-contained metadata-only rows that intentionally omit `profile_level`; no model-fit results are synthesized.
- Native calibration self-test passed.
- Clean-current adapter Python suite passed 57/57 tests in 38.671 seconds.
- Stage-two R rule and first-look registry tests passed.
- Stage-two R combine test passed both the expected legacy metadata rejection and the sealed clean-current 12,000-attempt path without fits.
- Updated `.unlazy/general-sd-regression/GATES.md` with harness-only evidence; G5 remains open.
- This is harness-integrity evidence only. G5 and the programme goal remain open.
