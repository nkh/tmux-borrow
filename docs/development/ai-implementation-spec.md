# AI implementation specification

This is the coding contract. Do not silently change product behavior.

## Non-negotiable constraints

2. Do not create a monolithic script; keep modules small.
3. Use Bash for orchestration and Perl where useful. Do not use Python in runtime code or examples.
4. Never use `eval` for config, argv, or hooks.
6. Never move, resize, kill, or claim ordinary user panes.
8. Do not suspend utilities by default.

## Source of truth

Follow `requirements/functional-requirements.md`, `requirements/arguments.md`, `requirements/lifecycle.md`, `requirements/layouts.md`, `architecture/architecture.md`, and `metadata/metadata-model.md`. If documents conflict, stop and report; do not choose silently.

## Required tests

Implement every invariant in `testing-strategy.md`, including failure injection between database and tmux operations and tests with ordinary panes present.

## Deliverables per task

Report changed files and reasons, tests added, exact test command/result, documentation updates, known limitations, and tests not run. Never claim tests passed unless actually run.

## Completion

A release candidate requires all P0 requirements, integration tests on supported tmux versions, CLI help matching docs, and archive integrity checks.
