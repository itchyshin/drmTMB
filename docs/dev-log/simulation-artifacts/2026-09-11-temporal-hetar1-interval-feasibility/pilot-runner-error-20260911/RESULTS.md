# Interrupted heterogeneous-AR1 interval-feasibility pilot

The first frozen-pilot invocation stopped before emitting any fitted-result or interval files because the runner selected a non-existent `error` column from successful two-start attempts. No fixture result was written and no seed, model configuration or estimator result is claimed from this directory. The exact error is retained in the execution record; the repaired runner reruns the same five frozen C1 seeds into the separate `pilot/` directory without overwriting this record.
