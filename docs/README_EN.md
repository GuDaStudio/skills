![Title](../imgs/title.png)

<div align="center">

**Agent Skills Collection — Seamless Collaboration Between Claude and Multi-Model/Tools**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT) [![Claude Code](https://img.shields.io/badge/Claude%20Code-Compatible-green.svg)](https://claude.ai/code) [![Share](https://img.shields.io/badge/share-000000?logo=x&logoColor=white)](https://x.com/intent/tweet?text=GudaCC%20Skills：Claude%20Code%20Agent%20Skills%20Collection%20https://github.com/GuDaStudio/skills%20%23AI%20%23Coding%20%23ClaudeCode) [![Share](https://img.shields.io/badge/share-1877F2?logo=facebook&logoColor=white)](https://www.facebook.com/sharer/sharer.php?u=https://github.com/GuDaStudio/skills) [![Share](https://img.shields.io/badge/share-0088CC?logo=telegram&logoColor=white)](https://t.me/share/url?url=https://github.com/GuDaStudio/skills&text=GudaCC%20Skills：Claude%20Code%20Agent%20Skills%20Collection)

Star us on GitHub — your support means a lot! 🙏😊

[简体中文](../README.md) | English

</div>

---

## Introduction

**Agent Skills** is a modular capability extension mechanism [introduced by Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) that enables LLMs to load domain-specific knowledge and workflows on demand. This repository contains a collection of Agent Skills developed by **GudaStudio**, enabling seamless collaboration between Claude and other AI models/tools.

### Available Skills

| Skill | Description | Collaborating Model |
|-------|-------------|---------------------|
| [collaborating-with-codex](../collaborating-with-codex) | Delegates coding tasks to Codex CLI for prototyping, debugging, and code review | OpenAI Codex |
| [collaborating-with-gemini](../collaborating-with-gemini) | Delegates coding tasks to Gemini CLI for prototyping, debugging, and code review | Google Gemini |

---

## Quick Start

### 0. Prerequisites

Ensure the following tools are installed and configured:

- [Claude Code](https://docs.claude.com/docs/claude-code) (v2.0.56+)
- [Codex CLI](https://github.com/openai/codex) (if using collaborating-with-codex)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) (if using collaborating-with-gemini)

### 1. Clone Repository

```bash
# Clone to any location
git clone --recurse-submodules https://github.com/GuDaStudio/skills
cd skills
```

### 2. Install Skills

The install script provides flexible options for scope and target location.

<details open>
<summary><b>Linux / macOS</b></summary>

**List available Skills:**

```bash
./install.sh --list
```

**Option 1: Install All Skills**

```bash
# User-level installation (available for all projects)
./install.sh --user --all

# Project-level installation (current project only, run from project root)
./install.sh --project --all
```

**Option 2: Selective Installation**

```bash
# Install only collaborating-with-codex
./install.sh --user --skill collaborating-with-codex

# Install multiple specific Skills
./install.sh --user -s collaborating-with-codex -s collaborating-with-gemini
```

**Option 3: Custom Installation Path**

```bash
./install.sh --target /your/custom/path --all
```

</details>

<details open>
<summary><b>Windows (PowerShell)</b></summary>

**List available Skills:**

```powershell
.\install.ps1 -List
```

**Option 1: Install All Skills**

```powershell
# User-level installation (available for all projects)
.\install.ps1 -User -All

# Project-level installation (current project only, run from project root)
.\install.ps1 -Project -All
```

**Option 2: Selective Installation**

```powershell
# Install only collaborating-with-codex
.\install.ps1 -User -Skill collaborating-with-codex

# Install multiple specific Skills
.\install.ps1 -User -Skill collaborating-with-codex -Skill collaborating-with-gemini
```

**Option 3: Custom Installation Path**

```powershell
.\install.ps1 -Target C:\your\custom\path -All
```

</details>

<details>
<summary>Click to view full parameter reference</summary>

| Parameter (Bash) | Parameter (PowerShell) | Short | Description |
|------------------|------------------------|-------|-------------|
| `--user` | `-User` | `-u` | Install to user-level directory (`~/.claude/skills/`) |
| `--project` | `-Project` | `-p` | Install to project-level directory (`./.claude/skills/`) |
| `--target <path>` | `-Target <path>` | `-t` | Install to custom path |
| `--all` | `-All` | `-a` | Install all available Skills |
| `--skill <name>` | `-Skill <name>` | `-s` | Install specific Skill (can be used multiple times) |
| `--list` | `-List` | `-l` | List all available Skills |
| `--help` | `-Help` | `-h` | Show help message |

</details>

### 3. Verify Installation

Skills will auto-load when Claude Code starts. Verify by:

- Ask Claude to list all skills: `list all available SKILLs please`
- Claude should recognize and invoke `collaborating-with-codex` and `collaborating-with-gemini`
  ![Verify](../imgs/verify.png)

### 4. (🎊 Optional, Highly Recommended) Configure Prompts

To maximize the effectiveness of this SKILLS collection with Claude Code CLI, we strongly recommend adding the following prompts to `~/.claude/CLAUDE.md`.

````markdown
# CLAUDE.md

## 0. Global Protocols

All operations must strictly follow these system constraints:

- **Interaction Language**: Use **English** when interacting with tools or models; use **Chinese** for user output.
- **Multi-turn Conversations**: If tools or models return a persistent conversation field like `SESSION_ID`, indicating multi-turn support, record this field and **mandatory think** in subsequent calls whether to continue the conversation. For example, Codex/Gemini may interrupt sessions due to internal tool calls; if you don't get the needed response, continue the conversation.
- **Sandbox Security**: Codex/Gemini are **strictly forbidden** from writing to the filesystem. All code retrieval must **explicitly require** in the PROMPT to return `Unified Diff Patch`; Codex/Gemini are forbidden from making any real modifications.
- **Code Sovereignty**: Code generated by external models serves only as logical reference (Prototype); final delivered code **must be refactored** to ensure no redundancy and enterprise-grade standards.
- **Style Definition**: Overall code style is **always positioned** as lean, efficient, and zero redundancy. This requirement also applies to comments and documentation, which strictly follow the core principle of **not forming unless necessary**.
- **Only make targeted changes for requirements**, strictly forbidden to affect user's other existing functionality.
- Codex/Gemini interaction methods are provided as SKILLs, **mandatory to actively view and invoke**. Both require longer invocation time (system default "BASH_DEFAULT_TIMEOUT_MS": "300000"), just wait patiently.
- When parallelizable tasks are detected, execute in parallel as much as possible. For example, when multiple SKILL-related bash commands exist, use `run in background` to **immediately** suspend long-running programs to execute the next command, achieving parallelism.
- Mandatory to follow all Phases in 1. Workflow, strictly forbidden to omit any process.

## 1. Workflow

### Phase 1: Full Context Retrieval (Auggie Interface)

**Execution Condition**: Before generating any suggestions or code.

1.  **Tool Invocation**: Call `mcp__auggie-mcp__codebase-retrieval`.
2.  **Retrieval Strategy**:
    - Forbidden to answer based on assumptions.
    - Use Natural Language (NL) to construct semantic queries (Where/What/How).
    - **Completeness Check**: Must obtain complete definitions and signatures of relevant classes, functions, and variables. If context is insufficient, trigger recursive retrieval.
3.  **Requirements Alignment**: If requirements still have ambiguity after retrieval, **must** output a list of guiding questions to the user until requirement boundaries are clear (no omissions, no redundancy).

### Phase 2: Multi-Model Collaborative Analysis (Analysis & Strategy)

**Execution Condition**: After context is ready, before coding begins.

1.  **Distribute Input**: Distribute user's **original requirements** (without preset opinions) to Codex and Gemini. Note that Codex/Gemini both have complete CLI systems, so **no need to provide excessive context**.
2.  **Solution Iteration**:
    - Require models to provide multi-perspective solutions.
    - Trigger **Cross-validation**: Integrate ideas from all parties, iterate and optimize, perform logical deduction and complement advantages/disadvantages during the process, until generating a Step-by-step implementation plan with no logical gaps.
3.  **User Confirmation**: Present the final implementation plan (with moderate pseudo-code) to the user.

### Phase 3: Prototype Acquisition (Prototyping)

**Execution Condition**: After implementation plan is confirmed. Route based on task type:

- **Route A: Frontend/UI/Styles (Gemini Kernel)**
  - **Limitation**: Context < 32k. Gemini has deficiencies in understanding backend logic; its responses need objective review.
  - **Instruction**: Request CSS/React/Vue prototypes. Use this as the final frontend design prototype and visual baseline.
- **Route B: Backend/Logic/Algorithm (Codex Kernel)**
  - **Capability**: Leverage its logical computation and debugging abilities.
  - **Instruction**: Request logic implementation prototypes.
- **Universal Constraint**: In any communication with Codex/Gemini, **must explicitly require** in the Prompt to return `Unified Diff Patch`; Codex/Gemini are forbidden from making any real modifications.

### Phase 4: Coding Implementation (Implementation)

**Execution Guidelines**:

1.  **Logic Refactoring**: Based on Phase 3 prototypes, remove redundancy, **rewrite** into highly readable, highly maintainable, enterprise-release-grade code.
2.  **Documentation Standards**: Do not generate comments and documentation unless necessary; code should be self-explanatory.
3.  **Minimal Scope**: Changes limited to requirement scope, **mandatory review** whether changes introduce side effects and make targeted corrections.

### Phase 5: Audit & Delivery (Audit & Delivery)

1.  **Automatic Audit**: After changes take effect, **mandatory immediate invocation** of both Codex and Gemini for Code Review simultaneously, and perform integrated fixes.
    - Check items: Logic correctness, requirement coverage, potential bugs.
2.  **Delivery**: Feedback to user after audit passes.

## 2. Resource Matrix

This matrix defines the **mandatory** resource invocation strategy for each phase. Claude as the **Orchestrator** must strictly schedule external resources according to the current Workflow phase per the following specifications.

| Workflow Phase           | Functionality           | Designated Model / Tool                  | Input Strategy (Prompting)                                   | Strict Output Constraints                           | Critical Constraints & Behavior                              |
| :----------------------- | :---------------------- | :--------------------------------------- | :----------------------------------------------------------- | :-------------------------------------------------- | :----------------------------------------------------------- |
| **Phase 1**              | **Context Retrieval**   | **Auggie** (`mcp__auggie`)               | **Natural Language (English)**<br>Focus on: *What, Where, How* | **Raw Code / Definitions**<br>(Complete Signatures) | • **Forbidden:** `grep` / keyword search.<br>• **Mandatory:** Recursive retrieval until context is complete. |
| **Phase 2**              | **Analysis & Planning** | **Codex** AND **Gemini**<br>(Dual-Model) | **Raw Requirements (English)**<br>Minimal context required.  | **Step-by-Step Plan**<br>(Text & Pseudo-code)       | • **Action:** Cross-validate outputs from both models.<br>• **Goal:** Eliminate logic gaps before coding starts. |
| **Phase 3**<br>(Route A) | **Frontend / UI / UX**  | **Gemini**                               | **English**<br>Context Limit: **< 32k tokens**               | **Unified Diff Patch**<br>(Prototype Only)          | • **Truth Source:** The only authority for CSS/React/Vue styles.<br>• **Warning:** Ignore its backend logic suggestions. |
| **Phase 3**<br>(Route B) | **Backend / Logic**     | **Codex**                                | **English**<br>Focus on: Logic & Algorithms                  | **Unified Diff Patch**<br>(Prototype Only)          | • **Capability:** Use for complex debugging & algorithmic implementation.<br>• **Security:** **NO** file system write access allowed. |
| **Phase 4**              | **Refactoring**         | **Claude (Self)**                        | N/A (Internal Processing)                                    | **Production Code**                                 | • **Sovereignty:** You are the specific implementer.<br>• **Style:** Clean, efficient, no redundancy. Minimal comments. |
| **Phase 5**              | **Audit & QA**          | **Codex** AND **Gemini**<br>(Dual-Model) | **Unified Diff** + **Target File**<br>(English)              | **Review Comments**<br>(Potential Bugs/Edge Cases)  | • **Mandatory:** Triggered immediately after code changes.<br>• **Action:** Synthesize feedback into a final fix. |
````

---

## Skills Reference

### collaborating-with-codex

Delegates coding tasks to OpenAI Codex CLI for algorithm implementation, bug analysis, and code review.

<details>
<summary>Click to view parameters</summary>

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--PROMPT` | `str` | ✅ | - | Task instruction for Codex |
| `--cd` | `Path` | ✅ | - | Working directory root path |
| `--sandbox` | `Literal` | ❌ | `read-only` | Sandbox policy: `read-only` / `workspace-write` / `danger-full-access` |
| `--SESSION_ID` | `UUID` | ❌ | `None` | Session ID (None starts new session) |
| `--skip-git-repo-check` | `bool` | ❌ | `False` | Allow running in non-Git repository |
| `--return-all-messages` | `bool` | ❌ | `False` | Return complete reasoning information |
| `--image` | `List[Path]` | ❌ | `None` | Attach image files to initial prompt |
| `--model` | `str` | ❌ | `None` | Specify model (use only when explicitly requested) |
| `--yolo` | `bool` | ❌ | `False` | Skip all approvals and sandbox restrictions |

</details>

<details>
<summary>Click to view usage examples</summary>

**Basic call:**
```bash
python scripts/codex_bridge.py --cd "/project" --PROMPT "Analyze authentication flow"
```

**Multi-turn conversation:**
```bash
# Start new session
python scripts/codex_bridge.py --cd "/project" --PROMPT "Review login.py for security issues"

# Continue session
python scripts/codex_bridge.py --cd "/project" --SESSION_ID "uuid-from-response" --PROMPT "Provide fix suggestions for identified issues"
```

**Get diff prototype:**
```bash
python scripts/codex_bridge.py --cd "/project" --PROMPT "Generate unified diff for adding logging feature"
```

</details>

### collaborating-with-gemini

Delegates coding tasks to Google Gemini CLI for algorithm implementation, bug analysis, and code review.

<details>
<summary>Click to view parameters</summary>

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--PROMPT` | `str` | ✅ | - | Task instruction for Gemini |
| `--cd` | `Path` | ✅ | - | Working directory root path |
| `--sandbox` | `bool` | ❌ | `False` | Enable sandbox mode |
| `--SESSION_ID` | `str` | ❌ | `""` | Session ID (empty string starts new session) |
| `--return-all-messages` | `bool` | ❌ | `False` | Return complete reasoning information |
| `--model` | `str` | ❌ | `None` | Specify model (use only when explicitly requested) |

</details>

<details>
<summary>Click to view usage examples</summary>

**Basic call:**
```bash
python scripts/gemini_bridge.py --cd "/project" --PROMPT "Analyze authentication flow"
```

**Multi-turn conversation:**
```bash
# Start new session
python scripts/gemini_bridge.py --cd "/project" --PROMPT "Review login.py for security issues"

# Continue session
python scripts/gemini_bridge.py --cd "/project" --SESSION_ID "uuid-from-response" --PROMPT "Provide fix suggestions for identified issues"
```

</details>

### Return Value Structure

Both Skills return a unified JSON format:

**On success:**
```json
{
  "success": true,
  "SESSION_ID": "550e8400-e29b-41d4-a716-446655440000",
  "agent_messages": "Model response content...",
  "all_messages": []
}
```

**On failure:**
```json
{
  "success": false,
  "error": "Error description"
}
```

---

## FAQ

<details>
<summary>Q1: What are Agent Skills?</summary>

Agent Skills is a modular capability extension mechanism introduced by Anthropic. Each Skill contains instructions, metadata, and optional resources (scripts, templates). Claude automatically uses them for relevant tasks. Skills use progressive loading, only loading relevant content when needed, effectively managing the context window.

</details>

<details>
<summary>Q2: Are there any additional costs?</summary>

**Skills themselves are completely free and open source.** However, using collaborating models (Codex, Gemini) may incur API fees depending on each platform's pricing policy.

</details>

<details>
<summary>Q3: What is the SESSION_ID for in multi-turn conversations?</summary>

`SESSION_ID` maintains conversation context. The first call returns a new SESSION_ID, and subsequent calls with this ID continue the previous conversation. The model remembers prior interactions. Each SESSION_ID corresponds to an independent session, completely isolated from others.

</details>

<details>
<summary>Q4: How to ensure code security?</summary>

Always use the `read-only` sandbox policy and explicitly request the model to return `unified diff patch` in the PROMPT rather than directly modifying files. Code generated by external models should only serve as reference prototypes; final implementation should be refactored and confirmed by Claude.

</details>

---

## Contributing

<details>
<summary>We welcome all forms of contributions!</summary>

### Development Setup

```bash
# Clone repository (with submodules)
git clone --recurse-submodules https://github.com/GuDaStudio/skills.git
cd skills
```

### Commit Guidelines

- Follow [Conventional Commits](https://www.conventionalcommits.org/)
- Include test cases
- Update relevant documentation

</details>

---

## License

This project is open-sourced under the [MIT License](../LICENSE).

Copyright (c) 2025 [guda.studio](mailto:gudaclaude@gmail.com)

---

<div align="center">

## Star this project!
[![Star History Chart](https://api.star-history.com/svg?repos=GuDaStudio/skills&type=date&legend=top-left)](https://www.star-history.com/#GuDaStudio/skills&type=date&legend=top-left)

</div>
