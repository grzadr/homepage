---
name: go-testing-guardrails
description: Guides idiomatic Go 1.26-1.27 testing strategy, F.I.R.S.T. unit tests, black-box package_test suites, godog BDD acceptance tests, gremlins mutation testing, native fuzzing, b.Loop() benchmarks, and fail-fast Makefile quality gates. Use when designing test architecture, configuring coverage or complexity gates, writing acceptance or mutation tests, or verifying Go changes via make targets.
---

# Go Testing Approaches & Quality Guardrails

Align verification in Go 1.26–1.27 with standard-library-first tooling, Clean Architecture boundaries, TDD, and deterministic Makefile quality gates.

## Core Methodologies

- **TDD (Red-Green-Refactor)**: Write a failing test first (including compilation failure), implement the minimum code to pass, then refactor cleanly.
- **F.I.R.S.T. Principles**:
  - **Fast**: Keep `internal/domain` pure and I/O-free.
  - **Independent**: Call `t.Parallel()` and run with `-shuffle=on`.
  - **Repeatable**: Use injected clocks or `testing/synctest` bubbles instead of real sleeps.
  - **Self-Validating**: Use `t.Errorf` (continue subtests) or `t.Fatalf` (abort invalid state).
  - **Timely**: Write tests alongside or before production code.
- **Black-Box APIs & Test Doubles**: Author tests in `package foo_test`. Define narrow consumer-side interfaces (1–2 methods) and prefer lightweight in-memory **Fakes** or function-field **Stubs** over heavy mock frameworks.

## The Testing Pyramid (70 / 20 / 10)

1. **Unit Tests (~70%)**: Pure domain logic via table-driven subtests, `t.Context()`, `google/go-cmp`, `testing/synctest`, and `testing.F` fuzzing.
2. **Integration & Component Tests (~20%)**: Boundary adapters via `net/http/httptest`, `testing/iotest`, and `-tags=integration` for ephemeral containers (`testcontainers-go`).
3. **Acceptance & E2E Tests (~10%)**: Business-readable Gherkin `.feature` suites via `cucumber/godog` bound to `*testing.T` with `Strict: true` and per-scenario isolation in `ctx.Before`.

## Ecosystem Recommendations

- **Recommended (Core)**: `testing`, `testing/synctest`, `net/http/httptest`, `testing/iotest`, `google/go-cmp`.
- **Recommended (Specialized)**: `cucumber/godog`, `gremlins`, `testcontainers-go`, `golangci-lint` v2, `govulncheck`.
- **Use with Caution**: `stretchr/testify`, `mockgen` / `mockery` (avoid coupling tests to internal call counts or oversized interfaces).
- **Generally Discouraged**: `Ginkgo` / `Gomega` (nested closure DSL obscures standard Go control flow).

## Fail-Fast Makefile Funnel

Execute quality gates from fastest to slowest so cheap checks abort before expensive suites:

1. **Inner TDD Loop**: `make test-unit` (`go test -race -shuffle=on -short ./...`)
2. **Pre-Commit / Agent Gate**: `make lint test-cover test-acceptance` (`golangci-lint` v2 + `go vet`, `-covermode=atomic` `>= 80%`, `godog` acceptance)
3. **Pull Request Gate**: `make check test-integration` (`lint` -> `vuln` -> `test-cover` -> `test-acceptance` -> `test-mutation` `>= 85%` efficacy on domain packages)
4. **Nightly / Pre-Release**: `make fuzz bench` (`go test -fuzz` and `for b.Loop()` with `-benchmem -count=5` + `benchstat`)

## Reference

Read [references/testing-report.md](./references/testing-report.md) for code examples (`go-cmp`, `synctest`, `godog`, `gremlins`, `testing.F`, `b.Loop()`) and the complete Makefile integration blueprint.
