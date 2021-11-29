GO_INSTALL = ./hack/go-install.sh

TOOLS_DIR=hack/tools
GOBIN_DIR := $(abspath $(TOOLS_DIR))

CONTROLLER_GEN_VER := v0.7.0
CONTROLLER_GEN_BIN := controller-gen
CONTROLLER_GEN := $(TOOLS_DIR)/$(CONTROLLER_GEN_BIN)-$(CONTROLLER_GEN_VER)
export CONTROLLER_GEN # so hack scripts can use it

OPENSHIFT_GOIMPORTS_VER := b92214262c6ce8598aefdee87aae6b8cf1a9fc86
OPENSHIFT_GOIMPORTS_BIN := openshift-goimports
OPENSHIFT_GOIMPORTS := $(TOOLS_DIR)/$(OPENSHIFT_GOIMPORTS_BIN)-$(OPENSHIFT_GOIMPORTS_VER)
export OPENSHIFT_GOIMPORTS # so hack scripts can use it


all: build
.PHONY: all

build:
	go build -o bin ./cmd/...
.PHONY: build

vendor:
	go mod tidy
	go mod vendor
.PHONY: vendor

$(CONTROLLER_GEN):
	GOBIN=$(GOBIN_DIR) $(GO_INSTALL) sigs.k8s.io/controller-tools/cmd/controller-gen $(CONTROLLER_GEN_BIN) $(CONTROLLER_GEN_VER)

codegen: $(CONTROLLER_GEN)
	./hack/update-codegen.sh
	$(MAKE) imports
.PHONY: codegen

# Note, running this locally if you have any modified files, even those that are not generated,
# will result in an error. This target is mostly for CI jobs.
.PHONY: verify-codegen
verify-codegen: codegen
	@if !(git diff --quiet HEAD); then \
		git diff; \
		echo "You need to run 'make codegen' to update generated files and commit them"; exit 1; \
	fi


$(OPENSHIFT_GOIMPORTS):
	GOBIN=$(GOBIN_DIR) $(GO_INSTALL) github.com/coreydaley/openshift-goimports $(OPENSHIFT_GOIMPORTS_BIN) $(OPENSHIFT_GOIMPORTS_VER)

.PHONY: imports
imports: $(OPENSHIFT_GOIMPORTS)
	$(OPENSHIFT_GOIMPORTS) -m github.com/kcp-dev/kcp