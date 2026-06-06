---
name: dingtalk-docs
description: Upload existing local files into DingTalk Docs by controlling an already open browser session through chrome-devtools MCP. Use when Codex needs to sync generated reports, incident postmortems, weekly reports, runbooks, meeting notes, or other local documents into a user-specified DingTalk Docs folder.
---

# DingTalk Docs Publisher

Use this skill to upload already generated local files into DingTalk Docs while keeping content generation and destination decisions outside this skill.

This skill is intentionally generic:

- Do not generate business content here.
- Do not assume a specific project.
- Do not hardcode folder names unless the caller explicitly provides them.
- Do not create a new browser login session if an existing logged-in DingTalk page can be reused.

## What This Skill Owns

This skill owns only the file upload step:

- Reuse an already open browser session
- Navigate to DingTalk Docs
- Enter a caller-provided target folder
- Upload a caller-provided local file
- Return upload status and document URL when available

This skill does not own:

- report generation
- incident analysis
- metric aggregation
- local markdown rendering rules
- business folder selection
- report naming policy

## Expected Inputs

Collect or infer these values before using the workflow:

- `local_file_path`
- `target_folder_name` or `target_folder_path`
- `if_exists`
  - `keep_both`
  - `replace`
  - `skip`
- optional `expected_title`

Prefer explicit file upload over editor typing. This skill should not convert Markdown into rich text by pasting body text into the editor unless the user explicitly asks for that fallback.

For recurring weekly reports, prefer `skip` or a deliberate `replace` workflow. Avoid `keep_both` unless the caller explicitly wants duplicate historical copies, because DingTalk will create suffixes such as `(1)` and `(2)` for same-name uploads.

## Browser Assumptions

Use `chrome-devtools` MCP against the browser that is already open.

Default assumptions:

- DingTalk may already be logged in
- The desired folder may be reachable from:
  - recent pages
  - left navigation
  - search
  - favorites / 收藏
- The desired folder may open in a file list view with `Upload` capability
- The visible UI may be dynamic enough that direct click navigation is unreliable; when that happens, it is acceptable to use DingTalk Docs network responses in the current browser session to resolve the target folder node URL and navigate there directly

Prefer reusing an existing DingTalk Docs tab. Open a new tab only if no suitable DingTalk Docs page is already available.

## High-Level Workflow

1. Inspect open pages and reuse an existing DingTalk Docs tab if possible.
2. Navigate to DingTalk Docs if needed.
3. Dismiss onboarding popups, guide masks, and modal dialogs before interacting with the page.
4. Go to the requested folder supplied by the caller.
   - Prefer folder-node pages over search-result pages before uploading.
   - If the folder is in Favorites, open `https://alidocs.dingtalk.com/`, click `Favorites`, and wait for the folder name to appear.
   - If clicking the favorite row only focuses the virtualized list and does not open the folder, inspect `box/api/v2/star/list` and navigate directly to `https://alidocs.dingtalk.com/i/nodes/<dentryUuid>`.
5. Inspect whether a same-name file or document already exists in that folder.
6. Follow the requested `if_exists` behavior:
   - `keep_both`: upload directly and let DingTalk keep both versions; warn that same-name items may appear as `(1)`, `(2)` duplicates
   - `replace`: delete/rename old one only if the UI supports a reliable replace path; otherwise stop and report
   - `skip`: stop if a same-name item already exists
7. Use folder-level upload or import flow to upload the local file.
   - In the current DingTalk Docs UI, folder pages expose `Upload -> Upload File`; use the file chooser against that menu item.
8. Wait for upload/import to finish and ensure the new file appears in the folder list.
   - Treat task-panel text like `All tasks succeeded`, `1 completed, 0 failed`, and list count increase as strong evidence, but still verify the uploaded item appears in the folder list.
9. Open the uploaded file only when needed to capture a stable URL.
10. Report the result clearly.

## Folder Navigation Strategy

Do not assume one fixed UI path. Use the most reliable route available in the current session:

1. Favorites / 收藏
2. Search box
3. Left navigation tree
4. Breadcrumb backtracking from an already open document in the same area

If UI clicks are unstable but the browser session is valid, use network-assisted navigation as a fallback:

1. Inspect recent `chrome-devtools` network requests for favorites or search results.
2. Prefer DingTalk Docs APIs that already expose the target folder entry in the current session, for example:
   - favorites list endpoints such as `box/api/v2/star/list`
   - search endpoints such as `cs/api/v1/search`
