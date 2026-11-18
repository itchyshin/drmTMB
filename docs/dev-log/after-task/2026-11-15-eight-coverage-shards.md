# After task: eight coverage shards

The release candidate partitions the same R test-file list across eight coverage jobs and lists all eight reports in the trusted main-branch uploader. A preflight rejects a missing, empty or non-file report before upload. The producer's permissions and the uploader's main-only trust conditions are unchanged.

The change and local checks are recorded in `docs/dev-log/check-log.d/2026-11-15-eight-coverage-shards.md`. An independent review also examined a separate combined prototype with PR #1691; that prototype passed 13 local workflow tests but was not integrated or run on GitHub. No runtime reduction or upload success is claimed until the final candidate runs. The overlap with #1691 remains for reconciliation.
