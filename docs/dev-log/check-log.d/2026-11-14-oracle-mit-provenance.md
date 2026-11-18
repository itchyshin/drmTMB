# Two-intercept oracle provenance

Shinichi confirmed MIT terms for the identified oracle scripts and fixtures. This change adds the MIT notice, source generators, verification scripts and their original manifests beside the frozen R fixtures. The existing frozen JSON files are unchanged.

On 14 November 2026, both manifests matched the copied files. `verify.py` passed 90 points, 12 fits and seven controls; `verify_asymmetric.py` passed 60 points and eight fits. The replacement converter reproduced the Julia numeric fixture byte for byte with SHA-256 `b64bf2cfaa027996e40865ff1d20cf5be4042d617349ad56ea8bf95d0ffc77b6`. These checks used the retained Miniconda interpreter with threads capped. The original converter and original SciPy version remain unrecorded.

The prior full R checks apply to parent `15513ed7a`, before this provenance-only addition. Full checks on this new commit remain to be run. The scope excludes the protected PR #1651 history.
