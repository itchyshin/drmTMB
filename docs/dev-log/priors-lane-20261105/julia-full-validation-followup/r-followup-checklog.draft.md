# Julia prior validation follow-up

The unchanged Julia source aggregate a30e3472 passed all eight default-suite
shards on Julia 1.10.10: 554/554 selected files, JET executed, optional parity
off. Wall time was 2h11m31s. The crossed-Tweedie file took 113m40s, longer than
the original 90-minute total budget. No assertion or tolerance changed.

This supersedes the earlier pending full-suite disposition, while preserving
that original run as INCOMPLETE. R source remains 64956560; no R code, test,
cleanup or PR #1651 work changed. No push, merge or release. The Julia report
and source/runtime/hash receipts identify the exact checked environment.
