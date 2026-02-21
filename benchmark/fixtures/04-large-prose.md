# Large Prose Document (~200KB)

This document tests rendering performance for large text-heavy markdown files.
Primary concern: DOM construction time and layout cost for many elements.

## Chapter 1: Architecture Overview

Software architecture is the fundamental organization of a system, embodied in its components, their relationships to each other and the environment, and the principles governing its design and evolution. Good architecture enables a system to be built incrementally, to evolve over time, and to be maintained by teams of varying sizes.

### 1.1 The Eight Fallacies of Distributed Computing

The fallacies of distributed computing are a set of false assumptions that programmers new to distributed applications invariably make. These were first articulated by L Peter Deutsch and others at Sun Microsystems:

1. **The network is reliable.** Networks fail all the time. Routers crash, cables are cut, switches malfunction, and packets are dropped. Any system that assumes the network is reliable will fail in production.

2. **Latency is zero.** Network calls take time. Even on a local network, you should expect latency of at least 0.1ms. Cross-datacenter calls can be 50-100ms. Transatlantic calls can be 150ms or more.

3. **Bandwidth is infinite.** You can move only so much data over a network per unit time. Saturating a network link will cause latency to spike and packets to be dropped.

4. **The network is secure.** Every network packet travels through infrastructure you don't control. Encryption, authentication, and authorization are not optional.

5. **Topology doesn't change.** IP addresses change. Servers are added and removed. Load balancers are reconfigured. Any hardcoded assumptions about network topology will eventually be wrong.

6. **There is one administrator.** Large distributed systems involve multiple teams, organizations, and even countries. No single person controls everything.

7. **Transport cost is zero.** Serialization, deserialization, and network I/O all consume CPU cycles. Moving data across a network costs more than accessing it in memory.

8. **The network is homogeneous.** Networks use different protocols, speeds, and configurations. You cannot assume that all machines on a network are equivalent.

### 1.2 CAP Theorem

The CAP theorem, formulated by Eric Brewer in 2000 and formally proven by Gilbert and Lynch in 2002, states that it is impossible for a distributed data store to simultaneously provide more than two out of the following three guarantees:

**Consistency (C)**: Every read receives the most recent write or an error. All nodes see the same data at the same time.

**Availability (A)**: Every request receives a non-error response, though it may not contain the most recent write. The system is always available to serve requests.

**Partition Tolerance (P)**: The system continues to operate even when network messages are dropped or delayed between nodes. In a real distributed system, partitions will occur, so partition tolerance is essentially mandatory.

Since partitions are unavoidable in real distributed systems, the practical choice is between consistency and availability:

- **CP systems** (e.g., HBase, ZooKeeper, etcd): Choose consistency over availability. During a partition, some nodes will become unavailable rather than serve stale data.
- **AP systems** (e.g., Cassandra, CouchDB, DynamoDB): Choose availability over consistency. During a partition, all nodes remain available but may serve different (possibly stale) versions of the data.

### 1.3 SOLID Principles

The SOLID principles are five design principles intended to make object-oriented designs more understandable, flexible, and maintainable.

**Single Responsibility Principle (SRP)**: A class should have only one reason to change. Each class should have one primary responsibility and all its services should be narrowly aligned with that responsibility.

**Open/Closed Principle (OCP)**: Software entities should be open for extension but closed for modification. You should be able to extend a class's behavior without modifying it.

**Liskov Substitution Principle (LSP)**: Objects in a program should be replaceable with instances of their subtypes without altering the correctness of that program. A subclass should extend the capability of the parent class, not narrow it.

**Interface Segregation Principle (ISP)**: Clients should not be forced to depend on interfaces they do not use. Many client-specific interfaces are better than one general-purpose interface.

**Dependency Inversion Principle (DIP)**: High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details; details should depend on abstractions.

## Chapter 2: Performance Engineering

Performance engineering is the discipline of designing, building, and tuning software systems for acceptable performance. It encompasses all activities from initial design through testing and production operations.

### 2.1 Latency vs Throughput

These are two fundamental performance metrics that are often in tension:

**Latency** is the time taken to serve a single request. It is typically measured as the time from when a request is sent to when the response is received. Latency is usually expressed in milliseconds (ms).

Key latency metrics:
- **p50 (median)**: 50% of requests complete within this time
- **p95**: 95% of requests complete within this time
- **p99**: 99% of requests complete within this time
- **p99.9**: 99.9% of requests complete within this time
- **max**: the slowest request observed

High percentile latencies (p95, p99) are often more important than averages because they represent the worst experience users actually encounter. Averages can be misleading when distributions are skewed.

**Throughput** is the number of requests that can be served per unit time. It is typically measured in requests per second (RPS) or transactions per second (TPS).

