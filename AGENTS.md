# AI Agents Documentation

## Overview

This document describes the AI agents used in the Gemini-discovers-Diamonds project, their capabilities, configurations, and best practices for interaction.

## Available Agents

### Cloud Agent

**Purpose**: Autonomous background execution of complex development tasks

**Capabilities**:
- Code generation and refactoring
- File system operations
- Git operations (commits, pushes, branch management)
- Dependency management
- Testing and debugging
- Multi-step task execution

**Usage**:
- Operates autonomously in the background
- Executes tasks without requiring constant user interaction
- Manages git operations and commits changes progressively

**Configuration**:
- Context window: 1 million tokens
- Auto-refresh on context limit
- Background execution mode enabled

## Best Practices

### Working with Agents

1. **Clear Instructions**: Provide specific, actionable tasks
2. **Context**: Include relevant files and information using @ references
3. **Verification**: Review agent changes before merging
4. **Iteration**: Allow agents to complete full task cycles

### Task Complexity

- **Simple Tasks** (1-2 steps): Direct execution
- **Complex Tasks** (3+ steps): Automatic TODO list management
- **Multi-file Changes**: Systematic, tracked updates

### Git Workflow

Agents follow these git practices:
- Develop on feature branches
- Commit logical units of work
- Push changes progressively
- Create descriptive commit messages
- Handle network retries automatically

## Agent Limitations

### What Agents Can Do

✅ Read and modify files
✅ Execute terminal commands
✅ Install dependencies
✅ Run tests and linters
✅ Search codebases
✅ Manage git operations
✅ Create and update documentation

### What Agents Cannot Do

❌ Create PRs/MRs (handled automatically by the system)
❌ Merge branches without explicit instruction
❌ Run long-lived processes (dev servers, watch commands)
❌ Access external credentials (unless configured in dashboard)

## Security & Secrets

### Secret Management

- Secrets configured via Cursor Dashboard (Cloud Agents > Secrets)
- Injected as environment variables
- User secrets override team secrets
- Repository-scoped secrets available

### Best Practices

1. Never commit secrets to repository
2. Use environment variables for sensitive data
3. Configure secrets in Cursor Dashboard
4. Review secret access scopes regularly

## Communication

### Agent Responses

- Agents communicate through text output
- Tool usage happens transparently
- Progress updates provided for complex tasks
- Completion status clearly indicated

### Feedback Loop

1. Agent receives task
2. Analyzes requirements
3. Executes with tools
4. Reports results
5. Commits and pushes changes

## Task Management

### TODO System

For complex tasks (3+ steps), agents automatically:
- Create structured TODO lists
- Track task progress
- Update status in real-time
- Mark completion immediately

**Task States**:
- `pending`: Not yet started
- `in_progress`: Currently working
- `completed`: Finished successfully
- `cancelled`: No longer needed

## Troubleshooting

### Common Issues

**Missing Dependencies**
- Agent will attempt to install automatically
- May require manual configuration for specialized tools

**Git Operations Failing**
- Agents retry with exponential backoff
- Check network connectivity
- Verify branch permissions

**Test Failures**
- Agent will report failing tests
- Prefers producing code with failing tests over no code
- Review and fix iteratively

## Examples

### Simple Task

```
Create a helper function to validate email addresses
```

Agent will:
1. Create/update appropriate file
2. Implement function
3. Commit and push

### Complex Task

```
Implement user authentication system with JWT tokens
```

Agent will:
1. Create TODO list with subtasks
2. Implement each component
3. Write tests
4. Commit progressively
5. Report completion

## Version History

- **2026-02-14**: Initial documentation created

## Contributing

When working with agents:
1. Review agent-generated code
2. Test functionality
3. Provide feedback for improvements
4. Update this documentation as needed

## Resources

- [Cursor Documentation](https://cursor.sh/docs)
- [Cloud Agents Dashboard](https://cursor.sh/agents)
- Project README: [README.md](./README.md)
