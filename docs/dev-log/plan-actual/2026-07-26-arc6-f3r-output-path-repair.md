# Arc 6 F3R output-path repair — plan versus actual

## Plan

Canonicalize the approved relative output path against the package root, retain
the exact SHA-specific no-overwrite target, add a literal-command regression
test, clarify the approval packet, and do not invoke F3.

## Actual

The repair added package-root canonicalization before the existing exact path
comparison. The packet now states that relative paths are package-root relative.
The focused suite passed 48/48. No runner, data generation, fit, retry, F4, or
public interface was used.

## Reconciliation

**Adaptive:** formatter-induced broad churn was immediately reverted.
**No drift:** the final patch is limited to the planned runner, test, and packet
contract. A new SHA is required before any replacement F3 authorization.
