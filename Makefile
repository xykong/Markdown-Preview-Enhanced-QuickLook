.PHONY: all build_renderer generate app install dmg release delete-release

all: app

build_renderer:
	cd web-renderer && npm install --no-audit --no-fund --loglevel=warn && npm run build

generate: build_renderer
	@if ! command -v xcodegen >/dev/null; then \
		echo "Error: xcodegen is not installed. Please install it with 'brew install xcodegen'"; \
		exit 1; \
	fi
	@if [ ! -f .version ]; then echo "1.0.0" > .version; fi
	@full_v=$$(cat .version); \
	major=$$(echo $$full_v | cut -d'.' -f1); \
	minor=$$(echo $$full_v | cut -d'.' -f2); \
	build=$$(echo $$full_v | cut -d'.' -f3); \
	echo "Generating Project with Version: $$full_v (Major: $$major, Minor: $$minor, Build: $$build)"; \
	rm -rf FluxMarkdown.xcodeproj; \
	MARKETING_VERSION=$$full_v CURRENT_PROJECT_VERSION=$$build xcodegen generate --quiet

app: generate
	@echo "🔨 Building application in $(or $(CONFIGURATION),Release) configuration..."
	xcodebuild -project FluxMarkdown.xcodeproj -scheme Markdown -configuration $(or $(CONFIGURATION),Release) -destination 'platform=macOS,arch=arm64' clean build -quiet
	@echo "✅ Build completed: $(or $(CONFIGURATION),Release) configuration"

install:
	@config="Release"; \
	if echo "$(MAKECMDGOALS)" | grep -q "debug"; then \
		config="Debug"; \
	fi; \
	echo "🚀 Building and installing $$config configuration..."; \
	$(MAKE) app CONFIGURATION=$$config && \
	./scripts/install.sh $$config true

dmg:
	./scripts/create_dmg.sh

release:
	./scripts/release.sh $(filter-out $@,$(MAKECMDGOALS))

delete-release:
	./scripts/delete_release.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@:
