# Makefile for SwiftBrowser
# Builds the Swift package and creates app bundle in .build directory

# Variables
PROJECT_NAME = SwiftBrowser
BUILD_DIR = .build
APP_BUNDLE = $(BUILD_DIR)/$(PROJECT_NAME).app
SWIFT_BUILD_DIR = $(BUILD_DIR)/release
SOURCE_DIR = Sources/$(PROJECT_NAME)

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m

.PHONY: all build clean install run help

# Default target
all: build

# Build the application
build:
	@echo "$(YELLOW)Building $(PROJECT_NAME)...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@swift build -c release --build-path $(BUILD_DIR)
	@echo "$(YELLOW)Creating app bundle...$(NC)"
	@$(MAKE) create-bundle
	@echo "$(GREEN)Build complete: $(APP_BUNDLE)$(NC)"

# Create the app bundle structure
create-bundle:
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(SWIFT_BUILD_DIR)/$(PROJECT_NAME) $(APP_BUNDLE)/Contents/MacOS/
	@cp $(SOURCE_DIR)/Resources/Info.plist $(APP_BUNDLE)/Contents/
	@chmod +x $(APP_BUNDLE)/Contents/MacOS/$(PROJECT_NAME)
	@if [ -d "$(SOURCE_DIR)/Resources" ]; then \
		cp -r $(SOURCE_DIR)/Resources/* $(APP_BUNDLE)/Contents/Resources/ 2>/dev/null || true; \
	fi

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf SwiftBrowser.app
	@echo "$(GREEN)Clean complete$(NC)"

# Install (copy to Applications - requires sudo)
install: build
	@echo "$(YELLOW)Installing $(PROJECT_NAME) to /Applications...$(NC)"
	@sudo cp -r $(APP_BUNDLE) /Applications/
	@echo "$(GREEN)Installation complete$(NC)"

# Run the application
run: build
	@echo "$(YELLOW)Running $(PROJECT_NAME)...$(NC)"
	@open $(APP_BUNDLE)

# Show help
help:
	@echo "$(PROJECT_NAME) Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build     - Build the application (default)"
	@echo "  clean     - Clean build artifacts"
	@echo "  install   - Install to /Applications (requires sudo)"
	@echo "  run       - Build and run the application"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Output: $(APP_BUNDLE)"
