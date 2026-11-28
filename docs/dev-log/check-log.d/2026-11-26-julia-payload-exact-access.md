# Julia payload field access

The exact-source 24-shard drmTMB run on `fee04c81143f85781ce848e857aee146bcddcc4d` completed with 22 shards passing and two failures. Shard 12 failed the provenance test because its `TMPDIR` was outside the package clone but still resolved inside the parent `/home/snakagaw` Git worktree. A focused replay with `TMPDIR` under `/tmp`, outside that worktree, passed the provenance test. Shard 2 exposed a separate source-contract failure: `drm_julia_validate_fixed_priors_v2_result()` read raw result fields with `$`, while `test-julia-payload-exact-extraction.R` requires exact `[[ ]]` access.

The validator now uses `[[ ]]` for each `result` field. Verification passed locally with `Rscript --vanilla -e 'devtools::test(filter="julia-payload-exact-extraction", reporter="summary", stop_on_failure=TRUE)'`; `git diff --check` also passed. The corrected file contains no `result$` access.

The full package run on the pre-fix source remains diagnostic and red. A complete exact-source rerun is still required. Its launcher must place each shard's `TMPDIR` outside every enclosing Git worktree; the previous `$RUN/tmp/shard-12` location is under `/home/snakagaw`, which is itself a Git worktree. No Julia live-engine bridge tests ran in the focused local replay.
