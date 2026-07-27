# Arc 6 F3 — plan versus actual: local-helper preflight

## Plan

Run one approved replacement F3 from detached SHA `b1cf4d5d...`, then audit
its immutable provenance receipt. F4 was excluded.

## Actual

The exact command ran once after clean SHA/blob verification, but preflight
rejected the installed namespace before it loaded the approved local source.
No layout or receipt was created; no retry occurred.

## Reconciliation

**Adaptive:** receipt audit became a pre-layout lifecycle-failure audit.  
**No drift:** the runner was not rerun or modified, and F4 stayed locked.  
**Next decision owner:** Shinichi must approve a narrow local-helper lifecycle
repair and a later replacement F3 authorization.

