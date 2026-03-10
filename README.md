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

> **Windows users:** Use `.venv\Scripts\activate` instead.

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

## Running Tests

```bash
pytest tests/ -v
```

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

---

## Project Structure

```
Aider-Developer-Workflow/
├── .aider.conf.yml          # Aider config (model, language, settings)
├── .env                     # API key (create locally, not in Git)
├── .env.example             # Template for .env
├── .gitignore               # Files excluded from Git
├── requirements.txt         # Python dependencies
├── app/
│   ├── __init__.py          # Makes app/ a Python package
│   ├── database.py          # Database connection and session setup
│   ├── main.py              # FastAPI app entry point
│   ├── models.py            # Task data models (ORM + schemas)
│   └── routes.py            # API endpoints (CRUD operations)
└── tests/
    ├── __init__.py          # Makes tests/ a Python package
    └── test_tasks.py        # Test suite
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Welcome message |
| GET | `/tasks` | List all tasks |
| GET | `/tasks/{id}` | Get a specific task |
| POST | `/tasks` | Create a new task |
| PUT | `/tasks/{id}` | Update a task |
| DELETE | `/tasks/{id}` | Delete a task |

---

## Troubleshooting

**`ModuleNotFoundError`** — Make sure your virtual environment is activated (you see `(.venv)` in your prompt).

**Port already in use** — Another process is using port 8000. Either stop it or run on a different port: `uvicorn app.main:app --reload --port 8001`
