---
name: auto-skill-bootstrap
description: Deterministic helper to inventory existing project skills, detect missing capability coverage, search skills.sh via Skills CLI, and (optionally) install missing skills under a trust policy. Uses skills-manifest.json + state.json to stay idempotent across changing requirements.
capabilities: skills-management
---

# Auto Skill Bootstrap (project-level)

## What this is

This skill defines a **repeatable** workflow for:

- indexing already-present project skills into `skills-manifest.json`
- mapping the user request to **capabilities**
- finding gaps (capabilities not covered by existing skills)
- searching Skills CLI (`npx skills find ...`) for candidate skills
- filtering candidates by **trust policy**
- producing a short, structured “install plan”
- optionally installing skills (only under strict conditions)

The heavy lifting is done by deterministic scripts shipped with this skill.

## CLI + install scope (important)

- This workflow uses the **Skills CLI** via `npx skills` (internally: `npx skills find` and `npx skills add`).
- Default install scope is **project-local** (no `-g`) so skills travel with the repo.
- Global (user-level) installs with `-g` are **out of scope** for this bootstrap flow and should be done only when the user explicitly requests it.

## Files (state + inventory)

- Inventory of skills (generated): `.cursor/skills/skills-manifest.json`
- Bootstrap state (generated): `.cursor/skills/auto-skill-bootstrap/state.json`

## Hard rules

- **Never** install skills from unknown sources automatically.
- If multiple plausible candidates exist for a capability, **ask the user** to choose (multi-select).
- After any install/remove/update of skills, regenerate `skills-manifest.json` (do not edit JSON by hand).

## Deterministic commands

### 1) Rebuild skills manifest

Run inside the repo root:

```bash
python .cursor/skills/auto-skill-bootstrap/bin/update-manifest.py
```

### 2) Search for missing capability skills (no install)

```bash
python .cursor/skills/auto-skill-bootstrap/bin/auto-skill-bootstrap.py \
  --cap docker github devcontainers \
  --no-install
```

Outputs:
- `.cursor/skills/auto-skill-bootstrap/candidates.json` (grouped by capability)
- updates `.cursor/skills/auto-skill-bootstrap/state.json`

### 3) Optional: install (trust-policy only)

Only when **explicitly allowed** by the user or project policy.

```bash
python .cursor/skills/auto-skill-bootstrap/bin/auto-skill-bootstrap.py \
  --cap docker github \
  --install-allowlisted \
  --max-per-cap 1
```

## Trust policy

Trust rules live here and are deterministic:

- `.cursor/skills/auto-skill-bootstrap/trust-policy.json`

Default stance: allowlist only.

## When to run

- At the start of a new task (before deep work).
- Again when the user introduces new constraints/tech (“also add CI”, “needs k8s”, etc.).
- Also when the agent **discovers new work domains** during planning/execution (new stack, new process area like testing/CI, new business domain like marketing/ads, etc.).

## Domain coverage loop (planning + execution)

Goal: keep domain coverage up to date without guessing.

- Maintain a working set of active domains (use `.cursor/skills/find-skills/domains.json` as vocabulary, but do not treat it as limiting).
- When a plan/task expands into a **new domain**, re-run bootstrap for the delta capabilities.
- If the new domain does not map cleanly to existing capabilities, use the ad-hoc mode (`other`) to search by explicit queries.

## Phases + gating (recommended)

To avoid “skipping engineering skills”, treat work as phases and run bootstrap *before* producing high-impact outputs:

- **Planning/Spec Gate (Gate A)**: before producing a plan/spec/architecture decision/best-practice recommendation, bootstrap the planning caps:
  - baseline: `architecture`, `system-design`, `api-design`, `security`, `docs`, `project-mgmt`, `product`
  - plus relevant domain/stack caps already known

- **Implementation Gate (Gate B)**: before changing code/config, bootstrap the implementation caps:
  - baseline: `code-quality`, `testing-unit`, `security`
  - plus required domain/stack caps (language/runtime, backend/frontend, devops/ci-cd, etc.)

When reporting progress, prefer to cite a short summary from `state.json` (`caps`, `missing_caps`, `non_allowlisted_only_caps`, `no_candidates_caps`, `adhoc_queries`) rather than saying “skills are ok” without evidence.

## Per-capability decisions (recommended)

When user choice is required, ask **per capability**, not with one combined list. Each per-capability question should allow:
- select **one** skill
- select **multiple** skills (when it makes sense)
- select **none**

If the user declines a capability, persist it as ignored so the agent does not re-ask:

```bash
python .cursor/skills/auto-skill-bootstrap/bin/auto-skill-bootstrap.py --no-install \
  --cap <cap1> --cap <cap2> \
  --ignore-cap <cap1>
```

## Ad-hoc search (capability: other)

Use this when you need to search for skills outside the predefined capability mapping, while keeping results tracked in `state.json`:

```bash
python .cursor/skills/auto-skill-bootstrap/bin/auto-skill-bootstrap.py --no-install \
  --cap other \
  --query "react best practices" \
  --query "testing patterns"
```

