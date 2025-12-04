# Handy Dictation - Makefile
# A customized fork of Handy for local speech-to-text transcription

.PHONY: all install dev build release install-app uninstall clean format lint check help

# Configuration
APP_NAME := Handy
BUNDLE_PATH := src-tauri/target/release/bundle/macos/$(APP_NAME).app
INSTALL_PATH := /Applications/$(APP_NAME).app

# Default target
all: help

#───────────────────────────────────────────────────────────────────────────────
# Development
#───────────────────────────────────────────────────────────────────────────────

## Install all dependencies (run this first)
install:
	@echo "📦 Installing dependencies..."
	bun install
	@echo "✅ Dependencies installed"

## Start development server with hot reload
dev:
	@echo "🚀 Starting development server..."
	bun tauri dev

## Check if code compiles without building
check:
	@echo "🔍 Checking code..."
	cd src-tauri && cargo check
	@echo "✅ Code check passed"

#───────────────────────────────────────────────────────────────────────────────
# Building
#───────────────────────────────────────────────────────────────────────────────

## Build release version
build:
	@echo "🔨 Building release version..."
	bun tauri build
	@echo "✅ Build complete: $(BUNDLE_PATH)"

## Build release and install to /Applications (one command to update locally)
release: build install-app
	@echo "🎉 Release installed to $(INSTALL_PATH)"

#───────────────────────────────────────────────────────────────────────────────
# Installation
#───────────────────────────────────────────────────────────────────────────────

## Install built app to /Applications
install-app:
	@echo "📲 Installing to $(INSTALL_PATH)..."
	@if [ -d "$(INSTALL_PATH)" ]; then \
		echo "  Removing existing installation..."; \
		rm -rf "$(INSTALL_PATH)"; \
	fi
	cp -r "$(BUNDLE_PATH)" "$(INSTALL_PATH)"
	@echo "🔍 Updating Spotlight index..."
	mdimport "$(INSTALL_PATH)"
	@echo "✅ Installed successfully!"
	@echo ""
	@echo "📌 You can now find '$(APP_NAME)' in Spotlight (Cmd+Space)"

## Uninstall app from /Applications
uninstall:
	@echo "🗑️  Uninstalling $(APP_NAME)..."
	@if [ -d "$(INSTALL_PATH)" ]; then \
		rm -rf "$(INSTALL_PATH)"; \
		echo "✅ Uninstalled successfully"; \
	else \
		echo "⚠️  App not found at $(INSTALL_PATH)"; \
	fi

#───────────────────────────────────────────────────────────────────────────────
# Code Quality
#───────────────────────────────────────────────────────────────────────────────

## Format all code (frontend + backend)
format:
	@echo "🎨 Formatting code..."
	bun run format
	@echo "✅ Code formatted"

## Check code formatting without making changes
lint:
	@echo "🔍 Checking code format..."
	bun run format:check
	@echo "✅ Code format check passed"

#───────────────────────────────────────────────────────────────────────────────
# Cleanup
#───────────────────────────────────────────────────────────────────────────────

## Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf src-tauri/target
	rm -rf dist
	rm -rf node_modules/.vite
	@echo "✅ Clean complete"

## Deep clean (including node_modules - requires reinstall)
clean-all: clean
	@echo "🧹 Deep cleaning..."
	rm -rf node_modules
	@echo "✅ Deep clean complete (run 'make install' to reinstall dependencies)"

#───────────────────────────────────────────────────────────────────────────────
# Utilities
#───────────────────────────────────────────────────────────────────────────────

## Open app logs
logs:
	@echo "📜 Opening app logs..."
	open ~/Library/Logs/$(APP_NAME)

## Show app data location
info:
	@echo "📍 App Locations:"
	@echo "  Install path: $(INSTALL_PATH)"
	@echo "  Logs: ~/Library/Logs/$(APP_NAME)"
	@echo "  Data: ~/Library/Application Support/$(APP_NAME)"
	@echo "  Bundle ID: com.pais.handy"

#───────────────────────────────────────────────────────────────────────────────
# Help
#───────────────────────────────────────────────────────────────────────────────

## Show this help message
help:
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║           🎤 Handy Dictation - Development Commands              ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Quick Start:"
	@echo "  make install      Install dependencies (run first)"
	@echo "  make dev          Start development server"
	@echo "  make release      Build and install to /Applications"
	@echo ""
	@echo "Development:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | \
		awk 'BEGIN {FS = ":"}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Common Workflows:"
	@echo "  First time setup:     make install && make dev"
	@echo "  Update local install: make release"
	@echo "  Clean rebuild:        make clean && make release"
	@echo ""
