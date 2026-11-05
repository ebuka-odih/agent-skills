# Laravel AI SDK (`laravel/ai`)

Install: `composer require laravel/ai` → `php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider"` → `php artisan migrate`. Config: `config/ai.php`. Docs: https://laravel.com/docs/ai-sdk

## Layout
```
app/Ai/
├── Agents/        # php artisan make:agent InvoiceExtractor --structured
├── Tools/         # php artisan make:tool LookupVendor
└── Middleware/    # php artisan make:agent-middleware LogUsage
config/ai.php      # providers; add a 'tiers' section mapping fast/standard/smart
```

## Agent
```php
#[Timeout(60)]
#[MaxSteps(8)]
class InvoiceExtractor implements Agent, HasStructuredOutput, HasTools, HasMiddleware
{
    use Promptable;

    public const PROMPT_VERSION = 'v3';

    public function instructions(): string { return view('ai.prompts.invoice-extractor-v3')->render(); }

    public function schema(JsonSchema $schema): array
    {
        return [
            'vendor'      => $schema->string(),
            'total_cents' => $schema->integer()->min(0),
            'confidence'  => $schema->string()->enum(['low', 'medium', 'high'])->required(),
        ];
    }

    public function tools(): iterable { return [new LookupVendor]; }
    public function middleware(): array { return [new LogUsage]; }
}

$response = (new InvoiceExtractor)->prompt($text, provider: config('ai.tiers.standard'));
$response['total_cents'];
```

## Building blocks to use
| Need | SDK feature |
|---|---|
| Failover | `provider: [Lab::Anthropic, Lab::OpenAI]` or keyed by `Lab::X->value => 'model'`; triggers on rate limit / overload / credits only |
| Queue | `(new Agent)->queue($input)->then(fn (AgentResponse $r) => ...)->catch(...)` |
| Streaming | `->stream($input)`, `->usingVercelDataProtocol()`, `broadcastOnQueue()` |
| Chat memory | `RemembersConversations`, `->forUser($user)`, `->continue($id, as: $user)` — **authorize before continuing** (no ownership check) |
| RAG | `Embeddings::for([...])->generate()`, `$table->vector(...)`, `whereVectorSimilarTo()`, `SimilaritySearch::usingModel()`, `Reranking::of()->rerank()`, `Stores` + `FileSearch` |
| Classification | `Classification::of($text)->questions([...])->classify()`, `collect([...])->decide(...)` |
| Usage / cost | `$response->usage` (`inputTokens`, `outputTokens`, `cacheReadInputTokens`, `reasoningTokens`); events `AgentPrompted`, `AgentFailed`, `ProviderFailedOver`, `ToolInvoked` |
| Tool approval | tool implements `Approvable`; agent uses `InteractsWithApprovals` |
| Prompt caching | `#[CacheInstructions('1h')]`, `#[CacheToolDefinitions('1h')]` (Anthropic, Bedrock) |

## Testing
```php
InvoiceExtractor::fake([['vendor' => 'Acme', 'total_cents' => 1200, 'confidence' => 'high']])->preventStrayPrompts();
// ... run code ...
InvoiceExtractor::assertPrompted(fn (AgentPrompt $p) => $p->contains('Acme'));
```
Fakes exist for `Embeddings`, `Image`, `Audio`, `Transcription`, `Reranking`, `Classification`, `Files`, `Stores`.

## Logging
Listen to `AgentPrompted` / `AgentFailed` / `ProviderFailedOver` events (or agent middleware) to write the ai-ops usage row.
