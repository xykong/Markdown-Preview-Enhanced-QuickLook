# Medium Code Document (~50KB)

Tests syntax highlighting across multiple languages. This is the primary
stress test for highlight.js performance.

## TypeScript / JavaScript

```typescript
import { useState, useEffect, useCallback, useMemo } from 'react';
import type { FC, ReactNode } from 'react';

interface Config {
  apiUrl: string;
  timeout: number;
  retries: number;
  headers: Record<string, string>;
}

type Status = 'idle' | 'loading' | 'success' | 'error';

interface ApiState<T> {
  data: T | null;
  status: Status;
  error: Error | null;
}

function useApi<T>(url: string, config: Partial<Config> = {}): ApiState<T> {
  const [state, setState] = useState<ApiState<T>>({
    data: null,
    status: 'idle',
    error: null,
  });

  const mergedConfig = useMemo<Config>(() => ({
    apiUrl: '',
    timeout: 5000,
    retries: 3,
    headers: { 'Content-Type': 'application/json' },
    ...config,
  }), [config]);

  const fetchData = useCallback(async () => {
    setState(prev => ({ ...prev, status: 'loading' }));
    
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), mergedConfig.timeout);
    
    try {
      const response = await fetch(url, {
        signal: controller.signal,
        headers: mergedConfig.headers,
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const data: T = await response.json();
      setState({ data, status: 'success', error: null });
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      setState({ data: null, status: 'error', error });
    } finally {
      clearTimeout(timeoutId);
    }
  }, [url, mergedConfig]);

  useEffect(() => {
    fetchData();
    return () => { /* cleanup */ };
  }, [fetchData]);

  return state;
}

const DataTable: FC<{ columns: string[]; rows: ReactNode[][] }> = ({ columns, rows }) => (
  <table>
    <thead>
      <tr>{columns.map(col => <th key={col}>{col}</th>)}</tr>
    </thead>
    <tbody>
      {rows.map((row, i) => (
        <tr key={i}>{row.map((cell, j) => <td key={j}>{cell}</td>)}</tr>
      ))}
    </tbody>
  </table>
);

export { useApi, DataTable };
export type { Config, ApiState };
```

## Python

```python
from __future__ import annotations

import asyncio
import json
import logging
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from pathlib import Path
from typing import AsyncGenerator, Generic, TypeVar

T = TypeVar('T')
logger = logging.getLogger(__name__)


@dataclass
class CacheEntry(Generic[T]):
    value: T
    ttl: float
    created_at: float = field(default_factory=lambda: asyncio.get_event_loop().time())

    @property
    def is_expired(self) -> bool:
        return asyncio.get_event_loop().time() - self.created_at > self.ttl


class AsyncCache(Generic[T]):
    def __init__(self, max_size: int = 1000) -> None:
        self._store: dict[str, CacheEntry[T]] = {}
        self._lock = asyncio.Lock()
        self._max_size = max_size

    async def get(self, key: str) -> T | None:
        async with self._lock:
            entry = self._store.get(key)
            if entry is None or entry.is_expired:
                self._store.pop(key, None)
                return None
            return entry.value

    async def set(self, key: str, value: T, ttl: float = 300.0) -> None:
        async with self._lock:
            if len(self._store) >= self._max_size:
                # Evict oldest entry
                oldest = min(self._store.items(), key=lambda x: x[1].created_at)
                del self._store[oldest[0]]
            self._store[key] = CacheEntry(value=value, ttl=ttl)

    async def invalidate(self, pattern: str | None = None) -> int:
        async with self._lock:
            if pattern is None:
                count = len(self._store)
                self._store.clear()
                return count
            keys_to_delete = [k for k in self._store if pattern in k]
            for key in keys_to_delete:
                del self._store[key]
            return len(keys_to_delete)


@asynccontextmanager
async def managed_resource(name: str) -> AsyncGenerator[dict, None]:
    logger.info(f"Acquiring resource: {name}")
    resource = {"name": name, "active": True}
    try:
        yield resource
    finally:
        resource["active"] = False
        logger.info(f"Released resource: {name}")


async def process_files(paths: list[Path], cache: AsyncCache[str]) -> dict[str, str]:
    results: dict[str, str] = {}
    
    async def process_one(path: Path) -> tuple[str, str]:
        cache_key = str(path)
        cached = await cache.get(cache_key)
        if cached is not None:
            return cache_key, cached
        
        async with managed_resource(cache_key) as _:
            content = await asyncio.to_thread(path.read_text, encoding='utf-8')
            processed = content.upper()  # placeholder
            await cache.set(cache_key, processed)
            return cache_key, processed
    
    tasks = [process_one(p) for p in paths]
    completed = await asyncio.gather(*tasks, return_exceptions=True)
    
    for result in completed:
        if isinstance(result, Exception):
            logger.error(f"Processing failed: {result}")
        else:
            key, value = result
            results[key] = value
    
    return results
```

