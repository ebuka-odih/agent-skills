# See it — verify the release where the user looks

A published release the user isn't running is not shipped. Project 3 published three versions in a row while the user's Mac still ran an older build: "none of the changes you made is showing".

| Product | Where the user looks | Update it | Verify |
|---|---|---|---|
| macOS / desktop app | the installed app (`/Applications/X.app`) | the project's install/update command (installer script, `brew upgrade`, DMG); quit the running app first, and never while it is recording or saving | `version.sh verify --app /Applications/X.app` |
| Web app | the deployed URL (staging for preview, production after go-ahead) | the deploy pipeline; wait for it to finish | `version.sh verify --url https://app.example.com/version` (or a page that prints it) |
| CLI / package | the binary on PATH, the registry | `npm i -g`, `pipx upgrade`, `brew upgrade` | `version.sh verify --cmd "x --version"` |
| Mobile | TestFlight / internal track build | upload + processing | build number in the store console; manual: user opens the About screen |
| Library | the registry page | `npm publish`, `twine upload` | `version.sh verify --cmd "npm view pkg version"` |
| Website (static) | the live site | hosting deploy | `version.sh verify --url https://site/` when the page carries the version (meta tag or footer) |

## Rules
- Verify after every release; the evidence line goes into the report and the progress log.
- A failed verify is a release in progress, not a done release: update the user's copy (or say exactly what they must run) and verify again.
- When the product can't show its version yet, add that first (About / footer / `/version`) — it's a one-time S task.
- Before replacing a running desktop app, check it isn't busy (recording, exporting, unsaved work) — read its log or ask.
