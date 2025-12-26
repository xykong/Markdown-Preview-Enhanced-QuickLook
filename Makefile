.PHONY: all build_renderer generate app

all: app

build_renderer:
	cd web-renderer && npm install && npm run build

generate: build_renderer
	@if ! command -v xcodegen >/dev/null; then \
		echo "Error: xcodegen is not installed. Please install it with 'brew install xcodegen'"; \
		exit 1; \
	fi
	@if [ ! -f .build_number ]; then echo 1 > .build_number; fi
	@n=$$(cat .build_number); \
	echo "Current Build Number: $$n"; \
	rm -rf MarkdownPreviewEnhanced.xcodeproj; \
	MARKETING_VERSION=1.0 CURRENT_PROJECT_VERSION=$$n xcodegen generate

app: generate
	xcodebuild -project MarkdownPreviewEnhanced.xcodeproj -scheme Markdown -configuration Release -destination 'platform=macOS' build

dmg:
	./scripts/create_dmg.sh
