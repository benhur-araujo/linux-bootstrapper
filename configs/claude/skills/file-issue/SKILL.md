---
name: file-issue
description: Files an issue on Procuro-Inc/pdp-gitops, assigns it to you, and puts it in the PDP project backlog.
disable-model-invocation: true
---

# File an Issue

An issue of this repo is filed when it holds three states: assigned to the user, an item of the PDP project <https://github.com/orgs/Procuro-Inc/projects/2>, and `Backlog` status. An issue that GitHub created but the project does not hold is not filed.

Read the project ids from the project. Do not write an id in a command.

## Step 1 — Write the issue

Invoke the `git-ops:git-ops` skill with the Skill tool. It holds the title rule and the body template. Take the triage label from `docs/agents/triage-labels.md`.

For a plan or a list that gives more than one issue, write each one in full before you create any of them, and keep the order the user gave.

Done when each issue has a title, a body per that template, and one triage label.

## Step 2 — Read the project ids

Run this one time in the run:

```bash
export PROJECT_NUMBER=2 PROJECT_OWNER=Procuro-Inc
export PROJECT_ID=$(gh project view "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq .id)
export STATUS_FIELD=$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
  --jq '.fields[] | select(.name == "Status") | .id')
export BACKLOG_OPTION=$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json \
  --jq '.fields[] | select(.name == "Status") | .options[] | select(.name == "Backlog") | .id')
```

Done when the three variables hold a value.

## Step 3 — Create each issue

Write the body to a file, then create the issue. The command prints the issue url:

```bash
cat > /tmp/issue-body.md <<'BODY'
<the body from step 1>
BODY

ISSUE_URL=$(gh issue create \
  --title "<the title from step 1>" \
  --body-file /tmp/issue-body.md \
  --assignee @me \
  --label "<the triage label from step 1>")
```

For an issue that GitHub already holds, take its url and assign it instead: `gh issue edit <number> --add-assignee @me`.

Done when each issue of step 1 printed a url.

## Step 4 — Put each issue in the backlog

Run this for each url of step 3:

```bash
ITEM_ID=$(gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "$ISSUE_URL" --format json --jq .id)
gh project item-edit --id "$ITEM_ID" --project-id "$PROJECT_ID" \
  --field-id "$STATUS_FIELD" --single-select-option-id "$BACKLOG_OPTION"
```

`item-add` on an issue the project already holds returns the same item id, so a second run changes nothing.

Done when each issue has an item id.

## Step 5 — Link the related issues

When the issues of this run depend on each other or belong to a parent, add the `blocked_by` edges and the sub-issue edges with the endpoints in `docs/agents/issue-tracker.md`.

Done when each dependency and each parent the user named is an edge on GitHub.

## Step 6 — Verify

```bash
gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --limit 200 --format json \
  --jq '.items[] | select(.content.number == <number>) | {number: .content.number, status, assignees}'
```

Done when each issue of this run prints `"status": "Backlog"` and the user login in `assignees`. An issue that prints a null status or an empty `assignees` sends you back to step 3.

Report one line for each issue: the number, the title, and the url.
