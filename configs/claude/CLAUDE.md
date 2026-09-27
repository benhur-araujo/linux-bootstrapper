# Global Instructions

## Code style

Follow Clean Code (Robert C. Martin): intention-revealing names; small functions that do one thing; one level of abstraction per function.
Public methods read as a narrative of named steps (Stepdown Rule); extract large logic branches into intent-named private methods.

## Line Length

Wrap all lines at 150 characters. This applies to every file you write: code, comments, documentation, Markdown, configuration.

- Break a line at a word boundary. Do not break a word, a URL, or an inline code span.
- Keep a line longer than 150 characters only if a break is not possible, for example a long URL or a string literal.

## Writing Style

**Write all text in ASD-STE100 Simplified Technical English (STE).**
This applies to every text you produce: chat replies, documentation, READMEs, code comments, commit messages, PR and issue descriptions,
and log or error strings you author.

## Markdown Files

Write all Markdown files with this style. Apply the same style to Markdown blocks in chat replies, issues, and PR descriptions.

### Structure

- Start each file with one top-level heading (`#`). Use only one top-level heading in a file.
- Increment heading levels by one. Do not go from `##` to `####`.
- Use `#` characters for headings. Do not use the underline style (`===` or `---`).
- Do not put punctuation at the end of a heading. A question mark is permitted.
- Do not use the same heading text two times at the same level.
- Do not use emphasis (`**text**`) in place of a heading.

### Spacing

- Put one blank line above and below each heading, list, code block, and table.
- Use one blank line between blocks. Do not use two or more blank lines.
- Do not leave space characters at the end of a line. To make a line break, use a backslash (`\`) or a `<br>` tag.
- Do not leave blank lines at the end of the file. End the file with one newline character.
- Do not put space characters inside emphasis marks: write `**text**`, not `** text **`.

### Lists

- Use `-` for each item of an unordered list. Keep the same character in all the file.
- Use `1.` for each item of an ordered list, or count up (`1.`, `2.`, `3.`). Keep one method in all the file.
- Put one space after the list marker.
- Indent nested list items by two spaces for unordered lists and three spaces for ordered lists.
- Do not indent top-level list items.

### Code

- Use fenced code blocks with three backticks. Do not use the indented style.
- Give a language to each fenced code block, for example ` ```bash `. Use `text` if no language applies.
- Do not put space characters inside inline code marks.

### Links and Images

- Use descriptive link text. Do not use `here`, `link`, or `click here`.
- Write bare URLs as autolinks in angle brackets (`<https://example.com>`) or as full links.
- Give alternative text to each image.
- Do not use reference links or images that have no definition. Do not keep definitions that no link uses.

### Other

- Use `*` or `_` for emphasis and `**` for strong emphasis. Keep the same characters in all the file.
- Do not use raw HTML unless the content is not possible in Markdown.
- Write the text of the first cell of each table row between pipe characters, and give each row the same number of cells.

## Git & Version Control

### Commits

- Always follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages.
- Always set a scope in the commit message, e.g. `feat(auth): add token refresh`.

### Pull Requests

- Never open a PR unless explicitly instructed to do so.
- When opening a PR, always include the associated GitHub issue in the description if one exists for that PR (e.g. `Closes #123`).
- Never merge PRs unless explicitly instructed to do so.
