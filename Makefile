.PHONY: all build_renderer generate app

all: app

build_renderer:
	cd web-renderer && npm install --no-audit --no-fund --loglevel=warn && npm run build

generate: build_renderer
	@if ! command -v xcodegen >/dev/null; then \
		echo "Error: xcodegen is not installed. Please install it with 'brew install xcodegen'"; \
		exit 1; \
	fi
	@if [ ! -f .version ]; then echo "1.0" > .version; fi
	@base_v=$$(cat .version); \
	commit_count=$$(git rev-list --count HEAD); \
	full_v="$$base_v.$$commit_count"; \
	echo "Generating Project with Version: $$full_v (Build $$commit_count)"; \
	rm -rf MarkdownPreviewEnhanced.xcodeproj; \
	MARKETING_VERSION=$$full_v CURRENT_PROJECT_VERSION=$$commit_count xcodegen generate --quiet

app: generate
	xcodebuild -project MarkdownPreviewEnhanced.xcodeproj -scheme Markdown -configuration $(or $(CONFIGURATION),Release) -destination 'platform=macOS' clean build -quiet

install:
	./scripts/install.sh

dmg:
	./scripts/create_dmg.sh

release:
	./scripts/release.sh $(filter-out $@,$(MAKECMDGOALS))

delete-release:
	./scripts/delete_release.sh $(filter-out $@,$(MAKECMDGOALS))

%:
	@:
