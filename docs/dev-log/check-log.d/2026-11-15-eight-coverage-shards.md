# Check log: eight coverage shards

The first coverage shard of release candidate `e65cd0ac64edc425383cc6e8009267e98a0cd216` was cancelled after 180 minutes while its test step was running. The other three coverage shards passed. The cancellation matched the configured limit; its initiator was not established.

At candidate commit `4216c0418`, the following local checks passed:

- `TMPDIR=/private/tmp python3 tools/tests/test_codecov_workflow.py`: nine tests, including runtime controls for each missing, empty and directory report path.
- `yaml::read_yaml()` parsed three workflow files, including both changed by the eight-shard commit. The first partition-check command had a quoting error and did not run its partition assertion; the corrected command verified that all 897 test files are allocated exactly once across eight shards.
- A separate 1/32 covr smoke on the `e65cd0ac` source completed in 426.14 seconds and generated a Cobertura report, with one existing-directory warning. It tested the coverage setup for that subset; it does not establish full-shard runtime or full-suite coverage.

PR #1691 also changes the coverage workflows and their contract test. Its branch remains unchanged and must reconcile the eight R reports with its separate Julia-bridge report. The uploader requires all eight nonempty R files before uploading. Older in-flight four-shard producer runs that meet the new uploader will fail closed and need a rerun. Codecov upload, hosted eight-shard runtime, complete test execution and the final release artifact remain unverified.
