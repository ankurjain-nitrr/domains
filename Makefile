SHELL := /bin/bash

GEN_DIR := gen
GO_GEN_DIR := $(GEN_DIR)/proto/go
BIN_DIR := $(CURDIR)/bin
DESCRIPTORS := $(GEN_DIR)/descriptors.binpb

# Tool versions. Code generation plugin versions are pinned in buf.gen.yaml.
API_LINTER_VERSION := v2.4.0

.DEFAULT_GOAL := check

.PHONY: check all init generate lint format format-check api-lint lock-check compile-go compile-java deps clean help \
	install-buf install-maven install-api-linter check_buf check_go check_java check_maven check_os check_brew

# Everything CI runs
check: format-check lint api-lint lock-check compile-go compile-java
	@echo "All checks passed."

all: clean check

# Install tools (macOS only). Go, Java and Homebrew must already be installed.
init: check_os check_brew check_go check_java install-buf install-maven install-api-linter
	@echo "Initialization complete."

# Generate Go and Java code with the pinned remote plugins in buf.gen.yaml. Clears the previous output first,
# so code for removed messages doesn't linger and break compilation.
generate: check_buf
	@rm -rf $(GEN_DIR)/proto
	@buf generate

# buf lint: STANDARD and COMMENTS rules, including protovalidate rule checks
lint: check_buf
	@buf lint

# Format proto files in place
format: check_buf
	@buf format -w

# Fail if any proto file isn't formatted
format-check: check_buf
	@buf format -d --exit-code

# Google API linter (AIPs), configured in .api-linter.yaml
api-lint: check_buf install-api-linter
	@mkdir -p $(GEN_DIR)
	@buf build -o $(DESCRIPTORS)
	@$(BIN_DIR)/api-linter --config .api-linter.yaml --descriptor-set-in $(DESCRIPTORS) --skip-compilation \
		--set-exit-status --output-format summary $$(buf ls-files)

# Fail if buf.lock has entries buf.yaml no longer needs. Deps missing from buf.lock already fail `buf build`.
lock-check: check_buf
	@buf dep prune
	@git diff --exit-code -- buf.lock || (echo "buf.lock is out of date with buf.yaml: commit the change above." && exit 1)

# Compile and vet the generated Go code against the pinned module in build/go
compile-go: generate check_go
	@cp build/go/go.mod build/go/go.sum $(GO_GEN_DIR)/
	@cd $(GO_GEN_DIR) && go build ./... && go vet ./...

# Compile the generated Java code with build/java/pom.xml
compile-java: generate check_maven
	@mvn -q -B -f build/java/pom.xml compile

# Update dependencies in buf.lock to their latest versions
deps: check_buf
	@buf dep update

clean:
	@rm -rf $(GEN_DIR) build/java/target $(BIN_DIR)

help:
	@echo "Targets:"
	@echo "  check         Run everything CI runs (default)"
	@echo "  all           clean, then check"
	@echo "  init          Install buf, Maven and api-linter (macOS only)"
	@echo "  generate      Generate Go and Java code into gen/"
	@echo "  lint          buf lint (STANDARD + COMMENTS)"
	@echo "  format        Format proto files in place"
	@echo "  format-check  Fail if any proto file isn't formatted"
	@echo "  api-lint      Google API linter (AIPs)"
	@echo "  lock-check    Fail if buf.lock is out of date with buf.yaml"
	@echo "  compile-go    Generate and compile the Go code"
	@echo "  compile-java  Generate and compile the Java code"
	@echo "  deps          Update buf.lock to the latest dependency versions"
	@echo "  clean         Remove gen/, build outputs and installed tools"

install-buf: check_brew
	@command -v buf &> /dev/null || brew install bufbuild/buf/buf

install-maven: check_brew
	@command -v mvn &> /dev/null || brew install maven

install-api-linter: check_go
	@[ -x $(BIN_DIR)/api-linter ] && [ "$$($(BIN_DIR)/api-linter --version)" = "api-linter $(API_LINTER_VERSION:v%=%)" ] || \
		GOBIN=$(BIN_DIR) go install github.com/googleapis/api-linter/v2/cmd/api-linter@$(API_LINTER_VERSION)

check_os:
	@[ "$$(uname)" = "Darwin" ] || (echo "Error: 'make init' only supports macOS; install the tools manually." && exit 1)

check_brew:
	@which brew > /dev/null || (echo "Error: Homebrew is not installed. See https://brew.sh/" && exit 1)

check_buf:
	@which buf > /dev/null || (echo "Error: buf is not installed. Run 'make install-buf'." && exit 1)

check_go:
	@which go > /dev/null || (echo "Error: Go is not installed. See https://go.dev/doc/install" && exit 1)

check_java:
	@which java > /dev/null || (echo "Error: Java is not installed." && exit 1)

check_maven:
	@which mvn > /dev/null || (echo "Error: Maven is not installed. Run 'make install-maven'." && exit 1)
