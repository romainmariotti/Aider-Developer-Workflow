# Windows Script

# Reads docs/issues/ISSUE-<id>/{SPEC,ARCHITECTURE,DB_SCHEMA}.md and implement the feature using Aider.

param(
  [Parameter(Mandatory=$true)]
  [string]$IssueId,

  [switch]$AutoYes
)

function Fail($msg) {
  Write-Error $msg
  exit 1
}

if (-not (Get-Command aider -ErrorAction SilentlyContinue)) {
  Fail "❌ aider not found. Install/run aider first."
}

$IssueDir = "docs/issues/ISSUE-$IssueId"
$SpecPath = Join-Path $IssueDir "SPEC.md"
$ArchPath = Join-Path $IssueDir "ARCHITECTURE.md"
$DbPath   = Join-Path $IssueDir "DB_SCHEMA.md"
$PromptFile = "prompts/docs_to_code.md"

if (-not (Test-Path $SpecPath)) { Fail "❌ Missing $SpecPath" }
if (-not (Test-Path $ArchPath)) { Fail "❌ Missing $ArchPath" }
if (-not (Test-Path $DbPath))   { Fail "❌ Missing $DbPath" }
if (-not (Test-Path $PromptFile)) { Fail "❌ Missing $PromptFile" }

# Collect editable files (backend + tests + optional frontend)
$editFiles = @()

if (Test-Path "app") {
  $editFiles += Get-ChildItem "app" -Recurse -File | ForEach-Object { $_.FullName }
}
if (Test-Path "tests") {
  $editFiles += Get-ChildItem "tests" -Recurse -File | ForEach-Object { $_.FullName }
}
if (Test-Path "frontend") {
  $editFiles += Get-ChildItem "frontend" -Recurse -File | ForEach-Object { $_.FullName }
}

if ($editFiles.Count -eq 0) {
  Fail "❌ No editable files found (expected app/ and/or tests/ and/or frontend/)."
}

# Build temp message file (robust)
$tmpPath = Join-Path $env:TEMP ("aider_impl_message_" + [guid]::NewGuid().ToString() + ".txt")
$promptText = Get-Content $PromptFile -Raw

$message = @"
$promptText

--- DOCS INPUT START ---
Issue: $IssueId

[SPEC]
$(Get-Content $SpecPath -Raw)

[ARCHITECTURE]
$(Get-Content $ArchPath -Raw)

[DB_SCHEMA]
$(Get-Content $DbPath -Raw)
--- DOCS INPUT END ---
"@

Set-Content -Path $tmpPath -Value $message -Encoding UTF8

# Build read-only context args (only if present)
$readArgs = @()
if (Test-Path "app/models.py")      { $readArgs += @("--read", "app/models.py") }
if (Test-Path "app/routes.py")      { $readArgs += @("--read", "app/routes.py") }
if (Test-Path "app/main.py")        { $readArgs += @("--read", "app/main.py") }
if (Test-Path "app/database.py")    { $readArgs += @("--read", "app/database.py") }
if (Test-Path "tests/test_tasks.py"){ $readArgs += @("--read", "tests/test_tasks.py") }

# Optional auto-accept
$autoYesArgs = @()
if ($AutoYes) { $autoYesArgs = @("--yes-always") }

Write-Host "▶ Implementing ISSUE-$IssueId from docs in $IssueDir"
Write-Host "   Edit files: $($editFiles.Count)"
Write-Host ""

try {
  aider `
    --edit-format diff `
    --map-tokens 0 `
    --map-refresh manual `
    --no-detect-urls `
    @autoYesArgs `
    @readArgs `
    --message-file $tmpPath `
    @editFiles
}
finally {
  Remove-Item $tmpPath -ErrorAction SilentlyContinue
}

# Run tests (uses venv python if present)
Write-Host ""
Write-Host "▶ Running tests..."
$py = ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) { $py = "python" }

& $py -m pytest tests/ -v
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
  Write-Host ""
  Write-Host "❌ Tests failed. You can re-run this script after pasting the pytest output into inputs/issue.md,"
  Write-Host "   or we can add an automatic 'fix failing tests' loop next."
  exit $exitCode
}

Write-Host ""
Write-Host "✅ Done. Implementation complete and tests passed."
Write-Host "Next:"
Write-Host "  1) Review: git diff"
Write-Host "  2) Commit: git status + git add + git commit"