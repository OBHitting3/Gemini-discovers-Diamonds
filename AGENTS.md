# AI Agents Guide

This document provides information about AI agents working in this repository and guidelines for effective collaboration.

## About This Repository

**Repository**: Gemini-discovers-Diamonds

This repository leverages AI agents to assist with development tasks, code reviews, and automation.

## Supported AI Agents

### Cursor AI Agents

This repository is configured to work with Cursor AI agents, including:

- **Cloud Agents**: Autonomous agents that run in the background to handle GitHub issues, pull requests, and automated tasks
- **Code Completion**: Context-aware code suggestions
- **Chat Agents**: Interactive assistance for development questions and problem-solving

## Working with Agents

### Best Practices

1. **Clear Instructions**: Provide specific, actionable requests
2. **Context**: Reference relevant files using `@filename` or `@folder/` syntax
3. **Iterative Development**: Break complex tasks into smaller steps
4. **Code Review**: Always review agent-generated code before merging
5. **Testing**: Ensure tests pass before accepting changes

### Task Guidelines

When requesting agent assistance:

- Be specific about the desired outcome
- Mention any constraints or requirements
- Indicate preferred patterns or libraries
- Specify test requirements if applicable

### Code Quality Standards

Agents in this repository follow these standards:

- **Readability**: Clear, maintainable code with appropriate comments
- **Best Practices**: Industry-standard patterns and conventions
- **Testing**: Include tests for new functionality
- **Documentation**: Update relevant documentation for significant changes

## Agent Capabilities

### Development Tasks

- Code generation and refactoring
- Bug fixes and debugging
- Test creation and maintenance
- Documentation updates
- Dependency management

### Repository Operations

- Git operations (commit, branch, push)
- Pull request creation and updates
- Issue triage and resolution
- Code review assistance

## Configuration

### Branch Strategy

Agents work on feature branches following the pattern:
- `cursor/agents-*` for agent-initiated changes
- Clear commit messages describing changes
- Regular pushes to track progress

### Environment

- **OS**: Linux-based development environment
- **Shell**: Bash
- **Git**: Version control with GitHub integration

## Communication

### With Agents

- Use natural language for requests
- Provide feedback on agent responses
- Correct misunderstandings promptly
- Ask for clarification when needed

### Agent Responses

Agents will:
- Explain their approach before major changes
- Use appropriate tools for file operations
- Commit and push changes incrementally
- Report progress and completion status

## Limitations

Be aware of agent limitations:

- Cannot access external services without credentials
- May require guidance for ambiguous tasks
- Should be supervised for critical changes
- Need explicit instructions for architectural decisions

## Getting Started

To work effectively with AI agents in this repository:

1. Ensure you have appropriate access permissions
2. Review this document and repository structure
3. Start with small, well-defined tasks
4. Provide feedback to improve agent performance
5. Gradually increase task complexity as you build confidence

## Feedback and Improvement

Help improve agent performance by:

- Reporting issues or unexpected behavior
- Suggesting improvements to guidelines
- Documenting successful patterns
- Sharing lessons learned

---

**Last Updated**: February 14, 2026
**Maintained By**: Repository contributors and AI agents
