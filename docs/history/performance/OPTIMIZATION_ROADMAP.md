# Optimization Roadmap

**Status:** Draft
**Date:** 2026-01-06
**Context:** Analysis of current implementation vs. "State of the Art" requirements.

## Overview
This document outlines the optimization opportunities identified to elevate the product quality to a "极致" (Ultimate) level. Focus areas: Performance, User Experience (UX), Feature Robustness, and Engineering Health.

## 1. Performance (Extreme Speed)

Current issue: Monolithic bundling of heavy libraries (Mermaid, KaTeX, Highlight.js) and inefficient string injection.

### 1.1 Lazy Loading / Bundle Optimization
- **Problem**: Mermaid.js is huge (>1MB) but used infrequently.
- **Solution**:
  - Implement dynamic import for Mermaid: load only when ```mermaid blocks are detected.
  - Split `katex` and `highlight.js` if possible.

### 1.2 Large File Handling
- **Problem**: Injecting 5MB+ strings via `evaluateJavaScript` blocks the main thread.
- **Solution**:
  - **Pagination/Truncation**: Limit initial preview to the first 5000 lines.
  - **Data Streaming**: Use `WKUserContentController` custom handler to stream content instead of string literal injection.
  - **Virtual Scrolling**: Implement in the web layer to handle massive DOM trees.

## 2. User Experience (Polished Feel)

Current issue: Native/Web boundary feels "rough" (flickering, broken images).

### 2.1 Perfect Dark Mode Sync
- **Problem**: Theme switching may cause "White Flash" or desynchronized code block themes.
- **Solution**:
  - Swift -> JS: Proactive notification of theme change via Bridge.
  - CSS: Ensure `body.dark-mode` controls all sub-components (Mermaid, hljs) instantly.

### 2.2 Local Image Sandbox (Critical)
- **Problem**: `![img](./pic.png)` fails in QuickLook due to sandbox read restrictions.
- **Solution**:
  - **Scheme Handler**: Implement `WKURLSchemeHandler` (e.g., `local-resource://`) to proxy file access securely.
  - **Read Access**: Ensure `webView.loadFileURL` grants access to the file's parent directory, not just the bundle.

### 2.3 Render Stability
- **Problem**: Mermaid diagrams replace source code visibly (FOUC - Flash of Unstyled Content).
- **Solution**:
  - Reserve layout space during parsing.
  - Hide container until rendering completes.

## 3. Robustness (Reliability)

### 3.1 State Persistence
- **Problem**: Scroll position is lost when reopening or reloading.
- **Solution**:
  - Swift: Persist `scrollTop` keyed by file path.
  - JS: Restore scroll position on `renderMarkdown` completion.

### 3.2 Enhanced Bridge Reliability
- **Problem**: Polling (`0.2s`) for JS readiness is flaky.
- **Solution**:
  - Event-driven: JS posts `onReady` message to Swift.
  - Swift queues content until `onReady` is received.

## 4. Engineering (Maintainability)

### 4.1 Unified Logging
- **Problem**: Split logs (Console.app vs Web Inspector).
- **Solution**: Forward all `console.log/error` to `os_log` via Bridge.

### 4.2 Typed Contracts
- **Problem**: String-based API calls are error-prone.
- **Solution**: Define shared JSON schemas (Codable in Swift, Interface in TS) for all Bridge messages.

## Execution Plan (Priority)

1.  **Local Image Sandbox** (High Impact, Fixes broken functionality)
2.  **Mermaid Lazy Loading** (High Impact, Fixes startup time)
3.  **Large File Truncation** (Medium Impact, Prevents crashes)
4.  **Dark Mode Sync** (Completed 2026-01-07) - Implemented adaptive CSS and explicit theme passing.
5.  **Render Stability (Mermaid FOUC)** (Medium Impact, Polish) - Next Priority
6.  **State Persistence** (Medium Impact, User Convenience)
