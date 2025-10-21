.PHONY: help install install-local test clean uninstall

# Configuration
CLAUDE_DIR := $(HOME)/.claude
PROJECT_DIR := $(CURDIR)
BACKUP_DIR := $(HOME)/.claude.backup

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
	@echo "  make install        - Install to ~/.claude (with backup)"
	@echo "  make install-local  - Install to project .claude directory"
	@echo "  make test          - Run validation tests"
	@echo "  make clean         - Clean test artifacts"
	@echo "  make uninstall     - Uninstall from ~/.claude (restore backup if exists)"
	@echo "  make help          - Show this help message"
	@echo ""

install:
	@echo "========================================"
	@echo "  Installing Claude Config to ~/.claude"
	@echo "========================================"
	@# Check if ~/.claude exists and back it up
	@if [ -d "$(CLAUDE_DIR)" ]; then \
		echo "$(YELLOW)⚠  Backing up existing ~/.claude to ~/.claude.backup$(NC)"; \
		rm -rf "$(BACKUP_DIR)"; \
		cp -r "$(CLAUDE_DIR)" "$(BACKUP_DIR)"; \
		echo "$(GREEN)✓$(NC) Backup created at ~/.claude.backup"; \
	fi
	@# Create ~/.claude if it doesn't exist
	@mkdir -p "$(CLAUDE_DIR)"
	@# Copy directories
	@echo "Copying configuration files..."
	@if [ -d "$(PROJECT_DIR)/commands" ]; then \
		cp -r "$(PROJECT_DIR)/commands" "$(CLAUDE_DIR)/"; \
		echo "$(GREEN)✓$(NC) Copied commands/"; \
	fi
	@if [ -d "$(PROJECT_DIR)/hooks" ]; then \
		cp -r "$(PROJECT_DIR)/hooks" "$(CLAUDE_DIR)/"; \
		chmod +x "$(CLAUDE_DIR)"/hooks/*.sh 2>/dev/null || true; \
		echo "$(GREEN)✓$(NC) Copied hooks/ (made scripts executable)"; \
	fi
	@if [ -d "$(PROJECT_DIR)/agents" ]; then \
		cp -r "$(PROJECT_DIR)/agents" "$(CLAUDE_DIR)/"; \
		echo "$(GREEN)✓$(NC) Copied agents/"; \
	fi
	@if [ -d "$(PROJECT_DIR)/skills" ]; then \
		cp -r "$(PROJECT_DIR)/skills" "$(CLAUDE_DIR)/"; \
		echo "$(GREEN)✓$(NC) Copied skills/"; \
	fi
	@# Copy settings.json if it exists
	@if [ -f "$(PROJECT_DIR)/settings.json" ]; then \
		cp "$(PROJECT_DIR)/settings.json" "$(CLAUDE_DIR)/settings.json"; \
		echo "$(GREEN)✓$(NC) Copied settings.json"; \
	fi
	@# Copy CLAUDE.md if it exists
	@if [ -f "$(PROJECT_DIR)/CLAUDE.md" ]; then \
		cp "$(PROJECT_DIR)/CLAUDE.md" "$(CLAUDE_DIR)/CLAUDE.md"; \
		echo "$(GREEN)✓$(NC) Copied CLAUDE.md"; \
	fi
	@echo ""
	@echo "$(GREEN)✓ Installation complete!$(NC)"
	@echo ""
	@echo "Your Claude configuration is now at: $(CLAUDE_DIR)"
	@echo "Backup available at: $(BACKUP_DIR)"

install-local:
	@echo "========================================"
	@echo "  Installing to Project .claude"
	@echo "========================================"
	@# Create .claude directory in project
	@mkdir -p "$(PROJECT_DIR)/.claude"
	@# Copy directories
	@echo "Copying configuration files..."
	@if [ -d "$(PROJECT_DIR)/commands" ]; then \
		cp -r "$(PROJECT_DIR)/commands" "$(PROJECT_DIR)/.claude/"; \
		echo "$(GREEN)✓$(NC) Copied commands/"; \
	fi
	@if [ -d "$(PROJECT_DIR)/hooks" ]; then \
		cp -r "$(PROJECT_DIR)/hooks" "$(PROJECT_DIR)/.claude/"; \
		chmod +x "$(PROJECT_DIR)"/.claude/hooks/*.sh 2>/dev/null || true; \
		echo "$(GREEN)✓$(NC) Copied hooks/ (made scripts executable)"; \
	fi
	@if [ -d "$(PROJECT_DIR)/agents" ]; then \
		cp -r "$(PROJECT_DIR)/agents" "$(PROJECT_DIR)/.claude/"; \
		echo "$(GREEN)✓$(NC) Copied agents/"; \
	fi
	@if [ -d "$(PROJECT_DIR)/skills" ]; then \
		cp -r "$(PROJECT_DIR)/skills" "$(PROJECT_DIR)/.claude/"; \
		echo "$(GREEN)✓$(NC) Copied skills/"; \
	fi
	@# Copy settings.json to settings.local.json
	@if [ -f "$(PROJECT_DIR)/settings.json" ]; then \
		cp "$(PROJECT_DIR)/settings.json" "$(PROJECT_DIR)/.claude/settings.local.json"; \
		echo "$(GREEN)✓$(NC) Copied settings.json to .claude/settings.local.json"; \
	fi
	@echo ""
	@echo "$(GREEN)✓ Local installation complete!$(NC)"
	@echo ""
	@echo "Your project-level Claude configuration is at: $(PROJECT_DIR)/.claude"

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

uninstall:
	@echo "========================================"
	@echo "  Uninstalling from ~/.claude"
	@echo "========================================"
	@# Confirm before uninstalling
	@echo "$(YELLOW)⚠  This will remove ~/.claude$(NC)"
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" != "y" ] && [ "$$confirm" != "Y" ]; then \
		echo "Cancelled."; \
		exit 0; \
	fi
	@# Remove ~/.claude
	@if [ -d "$(CLAUDE_DIR)" ]; then \
		rm -rf "$(CLAUDE_DIR)"; \
		echo "$(GREEN)✓$(NC) Removed ~/.claude"; \
	else \
		echo "$(YELLOW)⚠$(NC) ~/.claude does not exist"; \
	fi
	@# Restore backup if it exists
	@if [ -d "$(BACKUP_DIR)" ]; then \
		echo ""; \
		read -p "Restore backup from ~/.claude.backup? (y/N): " restore; \
		if [ "$$restore" = "y" ] || [ "$$restore" = "Y" ]; then \
			cp -r "$(BACKUP_DIR)" "$(CLAUDE_DIR)"; \
			echo "$(GREEN)✓$(NC) Restored backup from ~/.claude.backup"; \
		fi \
	fi
	@echo ""
	@echo "$(GREEN)✓ Uninstall complete$(NC)"
