GOAL: see GOAL.md.  STATE: overnight unattended run; owner away until 05:00 MDT.

ARCS DONE (verified by reading GitHub, not by an agent's report):
  13 drmTMB PRs merged 2026-09-05: #1172 #1174 #1183 #1186 #1175 #1195 #1194 #1192 #1185
  #1196 #1193 #1206 #1200.  DRM.jl merged: #638 #644 #645 #640 #648 #650 (+ earlier #643).
  #1206 was the urgent one: pkgdown::build_site() ABORTED on main (missing _pkgdown.yml
  topics from #1116/#1118) -- the docs site now builds again, with an alias-keyed guard test.

ARC IN PROGRESS:
  - Wave 3 (run wf_18c9e6ff-4ff, 10 leaves, opus/high): admit biv_student, biv_lognormal,
    zi_poisson, zi_nbinom2, hurdle_nbinom2 through engine="julia"; #1156 profile_targets;
    #1144 cutpoints; #1108 route diagnostics; verify DRM.jl #620's closure; docs staleness.
    LANDED = a PR number on GitHub. Nothing else counts.
  - Overnight integrator (overnight.sh, 10 h): PRIORITY list first, then DISCOVERS any open
    non-draft claude/parity-* PR each pass. Merges ONLY via pr_merge_when_green.sh.
    EXCLUDED: 1163 1191 1205 + the three dormant codex PRs.

NOT STARTED (relaunch when wave 3 frees capacity -- scripts already patched and parsing):
  - ci-blindspot wf_854e440d-1c9: DROP the reader-contract leaf (done, PR #1207); the other
    three are the nine missing cheatsheet exports, the conditioning premise-guard hole, and
    the CI source-tree lane.
  - night-wave wf_4fe9b709-acf: G3 profile inference, G3 bootstrap + #1188 mask-preserving
    replicates, DRM.jl #467/#609 factors, engine_control_surface, closure artefacts.

OPEN GATES (need the owner):
  - A10 full performance grid (pre-run receipt exists; D-139 requires an explicit go).
  - The non-Gaussian precision bar, draft PR #1191.
  - DRM.jl registry name (General requires >= 5 characters; "DRM" fails).
  - Any tag / release / CRAN / collaborator message. 0.7.1 is PREPARED, NOT tagged.

TRUTH LIVES IN:
  drmTMB origin/main (4c1f5a63a after #1206) and DRM.jl origin/main (518f489e8).
  Ledgers: .unlazy/parity/gates/leaf-*.md.  Lane kit: this directory.
  Pin: DRM.jl 430ef64cc at ~/local-scratch/parity-joint/drmjl-430ef64cc.

WHAT BIT US TONIGHT, so it does not bite again:
  1. SESSION LIMIT. 19 Opus-max agents launched at once all died with zero output after ~20
     min. Stagger waves and prefer effort:'high'; a wave that never returns is worth less
     than a smaller one that does.
  2. A killed agent can leave a RED CONTROL UNRESTORED. wt-reader-contracts held a planted
     private-slot violation in a shipped vignette (model-workflow.Rmd), uncommitted. Restored
     from HEAD before pushing. ALWAYS check `git status` in a killed agent's worktree before
     trusting or building on its branch.
  3. A CONFLICTED PR GETS ZERO CHECKS, and zero checks reads as "not red" to a human.
     #1203/#1204/DRM.jl #659 all sat invisible this way.

RESUME: You are drmTMB2, the single continuous Claude lane over drmTMB and DRM.jl running the
approved G0 arc-loop (~/.claude/plans/piped-dancing-floyd.md). Read GOAL.md -> this file ->
arcs.md. Verify state from GitHub, never from an agent's report. Then: (a) confirm overnight.sh
is alive (pgrep -f overnight.sh) and restart it if not; (b) relaunch the two patched workflows
above as capacity allows; (c) as DRM.jl #641/#647/#652/#653 merge, their drmTMB halves follow
automatically; (d) #1163 LAST, as one unbroken merge-main -> regenerate-receipt -> push ->
merge sequence; (e) then LOOP/final-repin.sh <new DRM.jl main sha>, regenerate the parity
matrix and 261, Rose after-task on both repos, handover. Pause at every OPEN GATE above.
