# Developer entry points for the bi-digital-banking monorepo.
# Every target delegates to Melos (declared as a root dev dependency), so no
# global activation is required locally or in CI.

MELOS   := dart run melos
APP_DIR := apps/banking_app
FIREBASE_PROJECT := bi-digital-banking

.DEFAULT_GOAL := help
.PHONY: help setup bootstrap gen analyze format format-check test coverage \
        run-dev run-prod build-apk-dev build-apk-prod brand-assets rc-template \
        deploy-rc clean

help: ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

setup: ## First-time setup: check toolchain, resolve deps and run codegen
	flutter --version
	dart pub get
	$(MELOS) bootstrap
	$(MELOS) run build_runner

bootstrap: ## Resolve dependencies for every workspace package
	$(MELOS) bootstrap

gen: ## Run code generation: build_runner and gen-l10n
	$(MELOS) run build_runner
	$(MELOS) run gen-l10n

analyze: ## Static analysis on every package (infos are fatal)
	$(MELOS) run analyze

format: ## Apply dart format to the whole workspace
	$(MELOS) run format:fix

format-check: ## Fail if any file is not formatted (used by CI)
	$(MELOS) run format

test: ## Run unit and widget tests on every package
	$(MELOS) run test

coverage: ## Run tests with coverage and merge them into coverage/lcov.info
	$(MELOS) exec --dir-exists=test -- flutter test --no-pub --coverage
	@rm -rf coverage && mkdir -p coverage
	@for f in $$(find apps packages -path '*/coverage/lcov.info'); do \
		pkg=$$(dirname $$(dirname $$f)); \
		sed "s|^SF:|SF:$$pkg/|" $$f >> coverage/lcov.info; \
	done
	@echo "Merged report: coverage/lcov.info"
	@if command -v genhtml >/dev/null; then \
		genhtml -q coverage/lcov.info -o coverage/html && echo "HTML report: coverage/html/index.html"; \
	else \
		echo "Install lcov (brew install lcov) to get an HTML report"; \
	fi

run-dev: ## Run the app with the dev flavor
	cd $(APP_DIR) && flutter run --flavor dev -t lib/main_dev.dart

run-prod: ## Run the app with the prod flavor
	cd $(APP_DIR) && flutter run --flavor prod -t lib/main_prod.dart

build-apk-dev: ## Build a release APK for the dev flavor
	cd $(APP_DIR) && flutter build apk --release --flavor dev -t lib/main_dev.dart

build-apk-prod: ## Build a release APK for the prod flavor
	cd $(APP_DIR) && flutter build apk --release --flavor prod -t lib/main_prod.dart

brand-assets: ## Render the app icon and splash images from the NexoLogo painter
	cd $(APP_DIR) && flutter test tool/brand_assets_test.dart

rc-template: ## Build the Remote Config template from firebase/remote-config/*.json
	cd $(APP_DIR) && dart run tool/remote_config_template.dart

deploy-rc: rc-template ## Publish the Remote Config template (needs `firebase login`)
	firebase deploy --only remoteconfig --project $(FIREBASE_PROJECT)

clean: ## Remove build outputs and coverage reports
	$(MELOS) exec -- flutter clean
	rm -rf coverage
