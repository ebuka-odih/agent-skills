# Stack-specific security rules

## Laravel
| Do | Avoid |
|---|---|
| `$this->authorize('update', $post)` / policies; `->can()` middleware | Route model binding with no policy |
| Form Requests + `$request->validated()` | `$request->all()` into `create()`/`update()` |
| `$fillable` on every model taking input | `$guarded = []` |
| Query builder bindings; `whereRaw('x = ?', [$v])` | `DB::raw("… {$v}")` |
| `{{ }}` escaping | `{!! !!}` with user content |
| `RateLimiter::for('login', …)`; `throttle` middleware | Unthrottled login/reset/OTP |
| `Storage::disk('s3')->putFile(...)` private, temporary URLs | Saving uploads in `public/` with original names |
| `config('services.x.key')` | `env()` outside config files; keys in code |
| `APP_DEBUG=false`, `APP_ENV=production` | Debug pages in prod (leak env) |
| Encrypted casts (`'ssn' => 'encrypted'`) | Plaintext sensitive columns |

## FastAPI
| Do | Avoid |
|---|---|
| `Depends(get_current_user)` on every route; ownership check in service | Trusting `user_id` from the body |
| Pydantic input models with `extra="forbid"`; separate response models | Returning ORM objects (leaks fields) |
| SQLAlchemy bound params / ORM | f-strings into `text()` |
| `CORSMiddleware(allow_origins=[...])` explicit | `allow_origins=["*"]` with credentials |
| `passlib`/`argon2-cffi`, `pyjwt` with algorithm allow-list | Hand-rolled hashing; `jwt.decode(..., options={"verify_signature": False})` |
| `slowapi`/gateway rate limits | Unlimited auth and AI endpoints |
| `debug=False`; generic 500 handler | Tracebacks in responses |
| `yaml.safe_load`, JSON | `pickle.loads`, `yaml.load` on input |

## React / TypeScript
| Do | Avoid |
|---|---|
| JSX escaping; DOMPurify when rendering HTML | `dangerouslySetInnerHTML` with untrusted data |
| Session cookies via BFF; tokens out of JS reach | Tokens in `localStorage` |
| Validate API data with Zod at the boundary | Trusting response shapes |
| `rel="noopener noreferrer"` on `target="_blank"` | `javascript:` URLs from user input in `href` |
| Only public config in `VITE_*` / `NEXT_PUBLIC_*` | Secret keys in any bundled env var (they ship to every browser) |
| CSP without `unsafe-inline` where possible | Inline scripts everywhere |
