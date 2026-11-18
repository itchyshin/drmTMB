# Give the timed-out PR shard a bounded rerun

The release candidate's first GitHub test shard was cancelled after about 75 minutes while still running, matching its configured limit. Its proposed limit is 150 minutes; the test selection and other timeout limits are unchanged.

The separate Totoro run completed with warnings and skips, and does not certify the GitHub job. A fresh exact-head run and reconciliation with the other workflow lanes remain open.
