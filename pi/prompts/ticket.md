---
description: Manage project tickets in todos.md file with grooming and planning features
---

# Project Ticket Manager

Manage tickets in a `todos.md` file at the root of your current project directory. Use the `groom` command to break down features into tickets, and the `plan` command to automatically work on and complete tickets.

## Usage Examples:
- `/ticket create "Fix login authentication bug" high` - Create new ticket
- `/ticket groom "implement user authentication"` - Start grooming session
- `/ticket plan 1` or `/ticket plan T-001` - Work on ticket #T-001
- `/ticket done 1` or `/ticket done T-001` - Mark ticket #T-001 as done
- `/ticket list` - Show all active tickets
- `/ticket list open` - Show open tickets
- `/ticket convert 2 feature` or `/ticket convert T-002 feature` - Change ticket type

## Instructions:

You are a ticket manager for the current project. When this command is invoked:

1. **Determine the project root** by looking for common indicators (.git, package.json, etc.)
2. **Locate or create** `todos.md` in the project root
3. **Parse the command arguments** to determine the action:
   - `create "description" [priority]` - Create a new ticket with auto-correction (priority: low/medium/high, default: medium)
   - `groom "feature/idea description"` - Start grooming session
   - `done N` or `done T-N` - Mark ticket as completed (accepts both formats: 1 or T-001)
   - `list [status]` - Show all tickets or filter by status (open/done)
   - `convert N [type]` or `convert T-N [type]` - Convert ticket to different type (bug/feature/task)
   - `plan N` or `plan T-N` - Create and execute a plan for ticket
   - `remove N` or `remove T-N` - Remove ticket entirely
   - `reopen N` or `reopen T-N` - Reopen a completed ticket
4. **Automatically apply English corrections and naming convention fixes** when creating tickets
5. **When using `plan N`**: Analyze the ticket, create an execution plan, work on the task, and automatically run `/ticket done N` when completed
6. **When using `groom "description"`**: Interactively analyze the feature, ask clarifying questions, break it down into tickets, and automatically create all necessary tickets

**Note**: All tickets use the format #T-XXX (e.g., #T-001, #T-002) for unique identification. Commands accept both short format (1, 2, 3) and full format (T-001, T-002, T-003).

## Ticket Format:
Use this markdown format in todos.md:
```markdown
# Project Tickets

## Active Tickets
- [ ] #T-001 [BUG] [HIGH] Fix login authentication bug | Created: 01-15-2025
- [ ] #T-002 [FEATURE] [MEDIUM] Add dark mode feature | Created: 01-15-2025

## Completed Tickets
- [x] #T-004 [BUG] [HIGH] Fix memory leak in dashboard | Created: 01-14-2025 | Completed: 01-15-2025
```

## Behavior:
- Auto-increment ticket numbers with unique convention (#T-001, #T-002, etc.)
- Default type is [BUG] unless specified
- Default priority is [MEDIUM] unless specified
- Types: BUG, FEATURE, TASK
- Priorities: LOW, MEDIUM, HIGH
- Keep completed tickets in a separate section
- Sort active tickets by priority (HIGH -> MEDIUM -> LOW)
- If todos.md doesn't exist, create it with the basic structure
- Show ticket number and brief summary after each action
- **Auto-fix naming conventions** when creating tickets

## Plan Command Behavior:
When `/ticket plan N` is invoked:
1. Display the ticket details
2. Analyze the task and create an execution plan
3. Work through the implementation
4. Upon successful completion, run `/ticket done N`
5. If partially completed, add progress notes without marking as done

## Groom Command Behavior:
When `/ticket groom "description"` is invoked:
1. Analyze the feature/idea description
2. Ask clarifying questions to understand requirements
3. Identify technical considerations and dependencies
4. Break down the work into appropriately-sized tickets
5. Automatically create all tickets with proper types and priorities
6. Show summary of created tickets ready for implementation

## Automatic English Correction (During Creation)

When creating tickets, automatically fix:
1. **Grammar and spelling** - Correct English errors
2. **Capitalize first letter** - "fix login bug" -> "Fix login bug"
3. **Remove trailing punctuation** - "Add new feature." -> "Add new feature"
4. **Fix articles (a/an/the)** - "Add a authentication" -> "Add an authentication"
5. **Fix verb forms** - "Fixing the bug" -> "Fix the bug" (imperative mood)
6. **Standardize verbs** for each type:
   - **BUG**: Fix, Resolve, Debug, Investigate
   - **FEATURE**: Add, Implement, Create, Enable
   - **TASK**: Update, Refactor, Document, Optimize

$ARGUMENTS
