---
name: find-skills
description: Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can...", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.
capabilities: skills-management
---

# Find Skills

This skill helps you discover and install skills from the open agent skills ecosystem.

## When to Use This Skill

Use this skill when the user:

- Asks "how do I do X" where X might be a common task with an existing skill
- Says "find a skill for X" or "is there a skill for X"
- Asks "can you do X" where X is a specialized capability
- Expresses interest in extending agent capabilities
- Wants to search for tools, templates, or workflows
- Mentions they wish they had help with a specific domain (design, testing, deployment, etc.)

## What is the Skills CLI?

The Skills CLI (`npx skills`) is the package manager for the open agent skills ecosystem. Skills are modular packages that extend agent capabilities with specialized knowledge, workflows, and tools.

**Key commands:**

- `npx skills find [query]` - Search for skills interactively or by keyword
- `npx skills add <package>` - Install a skill from GitHub or other sources
- `npx skills check` - Check for skill updates
- `npx skills update` - Update all installed skills

**Browse skills at:** https://skills.sh/

## How to Help Users Find Skills

### Step 1: Understand What They Need

When a user asks for help with something, identify:

1. The domain (e.g., React, testing, design, deployment)
2. The specific task (e.g., writing tests, creating animations, reviewing PRs)
3. Whether this is a common enough task that a skill likely exists

### Step 2: Search for Skills

Run the find command with a relevant query:

```bash
npx skills find [query]
```

For example:

- User asks "how do I make my React app faster?" → `npx skills find react performance`
- User asks "can you help me with PR reviews?" → `npx skills find pr review`
- User asks "I need to create a changelog" → `npx skills find changelog`

The command will return results like:

```
Install with npx skills add <owner/repo@skill>

vercel-labs/agent-skills@vercel-react-best-practices
└ https://skills.sh/vercel-labs/agent-skills/vercel-react-best-practices
```

### Step 3: Present Options to the User

When you find relevant skills, present them to the user with:

1. The skill name and what it does
2. The install command they can run
3. A link to learn more at skills.sh

Example response:

```
I found a skill that might help! The "vercel-react-best-practices" skill provides
React and Next.js performance optimization guidelines from Vercel Engineering.

To install it:
npx skills add vercel-labs/agent-skills@vercel-react-best-practices

Learn more: https://skills.sh/vercel-labs/agent-skills/vercel-react-best-practices
```

### Step 4: Offer to Install

If the user wants to proceed, you can install the skill for them:

```bash
npx skills add <owner/repo@skill> -y
```

By default, prefer **project-local** install (no `-g`) so the skill travels with the repo.

If the user explicitly wants a global (user-level) install, use:

```bash
npx skills add <owner/repo@skill> -g -y
```

The `-y` flag skips confirmation prompts.

## Common Skill Categories

When searching, consider these common categories.

Important:
- This list is **recommendational**. It is a starting point for good search queries, not a fixed taxonomy.
- The agent may use **other domains and queries** when it improves results for the user’s task.

| Category        | Example Queries                          |
| --------------- | ---------------------------------------- |
| Web Development | react, nextjs, typescript, css, tailwind |
| Frontend        | frontend best practices, component patterns, state management |
| Backend         | backend patterns, service architecture, api integration |
| API Design      | rest best practices, openapi, api versioning |
| Auth            | authentication, authorization, jwt, oauth |
| Databases       | postgres, schema design, migrations, orm |
| SQL             | sql optimization, indexing, query tuning |
| Caching         | redis, caching strategies, cache invalidation |
| Messaging       | kafka, rabbitmq, queues, event-driven |
| Architecture    | architecture patterns, ddd, clean architecture |
| System Design   | scalability, distributed systems, high availability |
| Performance     | performance optimization, profiling, latency |
| Observability   | logging, metrics, tracing, opentelemetry |
| Reliability/SRE | sre, incident response, resilience, retries |
| Security        | api security, secrets management, hardening |
| Testing (Unit)  | unit testing, tdd, pytest, junit |
| Testing (E2E)   | e2e testing, playwright, cypress, test automation |
| QA              | test strategy, test plan, acceptance criteria |
| Documentation   | docs, readme, changelog, api-docs |
| Code Quality    | review, lint, refactor, best practices |
| DevOps          | deploy, docker, kubernetes, ci-cd |
| CI/CD           | github actions, pipelines, release automation |
| Cloud           | aws, gcp, azure, cloud architecture |
| IaC             | terraform, pulumi, infrastructure as code |
| Mobile          | ios, android, react native, mobile architecture |
| Design          | ui, ux, design-system, accessibility |
| Product         | product discovery, roadmap, product specs |
| Project Mgmt    | project management, estimation, planning |
| Productivity    | workflow, automation, git |
| Python          | python best practices, pytest, async python |
| Node.js         | nodejs patterns, typescript, nestjs |
| .NET            | dotnet best practices, asp.net, c# |
| Java            | spring, java best practices, jvm performance |
| Go              | go best practices, concurrency, http client |
| Rust            | rust patterns, tokio, performance |
| Marketing       | marketing strategy, go-to-market, positioning |
| Product Marketing | product marketing, messaging, launch plan |
| Branding        | brand voice, brand strategy, guidelines |
| Content Strategy | content strategy, editorial calendar, content plan |
| Copywriting     | copywriting, landing page copy, sales copy |
| SEO             | seo audit, keyword research, technical seo |
| Programmatic SEO | programmatic seo, content at scale |
| Social Media    | social content, linkedin posts, twitter threads |
| Paid Ads        | paid ads, google ads, meta ads, ad creative |
| Email Marketing | email sequence, newsletter, deliverability |
| Analytics       | marketing analytics, attribution, funnels, ga4 |
| CRO             | conversion rate optimization, a/b test, landing page optimization |
| Sales           | sales process, outreach, discovery calls |
| CRM             | crm, pipeline, lead management |
| Partnerships    | partnerships, affiliate, channel strategy |
| Customer Success | onboarding, retention, churn reduction |

Note (for automation):
- A machine-readable copy of this table lives in `domains.json` next to this skill.

## Tips for Effective Searches

1. **Use specific keywords**: "react testing" is better than just "testing"
2. **Try alternative terms**: If "deploy" doesn't work, try "deployment" or "ci-cd"
3. **Check popular sources**: Many skills come from `vercel-labs/agent-skills` or `ComposioHQ/awesome-claude-skills`

## When No Skills Are Found

If no relevant skills exist:

1. Acknowledge that no existing skill was found
2. Offer to help with the task directly using your general capabilities
3. Suggest the user could create their own skill with `npx skills init`

Example:

```
I searched for skills related to "xyz" but didn't find any matches.
I can still help you with this task directly! Would you like me to proceed?

If this is something you do often, you could create your own skill:
npx skills init my-xyz-skill
```

