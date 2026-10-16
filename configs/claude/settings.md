# Claude Code user settings

This file tells what each key in `settings.json` does. JSON does not allow comments, and Claude Code does not load a `settings.json` file that has
comments. Thus, the explanations are in this file.

The bootstrap makes `~/.claude/settings.json` a soft link to `settings.json` in this directory. When you change a key in `settings.json`, update this
file too.

## General keys

| Key | Value | What it does |
| :- | :- | :- |
| `syncClaudeAiSkills` | `false` | Does not load the skills that you enabled on your claude.ai account. |
| `disableBundledSkills` | `true` | Removes the bundled skills and workflows of Claude Code from the skill list. This decreases the context size. |
| `disableWorkflows` | `true` | Turns off dynamic workflows. |
| `enableArtifact` | `false` | Turns off the Artifact tool. |
| `statusLine` | `type: command` | Runs `~/.claude/statusline-command.sh` to show the status line. |
| `tui` | `fullscreen` | Uses the full-screen terminal UI renderer. |
| `autoMemoryEnabled` | `false` | Stops the read and write of auto memory files. This decreases the context size. |
| `theme` | `dark` | Uses the dark color theme. |
| `editorMode` | `vim` | Uses vim key bindings in the prompt input. |
| `includeGitInstructions` | `false` | Removes the built-in git instructions and the git status snapshot. The `git-ops` skill gives the git rules. |
| `disableClaudeAiConnectors` | `true` | Does not load the MCP connectors of your claude.ai account. |

## Permissions

| Key | Value | What it does |
| :- | :- | :- |
| `permissions.defaultMode` | `auto` | Starts each session in auto mode. |
| `permissions.deny` | List of tools | Blocks each tool in the list. The model does not get the schema of a denied tool. |

### Denied tools

| Rule | What it blocks |
| :- | :- |
| `EnterPlanMode` | The tool that starts plan mode. |
| `ExitPlanMode` | The tool that stops plan mode and shows the plan for approval. |
| `DesignSync` | The tool that syncs design files and assets. |
| `NotebookEdit` | The tool that edits Jupyter notebook cells. |
| `SendMessage` | The tool that sends a message to other agents or sessions. |
| `PushNotification` | The tool that sends an operating system notification. |
| `RemoteTrigger` | The tool that manages remote triggers. |
| `ReportFindings` | The tool that reports code review findings as a typed list for the host UI. |
| `ScheduleWakeup` | The tool that schedules the session to start again at a later time. |
| `AskUserQuestion` | The tool that asks the user multiple-choice questions. |
| `CronCreate` | The tool that creates a scheduled task. |
| `CronDelete` | The tool that deletes a scheduled task. |
| `CronList` | The tool that lists the scheduled tasks. |

## Disabled plugins

Each key in `enabledPlugins` has the value `false`. Thus, Claude Code does not load these plugins, and their skills and tools do not go into the
context. The project `.claude/settings.json` file of each repository enables the plugins that the repository needs.

| Plugin | Source |
| :- | :- |
| `clickup@synced` | The ClickUp plugin of your claude.ai account. |
| `cc-plugin-tips@builtin` | Built-in plugin for usage tips. |
| `cc-plugin-diff@builtin` | Built-in plugin for diffs. |
| `cc-plugin-plugin-authoring@builtin` | Built-in plugin for plugin authoring. |
| `mods-guide@builtin` | Built-in plugin for the mods guide. |
| `you-should-know@builtin` | Built-in plugin for feature suggestions. |
| `cc-plugin-claude-test@builtin` | Built-in plugin for tests. |
| `cc-plugin-agents-md@builtin` | Built-in plugin for `AGENTS.md` files. |
| `cc-plugin-telemetry@builtin` | Built-in plugin for telemetry. |
| `cc-plugin-sec-default@builtin` | Built-in plugin for default security checks. |
