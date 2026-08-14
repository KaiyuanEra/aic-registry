# {Project Name} Development Plan

> Last updated: {YYYY-MM-DD} | Version: v1 | Status: in progress

## Archived Phase Index

| Phase | Stage name | Completion date | Task count | Issue range |
|-------|--------|---------|--------|-----------|
| (none) | - | - | - | - |

---

## Change Log

| Version | Date | Change description |
|------|------|----------|
| v1 | {YYYY-MM-DD} | Initial version |

---

## 1. Project Overview

### 1.1 Background and Goals

{Describe project background, problem to solve, core goals}

### 1.2 Core User Scenarios (3-5 items)

1. User A needs {scenario description}; expects {result}
2. User B needs {scenario description}; expects {result}
3. {more scenarios}

### 1.3 Scope Boundaries

**Do:**
- {feature one}
- {feature two}

**Do NOT (this iteration):**
- {exclusion one}
- {exclusion two}

---

## 2. Technology Stack

| Layer | Technology | Version | Selection rationale |
|------|----------|------|----------|
| Language | {Go / Python / TypeScript} | {version} | {reason} |
| Framework | {framework name} | {version} | {reason} |
| Storage | {database} | {version} | {reason} |
| {other} | {technology} | {version} | {reason} |

---

## 3. Overall Architecture Design

### 3.1 Architecture Diagram

```
{ASCII architecture diagram or Mermaid code}

Example (ASCII):
User Request
    |
    v
+-----------+     +-----------+
|  Module A  |---->|  Module B  |
+-----------+     +-----------+
                     |
                     v
               +-----------+
               |  Storage   |
               +-----------+
```

### 3.2 Module Responsibilities

| Module | Responsibility |
|------|------|
| {Module A} | {one-sentence description} |
| {Module B} | {one-sentence description} |

### 3.3 Key Data Flows

```
{Describe how data flows through core business processes}
Step 1: {input} -> {processing} -> {output}
Step 2: {input} -> {processing} -> {output}
```

---

## 4. Project Structure

```
{project-name}/
+-- {directory or file}      # {one-sentence description}
+-- {directory or file}/
|   +-- {sub-file}      # {one-sentence description}
|   +-- {sub-file}      # {one-sentence description}
+-- {directory or file}      # {one-sentence description}
```

---

## 5. Development Plan

### Phase Division Principle

{Explain what dimension Phases are divided by: feature modules / delivery milestones / dependency relationships}

---

### Phase 1: {feature name, human-readable, e.g. "User Login and Permission Validation"} | Estimated: {n} days | Priority: P0 | Issue: #(pending) | Status: in progress

**Goal:** {what this Phase delivers; why it is done first}

#### Task 1.1: Implement {specific feature}

- **Goal:** {what to implement; what the acceptance criteria are}
- **Files involved:** `path/to/file.go`, `path/to/other.go`
- **Input:** no dependency (foundation module)
- **Output:** `FunctionName(param Type) (ReturnType, error)` function callable
- **Estimate:** {n} hours
- **Issue:** #(pending)
- **Note:** {edge cases, technical risks} (optional)

#### Task 1.2: Implement {specific feature}

- **Goal:** {what to implement; what the acceptance criteria are}
- **Files involved:** `path/to/file.go`
- **Input:** Task 1.1 completed
- **Output:** {deliverable}
- **Estimate:** {n} hours
- **Issue:** #(pending)

---

### Phase 2: {feature name, human-readable, e.g. "Command-Line Install and Config Wizard"} | Estimated: {n} days | Priority: P1 | Issue: #(pending) | Status: in progress

**Goal:** {what this Phase delivers}

#### Task 2.1: Implement {specific feature}

- **Goal:** {what to implement}
- **Files involved:** `path/to/file`
- **Input:** Phase 1 all completed
- **Output:** {deliverable}
- **Estimate:** {n} hours
- **Issue:** #(pending)

---

<!-- Phase template below; copy as needed -->
<!--
### Phase N: {stage name} | Estimated: {n} days | Priority: P{n}

**Goal:** {what this Phase delivers}

#### Task N.1: Implement {specific feature}
- **Goal:**
- **Files involved:**
- **Input:**
- **Output:**
- **Estimate:**
- **Issue:** #(pending)
-->
