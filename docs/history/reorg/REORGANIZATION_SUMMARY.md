# Project Reorganization Summary (Archived)

> Note: This document describes an earlier reorganization and used a `tests/` folder naming in examples.
> Current convention: use `Tests/` (capital T).

**Date:** 2026-01-31

## Overview

Reorganized project directory structure to separate documentation and test files from the root directory, making the repository cleaner and more maintainable.

## Changes Made

### 1. Documentation Consolidation

#### Created New Structure
- `docs/features/` - Feature-specific documentation
- `docs/testing/` - Testing-related documentation

#### Merged Files
- **Zoom Documentation** → `docs/features/ZOOM.md`
  - Merged: `ZOOM_FEATURE.md`, `ZOOM_STATUS.md`, `QUICK_START_ZOOM.md`
  - Result: Single comprehensive zoom feature documentation

- **Testing Documentation** → `docs/testing/TESTING.md`
  - Merged: `docs/TESTING.md`, `TEST_INSTRUCTIONS.md`
  - Result: Complete testing guide with all test scenarios

#### Moved Files
- `THIRD_PARTY_LICENSES.md` → `docs/licenses/THIRD_PARTY_LICENSES.md`

### 2. Test Organization

#### Created New Structure
- `Tests/fixtures/` - Test markdown files and HTML fixtures
- `Tests/scripts/` - Test and debug scripts

#### Moved Files
**Test Fixtures:**
- `test-sample.md` → `Tests/fixtures/feature-validation.md`
- `test-zoom.md` → `Tests/fixtures/zoom-test.md`
- `test-auto-refresh.md` → (removed)
- `check-keyboard.html` → (removed)

**Test Scripts:**
- `debug-extension.sh` → (removed)
- `debug-zoom.sh` → (removed)
- `test-zoom.sh` → (removed)
- `verify-extension.sh` → (removed)

### 3. Updated References

Updated file paths in the following files:
- `AGENTS.md` - Updated debug script path
- `README.md` - Updated test file path
- `README_ZH.md` - Updated test file path
- `docs/user/TROUBLESHOOTING.md` - Updated test file paths
- `docs/debug/DEBUG_KATEX_RENDERING.md` - Updated test file path

## Root Directory (Clean State)

### Files Kept in Root
Essential project files only:
- `README.md`, `README_ZH.md` - Project entry points
- `CHANGELOG.md` - Version history
- `LICENSE` - License information
- `AGENTS.md` - AI context
- `Makefile`, `project.yml`, `.version` - Build configuration
- `.clinerules`, `.gitignore` - Development configuration

### Directories in Root
- `docs/` - All documentation
- `Tests/` - All test files and scripts
- `scripts/` - Build and release scripts (kept separate from test scripts)
- `Sources/` - Swift source code
- `web-renderer/` - TypeScript rendering engine

## Directory Structure

```
.
├── docs/
│   ├── features/
│   │   └── ZOOM.md
│   ├── testing/
│   │   └── TESTING.md
│   ├── ARCHITECTURE.md
│   ├── DEBUG_*.md
│   ├── DESIGN_*.md
│   ├── DEVELOPMENT.md
│   ├── OPTIMIZATION_ROADMAP.md
│   ├── RELEASE_PROCESS.md
│   ├── RENDERER_MARKDOWN_IT_PLUGIN_ROADMAP.md
│   ├── THIRD_PARTY_LICENSES.md
│   └── TROUBLESHOOTING.md
├── Tests/
│   ├── fixtures/
│   │   ├── feature-validation.md
│   │   ├── images-test.md
│   │   └── zoom-test.md
│   ├── MarkdownTests/
│   │   ├── ResourceLoadingTests.swift
│   │   └── WindowSizePersistenceTests.swift
│   └── scripts/
│       └── watch-link-clicks.sh
├── scripts/
│   ├── analyze-pr.sh
│   ├── create_dmg.sh
│   ├── delete_release.sh
│   ├── generate_large_md.sh
│   ├── install.sh
│   ├── release.sh
│   ├── update-homebrew-cask.sh
│   └── verify_truncation.sh
├── Sources/
├── web-renderer/
├── README.md
├── README_ZH.md
├── CHANGELOG.md
├── LICENSE
├── AGENTS.md
├── Makefile
└── project.yml
```

## Verification

### Build Test
✅ Project generation successful: `make generate`
- Version: 1.4.84 (Build 84)
- All dependencies built correctly
- No build errors

### Files Deleted
The following files were successfully removed from root:
- `ZOOM_FEATURE.md`
- `ZOOM_STATUS.md`
- `QUICK_START_ZOOM.md`
- `TEST_INSTRUCTIONS.md`
- `THIRD_PARTY_LICENSES.md`
- `test-sample.md`
- `test-zoom.md`
- `test-auto-refresh.md`
- `check-keyboard.html`
- `debug-extension.sh`
- `debug-zoom.sh`
- `test-zoom.sh`
- `verify-extension.sh`

## Benefits

1. **Cleaner Root Directory**: Only essential project files remain
2. **Better Organization**: Documentation and tests are properly categorized
3. **Easier Navigation**: Clear separation between docs, tests, and source code
4. **Reduced Clutter**: Related files are consolidated (e.g., zoom docs merged)
5. **Maintained Functionality**: All references updated, build still works

## Notes

- All file references in documentation and scripts have been updated
- Build system (Makefile, project.yml) did not require changes
- No changes to source code or dependencies
- Project functionality remains unchanged
