# CLAUDE.md
 
## Purpose
 
This document defines **how humans and AI assistants are expected to work on this codebase**.
 
## 🚨 PRIORITY RULES (read first) where P0 is highest and P2 is lowest. If no P0-2 treat the rule as P2
## Priority Levels
- **P0 (MANDATORY):** Must always follow. No exceptions.
- **P1 (HIGH):** Follow unless it directly conflicts with a P0 rule.
- **P2 (NORMAL):** Best practice / guidance.
 
It exists to:
- reduce breakage
- prevent over-engineering
- avoid clever-but-unnecessary abstractions
- minimise cognitive load
- keep the project understandable after weeks or months away
 
If you are an AI assistant: **read this fully before suggesting or generating code**.
 
---
 
## Core Principles
 
### P0 ALLWAYS / CRITICAL
- when patching a function or file while trying to resolve a bug or issue do not immediatly keep adding to a patch unless its useful - ALWAYS review the previous patch and decide if the previous patch needs to be undone or rolled back BEFORTE adding to it with additional patching!!!!
 
### P1. Boring is good
Prefer:
- explicit code
- simple control flow
- obvious variable names
- small, readable functions
 
Avoid:
- clever tricks
- over-abstraction
- “future-proofing”
- unnecessary indirection
- advanced language features unless strictly required
 
If something can be written plainly, do that.
 
---
 
### P1. Stability over elegance
This project values:
- predictability
- debuggability
- incremental change
 
More than:
- elegance
- theoretical correctness
- architectural purity
 
A working, understandable solution beats a clever one every time.
 
---
 
### P1. Minimal surface area
Changes should be:
- **local**
- **isolated**
- **easy to revert**
 
Avoid changes that ripple across multiple files unless explicitly requested.
 
---
 
## Frozen Interfaces (Critical)
 
Unless explicitly instructed otherwise, **do not change**:
 
- public function signatures
- dataclass fields
- config keys
- file/module structure
- CLI behaviour
- return types
 
If a change would require touching multiple modules, **stop and ask first**.
 
---
 
## Code Style Rules
 
### Language & Version
- **Python:** Target Python 3.8+. Always use **4 spaces per indent**.
- **Java-style languages:** Always use **Allman style** (braces on new lines) and **3 spaces per indent**.
 
### Python Specifics
- **Type Hinting:** Always use type checking compatible with **mypy** or similar static analysis tools.
- **Decorators:** Avoid the overuse of decorators (e.g., `@dataclass`, `@property`). Only use them if they significantly improve clarity; do not allow them to obfuscate readability or hide underlying logic unnecessarily.
- Avoid features that reduce readability or portability
 
### Python Type Checking Philosophy
- Types are for humans first, tools second
- Clarity beats clever typing
- Avoid complex generics unless they materially improve correctness
- If typing becomes noisy or unclear, reconsider the design
- If a function cannot be typed cleanly, that is usually a design smell.
 
### Formatting
- Readable over compact
- Prefer clarity over DRY
- Repetition is acceptable if it improves understanding
- Avoid clever refactors that reduce line count but obscure intent
 
### P1 Imports
- No wildcard imports
- No implicit side effects on import
- Keep imports minimal and explicit
 
---
 
## AI-Specific Rules
 
### P1. No “impressive” code
Do **not**:
- introduce advanced patterns unless asked
- refactor for style alone
- replace working code with more abstract versions
- add frameworks, helpers, or utilities “for later”
 
If the user didn’t ask for it, don’t do it.
 
---
 
### P0. Prefer small feature modules (ask first)
If a new feature adds significant complexity (roughly 80–120+ lines), consider isolating it into a small, clearly named helper/module **if** it does not increase surface area or require touching unrelated files. Because of the one-file-at-a-time rule, **ask before splitting** when it would require creating or modifying additional files.
 
---
 
### P2. One-file-at-a-time rule
When modifying code:
- Only touch the file explicitly requested
- Do not assume other files can be changed
- Do not invent functions that don’t exist
 
If context is missing, ask.
 
---
 
### P1. Prefer explanation before generation
When proposing non-trivial changes:
- explain intent first
- explain risks
- explain trade-offs
 
Only then generate code.
 
---
 
### P1. Avoid silent behaviour changes
If a change alters:
- logic
- performance characteristics
- error handling
- external behaviour
 
This **must be stated explicitly**.
 
---
 
## P1 Refactoring Rules
 
Refactoring is allowed **only if**:
- behaviour is unchanged
- interfaces are untouched
- the user explicitly asked for a refactor
 
Otherwise:
- suggest, don’t apply
 
---
 
## Search / External APIs
 
- Prefer deterministic APIs over scraping
- Avoid brittle HTML parsing
- Respect rate limits
- Cache aggressively
- Fail gracefully
 
If a provider blocks or errors, return a safe result — do not crash or loop indefinitely.
 
---
 
## P1 Debugging Expectations
 
When something breaks:
- explain *why* before proposing fixes
- identify whether the failure is:
  - logic
  - interface mismatch
  - external dependency
  - environment / network
- avoid speculative changes
 
---
 
## P0 Communication Style
 
- Be direct
- Be honest
- Don’t over-sell solutions
- Don’t be verbose for its own sake
- Call out uncertainty clearly
 
If something is a trade-off, say so.
 
---
 
## P0 Feature-Switch Workflow (Critical)
 
When editing files under `premium-features/src/*`:
- Do **not** manually copy files into `scrubber-chromium/` or `scrubber-safari/`.
- After changes, tell the user to run the platform script (for Chromium: `./scripts/switch-chromium-features.sh premium`).
- Treat script-driven sync as the only supported path for propagating premium feature changes.
 
---
 
## Summaries (Requested by user)
 
When the user asks for a summary:
- Ask whether to save it to `docs/summary/YYYY-MM-DD-summary.txt` before writing.
- If approved, append to the file (do not overwrite).
- Include a short header with date/time before the summary text.
 
---
 
## P1 When in Doubt
 
Default to:
- smaller changes
- fewer assumptions
- clearer code
- asking a question before acting
 
---
 
## Summary
 
This project prioritises:
- maintainability over novelty
- understanding over cleverness
- stability over speed
- human comprehension over theoretical elegance
 
If an AI agent violates these principles, its output should be considered suspect.
 
 
## P0 Feature Boundaries And Function Size
 
- Do not bundle unrelated features or behaviors into one source file.
- For each new feature/trait, create a clearly named source file when practical.
- Keep feature-specific logic local: one feature should mainly live in its own function(s) or module.
- Keep functions/methods small and single-purpose. If a function is getting long or handling multiple concerns, split it.
- Avoid complex or clever function design. Prefer straightforward control flow and explicit naming.
- Do not spread one feature’s logic across many files unless explicitly required.