## Rust

```rust
use std::collections::HashMap;
use std::sync::{Arc, RwLock};
use std::time::{Duration, Instant};

use tokio::sync::mpsc;
use tokio::time::sleep;

#[derive(Debug, Clone)]
pub struct CacheEntry<V> {
    value: V,
    expires_at: Instant,
}

impl<V> CacheEntry<V> {
    fn new(value: V, ttl: Duration) -> Self {
        Self {
            value,
            expires_at: Instant::now() + ttl,
        }
    }

    fn is_expired(&self) -> bool {
        Instant::now() > self.expires_at
    }
}

pub struct TtlCache<K, V> {
    inner: Arc<RwLock<HashMap<K, CacheEntry<V>>>>,
    max_size: usize,
}

impl<K, V> TtlCache<K, V>
where
    K: std::hash::Hash + Eq + Clone + Send + Sync + 'static,
    V: Clone + Send + Sync + 'static,
{
    pub fn new(max_size: usize) -> Self {
        Self {
            inner: Arc::new(RwLock::new(HashMap::new())),
            max_size,
        }
    }

    pub fn get(&self, key: &K) -> Option<V> {
        let guard = self.inner.read().unwrap();
        guard.get(key).and_then(|entry| {
            if entry.is_expired() {
                None
            } else {
                Some(entry.value.clone())
            }
        })
    }

    pub fn insert(&self, key: K, value: V, ttl: Duration) -> bool {
        let mut guard = self.inner.write().unwrap();
        if guard.len() >= self.max_size {
            // Simple eviction: remove first expired entry found
            let expired_key = guard
                .iter()
                .find(|(_, v)| v.is_expired())
                .map(|(k, _)| k.clone());
            if let Some(k) = expired_key {
                guard.remove(&k);
            } else {
                return false; // Cache full, no expired entries
            }
        }
        guard.insert(key, CacheEntry::new(value, ttl));
        true
    }

    pub fn evict_expired(&self) -> usize {
        let mut guard = self.inner.write().unwrap();
        let before = guard.len();
        guard.retain(|_, v| !v.is_expired());
        before - guard.len()
    }

    pub fn spawn_cleanup(self: Arc<Self>, interval: Duration) {
        tokio::spawn(async move {
            loop {
                sleep(interval).await;
                let evicted = self.evict_expired();
                if evicted > 0 {
                    tracing::debug!("Evicted {} expired cache entries", evicted);
                }
            }
        });
    }
}

#[derive(Debug)]
pub enum WorkerMessage<T> {
    Task(T),
    Shutdown,
}

pub async fn worker_pool<T, F, Fut>(
    workers: usize,
    mut rx: mpsc::Receiver<WorkerMessage<T>>,
    handler: F,
) where
    T: Send + 'static,
    F: Fn(T) -> Fut + Clone + Send + 'static,
    Fut: std::future::Future<Output = ()> + Send,
{
    let (done_tx, mut done_rx) = mpsc::channel::<()>(workers);
    let mut active = 0usize;

    loop {
        tokio::select! {
            msg = rx.recv() => {
                match msg {
                    Some(WorkerMessage::Task(task)) => {
                        let handler = handler.clone();
                        let done_tx = done_tx.clone();
                        active += 1;
                        tokio::spawn(async move {
                            handler(task).await;
                            let _ = done_tx.send(()).await;
                        });
                    }
                    Some(WorkerMessage::Shutdown) | None => break,
                }
            }
            _ = done_rx.recv(), if active > 0 => {
                active -= 1;
            }
        }
    }

    // Drain remaining completions
    while active > 0 {
        done_rx.recv().await;
        active -= 1;
    }
}
```

