# Completed win-builder result identification

The final immutable candidate was uploaded to all three win-builder arms at
2026-08-19 01:51–01:52 UTC. Therefore a result URL generated before that time
cannot belong to candidate `1d6445db…`, regardless of the shared package name
`drmTMB_0.7.0.tar.gz`.

For each arm, the packet now archives:

1. the notification email or an honest transcript/screenshot when available;
2. the random result URL and directory listing;
3. the complete `00check.log`;
4. the examples and tests indexes;
5. the raw `testthat.Rout` output;
6. installation/check timestamps, R version, NOTE status, and test counts;
7. the existing upload trace, client SHA-256, and exact size.

All three requirements are complete except that full notification email bodies
were not supplied; the maintainer supplied the labelled random URLs instead,
and this gap is declared in `winbuilder-maintainer-url-transcript.md`. The
association is a client-side chain of custody. win-builder does not attest
the uploaded server-side SHA-256.

Previously supplied URLs `418jnDxdX8gy`, `uCbpi6X2Ro3u`, and `U246pNXO3CGX`
were generated before the final upload and are retained only as predecessor
evidence. They must not be repointed to this candidate.
