# 2026-10-20: Clean-current adapter qualification case mapping

Added `adapter_qualification_cases()` to the clean-current look-two manifest
module. It revalidates all three batches against the frozen `look2.csv` and
returns one source-bound probe per truth at local indices 1, 1001, and 2001
(global stage-two rows 1, 4001, and 8001). The check rejects a changed probe
identity.

The new tests first failed because the function was absent, then passed after
implementation. Running the test class alone also exposed an existing setup
dependency on another test class; setup now imports its own adapter and
manifest.

Checks:

- `python3 -m unittest test_stage_two.py`: PASS, 45 tests.
- `python3 -m py_compile clean_current_stage_two.py test_stage_two.py`: PASS.
- `git diff --check`: PASS.

The remote v7 qualification receipt is PASS for the legacy manifest SHA-256
`8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96`. The
clean-current `look2.csv` is SHA-256
`7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98`; the old
receipt does not qualify this source. The exact source-bound v4 library remains
on Totoro and its registered DLL/R database hashes matched on readback. No
worker or stage-two process was running during the read-only check. No fit was
launched in this slice.

GitHub issue searches found no matching adapter issue. #496 concerns the
separate GVA/Laplace programme; no issue was changed. The clean-current
prepare/run adapter qualification and its three real probes remain open; the
current work proves source identity mapping only.