The relationship between latency and throughput follows Little's Law: `L = λW`, where L is the average number of requests in the system, λ is the average arrival rate, and W is the average time spent in the system. As you approach saturation, queuing effects cause latency to increase nonlinearly.

### 2.2 Profiling Strategies

Before optimizing, you must measure. The three golden rules of performance optimization are:

1. **Measure first**: Never guess about performance bottlenecks. Always profile before optimizing.
2. **Optimize the bottleneck**: Optimizing a non-bottleneck yields no improvement in end-to-end performance.
3. **Measure again**: Verify that your optimization actually improved performance.

**CPU Profiling** identifies where your code spends CPU time. Tools include:
- `perf` on Linux
- Instruments.app on macOS
- `py-spy` for Python
- `async-profiler` for JVM
- `pprof` for Go

**Memory Profiling** identifies memory usage patterns and leaks. Look for:
- Allocation rate (how fast memory is being allocated)
- Live objects (what's keeping memory alive)
- Retained size (how much memory would be freed if an object were collected)

**I/O Profiling** identifies disk and network bottlenecks. Key metrics:
- Read/write throughput
- IOPS (I/O operations per second)
- Latency distribution
- Queue depth

### 2.3 Amdahl's Law

Amdahl's Law predicts the theoretical speedup achievable by parallelizing a task:

`Speedup(n) = 1 / (S + (1-S)/n)`

Where:
- `n` is the number of parallel processors
- `S` is the fraction of the task that must be executed sequentially (not parallelizable)
- `(1-S)` is the parallelizable fraction

Key insight: as `n` approaches infinity, the maximum speedup approaches `1/S`. If 10% of your program is sequential, the maximum possible speedup is 10x regardless of how many processors you use.

This has profound implications for architecture. Reducing the sequential fraction of your workload (through better algorithms, caching, or restructuring) yields more benefit than adding more hardware.

## Chapter 3: Data Structures and Algorithms

Understanding the time and space complexity of data structures is fundamental to writing performant software.

### 3.1 Big-O Notation

Big-O notation describes the limiting behavior of a function as the input size grows towards infinity. It characterizes the worst-case complexity.

| Complexity | Name | Example |
|------------|------|---------|
| O(1) | Constant | Hash table lookup |
| O(log n) | Logarithmic | Binary search |
| O(n) | Linear | Array scan |
| O(n log n) | Linearithmic | Merge sort |
| O(n²) | Quadratic | Bubble sort |
| O(n³) | Cubic | Matrix multiplication (naïve) |
| O(2ⁿ) | Exponential | Subset enumeration |
| O(n!) | Factorial | Permutation generation |

### 3.2 Hash Tables

Hash tables provide O(1) average case for insert, delete, and lookup operations. They achieve this through:

1. **Hash function**: Maps keys to integer indices in the backing array
2. **Collision resolution**: Handles the case where two keys hash to the same index

Two common collision resolution strategies:

**Chaining**: Each array slot holds a linked list of entries. Lookup walks the list. Performance degrades to O(n) in the worst case when all keys hash to the same slot.

**Open addressing**: When a collision occurs, probe other slots according to some scheme until an empty slot is found. Linear probing, quadratic probing, and double hashing are common schemes.

Load factor (ratio of entries to slots) determines performance. Most implementations resize when the load factor exceeds 0.75, doubling the backing array size and rehashing all entries.

### 3.3 B-Trees

B-trees are the data structure underlying most database indexes. They are self-balancing tree structures that maintain sorted data and allow searches, sequential access, insertions, and deletions in O(log n).

Unlike binary trees, B-tree nodes can have many children (typically hundreds or thousands). This is critical for disk-based data structures because it minimizes I/O operations: each node can be sized to fit in exactly one disk block.

A B-tree of order m has the following properties:
- Every node has at most m children
- Every internal node has at least ⌈m/2⌉ children
- All leaves appear at the same level
- A non-leaf node with k children contains k-1 keys

B+ trees (a variant used in most databases) store all data in leaves, with internal nodes storing only keys for navigation. This allows efficient range scans by traversing the leaf level linked list.

### 3.4 Skip Lists

Skip lists are a probabilistic data structure that provides O(log n) average case for search, insert, and delete, and O(n) for sequential access. They are an alternative to balanced trees that are simpler to implement correctly.

A skip list maintains multiple layers of linked lists. The bottom layer contains all elements. Each higher layer contains a randomly selected subset of the elements from the layer below (typically each element is included with probability 0.5).

Search: Start at the highest layer. Move forward until you would overshoot the target, then drop down a level. Repeat until you find the element or exhaust all levels.

The probabilistic nature means performance can degrade in theory, but in practice the distribution of heights ensures O(log n) behavior with high probability.

Redis uses skip lists as the underlying data structure for sorted sets.

## Chapter 4: Security Considerations

Security must be designed in from the start. Retrofitting security into an existing system is expensive and error-prone.

### 4.1 OWASP Top 10

The OWASP Top 10 is the authoritative list of the most critical web application security risks:

1. **Broken Access Control**: Restrictions on what authenticated users are allowed to do are not properly enforced.

2. **Cryptographic Failures**: Previously known as "Sensitive Data Exposure." Failures related to cryptography that often lead to exposure of sensitive data.

3. **Injection**: User-supplied data is not validated, filtered, or sanitized. SQL, NoSQL, OS command, LDAP injection attacks.

4. **Insecure Design**: Risks related to design and architectural flaws. Threat modeling and secure design patterns are not applied.

5. **Security Misconfiguration**: Missing hardening, improperly configured permissions, default credentials, unnecessary features enabled.

6. **Vulnerable and Outdated Components**: Using components with known vulnerabilities.

7. **Identification and Authentication Failures**: Incorrectly implemented authentication and session management.

8. **Software and Data Integrity Failures**: Code and infrastructure that does not protect against integrity violations.

9. **Security Logging and Monitoring Failures**: Without logging and monitoring, breaches cannot be detected.

10. **Server-Side Request Forgery (SSRF)**: Application fetches a remote resource without validating the user-supplied URL.

### 4.2 Cryptographic Primitives

**Symmetric encryption**: Same key used for encryption and decryption.
- AES-256-GCM: Recommended for most uses. Authenticated encryption.
- ChaCha20-Poly1305: Alternative to AES, particularly on platforms without AES hardware acceleration.
- **Never use**: ECB mode (no IV, deterministic), DES/3DES (too weak), RC4 (broken).

**Asymmetric encryption**: Different keys for encryption and decryption.
- RSA-OAEP with 2048+ bit keys
- X25519 for key exchange (Elliptic Curve Diffie-Hellman)
- **Never use**: RSA with PKCS#1 v1.5 padding (PKCS#1 v1.5 encryption is broken)

**Hash functions**:
- SHA-256, SHA-384, SHA-512: Suitable for data integrity
- SHA-3: Alternative standard
- BLAKE3: Very fast, suitable for non-cryptographic uses
- **Never use**: MD5, SHA-1 (collision attacks known)

**Password hashing**: Must use slow, memory-hard functions
- Argon2id: Winner of the Password Hashing Competition, recommended
- bcrypt: Widely supported, battle-tested
- scrypt: Memory-hard, good alternative
- **Never use**: SHA-256 for passwords (too fast, vulnerable to GPU attacks)

## Chapter 5: Observability

Modern software systems require comprehensive observability to understand what is happening in production.

### 5.1 The Three Pillars of Observability

**Metrics**: Numerical measurements aggregated over time.
- Counter: monotonically increasing (request count, errors)
- Gauge: point-in-time measurement (memory usage, active connections)
- Histogram: distribution of values (request latency, response sizes)

Key properties of a good metrics system:
- Low overhead collection
- High cardinality support (many unique label combinations)
- Efficient storage (downsampling for long-term retention)
- Fast query performance for dashboards and alerting

**Traces**: Records of requests as they flow through distributed systems.
- Span: a unit of work (a service call, a database query)
- Trace: a collection of spans forming a tree
- Trace context propagation: passing trace IDs across service boundaries

OpenTelemetry has become the standard for trace instrumentation, replacing vendor-specific SDKs.

**Logs**: Timestamped text records of discrete events.
- Structured logging (JSON) is preferred over unstructured text
- Include trace IDs in logs to correlate with traces
- Use appropriate log levels (DEBUG, INFO, WARN, ERROR, FATAL)
- Ship logs to a centralized system (ELK stack, Loki, CloudWatch)

### 5.2 SLOs, SLIs, and Error Budgets

**Service Level Indicator (SLI)**: A quantitative measure of service behavior. Common SLIs:
- Availability: fraction of time the service is working
- Latency: how fast responses are returned
- Error rate: fraction of requests that fail
- Throughput: requests served per second

**Service Level Objective (SLO)**: A target value for an SLI. Example: "99.9% of requests complete in under 200ms."

**Error budget**: The amount of unreliability permitted. If your SLO is 99.9% availability, your error budget is 0.1% of requests, or about 43.8 minutes of downtime per month.

Error budgets create alignment between development velocity and reliability. Teams can move fast while there's error budget to spend, and must slow down (focus on reliability work) when the budget is exhausted.

## Summary

This large document exercises:
- Many headings across multiple levels
- Large tables
- Numbered and bulleted lists (deeply nested)
- Bold, italic formatting throughout
- Inline code
- Long paragraphs

The primary purpose is to stress-test layout and DOM construction performance,
not any specific markdown feature.
