# Invalid AOI-2D3 local replay attempt — do not analyze

This directory preserves a stopped local diagnostic replay attempt. It is not
evidence and must not be combined with any later replay result.

The original batch runner resolved `git rev-parse HEAD` independently in each
child. An internal summary-tool commit made the 14 completed rows carry two
different source SHAs: nine rows at
`0ac5724bd9cdd9842cf1b8b8a260ce5b4a18549e` and five at
`b3f7c592ab5c231d9c4de894ac2a0b38f0d9ff0c`. The run was stopped before
completion, preserving the partial rows for provenance rather than deleting
them.

The frozen 113-key manifest is unchanged. The replacement runner pins one
replay SHA at batch start and passes it to every child through
`AOI2_SOURCE_SHA`; its one-key local smoke verified exact raw/dispatch SHA
identity at `e9375dbed4243e1e9d9f17b36a7236b29db55685`.

No retained Rorqual r3/r4 output was modified. No AOI-3, public API,
documentation, capability, point-recovery, or uncertainty claim follows from
this invalid attempt.