## Swift

```swift
import Foundation
import Combine
import os.log

private let logger = Logger(subsystem: "com.example.app", category: "Networking")

// MARK: - Models

struct APIError: LocalizedError {
    let statusCode: Int
    let message: String

    var errorDescription: String? {
        "HTTP \(statusCode): \(message)"
    }
}

// MARK: - Network Client

final class NetworkClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private var cancellables = Set<AnyCancellable>()

    init(configuration: URLSessionConfiguration = .default) {
        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> {
        guard let request = endpoint.urlRequest else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        logger.debug("→ \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")

        return session.dataTaskPublisher(for: request)
            .tryMap { [weak self] data, response -> T in
                guard let self, let http = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw APIError(statusCode: http.statusCode, message: String(data: data, encoding: .utf8) ?? "")
                }
                logger.debug("← \(http.statusCode) (\(data.count) bytes)")
                return try self.decoder.decode(T.self, from: data)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Endpoint

struct Endpoint {
    let baseURL: URL
    let path: String
    let method: String
    let queryItems: [URLQueryItem]
    let body: Data?
    let headers: [String: String]

    var urlRequest: URLRequest? {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        if !queryItems.isEmpty { components?.queryItems = queryItems }
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = method
        request.httpBody = body
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}
```

## Go

```go
package main

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"sync"
	"time"
)

type CacheItem[V any] struct {
	Value     V
	ExpiresAt time.Time
}

func (c CacheItem[V]) IsExpired() bool {
	return time.Now().After(c.ExpiresAt)
}

type Cache[K comparable, V any] struct {
	mu      sync.RWMutex
	items   map[K]CacheItem[V]
	maxSize int
}

func NewCache[K comparable, V any](maxSize int) *Cache[K, V] {
	return &Cache[K, V]{
		items:   make(map[K]CacheItem[V], maxSize),
		maxSize: maxSize,
	}
}

func (c *Cache[K, V]) Get(key K) (V, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	item, ok := c.items[key]
	if !ok || item.IsExpired() {
		var zero V
		return zero, false
	}
	return item.Value, true
}

func (c *Cache[K, V]) Set(key K, value V, ttl time.Duration) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if len(c.items) >= c.maxSize {
		return errors.New("cache full")
	}
	c.items[key] = CacheItem[V]{Value: value, ExpiresAt: time.Now().Add(ttl)}
	return nil
}

type Handler struct {
	cache  *Cache[string, []byte]
	client *http.Client
	log    *slog.Logger
}

func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	key := r.URL.Path
	if cached, ok := h.cache.Get(key); ok {
		w.Header().Set("X-Cache", "HIT")
		w.Header().Set("Content-Type", "application/json")
		w.Write(cached)
		return
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://api.example.com"+key, nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	resp, err := h.client.Do(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	var result map[string]any
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	data, _ := json.Marshal(result)
	h.cache.Set(key, data, 5*time.Minute)

	w.Header().Set("X-Cache", "MISS")
	w.Header().Set("Content-Type", "application/json")
	w.Write(data)
}
```

