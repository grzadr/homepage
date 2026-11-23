PORT ?= 8080
PROXY_PORT ?= 8081
COVERAGE_FILE := coverage.out
COVERAGE_MIN ?= 80.0
DOMAIN_PKGS := ./internal/domain/...

.PHONY: generate build run dev vendor-htmx lint vuln test test-unit test-cover test-acceptance test-integration test-mutation fuzz bench check

generate:
	go tool templ generate

build: generate
	go build -o bin/server ./cmd/server

run: generate
	PORT=$(PORT) go run ./cmd/server

dev:
	PORT=$(PORT) go tool templ generate -watch -proxy="http://localhost:$(PORT)" -proxyport="$(PROXY_PORT)" -cmd="go run ./cmd/server"

vendor-htmx:
	curl -fsSL https://unpkg.com/htmx.org@2.0.4/dist/htmx.min.js -o internal/assets/static/js/htmx.min.js

lint: generate
	golangci-lint run ./...
	go vet ./...

vuln:
	govulncheck ./...

test: test-unit

test-unit: generate
	go test -race -shuffle=on -short ./...

test-cover: generate
	go test -race -covermode=atomic -coverprofile=$(COVERAGE_FILE) -short ./...
	@total=$$(go tool cover -func=$(COVERAGE_FILE) | awk '/^total:/ {gsub("%","",$$3); print $$3}'); \
	awk -v t="$$total" -v m="$(COVERAGE_MIN)" 'BEGIN { if (t+0 < m+0) { printf "Coverage %.1f%% < %.1f%%\n", t, m; exit 1 } }'

test-acceptance: generate
	go test -race ./acceptance/...

test-integration: generate
	go test -race -count=1 -tags=integration ./...

test-mutation:
	gremlins unleash --workers 4 --threshold-efficacy 85.0 $(DOMAIN_PKGS)

fuzz:
	go test -fuzz=Fuzz -fuzztime=30s $(DOMAIN_PKGS)

bench:
	go test -bench=. -benchmem -count=5 $(DOMAIN_PKGS)

check: lint vuln test-cover test-acceptance test-mutation
