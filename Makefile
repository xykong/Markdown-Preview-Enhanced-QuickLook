.PHONY: all build_renderer generate app

all: app

generate:
	@if ! command -v xcodegen >/dev/null; then \
		echo "Error: xcodegen is not installed. Please install it with 'brew install xcodegen'"; \
		exit 1; \
	fi
	rm -rf MarkdownQuickLook.xcodeproj
	xcodegen generate

app: generate
	xcodebuild -project MarkdownQuickLook.xcodeproj -scheme MarkdownQuickLook -destination 'platform=macOS' build
