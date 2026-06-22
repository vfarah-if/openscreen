# OpenScreen - Electron Screen Recorder & Video Editor
# ====================================================

.PHONY: help install dev build build-vite build-mac build-mac-local build-win build-linux \
        lint lint-fix format typecheck test test-watch test-e2e test-e2e-install \
        i18n-check preview clean clean-all nvm-use prepare ci

# App version (read from package.json) — used to locate electron-builder output
VERSION := $(shell node -p "require('./package.json').version" 2>/dev/null)

# Default target
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Setup ──────────────────────────────────────────

install: ## Install dependencies
	npm ci

nvm-use: ## Switch to the correct Node version via nvm
	. "$${NVM_DIR:-$$HOME/.nvm}/nvm.sh" && nvm use

prepare: ## Set up Husky git hooks
	npm run prepare

# ── Development ────────────────────────────────────

dev: ## Start Vite + Electron dev server
	npm run dev

preview: ## Preview the Vite production build
	npm run preview

# ── Build ──────────────────────────────────────────

build: ## Full build (TypeScript + Vite + Electron Builder)
	npm run build

build-vite: ## Build only the Vite frontend (no Electron packaging)
	npm run build-vite

build-mac: ## Build macOS .dmg installer
	npm run build:mac

build-mac-local: ## Build arm64 .app (ad-hoc signed, no dmg) and install to /Applications
	@. "$${NVM_DIR:-$$HOME/.nvm}/nvm.sh" && nvm install && \
		export CSC_IDENTITY_AUTO_DISCOVERY=false && \
		echo "Building Openscreen $(VERSION) with node $$(node -v) (ad-hoc signing, arm64)" && \
		npm run build:native:mac && \
		npm run build-vite && \
		npx electron-builder --mac --arm64 --dir
	@echo "Installing to /Applications ..."
	@osascript -e 'tell application "Openscreen" to quit' 2>/dev/null || true
	@rm -rf /Applications/Openscreen.app
	@ditto "release/$(VERSION)/mac-arm64/Openscreen.app" /Applications/Openscreen.app
	@echo "Installed /Applications/Openscreen.app (Openscreen $(VERSION))"

build-win: ## Build Windows .exe installer
	npm run build:win

build-linux: ## Build Linux .AppImage installer
	npm run build:linux

# ── Code Quality ───────────────────────────────────

lint: ## Run Biome linter
	npm run lint

lint-fix: ## Auto-fix linting issues
	npm run lint:fix

format: ## Format code with Biome
	npm run format

typecheck: ## Run TypeScript type checking (no emit)
	npx tsc --noEmit

# ── Testing ────────────────────────────────────────

test: ## Run unit tests with Vitest
	npm run test

test-watch: ## Run unit tests in watch mode
	npm run test:watch

test-e2e-install: ## Install Playwright browsers
	npx playwright install --with-deps chromium

test-e2e: ## Run end-to-end tests with Playwright
	npm run test:e2e

# ── Internationalization ───────────────────────────

i18n-check: ## Validate i18n translation structure
	npm run i18n:check

# ── CI (mirrors GitHub Actions pipeline) ──────────

ci: lint typecheck build-vite test ## Run the full CI pipeline locally

# ── Cleanup ────────────────────────────────────────

clean: ## Remove build artifacts
	rm -rf dist dist-electron release

clean-all: clean ## Remove build artifacts and node_modules
	rm -rf node_modules
