#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["rich"]
# ///
"""
Ralph Loop Runner — Gameplay Fixes

Executes AI iterations until all stories complete.
Uses rich for beautiful terminal output with progress tracking.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

from rich.console import Console
from rich.panel import Panel

console = Console()

# Use absolute paths based on script location so CWD doesn't matter
PROJECT_DIR = Path(__file__).parent.parent.resolve()
RALPH_DIR = PROJECT_DIR / ".ralph"
PRD_FILE = RALPH_DIR / "prd.json"
PROGRESS_FILE = RALPH_DIR / "progress.txt"


def load_prd() -> dict:
    with open(PRD_FILE) as f:
        return json.load(f)


def count_stories(prd: dict) -> tuple[int, int]:
    stories = prd["stories"]
    complete = sum(1 for s in stories if s["passes"])
    return complete, len(stories)


def get_next_story(prd: dict) -> dict | None:
    incomplete = [s for s in prd["stories"] if not s["passes"]]
    return min(incomplete, key=lambda s: s["priority"]) if incomplete else None


def run_claude() -> int:
    result = subprocess.run([
        "claude",
        "--dangerously-skip-permissions",
        "--print",
        "Execute ralph loop iteration per .ralph/CLAUDE.md"
    ], cwd=PROJECT_DIR)
    return result.returncode


def show_header(max_iterations: int, complete: int, total: int):
    console.print(Panel.fit(
        f"[bold cyan]Ralph Loop — Gameplay Fixes[/]\n\n"
        f"[bold yellow]⚠️  AUTONOMOUS MODE ENABLED[/]\n"
        f"[dim]Commands execute without approval[/]\n\n"
        f"[dim]Max:[/] [yellow]{max_iterations}[/]  "
        f"[dim]Progress:[/] [green]{complete}[/]/[cyan]{total}[/]",
        border_style="blue",
        title="🔄 ralph",
        title_align="left"
    ))


def show_iteration(iteration: int, max_iterations: int, story: dict, remaining: int):
    console.print()
    console.rule(f"[bold]Iteration {iteration}/{max_iterations}[/]", style="dim")
    console.print(f"[cyan]Next:[/] {story['id']} - {story['title']}")
    console.print(f"[dim]Remaining:[/] {remaining} stories")
    console.print()


def show_progress_bar(complete: int, total: int):
    pct = (complete / total * 100) if total > 0 else 0
    filled = int(pct / 5)
    bar = "█" * filled + "░" * (20 - filled)
    console.print(f"[cyan]Progress:[/] [{bar}] {complete}/{total} ({pct:.0f}%)")


def show_completion():
    console.print()
    console.print(Panel.fit(
        "[bold green]✓ All 3 gameplay bugs fixed![/]\n\n"
        "[dim]• Player starts with Scrap Blade[/]\n"
        "[dim]• Player spawn position randomized[/]\n"
        "[dim]• Room dimensions now vary per room[/]",
        border_style="green"
    ))


def show_max_reached(max_iterations: int, incomplete: int):
    console.print()
    console.print(Panel.fit(
        f"[bold yellow]Max iterations reached ({max_iterations})[/]\n"
        f"[red]{incomplete} stories still incomplete[/]",
        border_style="yellow"
    ))


def main():
    max_iterations = int(os.environ.get("MAX_ITERATIONS", "10"))

    if not RALPH_DIR.exists():
        console.print("[red]Error:[/] .ralph directory not found")
        sys.exit(1)

    if not PRD_FILE.exists():
        console.print(f"[red]Error:[/] {PRD_FILE} not found")
        sys.exit(1)

    prd = load_prd()
    complete, total = count_stories(prd)
    show_header(max_iterations, complete, total)

    for iteration in range(1, max_iterations + 1):
        prd = load_prd()
        complete, total = count_stories(prd)
        incomplete = total - complete

        if incomplete == 0:
            show_completion()
            sys.exit(0)

        next_story = get_next_story(prd)
        show_iteration(iteration, max_iterations, next_story, incomplete)

        with console.status("[bold green]Starting claude...[/]", spinner="dots"):
            pass

        exit_code = run_claude()

        if exit_code != 0:
            console.print(f"[yellow]Warning:[/] claude exited with code {exit_code}")

        prd = load_prd()
        complete, total = count_stories(prd)
        show_progress_bar(complete, total)

    prd = load_prd()
    complete, total = count_stories(prd)
    incomplete = total - complete
    show_max_reached(max_iterations, incomplete)
    sys.exit(1 if incomplete > 0 else 0)


if __name__ == "__main__":
    main()
