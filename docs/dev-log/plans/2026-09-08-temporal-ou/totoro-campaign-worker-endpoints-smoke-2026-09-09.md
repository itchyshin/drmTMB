# Totoro temporal OU endpoint-artifact smoke

A one-task smoke ran on Totoro through the existing ControlMaster connection at
source `e6387ce9523aea45b52334ea07dbace3b91b7211`, from an archived source tree
under `/home/snakagaw/hsq_work/temporal-ou-profile-smoke-e6387ce9`. It used one
BLAS thread, the worker's explicit ten-minute timeout, and campaign task 1.

The task passed and retained `raw-attempts.csv`, the fit result, provenance,
and `profile-intervals.csv`. The latter contains exactly the three prespecified
mean targets, their truth and point estimates, finite profile endpoints,
availability, all-attempt coverage flags, and `conf.status = "profile"`.
The recorded worker MD5 is `606e76514fac0c50b35fdeb61f10c659`; provenance names
the same source commit and two optimizer attempts.

This verifies only the frozen-worker staging and shard schema. It is not part
of the Fir retained campaign, carries no 1,000-replicate denominator, and
makes no calibration claim.
