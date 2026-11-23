# Go + templ + htmx Architecture Reference

## Contents

1. [Layer Responsibilities](#1-layer-responsibilities)
2. [Partial vs. Full-Page Rendering](#2-partial-vs-full-page-rendering)
3. [Out-of-Band Multi-Target Updates](#3-out-of-band-multi-target-updates)
4. [Form Validation & HTTP Status Codes](#4-form-validation--http-status-codes-htmx-2x)
5. [Opting Into htmx 4.0](#5-opting-into-htmx-40)
6. [Production Hardening & Ecosystem Extensions](#6-production-hardening--ecosystem-extensions)

---

## 1. Layer Responsibilities

- `cmd/server/main.go`: Process entrypoint, environment configuration, `http.Server` timeouts, and `SIGINT`/`SIGTERM` graceful shutdown. Keep routing and business logic out of `main.go`.
- `internal/handler/`: HTTP transport layer. Parses form/path values, calls domain services, inspects `HX-*` headers, enforces `http.CrossOriginProtection`, and selects either a full page or partial `templ.Component`.
- `internal/view/`: Pure presentation components (`*.templ` and generated `*_templ.go`). Components accept typed Go structs and never perform database queries or HTTP calls.
- `internal/assets/`: Embedded static assets (`//go:embed all:static`) served under `/static/`.

## 2. Partial vs. Full-Page Rendering

Support progressive enhancement so routes work both via direct browser navigation (`hx-boost="true"` or full reload) and via targeted htmx requests:

```go
func isHTMX(r *http.Request) bool {
	return strings.EqualFold(r.Header.Get("HX-Request"), "true")
}

func (h *Handler) handleProfile(w http.ResponseWriter, r *http.Request) {
	profile := h.service.GetProfile(r.Context())
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	if isHTMX(r) && r.Header.Get("HX-Target") == "profile-panel" {
		_ = view.ProfilePanel(profile).Render(r.Context(), w)
		return
	}
	_ = view.ProfilePage(profile).Render(r.Context(), w)
}
```

### Useful htmx Response Headers

- `HX-Redirect`: Trigger a full client-side redirect after login/logout (`w.Header().Set("HX-Redirect", "/dashboard")`).
- `HX-Trigger`: Emit custom DOM events to refresh independent widgets (`w.Header().Set("HX-Trigger", "itemsChanged")`).
- `HX-Retarget` / `HX-Reswap`: Override target or swap strategy dynamically from the server.

## 3. Out-of-Band Multi-Target Updates

When a single mutation must update both a list and a summary counter elsewhere on the page, render a primary fragment alongside an `hx-swap-oob="true"` element in the same response:

```templ
templ CreateItemResponse(item Item, totalCount int) {
	@ItemRow(item)
	<span id="item-count" hx-swap-oob="true">{ fmt.Sprintf("%d", totalCount) }</span>
}
```

Ensure the target element (`id="item-count"`) exists in the initial DOM.

## 4. Form Validation & HTTP Status Codes (htmx 2.x)

By default, htmx 2.x does not swap response bodies on `4xx`/`5xx` status codes. Choose one consistent pattern per project:

- **Server-driven `200 OK` re-render**: Return the form partial populated with field error messages and `200 OK` so htmx swaps the form in place without client-side scripts.
- **Semantic `422 Unprocessable Entity`**: Register a single global listener in `layout.templ`:

```html
<script>
  document.addEventListener("htmx:beforeSwap", function (evt) {
    if (evt.detail.xhr.status === 422) {
      evt.detail.shouldSwap = true;
      evt.detail.isError = false;
    }
  });
</script>
```

## 5. Opting Into htmx 4.0

If a project opts into `htmx.org@4.0.0`, account for the following behavioral differences from htmx 2.x:

- **Explicit Attribute Inheritance**: Attributes such as `hx-target`, `hx-swap`, and `hx-select` no longer inherit implicitly from parent elements. Append `:inherited` (for example, `hx-target:inherited="#main"`).
- **Default `4xx`/`5xx` Swapping & `hx-status`**: htmx 4.0 swaps error status responses by default and supports declarative per-status overrides (for example, `hx-status:422="target:#form-errors swap:innerHTML"`).
- **Built-in Morphing & `<hx-partial>`**: Use `hx-swap="innerMorph"` or `hx-swap="outerMorph"` for idiomorph-style DOM preservation without extra plugins, or return multiple `<hx-partial target="#id" swap="innerHTML">...</hx-partial>` elements from a single response.
- **Updated Event Naming**: Events follow `htmx:<phase>:<action>` (for example, `htmx:after:request` instead of `htmx:afterRequest`).

## 6. Production Hardening & Ecosystem Extensions

- **Static Asset Cache Headers**: Version static filenames (or append `?v=<build-sha>`) and serve `/static/` with `Cache-Control: public, max-age=31536000, immutable`.
- **Database Layer**: Add `internal/store/` using `sqlc` with `pgx` (PostgreSQL) or `modernc.org/sqlite` (single-binary SQLite) and inject repository interfaces into `handler.NewHandler(...)`.
- **Zero-Node UI Component Libraries**: When scaling beyond custom components without adding Node.js, adopt `shadcn-templ` (copies component source directly into your repository) or `templ-components` (typed component packages with CSP nonce support).
