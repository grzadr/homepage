# AGENTS.md

Project instructions for `github.com/grzadr/homepage`.

## 1. Project Overview & Learning Mode

This repository is a server-rendered personal website and blog (**profile/about**, **projects showcase**, **Markdown blog**, and **contact form**) built progressively in **Go 1.27** (`net/http`), **`a-h/templ`**, and locally vendored **`htmx`**.

**No-Spoiler Learning Protocol**:
- Progress is tracked in `ROADMAP.md` (4 stages, 12 vertical-slice steps).
- **Do NOT write application implementation code for roadmap steps** unless the user explicitly asks to switch out of learning mode.
- Use `craft-gatekeeper` to generate step tests and evaluate passes/fails, `craft-tutor` or `craft-unstick` for spoiler-free guidance, `craft-refactor` for post-pass idiomatic reviews, and `craft-resume` when resuming after a break.

## 2. Tech Stack & Layer Boundaries

- **Runtime & HTTP**: Go 1.27+ standard library `net/http` (`http.ServeMux` with exact-root `GET /{$}` and `{slug}` path parameters, wrapped with `http.NewCrossOriginProtection()`). Avoid third-party routers unless requested.
- **Templating**: `github.com/a-h/templ` pinned in `go.mod` via `tool` (`go tool templ generate`). Never hand-edit `*_templ.go` files; always regenerate before building or testing.
- **Frontend**: Locally vendored `htmx@2.0.4` (`internal/assets/static/js/htmx.min.js`) embedded via `//go:embed`.
- **Planned Layout**:
  - `cmd/server/` — Process entrypoint, env config (`PORT`), `http.Server` timeouts, `slog`, `SIGINT`/`SIGTERM` graceful shutdown.
  - `internal/handler/` — HTTP transport, `HX-*` header inspection, CSRF middleware, view/domain wiring.
  - `internal/view/` — Pure `*.templ` presentation components accepting typed Go structs (no DB or HTTP calls).
  - `internal/domain/` — Pure domain models, validation, rate limiting, and narrow consumer-side interfaces.
  - `internal/blog/` — `io/fs.FS`-backed Markdown loader and frontmatter parser.
  - `internal/assets/` — Embedded static assets (`//go:embed all:static` served under `/static/`).
  - `acceptance/` — `cucumber/godog` BDD features bound to `*testing.T`.

## 3. Hypermedia (`templ` + `htmx`) Conventions

- **Progressive Enhancement**: Check `r.Header.Get("HX-Request") == "true"` (and `HX-Target` when targeting a panel/list). Return partial `templ.Component` fragments for htmx requests and full `Layout(...)` documents for direct/boosted navigation.
- **Form Validation (`422`)**: Because htmx 2.x ignores `4xx`/`5xx` bodies by default, register a `htmx:beforeSwap` listener in `layout.templ` for `422 Unprocessable Entity` so validation errors swap inline; return `303 See Other` PRG redirects for non-htmx POSTs.
- **Embed Paths**: `//go:embed` cannot traverse `..`; keep static assets inside `internal/assets/static/`.

## 4. Testing & Quality Guardrails

- **Methodologies**: TDD (Red-Green-Refactor) + F.I.R.S.T. principles (`t.Parallel()`, `-race -shuffle=on`, `t.Context()`).
- **Test Design**: Author black-box tests in `package foo_test`, use `google/go-cmp` for diffs, prefer lightweight in-memory Fakes/Stubs over mock frameworks, use `testing/synctest` for deterministic time/concurrency tests, `testing.F` for parser fuzzing, and `for b.Loop()` for benchmarks.
- **Linter Caps (`.golangci.yml`, golangci-lint v2)**: `errcheck`, `gocyclo` (15), `gocognit` (15), `dupl` (100), `usetesting` (`_test.go` exempt from `dupl`/`gocyclo`/`gocognit`; generated files excluded `lax`).
- **Canonical `Makefile` Targets**:
  - Inner TDD loop: `make test-unit` (`go test -race -shuffle=on -short ./...`)
  - Lint & vet: `make lint` (`golangci-lint run ./...` + `go vet ./...`)
  - Coverage gate (`>= 80%`): `make test-cover`
  - BDD acceptance (`Strict: true`): `make test-acceptance`
  - Integration (`-tags=integration`): `make test-integration`
  - Security & mutation (`>= 85%` on `./internal/domain/...`): `make vuln`, `make test-mutation`
  - Full pre-PR gate: `make check`

## 5. Workspace Skills & Agents (`.agents/`)

- **Agents (`.agents/agents/`)**: `docs-scout` (spoiler-free official docs lookup), `socratic-debugger` (spoiler-free failure diagnostics).
- **Craft Learning (`.agents/skills/craft-*`)**: `craft-blueprint`, `craft-gatekeeper`, `craft-refactor`, `craft-resume`, `craft-tutor`, `craft-unstick`.
- **Go & Hypermedia (`.agents/skills/`)**: `bootstrap-go-htmx-templ`, `go-senior-developer`, `go-modern-testing`, `go-concurrency-patterns`, `go-testing-guardrails`, `test-driven-development`, `git-workflow-and-versioning`.
