# C17 recertification label validation (#1597)

`tools/recertify-c17.py` now accepts only 1–64 character labels beginning with
a letter or digit and containing letters, digits, `.`, `_`, or `-`. It rejects
invalid labels before reading the manifest or moving the committed receipt.
The regression test covers a slash traversal label and whitespace, asserting
exit status 2, no runner invocation, unchanged receipt and manifest bytes, and
no parked receipt directory.

`python3 -m unittest tools.tests.test_recertify_c17`: 5 tests passed.
`git diff --check`: passed. The new regression failed on the previous code:
`../escape` raised `ValueError` while naming failure output, and `bad label`
displaced the committed receipt and ran the mock runner. No package tests or
recertification fits were run. NEWS.md remains unchanged because its file-scoped
lane preflight found 177 refs with parallel NEWS.md work; add the release note
in a coordinated NEWS edit.
