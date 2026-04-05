# Windows script

# Convert a GitHub issue stored in inputs/issue.md into docs using Aider
# No extra tools required besides Aider.

$IssueFile  = "inputs/issue.md"
$PromptFile = "prompts/issue_to_docs.md"

$DocSpec = "docs/SPEC.md"
$DocArch = "docs/ARCHITECTURE.md"
$DocDb   = "docs/DB_SCHEMA.md"

function Fail($msg) {
  Write-Error $msg
  exit 1
}

# --- Checks ---
if (-not (Get-Command aider -ErrorAction SilentlyContinue)) {
  Fail "❌ aider not found. Install/run aider first."
}

if (-not (Test-Path $PromptFile)) {
  Fail "❌ Missing $PromptFile"
}

if (-not (Test-Path $IssueFile)) {
  Fail "❌ Missing $IssueFile. Create it and paste the GitHub issue body into it."
}

# Read inputs
$issueText  = Get-Content $IssueFile -Raw
$promptText = Get-Content $PromptFile -Raw

# Ensure issue file isn't empty or placeholder
if ([string]::IsNullOrWhiteSpace($issueText)) {
  Fail "❌ inputs/issue.md is empty. Paste the GitHub issue body into it before running."
}

# Optional: detect placeholder text
if ($issueText -match "Paste GitHub issue body here" -or $issueText -match "Replace this file content") {
  Write-Warning "⚠ inputs/issue.md looks like a placeholder. Make sure you pasted the real issue body."
}

# --- Ensure docs exist ---
New-Item -ItemType Directory -Force -Path "docs" | Out-Null
New-Item -ItemType File -Force -Path $DocSpec | Out-Null
New-Item -ItemType File -Force -Path $DocArch | Out-Null
New-Item -ItemType File -Force -Path $DocDb | Out-Null

Write-Host "▶ Generating docs from $IssueFile using Aider..."
Write-Host "   Output files:"
Write-Host "   - $DocSpec"
Write-Host "   - $DocArch"
Write-Host "   - $DocDb"
Write-Host ""

Write-Host "Pre-check (file sizes before Aider):"
Get-Item $DocSpec, $DocArch, $DocDb | Format-Table Name, Length
Write-Host ""

# --- Run Aider (docs-only) ---
# IMPORTANT: If Aider asks "Add file to the chat?", type S (Skip all).

# Build a temporary message file (avoids PowerShell argument parsing issues)
$tmpPath = Join-Path $env:TEMP ("aider_issue_message_" + [guid]::NewGuid().ToString() + ".txt")

$message = @"
$promptText

--- ISSUE INPUT START ---
$issueText
--- ISSUE INPUT END ---
"@

Set-Content -Path $tmpPath -Value $message -Encoding UTF8

try {
  aider $DocSpec $DocArch $DocDb --edit-format whole --no-detect-urls --message-file $tmpPath
}
finally {
  Remove-Item $tmpPath -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Post-check (file sizes after Aider):"
Get-Item $DocSpec, $DocArch, $DocDb | Format-Table Name, Length
Write-Host ""

# Fail fast if still empty
$specLen = (Get-Item $DocSpec).Length
$archLen = (Get-Item $DocArch).Length
$dbLen   = (Get-Item $DocDb).Length

if ($specLen -eq 0 -or $archLen -eq 0 -or $dbLen -eq 0) {
  Fail "❌ Aider finished but one or more docs are still empty. Do NOT commit. Paste the last ~40 lines of terminal output and we’ll fix it."
}

Write-Host "✅ Done. Docs were generated successfully."
Write-Host "Next:"
Write-Host "  1) Review: git diff"
Write-Host "  2) Stage:  git add docs"
Write-Host "  3) Commit: git commit -m ""Generate docs from issue"""
Write-Host "  4) Push:   git push"