# Other stacks

Don't guess the library. Ask, then map the six AI-layer pieces onto what the developer uses.

## Ask (one batch, with proposals)
1. Language/framework of the backend that will call the model? (propose from repo files)
2. Preferred AI library? Propose by language:
   | Language | Proposal |
   |---|---|
   | TypeScript/Node | Vercel AI SDK (`generateObject` with Zod) or provider SDK + Zod |
   | Python (non-FastAPI) | Pydantic AI |
   | Ruby/Rails | ruby_llm or provider SDK + JSON schema validation |
   | Go | provider SDK + struct validation |
   | Java/Kotlin | Spring AI or LangChain4j |
   | Mobile only | call your own backend — never ship provider keys in the app |
3. Providers allowed, and any self-hosted / OpenAI-compatible endpoint?
4. Queue and streaming mechanisms already in the project?
5. Test framework, and how to stub HTTP?

## Map the six pieces
| Piece | Ask yourself |
|---|---|
| Tier config | Where does this stack keep config? Env + config module |
| Call wrapper | Middleware/interceptor available? Otherwise one function every feature calls |
| Prompts | Files with version in name, loaded at startup |
| Schemas | Zod / JSON Schema / structs — validated after every call |
| Fakes | Library test model, or HTTP stub at the provider boundary |
| Eval runner | Same language; reads `evals/ai/<F-id>/cases.jsonl` |

Record the mapping in AI.md "Where AI code lives". When a stack is used twice, `ai-learnings` proposes adding it to house defaults.
