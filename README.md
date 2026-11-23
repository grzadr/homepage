# homepage

Personal website and blog (profile/about, projects showcase, Markdown blog, and contact form) built with **Go 1.27** (`net/http`), **`a-h/templ`** (`go tool templ`), and locally vendored **`htmx` (`2.0.4`)**.

## Prerequisites

- **Go 1.27+** (`templ` is pinned in `go.mod` via `tool` and invoked with `go tool templ`)
- **GNU Make**
- **golangci-lint v2** (`make lint`)
- *Optional (for full `make check` / later roadmap stages)*: `govulncheck` (`make vuln`) and `gremlins` (`make test-mutation`)

## Quickstart

```bash
# Build binary (runs templ generate first)
make build

# Run server (default PORT=8080)
make run

# Live reload proxy during development (default PORT=8080, PROXY_PORT=8081)
make dev

# Run unit tests (-race -shuffle=on -short)
make test
```

## Makefile Targets

| Target | Command / Behavior |
| --- | --- |
| `generate` | Run `go tool templ generate` |
| `build` | Generate templates and build `bin/server` from `./cmd/server` |
| `run` | Generate templates and run `./cmd/server` on `PORT` (default `8080`) |
| `dev` | Watch `.templ` changes with live proxy (`PORT=8080`, `PROXY_PORT=8081`) |
| `vendor-htmx` | Download `htmx@2.0.4` into `internal/assets/static/js/htmx.min.js` |
| `lint` | Run `golangci-lint run ./...` and `go vet ./...` |
| `vuln` | Run `govulncheck ./...` |
| `test` / `test-unit` | Run `go test -race -shuffle=on -short ./...` |
| `test-cover` | Run race-enabled coverage (`coverage.out`) and enforce `COVERAGE_MIN` (`80.0%`) |
| `test-acceptance` | Run `go test -race ./acceptance/...` |
| `test-integration` | Run `go test -race -count=1 -tags=integration ./...` |
| `test-mutation` | Run `gremlins unleash --workers 4 --threshold-efficacy 85.0 ./internal/domain/...` |
| `fuzz` | Run `go test -fuzz=Fuzz -fuzztime=30s ./internal/domain/...` |
| `bench` | Run `go test -bench=. -benchmem -count=5 ./internal/domain/...` |
| `check` | Full gate: `lint`, `vuln`, `test-cover`, `test-acceptance`, `test-mutation` |

## Project Layout

```text
.
├── ROADMAP.md                    # 4-stage learning & implementation roadmap
├── Makefile                      # Unified dev, test, lint, and quality gate targets
├── .golangci.yml                 # golangci-lint v2 configuration
├── go.mod                        # Go 1.27 module + templ tool directive
├── cmd/server/
│   ├── main.go                   # Server entrypoint (Stage 1.3)
│   └── main_test.go              # Sanity test
└── internal/assets/static/
    ├── css/app.css               # Base stylesheet placeholder (Stage 1.2)
    └── js/htmx.min.js            # Vendored htmx 2.0.4
```

See [ROADMAP.md](ROADMAP.md) for the full 4-stage vertical-slice specification and acceptance criteria.

## License

MIT — see [LICENSE](LICENSE).
