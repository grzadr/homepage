# Personal Homepage & Blog — Learning Roadmap

## Project Overview

This project is a server-rendered personal website and blog featuring a profile/about page, a filterable projects showcase, a Markdown-backed blog, and a validated contact form built with Go 1.27 (`net/http`), `a-h/templ`, and locally vendored `htmx`. Throughout the stages, you will practice idiomatic Go architecture alongside automated verification guardrails including TDD, F.I.R.S.T. unit tests, black-box HTTP tests, Gherkin acceptance specifications, mutation testing, native fuzzing, and deterministic `testing/synctest` concurrency tests.

## Progress Tracker

`Active Step: Stage 1 - Step 1.1`

Legend: `[ ]` Locked/Pending | `[~]` In Progress | `[x]` Passed

- **Stage 1: The Heartbeat (Walking Skeleton)**
  - [ ] Step 1.1: Health Endpoint & Static Asset Embedding
  - [ ] Step 1.2: Base Layout & Profile Homepage (`GET /{$}`)
  - [ ] Step 1.3: Server Entrypoint & Graceful Shutdown
- **Stage 2: Core State & Happy Path (Projects Showcase & htmx Partials)**
  - [ ] Step 2.1: Projects Domain & Showcase Page (`GET /projects`)
  - [ ] Step 2.2: Live Tag Filtering with htmx (`GET /projects?tag=...`)
  - [ ] Step 2.3: Project Detail View (`GET /projects/{slug}`)
- **Stage 3: Persistence, Markdown Blog & Form Validation**
  - [ ] Step 3.1: Markdown Post Loader & Frontmatter Parser
  - [ ] Step 3.2: Blog Index, Pagination & Post Detail (`GET /blog`, `GET /blog/{slug}`)
  - [ ] Step 3.3: Contact Form with CSRF Protection & 422 Validation (`GET /contact`, `POST /contact`)
- **Stage 4: Quality Guardrails, Acceptance Tests & Concurrency Hardening**
  - [ ] Step 4.1: Gherkin Acceptance Suite (`acceptance/` with `godog`)
  - [ ] Step 4.2: Contact Rate Limiter & Deterministic `testing/synctest` Tests
  - [ ] Step 4.3: Cache Headers, Benchmarks (`b.Loop()`) & Mutation Testing Gate

---

## Stage 1: The Heartbeat (Walking Skeleton)

### Step 1.1: Health Endpoint & Static Asset Embedding
- **Goal**: Expose an embedded static asset filesystem and an HTTP handler serving a health check and static files.
- **Language Concepts Practiced**: `//go:embed` with `io/fs.Sub`, standard-library `http.ServeMux` method+path routing, and black-box `net/http/httptest` testing in an external `_test` package.
- **Specification & Acceptance Criteria**:
  - `internal/assets` exports `StaticFS() fs.FS` backed by `//go:embed all:static` rooted at the `static` subdirectory.
  - `internal/handler` exports `NewHandler(staticFS fs.FS) http.Handler`.
  - `GET /healthz` returns status `200 OK`, `Content-Type: text/plain; charset=utf-8`, and exact body `ok`.
  - `GET /static/css/app.css` and `GET /static/js/htmx.min.js` return status `200 OK` with non-empty asset contents; missing static paths return `404 Not Found`.

### Step 1.2: Base Layout & Profile Homepage (`GET /{$}`)
- **Goal**: Render the semantic HTML5 base layout and personal profile/about homepage at the exact root path.
- **Language Concepts Practiced**: Type-safe `templ` component composition (`{ children... }`), exact-root `GET /{$}` routing vs. catch-all 404s, and HTML response assertions.
- **Specification & Acceptance Criteria**:
  - `internal/view/layout.templ` defines `Layout(title string)` outputting a valid HTML5 document (`<!DOCTYPE html>`), linking `/static/css/app.css`, loading `/static/js/htmx.min.js` with `defer`, enabling `hx-boost="true"`, and rendering primary navigation links (`/`, `/projects`, `/blog`, `/contact`).
  - `internal/view/home.templ` defines `HomePage(...)` wrapped in `Layout` displaying the owner profile/bio and about sections.
  - `GET /` returns status `200 OK`, `Content-Type: text/html; charset=utf-8`, and the rendered full HTML page.
  - Unmatched paths (such as `GET /does-not-exist`) return status `404 Not Found` rather than falling back to the homepage.

### Step 1.3: Server Entrypoint & Graceful Shutdown
- **Goal**: Wire the production HTTP server entrypoint with environment-based port configuration, timeouts, structured logging, and signal-driven graceful shutdown.
- **Language Concepts Practiced**: `log/slog` structured logging, `signal.NotifyContext` (`SIGINT`/`SIGTERM`), and `http.Server` timeout and `Shutdown` lifecycle management.
- **Specification & Acceptance Criteria**:
  - `cmd/server/main.go` reads `PORT` from the environment (defaulting to `8080`) and binds `http.Server` using `handler.NewHandler(assets.StaticFS())`.
  - `http.Server` explicitly configures `ReadHeaderTimeout`, `ReadTimeout`, `WriteTimeout`, and `IdleTimeout` to non-zero values.
  - Sending `SIGINT` or `SIGTERM` triggers `srv.Shutdown` with a bounded timeout context and exits cleanly with code `0` without dropping in-flight requests.
  - Running `go build ./cmd/server` and `go vet ./...` succeeds cleanly with zero warnings.

