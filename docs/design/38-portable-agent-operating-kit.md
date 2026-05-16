# Portable Agent Operating Kit

The `docs/agent-kit/` directory packages the agent-collaboration pattern that
has worked well for `drmTMB` into a copyable form for sibling projects such as
`gllvmTMB`, statistical R packages, machine-learning projects, agent-based
modelling tools, and data-wrangling packages.

The kit is not a new dependency and it is not part of the modelling API. It is
a documentation and process bundle. Its purpose is to help a new project start
with durable repository-level instructions instead of relying on one agent's
private memory.

## Contents

- `docs/agent-kit/README.md`: what to copy and what to adapt.
- `docs/agent-kit/bootstrap-checklist.md`: first-hour setup steps.
- `docs/agent-kit/team-roles.md`: portable definitions for Ada, Boole, Gauss,
  Noether, Darwin, Fisher, Pat, Jason, Curie, Emmy, Grace, and Rose.
- `docs/agent-kit/project-memory-policy.md`: rules for keeping repository
  evidence authoritative.
- `docs/agent-kit/templates/`: files that can be copied into another project.

## Boundary

The kit copies process, not statistical claims. For example, another project
can reuse the after-task report structure, but it must rewrite parameter names,
model equations, test standards, examples, and roadmap language for its own
scope.

## Success Criteria

A sibling project has adopted the kit successfully when:

- its `AGENTS.md` states the project scope and non-goals;
- agents can use the standing review names without renaming them;
- meaningful work leaves check-log and after-task evidence;
- drift-prone facts such as branch, CI, and validation output are rechecked
  live;
- planned features are not described as implemented without code, tests, docs,
  examples, and validation evidence.
