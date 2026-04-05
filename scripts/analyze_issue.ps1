# Windows script

# Convert a GitHub issue stored in inputs/issue.md into docs using Aider
# No extra tools required besides Aider.

$IssueFile  = "inputs/issue.md"
$PromptFile = "prompts/issue_to_docs.md"

$DocSpec = "docs/SPEC.md"
$DocArch = "docs/ARCHITECTURE.md"
$DocDb   = "docs/DB_SCHEMA.md"

# Checks
if (-not (Get-Command aider -ErrorAction SilentlyContinue)) {
  Write-Error "❌ aider not found. Install/run aider first."
  exit 1
}

if (-not (Test-Path $PromptFile)) {
  Write-Error "❌ Missing $PromptFile"
  exit 1
}

if (-not (Test-Path $IssueFile)) {
  Write-Error "❌ Missing $IssueFile"
  Write-Error "Create it and paste the GitHub issue body into it."
  exit 1
}

# Ensure docs exist
New-Item -ItemType Directory -Force -Path "docs" | Out-Null
New-Item -ItemType File -Force -Path $DocSpec | Out-Null
New-Item -ItemType File -Force -Path $DocArch | Out-Null
New-Item -ItemType File -Force -Path $DocDb | Out-Null

$issueText  = Get-Content $IssueFile -Raw
$promptText = Get-Content $PromptFile -Raw

Write-Host "▶ Generating docs from $IssueFile using Aider..."
Write-Host "   Output files:"
Write-Host "   - $DocSpec"
Write-Host "   - $DocArch"
Write-Host "   - $DocDb"
Write-Host ""

aider $DocSpec $DocArch $DocDb --message @"
$promptText

--- ISSUE INPUT START ---
$issueText
--- ISSUE INPUT END ---
"@

Write-Host ""
Write-Host "✅ Done."
Write-Host "Next:"
Write-Host "  1) Review: git diff"
Write-Host "  2) Commit: git commit -am ""Generate docs from issue"" (or stage/commit normally)"