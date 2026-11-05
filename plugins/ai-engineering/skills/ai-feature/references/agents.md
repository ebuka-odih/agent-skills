# Agents with tools

## When an agent, not a pipeline
Use an agent only if the sequence of steps depends on the input. If you can draw the flowchart, write the flowchart.

## Tool design
| Rule | Why |
|---|---|
| Each tool does one thing, with a typed schema and a clear description | Models pick tools from descriptions |
| Read tools return IDs + compact fields, not whole records | Context cost, grounding |
| Write tools (create, update, send, pay, delete) need approval | See ai-safety |
| Validate tool args server-side; return errors as tool results | The model can recover |
| Scope tools to the current user/tenant through deps, never from model args | Prevents cross-tenant access |

## Limits (record in the card)
- Max steps per run (start at 8–10)
- Max tokens and wall-clock per turn
- `parallel_tool_calls` on/off (off if tools have side effects or ordering matters)
- Budget per run; stop and return partial result when hit

## Final answer
Structured: summary + referenced IDs + follow-up suggestions. After the run, check every referenced ID was returned by a tool in this run.

## Stack notes
- Pydantic AI: `Agent(model, output_type=Reply, deps_type=Deps, instructions=...)`, tools via `@agent.tool` (gets `RunContext[Deps]`) or `@agent.tool_plain`; `result = await agent.run(prompt, deps=deps)` → `result.output`.
- Laravel AI SDK: agent implements `HasTools`; tools via `php artisan make:tool` (`description()`, `handle(Request)`, `schema()`); approvals with `Approvable` + `needsApproval()`; `#[MaxSteps]` attribute; sub-agents returned from `tools()`.
