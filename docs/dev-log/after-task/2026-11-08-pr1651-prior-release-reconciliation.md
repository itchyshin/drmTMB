# PR #1651: reconcile with prior release main

## Goal

Preserve the tested Julia source pin and both branches' evidence when combining
PR #1651 with drmTMB release main.

## Changes

The frozen check log keeps the main-branch header; the PR's historical entry
already exists in a separate check-log fragment. The compatibility ledger keeps
both branches' historical claims and points to a new combined-source receipt.
No model or formula implementation was changed by the conflict resolution.

## Evidence

At combined source `ba09d0f52726c5f6cb0f4e39390b2027d57157a7`, the C17 runner
reproduced all three stored summary values exactly at zero tolerance. The 12
attempts passed their cell criteria. The capability-ledger check, 92 ledger unit
tests, and the C14 receipt-equivalence check passed. The local documentation
semantics test passed.

## Limits and next checks

The focused documentation test did not exercise a live Julia bridge. The first
receipt attempt exceeded its 80-second estimate and was stopped; its partial
output is retained outside the committed receipt. CI and review on the final PR
head remain required. This receipt does not widen the zero-one-beta capability
claim or establish current R–Julia parity.
