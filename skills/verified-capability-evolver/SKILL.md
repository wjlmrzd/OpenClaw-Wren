---
name: verified-capability-evolver
description: Safely improve agent capabilities with verification, rollback, and promotion gating to prevent unsafe upgrades.
---



\# Verified Capability Evolver



A structured system for safe, verifiable self-improvement of AI agents.



This skill ensures that improvements are:

\- logged

\- evaluated

\- verified (optionally)

\- and only then promoted to persistent behavior



\---



\## Execution Modes



This skill supports two execution modes depending on environment:



\### Full System Mode (OpenClaw / local environment)

\- Uses `.learnings/` files for persistent logs

\- Supports hooks and automation scripts

\- Enables inter-session learning



\### Lightweight Mode (SkillsMP / GitHub environments)

\- No filesystem or scripts required

\- Log learnings inline or conceptually

\- Apply the same evaluation, verification, and promotion logic manually



If persistent storage is unavailable, simulate `.learnings/` structure conceptually.



\---



\## Core Principle



An agent should not just improve — it should prove that it improved.



No learning becomes permanent unless it passes verification.



\---



\## Core Execution Loop



Follow this process for all improvements:



1\. Detect event:

&#x20;  - error

&#x20;  - correction

&#x20;  - improvement

&#x20;  - feature request



2\. Log learning:

&#x20;  - structured entry (file-based or conceptual)



3\. Define evaluation:

&#x20;  - what should improve?

&#x20;  - what should no longer fail?



4\. Verify (optional):

&#x20;  - use deterministic validation or SettlementWitness



5\. Decision:

&#x20;  - PASS → promote

&#x20;  - FAIL → rollback

&#x20;  - INDETERMINATE → hold



6\. Update state:

&#x20;  - mark status

&#x20;  - record outcome

&#x20;  - promote if eligible



\---



\## Data Handling and Trust



This skill defines a verification workflow, not automatic data transmission.



\- Only structured task data (spec + output) should be used for verification

\- Do NOT include secrets, API keys, credentials, or private data

\- External verification is optional and controlled by the runtime



\---



\## Agent Identity (Optional)



If using external verification, a stable agent\_id can be used:



{wallet\_address}:capability-evolver



\---



\## Logging System



If filesystem is available:

\- `.learnings/LEARNINGS.md`

\- `.learnings/ERRORS.md`

\- `.learnings/FEATURE\_REQUESTS.md`



If not:

\- log entries conceptually using the same structure



\---



\## Quick Reference



| Situation | Action |

|----------|--------|

| Error occurs | Log error |

| User corrects | Log learning |

| Feature requested | Log feature |

| Improvement identified | Define evaluation |

| Considering promotion | Verify first |

| PASS | Promote |

| FAIL | Rollback |

| INDETERMINATE | Hold |



\---



\## Learning Entry Format



\## \[LRN-YYYYMMDD-XXX] category



Status: pending | in\_progress | resolved | promoted  

Priority: low | medium | high | critical  



\### Summary

Short description



\### Details

What happened and why it matters



\### Suggested Action

What should change



\---



\## Error Entry Format



\## \[ERR-YYYYMMDD-XXX]



\### Summary

What failed



\### Context

What was attempted



\### Suggested Fix

Potential solution



\---



\## Feature Request Format



\## \[FEAT-YYYYMMDD-XXX]



\### Requested Capability

What is needed



\### Context

Why it matters



\### Suggested Implementation

How it could work



\---



\## Verification (Optional)



Use verification when promoting improvements.



Verification requires:

\- a clear expected outcome

\- a measurable result



Example structure:



{

&#x20; "spec": { "expected": "correct structured output" },

&#x20; "output": { "result": "..." }

}



Interpretation:

\- PASS → promote

\- FAIL → rollback

\- INDETERMINATE → hold



\---



\## Promotion Rules



Promote a learning only when:

\- it is broadly applicable

\- it improves behavior consistently

\- it passes verification (if used)



Promotion targets:

\- agent memory

\- workflow rules

\- behavioral guidelines



\---



\## Rollback Logic



If a promoted learning later fails:



1\. revert the change

2\. log counter-evidence

3\. mark learning as invalid or pending



\---



\## Recurring Pattern Detection



If similar issues occur repeatedly:

\- link related entries

\- increase priority

\- consider systemic fixes



Recurring issues often indicate:

\- missing rules

\- missing automation

\- structural problems



\---



\## When to Use This Skill



Use when:

\- improving agent behavior over time

\- refining workflows

\- preventing repeated mistakes

\- building long-running agents



\---



\## Outcome



Agents become:

\- safer to evolve

\- auditable

\- reversible

\- consistently improving



\---



\## Keywords



ai-agents, self-improvement, verification, agent-safety, automation, learning-systems