---

## Stage 2: Core State & Happy Path (Projects Showcase & htmx Partials)

### Step 2.1: Projects Domain & Showcase Page (`GET /projects`)
- **Goal**: Introduce a pure domain model for portfolio projects and render the projects showcase as either a full page or an htmx partial.
- **Language Concepts Practiced**: Pure domain structs separated from transport, narrow consumer-side interfaces ("accept interfaces, return structs"), and `HX-Request` / `HX-Target` header branching.
- **Specification & Acceptance Criteria**:
  - `internal/domain` defines a `Project` struct containing `Slug`, `Title`, `Summary`, `Tags` (`[]string`), `URL`, and `Featured` (`bool`), along with a narrow repository interface and an in-memory store implementation.
  - Direct `GET /projects` requests (including `hx-boost="true"` navigation without targeting the partial container) return status `200 OK` with the full `Layout` HTML document containing all projects.
  - Requests with `HX-Request: true` and `HX-Target: projects-panel` return status `200 OK` containing only the projects panel HTML fragment (no `<!DOCTYPE html>` or `<html>` wrapper).

### Step 2.2: Live Tag Filtering with htmx (`GET /projects?tag=...`)
- **Goal**: Enable case-insensitive tag filtering on the projects showcase with shareable URLs and partial DOM updates.
- **Language Concepts Practiced**: Table-driven unit tests with `t.Parallel()` and `google/go-cmp` in `package domain_test`, slice filtering without mutation, and URL query parameter handling.
- **Specification & Acceptance Criteria**:
  - Domain filtering matches `tag` case-insensitively and returns all projects when `tag` is empty or whitespace-only; when no projects match, it returns an empty slice without error.
  - `GET /projects?tag=<tag>` with `HX-Request: true` targeting the project list returns only the filtered project list fragment (`200 OK`), or a clear empty-state fragment if none match.
  - Direct `GET /projects?tag=<tag>` without `HX-Request` (or boosted navigation) returns the full page pre-filtered to `<tag>`, keeping filtered URLs bookmarkable.
  - Unit tests in `package domain_test` execute in parallel (`t.Parallel()`) and pass under `go test -race -shuffle=on`.

### Step 2.3: Project Detail View (`GET /projects/{slug}`)
- **Goal**: Serve dedicated project detail views using `net/http` path parameters and handle missing slugs gracefully.
- **Language Concepts Practiced**: `r.PathValue("slug")` route parameters, sentinel domain errors (`errors.Is`), and clean HTTP `404` mapping.
- **Specification & Acceptance Criteria**:
  - Domain lookup by slug returns the matching `Project` or a sentinel not-found error (`ErrProjectNotFound`).
  - `GET /projects/{slug}` returns status `200 OK` and renders the project title, full summary, tags, and link (full page on direct load; content fragment when targeted via htmx).
  - `GET /projects/{slug}` for an unknown slug returns status `404 Not Found` without leaking internal stack traces or errors.

---

## Stage 3: Persistence, Markdown Blog & Form Validation

### Step 3.1: Markdown Post Loader & Frontmatter Parser
- **Goal**: Parse Markdown blog posts with metadata frontmatter from an `fs.FS` source, filter drafts, sort chronologically, and harden parsing with native fuzzing.
- **Language Concepts Practiced**: `io/fs.FS` abstraction for testable file I/O, deterministic error handling with sentinel errors, and native `testing.F` fuzzing (`FuzzParsePost`).
- **Specification & Acceptance Criteria**:
  - `internal/blog` parses Markdown files with frontmatter fields: `title`, `slug`, `date` (`YYYY-MM-DD`), `tags`, and `draft` (`bool`), converting the Markdown body into safe HTML.
  - Published listings exclude `draft: true` posts by default and sort remaining posts newest-first by `date` (with deterministic tie-breaking by `slug`).
  - Missing required frontmatter fields or invalid dates return explicit, inspectable errors rather than panicking.
  - `FuzzParsePost(f *testing.F)` runs cleanly via `go test -fuzz=FuzzParsePost` without panics on arbitrary or malformed byte/string inputs.

### Step 3.2: Blog Index, Pagination & Post Detail (`GET /blog`, `GET /blog/{slug}`)
- **Goal**: Expose the blog index with tag filtering, htmx incremental "Load More" pagination, and individual post detail pages.
- **Language Concepts Practiced**: Cursor/page-based pagination logic, `hx-swap="beforeend"` fragment responses, and `testing/iotest` fault injection for I/O failure paths.
- **Specification & Acceptance Criteria**:
  - `GET /blog` accepts optional `tag` and `page` query parameters, returning bounded slices of posts (`200 OK`).
  - When `HX-Request: true` requests the next page from the "Load More" control, the handler returns only the next batch of post cards plus an updated (or removed, when exhausted) "Load More" trigger for `beforeend` appending.
  - `GET /blog/{slug}` returns status `200 OK` with the full rendered article for published slugs, and `404 Not Found` for unknown or draft-only slugs.
  - Underlying read/filesystem errors tested via `testing/iotest` map cleanly to `500 Internal Server Error` without crashing the server.

