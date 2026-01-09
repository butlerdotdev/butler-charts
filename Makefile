# Butler Charts Makefile
# Common operations for Helm chart development

CHARTS_DIR := charts
PACKAGE_DIR := .packages
GHCR_REGISTRY := ghcr.io/butlerdotdev/charts

# All chart names
CHARTS := butler-crds butler-bootstrap butler-controller \
          butler-provider-harvester butler-provider-nutanix butler-provider-proxmox \
          butler-console

.PHONY: help lint lint-all template package package-all push push-all clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

##@ Development

lint: ## Lint a specific chart (CHART=butler-controller)
ifndef CHART
	$(error CHART is not set. Usage: make lint CHART=butler-controller)
endif
	helm lint $(CHARTS_DIR)/$(CHART)

lint-all: ## Lint all charts
	@for chart in $(CHARTS); do \
		echo "Linting $$chart..."; \
		helm lint $(CHARTS_DIR)/$$chart || exit 1; \
	done
	@echo "All charts passed linting!"

template: ## Render templates for a specific chart (CHART=butler-controller)
ifndef CHART
	$(error CHART is not set. Usage: make template CHART=butler-controller)
endif
	helm template $(CHART) $(CHARTS_DIR)/$(CHART)

template-edge: ## Render templates with edge profile (CHART=butler-controller)
ifndef CHART
	$(error CHART is not set. Usage: make template-edge CHART=butler-controller)
endif
	helm template $(CHART) $(CHARTS_DIR)/$(CHART) -f profiles/edge.yaml

template-core: ## Render templates with core profile (CHART=butler-controller)
ifndef CHART
	$(error CHART is not set. Usage: make template-core CHART=butler-controller)
endif
	helm template $(CHART) $(CHARTS_DIR)/$(CHART) -f profiles/core.yaml

##@ Packaging

package: ## Package a specific chart (CHART=butler-controller)
ifndef CHART
	$(error CHART is not set. Usage: make package CHART=butler-controller)
endif
	@mkdir -p $(PACKAGE_DIR)
	helm package $(CHARTS_DIR)/$(CHART) -d $(PACKAGE_DIR)

package-all: ## Package all charts
	@mkdir -p $(PACKAGE_DIR)
	@for chart in $(CHARTS); do \
		echo "Packaging $$chart..."; \
		helm package $(CHARTS_DIR)/$$chart -d $(PACKAGE_DIR) || exit 1; \
	done
	@echo "All charts packaged in $(PACKAGE_DIR)/"

##@ Publishing

push: ## Push a specific chart to GHCR (CHART=butler-controller)
ifndef CHART
	$(error CHART is not set. Usage: make push CHART=butler-controller)
endif
	@VERSION=$$(grep '^version:' $(CHARTS_DIR)/$(CHART)/Chart.yaml | awk '{print $$2}'); \
	echo "Pushing $(CHART) version $$VERSION to $(GHCR_REGISTRY)..."; \
	helm push $(PACKAGE_DIR)/$(CHART)-$$VERSION.tgz oci://$(GHCR_REGISTRY)

push-all: package-all ## Package and push all charts to GHCR
	@for chart in $(CHARTS); do \
		VERSION=$$(grep '^version:' $(CHARTS_DIR)/$$chart/Chart.yaml | awk '{print $$2}'); \
		echo "Pushing $$chart version $$VERSION..."; \
		helm push $(PACKAGE_DIR)/$$chart-$$VERSION.tgz oci://$(GHCR_REGISTRY) || exit 1; \
	done
	@echo "All charts pushed to $(GHCR_REGISTRY)!"

##@ Installation (Local Testing)

install-crds: ## Install CRDs to current cluster
	helm upgrade --install butler-crds $(CHARTS_DIR)/butler-crds \
		--namespace butler-system --create-namespace

install-controller: ## Install controller to current cluster
	helm upgrade --install butler-controller $(CHARTS_DIR)/butler-controller \
		--namespace butler-system

install-console: ## Install console to current cluster
	helm upgrade --install butler-console $(CHARTS_DIR)/butler-console \
		--namespace butler-system

uninstall: ## Uninstall all Butler components
	-helm uninstall butler-console -n butler-system
	-helm uninstall butler-controller -n butler-system
	-helm uninstall butler-crds -n butler-system

##@ Utilities

clean: ## Clean packaged charts
	rm -rf $(PACKAGE_DIR)

versions: ## Show versions of all charts
	@for chart in $(CHARTS); do \
		VERSION=$$(grep '^version:' $(CHARTS_DIR)/$$chart/Chart.yaml | awk '{print $$2}'); \
		APP_VERSION=$$(grep '^appVersion:' $(CHARTS_DIR)/$$chart/Chart.yaml | awk '{print $$2}'); \
		printf "%-30s chart: %-10s app: %s\n" "$$chart" "$$VERSION" "$$APP_VERSION"; \
	done

docs: ## Generate documentation for all charts
	@for chart in $(CHARTS); do \
		echo "Generating docs for $$chart..."; \
		helm-docs --chart-search-root $(CHARTS_DIR)/$$chart 2>/dev/null || true; \
	done