## Shell / Bash

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/build.log"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE"; }
error() { log "ERROR: $*" >&2; exit 1; }
require() { command -v "$1" &>/dev/null || error "Required tool not found: $1"; }

require xcodebuild
require xcrun
require jq

build_target() {
    local target="$1"
    local config="${2:-Release}"
    
    log "Building $target ($config)..."
    
    xcodebuild \
        -project FluxMarkdown.xcodeproj \
        -scheme "$target" \
        -configuration "$config" \
        -destination 'platform=macOS,arch=arm64' \
        clean build \
        -quiet \
        MARKETING_VERSION="$(cat .version)" \
        2>&1 | grep -E '(error:|warning:|Build succeeded|FAILED)' \
        | tee -a "$LOG_FILE"
    
    local exit_code=${PIPESTATUS[0]}
    [[ $exit_code -eq 0 ]] && log "✅ $target built successfully" || error "❌ $target build failed"
}

run_tests() {
    log "Running test suite..."
    xcodebuild test \
        -project FluxMarkdown.xcodeproj \
        -scheme Markdown \
        -destination 'platform=macOS,arch=arm64' \
        2>&1 | xcpretty --color
}

main() {
    log "=== Build started at $TIMESTAMP ==="
    build_target "Markdown" "Release"
    run_tests
    log "=== Build completed ==="
}

main "$@"
```

## SQL

```sql
-- Performance-critical query with CTEs and window functions
WITH
  monthly_revenue AS (
    SELECT
      DATE_TRUNC('month', o.created_at)     AS month,
      p.category_id,
      SUM(oi.quantity * oi.unit_price)      AS revenue,
      COUNT(DISTINCT o.user_id)             AS unique_buyers,
      COUNT(DISTINCT o.id)                  AS order_count
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN products p ON p.id = oi.product_id
    WHERE o.status = 'completed'
      AND o.created_at >= NOW() - INTERVAL '12 months'
    GROUP BY 1, 2
  ),
  category_growth AS (
    SELECT
      mr.*,
      c.name AS category_name,
      LAG(mr.revenue) OVER (
        PARTITION BY mr.category_id
        ORDER BY mr.month
      ) AS prev_month_revenue,
      SUM(mr.revenue) OVER (
        PARTITION BY mr.category_id
        ORDER BY mr.month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
      ) AS rolling_3m_revenue
    FROM monthly_revenue mr
    JOIN categories c ON c.id = mr.category_id
  )
SELECT
  category_name,
  month,
  revenue,
  unique_buyers,
  order_count,
  rolling_3m_revenue,
  ROUND(
    100.0 * (revenue - prev_month_revenue) / NULLIF(prev_month_revenue, 0),
    2
  ) AS mom_growth_pct,
  RANK() OVER (
    PARTITION BY month
    ORDER BY revenue DESC
  ) AS revenue_rank
FROM category_growth
ORDER BY month DESC, revenue_rank;
```

## JSON / YAML

```json
{
  "version": "2.1",
  "services": {
    "api": {
      "image": "myapp/api:latest",
      "ports": ["8080:8080"],
      "environment": {
        "DATABASE_URL": "${DATABASE_URL}",
        "REDIS_URL": "redis://cache:6379",
        "LOG_LEVEL": "info"
      },
      "depends_on": {
        "db": { "condition": "service_healthy" },
        "cache": { "condition": "service_started" }
      },
      "healthcheck": {
        "test": ["CMD", "curl", "-f", "http://localhost:8080/health"],
        "interval": "30s",
        "timeout": "10s",
        "retries": 3
      }
    }
  }
}
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flux-markdown
  namespace: production
  labels:
    app: flux-markdown
    version: "1.13"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: flux-markdown
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: flux-markdown
    spec:
      containers:
        - name: app
          image: ghcr.io/xykong/flux-markdown:1.13
          resources:
            requests:
              memory: "64Mi"
              cpu: "50m"
            limits:
              memory: "256Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 30
```
