---
description: Analyze and fix a GitHub issue
model: claude-opus-4-6
thinking: high
---

Please analyze and fix the GitHub issue: $ARGUMENTS.

Follow these steps:

# PLAN
1. Use `gh issue view` to get the issue details
2. Understand the problem described in the issue
3. Ask clarifying questions if necessary
4. Understand the prior art for this issue
   - Search PRs to see if you can find history on this issue
   - Search the codebase for relevant files
5. Think about how to break the issue down into small, manageable tasks
6. Document your plan in `docs/plans/` with the issue name in the filename

# CREATE
- Create a new branch for the issue
- Solve the issue in small, manageable steps, according to your plan
- Commit your changes after each step

# TEST
- Write tests to describe the expected behavior of your code
- Run the full test suite to ensure you haven't broken anything
- If the tests are failing, fix them
- Ensure that all tests are passing before moving on to the next step

# DEPLOY
- Open a PR and request a review

Remember to use the GitHub CLI (`gh`) for all GitHub-related tasks.
