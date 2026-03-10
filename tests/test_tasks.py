import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine
from sqlmodel.pool import StaticPool

from app.main import app
from app.database import get_session
from app.models import Task


@pytest.fixture(name="session")
def session_fixture():
    """Create a fresh test database for each test"""
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


@pytest.fixture(name="client")
def client_fixture(session: Session):
    """Create a test client with overridden database session"""
    def get_session_override():
        return session

    app.dependency_overrides[get_session] = get_session_override
    client = TestClient(app)
    yield client
    app.dependency_overrides.clear()


def test_read_root(client: TestClient):
    """Test GET / returns welcome message"""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to Task Manager API"}


def test_create_task(client: TestClient):
    """Test POST /tasks creates a task and returns 201"""
    task_data = {
        "title": "Test Task",
        "description": "Test Description",
        "completed": False
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Task"
    assert data["description"] == "Test Description"
    assert data["completed"] is False
    assert "id" in data
    assert "created_at" in data


def test_get_tasks(client: TestClient, session: Session):
    """Test GET /tasks returns a list of tasks"""
    # Create some test tasks
    task1 = Task(title="Task 1", description="Description 1")
    task2 = Task(title="Task 2", description="Description 2", completed=True)
    session.add(task1)
    session.add(task2)
    session.commit()

    response = client.get("/tasks")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["title"] == "Task 1"
    assert data[1]["title"] == "Task 2"
    assert data[1]["completed"] is True


def test_get_task_by_id(client: TestClient, session: Session):
    """Test GET /tasks/{id} returns a specific task"""
    task = Task(title="Specific Task", description="Specific Description")
    session.add(task)
    session.commit()
    session.refresh(task)

    response = client.get(f"/tasks/{task.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == task.id
    assert data["title"] == "Specific Task"
    assert data["description"] == "Specific Description"


def test_get_task_not_found(client: TestClient):
    """Test GET /tasks/{id} returns 404 for non-existent task"""
    response = client.get("/tasks/999")
    assert response.status_code == 404
    assert response.json() == {"detail": "Task not found"}


def test_update_task(client: TestClient, session: Session):
    """Test PUT /tasks/{id} updates a task"""
    task = Task(title="Original Title", description="Original Description", completed=False)
    session.add(task)
    session.commit()
    session.refresh(task)

    update_data = {
        "title": "Updated Title",
        "description": "Updated Description",
        "completed": True
    }
    response = client.put(f"/tasks/{task.id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == task.id
    assert data["title"] == "Updated Title"
    assert data["description"] == "Updated Description"
    assert data["completed"] is True


def test_update_task_not_found(client: TestClient):
    """Test PUT /tasks/{id} returns 404 for non-existent task"""
    update_data = {
        "title": "Updated Title",
        "description": "Updated Description",
        "completed": True
    }
    response = client.put("/tasks/999", json=update_data)
    assert response.status_code == 404
    assert response.json() == {"detail": "Task not found"}


def test_delete_task(client: TestClient, session: Session):
    """Test DELETE /tasks/{id} deletes a task and returns 204"""
    task = Task(title="Task to Delete", description="Will be deleted")
    session.add(task)
    session.commit()
    session.refresh(task)
    task_id = task.id

    response = client.delete(f"/tasks/{task_id}")
    assert response.status_code == 204

    # Verify task is deleted
    deleted_task = session.get(Task, task_id)
    assert deleted_task is None


def test_delete_task_not_found(client: TestClient):
    """Test DELETE /tasks/{id} returns 404 for non-existent task"""
    response = client.delete("/tasks/999")
    assert response.status_code == 404
    assert response.json() == {"detail": "Task not found"}
