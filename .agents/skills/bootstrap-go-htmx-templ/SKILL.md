---
name: bootstrap-go-htmx-templ
description: Use this skill to scaffold, initialize, or bootstrap a Go 1.27+ web application using a-h/templ for type-safe HTML components and htmx for hypermedia interactivity. Trigger when creating or extending a server-rendered Go web app with templ templates, net/http, CrossOriginProtection, and htmx partials. Do NOT use for pure JSON/gRPC APIs without HTML rendering, React/Vue/Next.js SPAs, or Cobra CLIs.
license: MIT
compatibility: Requires Go 1.27+ and github.com/a-h/templ.
metadata:
  author: agentskills-community
  version: "1.1.0"
  stack: "go-templ-htmx"
---

# Go + templ + htmx Web Project Guide

Build and extend a production-ready, server-rendered Go 1.27 hypermedia web application using standard-library `net/http`, `github.com/a-h/templ`, and locally vendored `htmx`.

## Default Stack & Escape Hatches

Use this opinionated default unless the user explicitly specifies alternatives:

- **HTTP Router & Security**: Standard library `net/http` (`http.ServeMux` with exact-root `GET /{$}` and path parameters, wrapped with `http.NewCrossOriginProtection()` for built-in CSRF protection). Only introduce `chi` or `echo` if requested.
- **Templating**: `github.com/a-h/templ` registered as a `go.mod` tool (`go get -tool`) so teammates and CI runners share the exact generator version via `go tool templ`.
- **Frontend Interactivity**: Locally vendored `htmx.min.js` (`2.0.4` default) embedded in the binary via `//go:embed` to avoid CDN outages and CSP friction. See [references/ARCHITECTURE.md](./references/ARCHITECTURE.md) if opting into htmx 4.0.
- **Live Reload**: Built-in `make dev` target using `go tool templ generate -watch -proxy=...` (zero extra binaries required). Optional [assets/air.toml](./assets/air.toml) is included if `air` is requested.
- **Styling**: Zero-build semantic CSS in `internal/assets/static/css/app.css`. Add Tailwind CSS only if explicitly requested.

## Bundled Resources

- **[references/ARCHITECTURE.md](./references/ARCHITECTURE.md)**: Patterns for partial vs. full-page rendering, out-of-band swaps (`hx-swap-oob`), form validation (`422`), htmx 4.0 migration notes, and production hardening.
- **[assets/air.toml](./assets/air.toml)**: Optional live-reload configuration for `air`.
- **[assets/Dockerfile](./assets/Dockerfile)**: Optional multi-stage Go 1.27 distroless container build.

## Generate & Validate Loop

Execute the full code-generation and verification pipeline before concluding changes:

```bash
go tool templ generate
go vet ./...
go test -race ./...
```

## Gotchas

- **Stale `*_templ.go` files**: Go compiles `*_templ.go`, not `.templ`. Always run `go tool templ generate` before `go build` or `go test`.
- **Full layout vs. partial fragment responses**: Always check `r.Header.Get("HX-Request") == "true"`. Returning `Layout(...)` to an `hx-target` swap injects duplicate `<html>` and `<nav>` elements into the target container.
- **`//go:embed` path rules**: Go embed directives cannot traverse parent directories (`..`). Keep static assets inside `internal/assets/static/` alongside `internal/assets/assets.go`.
- **htmx 2.x vs. 4.x error swapping**: htmx 2.x ignores `422` response bodies unless handled via `htmx:beforeSwap` (or by returning `200 OK` with inline error markup). htmx 4.0 swaps `4xx`/`5xx` by default and changes inheritance rules. Keep htmx 2.0.4 unless htmx 4.0 is explicitly requested.
