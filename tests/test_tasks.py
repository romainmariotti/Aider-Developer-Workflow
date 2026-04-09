import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine, select
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
    """Test GET / returns welcome message when frontend doesn't exist"""
    response = client.get("/")
    assert response.status_code == 200
    # When frontend exists, it returns HTML; when it doesn't, it returns JSON
    # In test environment, frontend directory may not exist
    if response.headers.get("content-type", "").startswith("application/json"):
        assert response.json() == {"message": "Welcome to Task Manager API"}
    else:
        # Frontend HTML is served
        assert response.status_code == 200


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


def test_create_task_whitespace_only_spaces(client: TestClient):
    """Test POST /tasks with title containing only spaces returns 422"""
    task_data = {
        "title": "   ",
        "description": "should fail",
        "completed": False
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 422
    data = response.json()
    assert data["detail"] == "Title must be a non-empty string"


def test_create_task_whitespace_only_tabs(client: TestClient):
    """Test POST /tasks with title containing only tabs returns 422"""
    task_data = {
        "title": "\t\t\t",
        "description": "should fail",
        "completed": False
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 422
    data = response.json()
    assert data["detail"] == "Title must be a non-empty string"


def test_create_task_whitespace_mixed(client: TestClient):
    """Test POST /tasks with mixed whitespace returns 422"""
    task_data = {
        "title": " \t \n ",
        "description": "should fail",
        "completed": False
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 422
    data = response.json()
    assert data["detail"] == "Title must be a non-empty string"


def test_create_task_empty_string(client: TestClient):
    """Test POST /tasks with empty string title returns 422"""
    task_data = {
        "title": "",
        "description": "should fail",
        "completed": False
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 422
    data = response.json()
    assert data["detail"] == "Title must be a non-empty string"


def test_create_task_single_space(client: TestClient):
    """Test POST /tasks with single space returns 422"""
    task_data = {
        "title": " ",
        "description": "should fail",
        "completed": False
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 422
    data = response.json()
    assert data["detail"] == "Title must be a non-empty string"


def test_create_task_valid_with_surrounding_whitespace(client: TestClient):
    """Test POST /tasks with valid title containing surrounding whitespace succeeds"""
    task_data = {
        "title": "  valid task  ",
        "description": "should succeed",
        "completed": False
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "  valid task  "
    assert data["description"] == "should succeed"
    assert data["completed"] is False
    assert "id" in data


def test_create_task_no_database_entry_on_validation_failure(client: TestClient, session: Session):
    """Test that no task is created in database when validation fails"""
    # Get initial task count
    initial_tasks = session.exec(select(Task)).all()
    initial_count = len(initial_tasks)
    
    # Attempt to create task with whitespace-only title
    task_data = {
        "title": "   ",
        "description": "should not be created",
        "completed": False
    }
    response = client.post("/tasks", json=task_data)
    assert response.status_code == 422
    
    # Verify no new task was created
    final_tasks = session.exec(select(Task)).all()
    final_count = len(final_tasks)
    assert final_count == initial_count


def test_search_tasks_success(client: TestClient, session: Session):
    """Test GET /tasks/search returns matching tasks"""
    # Create test tasks with various titles
    task1 = Task(title="Buy groceries", description="Get milk and bread")
    task2 = Task(title="buy milk", description="From the store")
    task3 = Task(title="BUYING supplies", description="Office supplies")
    task4 = Task(title="Sell old items", description="Garage sale")
    session.add(task1)
    session.add(task2)
    session.add(task3)
    session.add(task4)
    session.commit()

    response = client.get("/tasks/search?title=buy")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 3
    titles = [task["title"] for task in data]
    assert "Buy groceries" in titles
    assert "buy milk" in titles
    assert "BUYING supplies" in titles
    assert "Sell old items" not in titles


def test_search_tasks_case_insensitive(client: TestClient, session: Session):
    """Test search is case-insensitive"""
    task = Task(title="Task Management", description="Manage tasks")
    session.add(task)
    session.commit()

    # Search with different cases
    response1 = client.get("/tasks/search?title=task")
    response2 = client.get("/tasks/search?title=TASK")
    response3 = client.get("/tasks/search?title=TaSk")
    
    assert response1.status_code == 200
    assert response2.status_code == 200
    assert response3.status_code == 200
    
    assert len(response1.json()) == 1
    assert len(response2.json()) == 1
    assert len(response3.json()) == 1
    
    assert response1.json()[0]["title"] == "Task Management"


def test_search_tasks_partial_match(client: TestClient, session: Session):
    """Test search supports partial matching"""
    task = Task(title="Buy groceries from the store", description="Shopping")
    session.add(task)
    session.commit()

    # Search with substring
    response = client.get("/tasks/search?title=gro")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["title"] == "Buy groceries from the store"


def test_search_tasks_empty_results(client: TestClient, session: Session):
    """Test search returns empty array when no matches found"""
    task = Task(title="Existing Task", description="Some task")
    session.add(task)
    session.commit()

    response = client.get("/tasks/search?title=xyz123notfound")
    assert response.status_code == 200
    data = response.json()
    assert data == []


def test_search_tasks_missing_title(client: TestClient):
    """Test search returns 422 when title parameter is missing"""
    response = client.get("/tasks/search")
    assert response.status_code == 422
    data = response.json()
    assert "detail" in data


def test_search_tasks_empty_title(client: TestClient):
    """Test search returns 422 when title is empty string"""
    response = client.get("/tasks/search?title=")
    assert response.status_code == 422
    data = response.json()
    assert data["detail"] == "Title parameter must be a non-empty string"


def test_search_tasks_whitespace_title(client: TestClient):
    """Test search returns 422 when title contains only whitespace"""
    response = client.get("/tasks/search?title=%20%20%20")
    assert response.status_code == 422
    data = response.json()
    assert data["detail"] == "Title parameter must be a non-empty string"
