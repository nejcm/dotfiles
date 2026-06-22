---
name: second-opinion
description: Get a second opinion from another LLM on any question, problem, review
---

## Capabilities

You can call other LLMs for a second opinion using these commands:

- **Codex (latest gpt)**: `codex exec "<your question here>"`
- **Claude (latest Opus)**: `claude -p "<your question here>"`

## Steps

- Step 1: Understand the request
- Step 2: Format the query with the question, any relevant context and any specific constraints or requirements
- Step 3: Call the other LLM with the formatted query. (eg. if current LLM is Codex gpt, call Claude and vice versa)
