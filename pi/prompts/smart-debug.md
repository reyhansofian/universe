---
description: Debug complex issues with structured root cause analysis
model: claude-opus-4-6
thinking: high
---

Debug the following issue using a structured approach:

## 1. Analyze
- Examine error messages and stack traces
- Identify code paths leading to the issue
- Check recent changes that may have introduced the problem

## 2. Reproduce
- Determine minimal reproduction steps
- Identify required environment setup
- Document test data or conditions needed

## 3. Isolate
- Narrow down to the specific module/function causing the issue
- Check if the issue is deterministic or intermittent
- Identify any dependency or state-related factors

## 4. Root Cause
- Explain precisely why the issue occurs
- Assess impact on other components
- Determine if this is a symptom of a deeper problem

## 5. Solution Options

**Quick Fix** - Minimal change to resolve:
- Implementation details
- Risk assessment

**Proper Fix** - Best long-term solution:
- Refactoring requirements
- Testing needs

**Preventive Measures** - Avoid similar issues:
- Code patterns to adopt
- Tests to add

## 6. Implementation
- Specific code changes needed
- Order of operations for the fix
- Validation steps

If the issue involves performance problems, also:
- Profile code execution paths
- Identify bottlenecks and resource usage
- Suggest optimization strategies with before/after projections

Issue to debug: $ARGUMENTS
