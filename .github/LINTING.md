# Code Linting & Formatting Guide

This guide explains how to set up and use linting tools for AIC-SOS, which includes Go, Rust, and TypeScript codebases.

**Quick Start:**
```bash
# Check all code with linters
make lint

# Format all code
make fmt

# Check individual languages
make lint-go
make lint-rust
make lint-ts

# Format individual languages
make fmt-go
make fmt-rust
make fmt-ts
```

## Overview

AIC-SOS uses language-specific linters to maintain code quality and consistency:

| Language | Linter | Purpose | Location |
|----------|--------|---------|----------|
| Go | [golangci-lint](https://golangci-lint.run/) | Multi-linter wrapper, security scanning | `.golangci.yaml` |
| Rust | [cargo clippy](https://doc.rust-lang.org/clippy/) | Lint warnings, code suggestions | `.clippy.toml` |
| TypeScript/JS | [ESLint](https://eslint.org/) + [Prettier](https://prettier.io/) | Style + formatting | `.eslintrc.json`, `.prettierrc.json` |

## Setup

### Go (golangci-lint)

Install golangci-lint:
```bash
# macOS
brew install golangci-lint

# Linux
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin latest

# Or globally
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

Verify installation:
```bash
golangci-lint version
```

### Rust (cargo clippy)

Clippy comes with Rust by default. Update to ensure latest version:
```bash
rustup update
rustc --version  # Should be 1.75+
```

Verify Clippy:
```bash
cargo clippy --version
```

### TypeScript/JavaScript (ESLint + Prettier)

Install dependencies in web app:
```bash
cd apps/web
npm install
```

Verify installation:
```bash
npm run lint --version
npx prettier --version
```

## Running Linters

### Run All Linters

```bash
make lint
```

This runs all three language linters:
- Go: `golangci-lint run ./services/{control-plane,connector-gateway,indexer}`
- Rust: `cargo clippy` on execution-plane and agent
- TypeScript: `eslint apps/web`

### Go Linting

```bash
make lint-go
```

**What it checks:**
- Unused variables, functions, imports
- Error handling (unchecked errors)
- Security issues (gosec)
- Code complexity
- Naming conventions
- Type safety

**Example output:**
```
services/control-plane/main.go:15:2: unused-parameter (unused)
    func handler(w http.ResponseWriter, r *http.Request) {
```

**Fix unused parameters:**
```go
func handler(_w http.ResponseWriter, _r *http.Request) {
    // Use _ prefix to mark intentionally unused
}
```

### Rust Linting

```bash
make lint-rust
```

**What it checks:**
- Clippy lints (100+ warnings)
- Security issues
- Performance suggestions
- API usage

**Example output:**
```
warning: variables can be used directly in the `format!` string
  --> src/main.rs:10:5
   |
10 | println!("value is {}", value);
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
```

**Fix with suggestion:**
```rust
println!("value is {value}");
```

### TypeScript/JavaScript Linting

```bash
make lint-ts
```

**What it checks:**
- Type safety (@typescript-eslint)
- Unused imports
- Import organization
- Code style
- No console in production code

**Example output:**
```
apps/web/src/app.ts:12:5 - error: variable declared but never used
```

## Formatting Code

### Format All Code

```bash
make fmt
```

This formats all three languages:
- Go: `gofmt` + `goimports`
- Rust: `rustfmt`
- TypeScript: `prettier`

### Go Formatting

```bash
make fmt-go
```

**Installs goimports if not present:**
```bash
go install golang.org/x/tools/cmd/goimports@latest
```

**Features:**
- Standard formatting (gofmt)
- Auto-organize imports
- Adds missing imports
- Removes unused imports

**Example:**
```bash
# Before
services/control-plane/main.go    (unformatted)

# After
services/control-plane/main.go    (formatted, imports organized)
```

### Rust Formatting

```bash
make fmt-rust
```

**Features:**
- Consistent indentation
- Brace style
- Line length

**Note:** Clippy is separate from formatting. Run both:
```bash
cargo fmt                    # Format code
cargo clippy                 # Check for issues
```

### TypeScript/JavaScript Formatting

```bash
make fmt-ts
```

**Installs Prettier if not present:**
```bash
cd apps/web && npm install
```

**Features:**
- Line width: 100 characters
- Semicolons: yes
- Single quotes: yes
- Trailing commas: es5
- Arrow parens: always

**Configuration:** `.prettierrc.json`

## Configuration Files

### `.golangci.yaml`

Configured with:
- **Enabled linters:** 17 static checkers (error checking, style, complexity, security)
- **Disabled checks:** `hugeParam` (proto), `ifElseChain` (clarity)
- **Complexity:** cyclomatic complexity max 15
- **Security:** gosec with most rules enabled

**Key rules:**
- Error checking required (errcheck)
- Unused variables (unused)
- Security scanning (gosec)

### `.clippy.toml`

Configured with:
- **MSRV:** 1.75 (Minimum Supported Rust Version)
- **Warn level:** all + pedantic group
- **Deny:** todo/unimplemented/panic/unsafe blocks
- **Allow:** type_complexity, module_name_repetitions (false positives)

**Key rules:**
- No todo/unimplemented in code (must be fixed)
- Unsafe code must be documented
- Explicit error handling

### `.eslintrc.json`

Configured with:
- **Parser:** @typescript-eslint/parser (TypeScript support)
- **Extends:** eslint:recommended + @typescript-eslint/recommended
- **Plugins:** @typescript-eslint, import, unused-imports

**Key rules:**
- No `any` type (strict)
- No floating promises
- Type safety on string operations
- Import organization

### `.prettierrc.json`

Configured with:
- Line width: 100
- Indentation: 2 spaces
- Quotes: single
- Semicolons: yes
- Trailing commas: es5

## Integration

### CI/CD

Linting is **not yet automated** in CI. See planned integrations below.

### Local Git Hooks

You can set up pre-commit hooks to lint before commits:

**Create `.git/hooks/pre-commit`:**
```bash
#!/bin/bash
make lint || exit 1
```

**Make executable:**
```bash
chmod +x .git/hooks/pre-commit
```

**Now linting runs before every commit.**

### IDE Integration

#### VSCode

Install extensions:
- **Go:** ms-vscode.go
- **Rust Analyzer:** rust-lang.rust-analyzer
- **ESLint:** dbaeumer.vscode-eslint
- **Prettier:** esbenp.prettier-vscode

**settings.json:**
```json
{
  "go.lintTool": "golangci-lint",
  "go.lintOnSave": "package",
  "rust-analyzer.checkOnSave.command": "clippy",
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true
  }
}
```

#### GoLand / IntelliJ IDEA

Built-in support for golangci-lint:
- Settings → Languages & Frameworks → Go → Linter
- Enable "Run golangci-lint"

## Troubleshooting

### "golangci-lint: command not found"

Install golangci-lint:
```bash
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

Check installation:
```bash
which golangci-lint
golangci-lint version
```

### "cargo clippy: command not found"

Update Rust:
```bash
rustup update
```

Clippy should come with Rust installation.

### "eslint: command not found"

Install dependencies:
```bash
cd apps/web
npm install
```

Or run through npm:
```bash
cd apps/web
npm run lint
```

### Linter disagrees with Prettier

This can happen if eslint and prettier have conflicting rules. Solution:

1. **Use prettier for formatting**, eslint for linting
2. Ensure `"prettier"` is last in eslintrc `extends` (it disables conflicting rules)
3. Run `make fmt-ts` before `make lint-ts`

## Fixing Common Issues

### Unused variable

**Error:** `variable declared but never used`

**Fix:**
```go
// Go: Use _ to discard
result, _ := someFunction()

// Rust: Mark with #[allow(unused)]
#[allow(unused)]
let value = expensive_operation();

// TypeScript: Remove the variable
// Or mark with /* eslint-disable-next-line @typescript-eslint/no-unused-vars */
const _unused = value;
```

### Error not checked

**Error:** `Error return value not checked`

**Fix:**
```go
// Before
file.Close()

// After
if err := file.Close(); err != nil {
    log.Printf("Failed to close file: %v", err)
}

// Or explicitly discard (if safe)
_ = file.Close()
```

### Missing import

**Error:** `undefined: SomeFunction`

**Fix:**
```bash
make fmt-go    # goimports automatically adds imports
```

### Type mismatch

**Error:** `cannot use type X as type Y`

**Fix:** Check type definitions, use type assertions where needed
```typescript
const str = value as string;  // Type assertion
```

## Next Steps

After linting is configured:

1. **Run locally:** `make lint` and `make fmt`
2. **Set up pre-commit hooks:** `.git/hooks/pre-commit`
3. **Configure IDE:** Install linter extensions
4. **Integrate with CI:** Add linting step to GitHub Actions (Phase 1+)

## References

- **golangci-lint:** https://golangci-lint.run/
- **cargo clippy:** https://doc.rust-lang.org/clippy/
- **ESLint:** https://eslint.org/
- **Prettier:** https://prettier.io/
- **TypeScript ESLint:** https://typescript-eslint.io/

## Decision Log

**Why these linters?**
- **golangci-lint:** Industry standard for Go, comprehensive, configurable
- **cargo clippy:** Official Rust linter, built-in
- **ESLint + Prettier:** Standard for TS/JS, complementary (lint + format)

**Why these rules?**
- Error checking required: Prevents silent failures
- Type safety: Catch bugs at lint time, not runtime
- Security (gosec): Identify known vulnerability patterns
- Code complexity limits: Prevent unmaintainable functions

**Why separate formatter?**
- ESLint can do formatting, but Prettier is purpose-built
- Prettier is faster and more opinionated
- Using both together with proper config avoids conflicts

---

**Last Updated:** December 19, 2024

**Status:** 🟢 Production Ready

See `.golangci.yaml`, `.clippy.toml`, `.eslintrc.json` for detailed rules.
