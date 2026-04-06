# Windows script

# Convert a GitHub issue stored in inputs/issue.md into docs/issues/ISSUE-<id>/ using Aider

param(
  [Parameter(Mandatory=$true)]
  [string]$IssueId
)

$IssueFile  = "inputs/issue.md"
$PromptFile = "prompts/issue_to_docs.md"

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
  Fail "❌ Missing $IssueFile. Paste the GitHub issue body into it."
}

$issueText  = Get-Content $IssueFile -Raw
$promptText = Get-Content $PromptFile -Raw

if ([string]::IsNullOrWhiteSpace($issueText)) {
  Fail "❌ inputs/issue.md is empty. Paste the GitHub issue body into it before running."
}

# --- Output folder per issue ---
$IssueDir = "docs/issues/ISSUE-$IssueId"
New-Item -ItemType Directory -Force -Path $IssueDir | Out-Null

$DocSpec = Join-Path $IssueDir "SPEC.md"
$DocArch = Join-Path $IssueDir "ARCHITECTURE.md"
$DocDb   = Join-Path $IssueDir "DB_SCHEMA.md"

# Ensure output files exist
New-Item -ItemType File -Force -Path $DocSpec | Out-Null
New-Item -ItemType File -Force -Path $DocArch | Out-Null
New-Item -ItemType File -Force -Path $DocDb   | Out-Null

Write-Host "▶ Generating docs for ISSUE-$IssueId into $IssueDir"
Write-Host "   - $DocSpec"
Write-Host "   - $DocArch"
Write-Host "   - $DocDb"
Write-Host ""

Write-Host "Pre-check (file sizes before Aider):"
Get-Item $DocSpec, $DocArch, $DocDb | Format-Table Name, Length
Write-Host ""

# --- Build temp message file (prevents PowerShell CLI parsing issues) ---
$tmpPath = Join-Path $env:TEMP ("aider_issue_message_" + [guid]::NewGuid().ToString() + ".txt")

$message = @"
$promptText

--- ISSUE INPUT START ---
Issue ID: $IssueId
$issueText
--- ISSUE INPUT END ---
"@

Set-Content -Path $tmpPath -Value $message -Encoding UTF8

# --- Build --read args only if files exist (prevents errors) ---
$readArgs = @()
if (Test-Path "app/models.py")      { $readArgs += @("--read", "app/models.py") }
if (Test-Path "app/routes.py")      { $readArgs += @("--read", "app/routes.py") }
if (Test-Path "app/main.py")        { $readArgs += @("--read", "app/main.py") }
if (Test-Path "app/database.py")    { $readArgs += @("--read", "app/database.py") }
if (Test-Path "tests/test_tasks.py"){ $readArgs += @("--read", "tests/test_tasks.py") }

try {
  # Key flags:
  # --map-tokens 0 : disables repo-map (reduces exploration + prompts)
  # --map-refresh manual : don't rebuild map
  # --no-detect-urls : reduces endpoint/url weirdness
  # --edit-format whole : reliable file writes
  aider $DocSpec $DocArch $DocDb `
    --edit-format whole `
    --map-tokens 0 `
    --map-refresh manual `
    --no-detect-urls `
    @readArgs `
    --message-file $tmpPath
}
finally {
  Remove-Item $tmpPath -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Post-check (file sizes after Aider):"
Get-Item $DocSpec, $DocArch, $DocDb | Format-Table Name, Length
Write-Host ""

# Fail fast if still empty
if ((Get-Item $DocSpec).Length -eq 0 -or (Get-Item $DocArch).Length -eq 0 -or (Get-Item $DocDb).Length -eq 0) {
  Fail "❌ Aider finished but one or more docs are still empty. Do NOT commit."
}

Write-Host "✅ Done. Docs generated in $IssueDir"
Write-Host "Next:"
Write-Host "  1) Review: git diff"
Write-Host "  2) Stage:  git add $IssueDir"
Write-Host "  3) Commit: git commit -m ""Generate docs for ISSUE-$IssueId"""