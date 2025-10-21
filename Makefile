.PHONY: help test clean

# Configuration
PROJECT_DIR := $(CURDIR)

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m

help:
	@echo "========================================"
	@echo "  Claude Config Makefile"
	@echo "========================================"
	@echo ""
	@echo "Targets:"
	@echo "  make test   - Run validation tests"
	@echo "  make clean  - Clean test artifacts"
	@echo "  make help   - Show this help message"
	@echo ""
	@echo "Installation:"
	@echo "  See INSTALLATION.md for git clone based installation"
	@echo ""

test:
	@echo "========================================"
	@echo "  Running Configuration Validation"
	@echo "========================================"
	@echo ""
	@if [ -x "$(PROJECT_DIR)/test/validate-config.sh" ]; then \
		"$(PROJECT_DIR)/test/validate-config.sh" "$(PROJECT_DIR)"; \
	else \
		echo "$(RED)✗ Test script not found or not executable$(NC)"; \
		echo "Run: chmod +x test/validate-config.sh"; \
		exit 1; \
	fi

clean:
	@echo "Cleaning test artifacts..."
	@# Currently no artifacts to clean, but placeholder for future
	@echo "$(GREEN)✓$(NC) Clean complete"