3. Resolve the folder's node URL from the response payload.
   - For `box/api/v2/star/list`, use the entry whose `name` matches the requested folder and `dentryType` is `folder`; the node id is usually `dentryUuid`.
   - The folder URL is usually `https://alidocs.dingtalk.com/i/nodes/<dentryUuid>`.
4. Navigate directly to that node URL.
5. Confirm the folder page shows a folder/file count and folder-level `Upload` control before uploading.

When the caller gives a folder name such as `云平台故障记录（2026）` or `平台运行情况`, treat it as a human-visible label, not a path ID.

If multiple folders have the same name:

- prefer the one in the currently active account/workspace
- prefer the one under favorites if the user explicitly said it is in favorites
- otherwise stop and report the ambiguity

## Upload Rules

When uploading a file:

- prefer the caller-provided local file path as the source of truth
- prefer `.md` files when the upstream skill already generated Markdown
- preserve the original file name unless the caller explicitly requests renaming
- for weekly reports such as `2026-W22.md`, check for existing titles `2026-W22`, `2026-W22(1)`, `2026-W22(2)` before uploading; do not create another suffixed copy unless requested
- if the caller/upstream workflow asks to align with an existing folder naming convention, it is acceptable to upload a temporary copy with the expected filename while leaving the local source file unchanged
- use DingTalk's upload or import entry instead of editor typing whenever possible
- on folder pages, prefer the folder-level `Upload -> Upload File` path instead of attempting to upload from search views or document pages

Current DingTalk UI note: after `Upload -> Upload File`, the underlying file input may be hidden as `input#portal_upload_files`. If `upload_file` cannot attach to the menu item, make that input visible, upload to the visible chooser, then dispatch a bubbling `change` event. This can trigger duplicate uploads in some sessions; verify the task panel count and folder list immediately afterward.

If DingTalk imports `.md` as an online doc preview rather than a raw attachment, accept that behavior. The skill should not try to re-render the Markdown itself.

## Validation Checks

Before finishing, verify:

- the correct folder was opened
- the uploaded item name matches the local file name or expected title
- the uploaded item appears in the folder list
- no unexpected duplicate same-title items were created; if duplicates were created and reliable UI deletion is unavailable, report their exact names for manual cleanup
- the resulting page URL is captured if available
- when a stable URL is needed, open the uploaded item from the folder list and return the resulting `/i/nodes/<node>` URL
- if the upload produces a transient success toast or task panel, prefer verifying via the refreshed folder list rather than trusting the toast alone

## Failure Handling

If something goes wrong, prefer recoverable retries in this order:

1. close popup / guide overlay
2. re-focus the correct tab
3. re-open the target folder as a real folder page instead of a search result page
4. retry upload once
5. if folder clicks still fail, fall back to resolving the folder node URL from network responses and navigate directly

Stop and report instead of looping when:

- the account is not logged in
- the target folder cannot be uniquely identified
- permissions prevent upload
- the upload UI changed enough that the target controls cannot be found reliably

## Output Contract

Return a compact result with:

- `success`
- `action`
  - `uploaded`
  - `skipped`
  - `failed`
- `local_file_path`
- `target_folder`
- `document_url` if available
- `notes`

## Project Integration Pattern

When another skill needs DingTalk publishing, keep responsibilities separated:

1. upstream skill generates the local file
2. upstream skill decides the destination folder
3. upstream skill hands `local_file_path` and `target_folder_*` to this skill
4. this skill uploads the file to DingTalk Docs
5. upstream skill decides whether to store the returned URL in local metadata

Examples:

- `incident-management` generates a local incident report or annual summary, decides the corresponding yearly incident folder, then uses this skill to upload the `.md` file
- `weekly-report-generation` generates a local weekly report, decides the weekly reports folder, then uses this skill to upload the `.md` file

## Usage Notes

- Prefer text snapshots over screenshots when using `chrome-devtools`.
- Use the latest snapshot before clicking or filling controls.
- Prefer file upload controls over editor interactions.
- Expect DingTalk file lists and upload dialogs to be dynamic; after each major navigation, take a fresh snapshot.
- Search results and favorites views are useful for locating folders, but final upload should happen from the resolved folder page whenever possible.
- When favorites already contains the target folder, it is often faster to resolve the folder via favorites list data than to keep retrying brittle UI clicks.
