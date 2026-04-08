# Task Manager API

A REST API built with FastAPI and SQLModel, developed using an AI-assisted developer workflow with [Aider](https://aider.chat/).

This project is part of our **Emerging Technologies** course at HES-SO, demonstrating how AI tools integrate into every stage of the software development lifecycle: coding, refactoring, TDD, Git, and CI/CD.

---

## Tech Stack

- **Python 3.12** — Language
- **FastAPI** — Web framework
- **SQLModel** — ORM (database layer)
- **SQLite** — Database (file-based, zero setup)
- **Aider** — AI coding assistant (uses Claude as LLM backend)
- **pytest** — Test runner
- **Ruff** — Linter / formatter
- **GitHub Actions** — CI/CD pipeline
- **Docker** — Containerization
- **Watchtower** — Automatic container updates

---

## Prerequisites

Make sure you have the following installed before starting:

- **Python 3.12** — Check with `python3.12 --version`
- **Git** — Check with `git --version`
- **An Anthropic API key** — Get one at [console.anthropic.com](https://console.anthropic.com/)

---

## Setup Guide

### 1. Clone the repository

```bash
git clone https://github.com/romainmariotti/Aider-Developer-Workflow.git
cd Aider-Developer-Workflow
```

### 2. Create and activate the virtual environment

```bash
python3.12 -m venv .venv
source .venv/bin/activate
```

> **Windows users:** Use `py -3.12 -m venv .venv` and `.venv\Scripts\Activate.ps1` instead.

You should see `(.venv)` at the start of your terminal prompt.

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Create the `.env` file

This file holds your API key for Aider. It is **not committed to Git** for security reasons, so each team member needs to create their own.

Create and open `.env` and add the API key.

```
ANTHROPIC_API_KEY=your-api-key-here
```

> **Important:** Never commit your `.env` file or share your API key in chat messages.

### 5. Run the API

```bash
uvicorn app.main:app --reload
```

The API will start at [http://localhost:8000](http://localhost:8000).

Open [http://localhost:8000/docs](http://localhost:8000/docs) in your browser to see the interactive Swagger UI where you can test all endpoints.

### 6. Verify it works

In the Swagger UI, try creating a task:

1. Click **POST /tasks**
2. Click **Try it out**
3. Paste this into the request body:
   ```json
   {
     "title": "My first task",
     "description": "Testing the API",
     "completed": false
   }
   ```
4. Click **Execute**
5. You should get a `201` response with the created task

---

## Using Aider

Aider is our AI coding assistant. It reads your code, takes instructions in natural language, edits files, and can auto-commit changes.

### Start Aider

```bash
aider app/main.py app/models.py app/routes.py app/database.py
```

Aider picks up the model and API key from `.aider.conf.yml` and `.env` automatically.

### Example prompts

```
> Add pagination to GET /tasks with query params skip and limit
> Write tests for the CRUD endpoints in tests/test_tasks.py
> Refactor the update endpoint to support partial updates with PATCH
```

Type `/help` inside Aider to see all available commands.

---

## Issues and Documentation

In order to make a change to the application by using our workflow, the developer must start by creating an Issue in GitHub, which will be converted into documentation files that will be used later in the coding part.

### Create issue

1. In the GitHub repository, navigate to `/issues`, and click `New issue`.
2. Select either `Bug`or `Feature request` according to the current need.
3. Fill-in the different fields, and click `Create`.

### Generate Documentation from the Issue with Aider

In GitHub, click on the newly created Issue, **copy** its **body**, and **remember** its **ID**.

Now, in the IDE, replace the content of `/inputs/issue.md` with the copied body of the Issue, and save the file.

Run the script with this command (here, 11 is the ID of the Issue) :

**Windows**

```
.\scripts\analyze_issue.ps1 11
```

**Mac/Linux**

```
./scripts/analyze_issue.sh 11
```

Once the script has finished running, a folder dedicated to the issue is created under `/docs/issues`. Inside this folder, we find three files:

- ARCHITECTURE.md
- DB_SCHEMA.md
- SPEC.md

These 3 files will be used in the next step to generate the code that will implement the Issue.

---

## Generate Code from Documentation

Now that we have our documentation files generated in `/docs`, we can feed them to Aider to implement the feature.

### Run script to generate Code from Documentation with Aider

To generate the code by using the Documentation as a base, we just have to run the following script (here, 11 is the ID of the Issue) :

**Windows**

```
.\scripts\implement_issue.ps1 11
```

**Mac/Linux**

```
./scripts/implement_issue.sh 11
```

This script reads:

- `docs/issues/ISSUE-<id>/SPEC.md`
- `docs/issues/ISSUE-<id>/ARCHITECTURE.md`
- `docs/issues/ISSUE-<id>/DB_SCHEMA.md`

and asks Aider to update the codebase. After Aider finishes, the script runs the test suite automatically.

---

## Running Tests

```bash
pytest tests/ -v
```

Tests use a **separate in-memory SQLite database** so they never touch your real `tasks.db` data. Each test gets a fresh database via a pytest fixture that overrides the `get_session` dependency.

### Test Cases

| #   | Test                     | Endpoint             | Expected                   |
| --- | ------------------------ | -------------------- | -------------------------- |
| 1   | Welcome message          | `GET /`              | 200, returns welcome JSON  |
| 2   | Create a task            | `POST /tasks`        | 201, returns created task  |
| 3   | List all tasks           | `GET /tasks`         | 200, returns list of tasks |
| 4   | Get a specific task      | `GET /tasks/{id}`    | 200, returns matching task |
| 5   | Get non-existent task    | `GET /tasks/{id}`    | 404                        |
| 6   | Update a task            | `PUT /tasks/{id}`    | 200, returns updated task  |
| 7   | Update non-existent task | `PUT /tasks/{id}`    | 404                        |
| 8   | Delete a task            | `DELETE /tasks/{id}` | 204, no content            |
| 9   | Delete non-existent task | `DELETE /tasks/{id}` | 404                        |

### TDD Workflow with Aider

The tests were generated using Aider following a test-driven development approach:

1. **Red** — Write tests first (they fail because the feature is missing or broken)
2. **Green** — Feed the test failures back to Aider and let it fix the code
3. **Refactor** — Clean up the code while keeping tests green

To feed test failures back to Aider:

```bash
# Run tests and see what fails
pytest tests/ -v

# Open Aider with the relevant files
aider tests/test_tasks.py app/routes.py app/models.py app/database.py

# Paste the failure output
> Fix the following test failures: [paste pytest output here]
```

### Automated TDD Loop (dev-loop.sh)

Instead of running tests and feeding errors to Aider manually, you can use the `dev-loop.sh` script to automate the entire cycle:

```bash
./dev-loop.sh
```

> **Windows users:** Run this script in Git Bash (comes with Git for Windows).

This script does the following automatically:

1. Runs `pytest tests/ -v`
2. If all tests pass, it prints a success message and exits
3. If any tests fail, it launches Aider with the failure output and lets it fix the code
4. After Aider finishes, it runs the tests again to verify the fix

This is the core of the AI-assisted TDD workflow — one command handles the full red-green cycle.

---

## Linting

Check for style issues:

```bash
ruff check app/
```

Auto-fix what it can:

```bash
ruff check --fix app/
```

### Automated Lint Loop (lint-fix.sh)

Instead of running lint checks and fixing issues manually, you can use the lint-fix.sh script to automate the entire process:

```bash
./lint-fix.sh
```

> **Windows users:** Run this script in Git Bash (comes with Git for Windows).

This script does the following automatically:

1. Runs ruff check app/ to detect lint issues
2. If no issues are found, it prints a success message and exits
3. If issues are detected, it attempts to fix them automatically with ruff check app/ --fix
4. It re-runs the lint check to verify if all issues were fixed
5. If issues still remain, it sends the lint errors to Aider so it can fix them without changing functionality

---

### Automated Test Coverage Loop (coverage-check.sh)

To ensure that the project maintains a healthy level of test coverage, this repository includes an automated coverage script.
Similar to the TDD loop and lint-fix loop, this script monitors your test coverage and uses Aider to improve tests whenever coverage falls below a configurable threshold.

```bash
./coverage-check.sh
```

You can also specify a custom minimum coverage percentage (default is 80%):

```bash
./coverage-check.sh 90
```

> **Windows users:** Run this script in Git Bash (comes with Git for Windows).

What the script does:

1. Generates an XML coverage report using pytest
2. Extracts the total line coverage percentage
3. Compares it to the threshold
4. If coverage is high enough → nothing to do
5. If coverage is too low → automatically launches Aider with a prompt to improve the tests
6. Automatically skips the Aider step in CI environments (CI=true) to avoid infinite loops
7. Cleans up temporary coverage files

This script integrates seamlessly into the AI-assisted dev workflow by continuously enforcing test quality while preserving developer productivity.

---

## CI/CD Pipeline

Every push and pull request to `main` or `development` triggers a GitHub Actions pipeline that automatically runs linting and tests. Pushes to `main` additionally build a Docker image and push it to GitHub Container Registry (GHCR) for automatic deployment.

### What the pipeline does

**On every push/PR (main and development):**

1. Sets up Python 3.12
2. Installs dependencies from `requirements.txt`
3. Runs `ruff check app/` — fails the build if there are style issues
4. Runs `pytest tests/ -v` — fails the build if any tests fail

**On push to main only (after tests pass):**

5. Logs in to GitHub Container Registry
6. Builds a Docker image from the `Dockerfile`
7. Pushes the image to `ghcr.io/romainmariotti/aider-developer-workflow:latest`

### Automatic Deployment

The production server runs [Watchtower](https://containrrr.dev/watchtower/), which polls GHCR every 60 seconds for new images. When a new image is detected, Watchtower automatically pulls it and restarts the container — no SSH or manual intervention required.

The full flow:

```
Push to main
  → GitHub Actions runs tests + linting
  → Builds Docker image
  → Pushes to GHCR
  → Watchtower detects new image (within 60s)
  → Pulls and restarts the container
  → Live at https://taskapi.mberchtold.ch/docs
```

### Viewing pipeline results

Go to the **Actions** tab in the GitHub repository to see pipeline runs. A green checkmark means linting and tests passed. A red X means something failed — click into the run to see which step failed and what the error was.

### Pipeline configuration

The pipeline is defined in `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main, development]
  pull_request:
    branches: [main, development]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Set up Python 3.12
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt

      - name: Run ruff check
        run: |
          ruff check app/

      - name: Run tests
        run: |
          pytest tests/ -v

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ghcr.io/${{ github.repository_owner }}/aider-developer-workflow:latest
```

---

## Project Structure

```
Aider-Developer-Workflow/
├── .github/
│   └── workflows/
│       └── ci.yml               # GitHub Actions CI/CD pipeline
├── .aider.conf.yml              # Aider config (model, language, settings)
├── .env                         # API key (create locally, not in Git)
├── .env.example                 # Template for .env
├── .gitignore                   # Files excluded from Git
├── Dockerfile                   # Docker image build instructions
├── requirements.txt             # Python dependencies
├── dev-loop.sh                  # Automated TDD loop script
├── app/
│   ├── __init__.py              # Makes app/ a Python package
│   ├── database.py              # Database connection and session setup
│   ├── main.py                  # FastAPI app entry point
│   ├── models.py                # Task data models (ORM + schemas)
│   └── routes.py                # API endpoints (CRUD operations)
└── tests/
    ├── __init__.py              # Makes tests/ a Python package
    └── test_tasks.py            # Test suite
```

---

## API Endpoints

| Method | Endpoint      | Description         |
| ------ | ------------- | ------------------- |
| GET    | `/`           | Welcome message     |
| GET    | `/tasks`      | List all tasks      |
| GET    | `/tasks/{id}` | Get a specific task |
| POST   | `/tasks`      | Create a new task   |
| PUT    | `/tasks/{id}` | Update a task       |
| DELETE | `/tasks/{id}` | Delete a task       |

---

## Troubleshooting

**`ModuleNotFoundError`** — Make sure your virtual environment is activated (you see `(.venv)` in your prompt).

**Port already in use** — Another process is using port 8000. Either stop it or run on a different port: `uvicorn app.main:app --reload --port 8001`
