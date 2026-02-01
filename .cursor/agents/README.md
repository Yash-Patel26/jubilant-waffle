# GamerFlick AI Agents

This directory contains specialized AI agent configurations for the GamerFlick project. Each agent has deep expertise in a specific domain and can be invoked for targeted assistance.

## Available Agents

### Development Agents

| Agent | File | Expertise |
|-------|------|-----------|
| Flutter Expert | `flutter-expert.md` | Flutter SDK, widgets, state management, cross-platform development |
| Mobile App Developer | `mobile-app-developer.md` | Platform integration, permissions, app lifecycle, deployment |
| Backend Engineer | `backend-engineer.md` | Supabase, PostgreSQL, RLS policies, server functions |
| Database Expert | `database-expert.md` | Schema design, query optimization, migrations, indexing |

### Specialized Domain Agents

| Agent | File | Expertise |
|-------|------|-----------|
| UI/UX Designer | `ui-designer.md` | Material Design, animations, accessibility, responsive design |
| Gaming Features Expert | `gaming-features-expert.md` | Tournaments, leaderboards, achievements, matchmaking |
| Real-time Expert | `realtime-expert.md` | WebSocket, Supabase Realtime, presence systems, WebRTC |
| Community/Social Expert | `community-social-expert.md` | Social features, feeds, moderation, engagement |

### Quality & Infrastructure Agents

| Agent | File | Expertise |
|-------|------|-----------|
| QA Engineer | `qa-engineer.md` | Testing strategies, widget tests, integration tests |
| Security Expert | `security-expert.md` | Authentication, encryption, input validation, RLS |
| Performance Engineer | `performance-engineer.md` | Optimization, profiling, memory management |
| DevOps Engineer | `devops-engineer.md` | CI/CD, GitHub Actions, app store deployment |

## How to Use

### In Cursor IDE

Reference agents using the `@` syntax in your prompts:

```
@flutter-expert How do I implement a custom scroll behavior?

@backend-engineer Create a RLS policy for the posts table

@gaming-features-expert Design a tournament bracket system
```

### Agent Combinations

For complex tasks, you can combine expertise:

```
@flutter-expert @performance-engineer Optimize this ListView for better performance

@backend-engineer @security-expert Review this authentication flow for security issues
```

## Agent Capabilities

Each agent is configured with:

1. **Domain Expertise** - Deep knowledge of their specialty area
2. **Project Context** - Understanding of GamerFlick's architecture and patterns
3. **Code Examples** - Ready-to-use code snippets and patterns
4. **Best Practices** - Guidelines specific to their domain
5. **Common Tasks** - Typical operations they can help with

## Customization

To modify an agent's behavior:

1. Open the agent's `.md` file
2. Update the expertise areas, code examples, or guidelines
3. Save the file - changes take effect immediately

## Creating New Agents

To add a new specialized agent:

1. Create a new `.md` file in this directory
2. Follow the existing agent template structure:
   - Title and description
   - Expertise areas
   - Project context
   - Code patterns/examples
   - Best practices
   - Common tasks
3. Update the main `.cursorrules` file to include the new agent

## Agent Template

```markdown
# Agent Name Agent

You are a senior [role] specializing in [areas].

## Expertise Areas
- Area 1
- Area 2

## Project Context
**GamerFlick** specific context...

## Code Patterns
\`\`\`dart
// Example code
\`\`\`

## Best Practices
1. Practice 1
2. Practice 2

## When Helping
1. Guideline 1
2. Guideline 2

## Common Tasks
- Task 1
- Task 2
```

## Integration with Workflows

Agents can be combined with project workflows:

- **Development Workflow**: Flutter Expert → QA Engineer → DevOps Engineer
- **Feature Development**: UI Designer → Flutter Expert → Backend Engineer
- **Security Review**: Security Expert → Backend Engineer → QA Engineer
- **Performance Optimization**: Performance Engineer → Flutter Expert

## Tips

1. **Be Specific** - Provide context when invoking agents
2. **Share Code** - Include relevant code snippets in your queries
3. **Iterate** - Use agent feedback to refine your approach
4. **Combine** - Multiple agents can provide holistic solutions
5. **Update** - Keep agents updated with new project patterns
