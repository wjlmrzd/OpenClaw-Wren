# Code Review Checklist

> 📝 **中文说明**：代码审查清单 - 一套系统化的代码审查模式，涵盖安全性、性能、可维护性、正确性和测试等方面，包含严重级别划分、结构化反馈指导、审查流程和需要避免的反模式。

Systematic code review patterns covering security, performance, maintainability, correctness, and testing — with severity levels, structured feedback guidance, review process, and anti-patterns to avoid.

> 📝 **中文说明**：本技能提供系统化的代码审查模式，覆盖安全性、性能、可维护性、正确性和测试五大维度，并提供严重级别划分、结构化反馈指导、审查流程和反模式警示。

## What's Inside

> 📝 **中文说明**：内容概览 - 本审查清单包含的主要模块。

- Review dimensions with priority ranking (Security → Performance → Correctness → Maintainability → Testing → Accessibility → Documentation)

> 📝 **中文说明**：审查维度及优先级排序：安全性 > 性能 > 正确性 > 可维护性 > 测试 > 可访问性 > 文档

- Security checklist (SQL injection, XSS, CSRF, auth, secrets, rate limiting)

> 📝 **中文说明**：安全检查清单 - 涵盖 SQL 注入、XSS 跨站脚本、CSRF 跨站请求伪造、身份认证、密钥管理、接口限流等安全问题。

- Performance checklist (N+1 queries, re-renders, memory leaks, bundle size, caching)

> 📝 **中文说明**：性能检查清单 - 检查 N+1 查询问题、重复渲染、内存泄漏、Bundle 大小、缓存策略等性能隐患。

- Correctness checklist (edge cases, null handling, race conditions, timezone handling)

> 📝 **中文说明**：正确性检查清单 - 验证边界条件处理、空值处理、竞态条件、时区处理等方面的代码正确性。

- Maintainability checklist (naming, SRP, DRY, dead code, dependency direction)

> 📝 **中文说明**：可维护性检查清单 - 评估命名规范、单一职责原则（SRP）、DRY 原则、死代码、依赖方向等可维护性因素。

- Testing checklist (coverage, edge cases, flaky tests, mocking discipline)

> 📝 **中文说明**：测试检查清单 - 审查测试覆盖率、边界用例、 flaky 测试问题、mock 使用规范等测试质量。

- Three-pass review process (high-level → line-by-line → edge cases)

> 📝 **中文说明**：三遍审查流程 - 第一遍宏观架构审查、第二遍逐行代码审查、第三遍边界情况验证。

- Severity levels (Critical, Major, Minor, Nitpick) with merge-blocking guidance

> 📝 **中文说明**：严重级别划分 - Critical（严重）、Major（重要）、Minor（轻微）、Nitpick（挑剔）四级，并提供是否阻止合并的指导。

- Feedback principles and example comments

> 📝 **中文说明**：反馈原则与示例评语 - 指导如何给出有效、建设性的代码审查反馈。

- Review anti-patterns to avoid

> 📝 **中文说明**：审查反模式警示 - 列举需要避免的不当审查行为。

## When to Use

> 📝 **中文说明**：适用场景 - 何时使用本代码审查清单。

- Reviewing pull requests or merge requests

> 📝 **中文说明**：审查 Pull Request 或 Merge Request 时使用。

- Establishing review standards for a team

> 📝 **中文说明**：为团队建立代码审查标准时使用。

- Improving the quality and consistency of code reviews

> 📝 **中文说明**：提高代码审查质量和一致性时使用。

- Training new reviewers on what to look for

> 📝 **中文说明**：培训新审查者了解审查要点时使用。

## Installation

> 📝 **中文说明**：安装指南 - 根据你使用的 AI 编程工具选择合适的安装方式。

```bash
npx add https://github.com/wpank/ai/tree/main/skills/testing/code-review
```

> 📝 **中文说明**：通用安装命令 - 使用 npx 添加代码审查技能。

### OpenClaw / Moltbot / Clawbot

> 📝 **中文说明**：OpenClaw/Moltbot/Clawbot 安装方式 - 使用 clawhub 安装。

```bash
npx clawhub@latest install code-review
```

> 📝 **中文说明**：使用 clawhub 一键安装代码审查技能，适用于 OpenClaw、Moltbot、Clawbot 等工具。

### Manual Installation

> 📝 **中文说明**：手动安装 - 针对不同工具的手动配置方式。

#### Cursor (per-project)

> 📝 **中文说明**：Cursor（按项目安装）- 只在当前项目内可用。

From your project root:

> 📝 **中文说明**：在项目根目录执行以下命令：

```bash
mkdir -p .cursor/skills
cp -r ~/.ai-skills/skills/testing/code-review .cursor/skills/code-review
```

> 📝 **中文说明**：创建 .cursor/skills 目录，将代码审查技能复制到项目本地。

#### Cursor (global)

> 📝 **中文说明**：Cursor（全局安装）- 在所有项目中使用。

```bash
mkdir -p ~/.cursor/skills
cp -r ~/.ai-skills/skills/testing/code-review ~/.cursor/skills/code-review
```

> 📝 **中文说明**：创建全局 skills 目录，复制代码审查技能到全局位置。

#### Claude Code (per-project)

> 📝 **中文说明**：Claude Code（按项目安装）- 只在当前项目内可用。

From your project root:

> 📝 **中文说明**：在项目根目录执行以下命令：

```bash
mkdir -p .claude/skills
cp -r ~/.ai-skills/skills/testing/code-review .claude/skills/code-review
```

> 📝 **中文说明**：创建 .claude/skills 目录，将代码审查技能复制到项目本地。

#### Claude Code (global)

> 📝 **中文说明**：Claude Code（全局安装）- 在所有项目中使用。

```bash
mkdir -p ~/.claude/skills
cp -r ~/.ai-skills/skills/testing/code-review ~/.claude/skills/code-review
```

> 📝 **中文说明**：创建全局 skills 目录，复制代码审查技能到全局位置。

## Related Skills

> 📝 **中文说明**：相关技能 - 与代码审查配合使用的其他技能。

- [clean-code](../clean-code/) — Coding standards that reviews enforce

> 📝 **中文说明**：clean-code（代码整洁规范）- 定义代码审查时需要执行的编码标准。

- [quality-gates](../quality-gates/) — Automated quality checkpoints in CI/CD

> 📝 **中文说明**：quality-gates（质量门禁）- 在 CI/CD 流程中设置的自动化质量检查点。

- [testing-patterns](../testing-patterns/) — Testing standards to check during review

> 📝 **中文说明**：testing-patterns（测试模式）- 审查时需要检查的测试标准。

---

> 📝 **中文说明**：本技能属于 Testing（测试）技能分类，是代码质量和测试实践的重要组成部分。

Part of the [Testing](..) skill category.
