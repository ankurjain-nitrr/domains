# Define the shell to use
SHELL := /bin/bash

# Define variables for directories
GEN_DIR := gen
PROTO_DIR := proto

# Define tool versions
BUF_VERSION := 1.17.0
PROTOC_GEN_GO_VERSION := v1.28.0
PROTOC_GEN_JAVA_VERSION := 3.21.7

GRPC_JAVA_VERSION := 1.68.0
PROTOC_GEN_GRPC_JAVA_PATH := $(HOME)/bin/protoc-gen-grpc-java

# Define the default target
.DEFAULT_GOAL := all

# PHONY targets
.PHONY: all generate lint clean help init install-buf install-protoc-gen-go install-protoc-gen-java check_buf check_go check_java check_os install-protoc-gen-grpc-java install-protoc-gen-go-grpc

# Default target: clean, lint, and generate
all: clean lint generate
	@echo "All tasks completed successfully."

# Initialize the project by installing dependencies (macOS only)
init: check_os check_brew check_go check_java install-buf install-protoc-gen-go install-protoc-gen-java install-protoc-gen-go-grpc install-protoc-gen-grpc-java
	@echo "Initialization complete."

# Check if running on macOS
check_os:
	@if [ "$$(uname)" != "Darwin" ]; then \
		echo "Error: 'make init' is currently only supported on macOS."; \
		echo "For other operating systems, please install the required dependencies manually."; \
		exit 1; \
	fi

# Check if Homebrew is installed
check_brew:
	@which brew > /dev/null || (echo "Error: Homebrew is not installed. Please install it from https://brew.sh/" && exit 1)

# Install buf
install-buf: check_brew
	@echo "Checking buf installation..."
	@if ! command -v buf &> /dev/null; then \
		echo "Installing buf..."; \
		brew install bufbuild/buf/buf; \
	else \
		echo "buf is already installed."; \
	fi

# Install protoc-gen-go
install-protoc-gen-go: check_brew check_go
	@echo "Checking protoc-gen-go installation..."
	@if ! command -v protoc-gen-go &> /dev/null; then \
		echo "Installing protoc-gen-go..."; \
		brew install protoc-gen-go; \
	else \
		echo "protoc-gen-go is already installed."; \
	fi

install-protoc-gen-grpc-java: 
	@echo "Installing protoc-gen-grpc-java..."
	@mkdir -p $(HOME)/bin
	@curl -L https://repo1.maven.org/maven2/io/grpc/protoc-gen-grpc-java/$(GRPC_JAVA_VERSION)/protoc-gen-grpc-java-$(GRPC_JAVA_VERSION)-osx-x86_64.exe -o $(PROTOC_GEN_GRPC_JAVA_PATH)
	@chmod +x $(PROTOC_GEN_GRPC_JAVA_PATH)

install-protoc-gen-go-grpc:
	@echo "Installing protoc-gen-go-grpc..."
	@go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Generate code from proto files
generate: check_buf
	@echo "Generating code..."
	@buf generate
	@echo "Code generation complete."

# Lint proto files
lint: check_buf
	@echo "Linting proto files..."
	@buf lint
	@echo "Linting complete."

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -rf $(GEN_DIR)
	@echo "Clean complete."

# Help target
help:
	@echo "Available targets:"
	@echo "  all                  : Run clean, lint, and generate"
	@echo "  init                 : Install all dependencies (macOS only)"
	@echo "  install-buf          : Install buf (macOS only)"
	@echo "  install-protoc-gen-go: Install protoc-gen-go (macOS only)"
	@echo "  install-protoc-gen-java: Install protoc-gen-java (macOS only)"
	@echo "  generate             : Generate code from proto files"
	@echo "  lint                 : Lint proto files"
	@echo "  clean                : Remove generated files"
	@echo "  help                 : Show this help message"
	@echo ""
	@echo "Note: 'make init' and installation targets are currently only supported on macOS."
	@echo "For other operating systems, please install the required dependencies manually."

# Check if buf is installed
check_buf:
	@which buf > /dev/null || (echo "Error: buf is not installed. Please run 'make install-buf' to install it." && exit 1)

# Check if Go is installed
check_go:
	@which go > /dev/null || (echo "Error: Go is not installed. Please install Go from https://golang.org/doc/install" && exit 1)

# Check if Java is installed
check_java:
	@which java > /dev/null || (echo "Error: Java is not installed. Please install Java from https://adoptopenjdk.net/" && exit 1)