### Step 3.3: Contact Form with CSRF Protection & 422 Validation (`GET /contact`, `POST /contact`)
- **Goal**: Build a CSRF-protected contact form that validates submissions in the domain layer and returns inline `422` errors for htmx or standard PRG redirects for non-htmx clients.
- **Language Concepts Practiced**: Standard-library `http.NewCrossOriginProtection()`, domain validation with field-level errors, and dependency injection via a narrow `ContactNotifier` interface with an in-memory Fake.
- **Specification & Acceptance Criteria**:
  - The root HTTP handler is wrapped with `http.NewCrossOriginProtection()`, rejecting cross-origin `POST /contact` requests (`Sec-Fetch-Site: cross-site`) with status `403 Forbidden`.
  - `GET /contact` renders the contact form (`name`, `email`, `message` fields) inside `Layout`, with `layout.templ` configuring `htmx:beforeSwap` to allow swapping `422` responses.
  - `POST /contact` with missing/invalid fields returns status `422 Unprocessable Entity` and re-renders the form partial with field-specific error messages and preserved valid inputs without invoking `ContactNotifier`.
  - Valid `POST /contact` invokes `ContactNotifier.Send(ctx, msg)`: for `HX-Request: true`, it returns `200 OK` with a confirmation partial and an `HX-Trigger` event header; for non-htmx requests, it returns `303 See Other` redirecting to `/contact?sent=1`.

---

## Stage 4: Quality Guardrails, Acceptance Tests & Concurrency Hardening

### Step 4.1: Gherkin Acceptance Suite (`acceptance/` with `godog`)
- **Goal**: Establish business-readable end-to-end acceptance specifications driving the HTTP handler through `cucumber/godog` bound to `go test`.
- **Language Concepts Practiced**: Behavior-Driven Development (BDD) driving adapters, `godog.TestSuite` integration with `*testing.T`, and per-scenario state isolation for parallel execution.
- **Specification & Acceptance Criteria**:
  - `acceptance/features/` contains `.feature` files covering core visitor journeys: viewing the profile homepage, filtering projects by tag, reading a blog post, and submitting valid/invalid contact forms.
  - `acceptance/acceptance_test.go` binds `godog.TestSuite` to `*testing.T` with `Strict: true` and initializes isolated per-scenario dependencies (fresh handler + fake notifier) inside `ctx.Before`.
  - `make test-acceptance` (`go test -race ./acceptance/...`) executes all Gherkin scenarios cleanly with zero undefined or pending steps.

### Step 4.2: Contact Rate Limiter & Deterministic `testing/synctest` Tests
- **Goal**: Protect `POST /contact` against burst abuse with a concurrency-safe per-IP rate limiter verified deterministically under virtualized time.
- **Language Concepts Practiced**: Concurrency-safe state synchronization, injected clocks or `time.AfterFunc`/tickers, and deterministic testing inside `testing/synctest` bubbles.
- **Specification & Acceptance Criteria**:
  - `POST /contact` enforces a configurable per-client-IP request quota over a sliding or fixed time window; requests exceeding the quota receive status `429 Too Many Requests` without invoking `ContactNotifier`.
  - Once the rate-limit window elapses, subsequent valid requests from that IP are accepted (`200 OK` or `303 See Other`).
  - Rate-limiter expiration and concurrent access tests run inside `synctest.Test` with zero `time.Sleep` wall-clock delays and pass under `go test -race -shuffle=on`.

### Step 4.3: Cache Headers, Benchmarks (`b.Loop()`) & Mutation Testing Gate
- **Goal**: Harden static asset caching, add allocation-aware performance benchmarks, and satisfy the full automated quality gate (`make check`).
- **Language Concepts Practiced**: HTTP `Cache-Control` response headers, modern `for b.Loop()` benchmarking with `-benchmem`, and mutation testing efficacy analysis (`gremlins`).
- **Specification & Acceptance Criteria**:
  - Responses under `/static/` include appropriate `Cache-Control` headers (`public, max-age=31536000, immutable` or configurable dev/prod policy) verified by HTTP tests.
  - Hot-path functions (Markdown/frontmatter parsing and domain filtering) include `Benchmark*` tests using `for b.Loop()` runnable via `make bench`.
  - `make test-cover` reports total coverage `>= 80.0%` and `make lint` passes with zero complexity, duplication, or `errcheck` violations.
  - `make test-mutation` (`gremlins unleash --workers 4 --threshold-efficacy 85.0 ./internal/domain/...`) achieves `>= 85.0%` test efficacy on core domain logic.
