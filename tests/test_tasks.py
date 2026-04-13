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


def test_duplicate_task_success(client: TestClient, session: Session):
    """Test POST /tasks/{id}/duplicate creates a new task and returns 201"""
    # Create original task
    original = Task(title="Original Task", description="Original Description", completed=True)
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    # Verify new task has different id
    assert data["id"] != original.id
    assert "id" in data
    
    # Verify title has " (copy)" suffix
    assert data["title"] == "Original Task (copy)"
    
    # Verify description is copied
    assert data["description"] == "Original Description"
    
    # Verify completed is false
    assert data["completed"] is False
    
    # Verify created_at exists
    assert "created_at" in data


def test_duplicate_task_different_id(client: TestClient, session: Session):
    """Test duplicated task has different id from original"""
    original = Task(title="Test Task", description="Test")
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    assert data["id"] != original.id


def test_duplicate_task_title_suffix(client: TestClient, session: Session):
    """Test duplicated task title has ' (copy)' suffix appended"""
    original = Task(title="My Task", description="Description")
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    assert data["title"] == "My Task (copy)"


def test_duplicate_task_description_copied(client: TestClient, session: Session):
    """Test duplicated task has same description as original"""
    original = Task(title="Task", description="Important details here")
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    assert data["description"] == "Important details here"


def test_duplicate_task_completed_false(client: TestClient, session: Session):
    """Test duplicated task has completed set to false even if original was true"""
    original = Task(title="Completed Task", description="Done", completed=True)
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    assert data["completed"] is False


def test_duplicate_task_new_timestamp(client: TestClient, session: Session):
    """Test duplicated task has valid created_at timestamp"""
    original = Task(title="Task", description="Test")
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    assert "created_at" in data
    # Verify it's a valid timestamp string
    from datetime import datetime
    datetime.fromisoformat(data["created_at"].replace('Z', '+00:00'))


def test_duplicate_task_not_found(client: TestClient):
    """Test POST /tasks/{id}/duplicate returns 404 for non-existent task"""
    response = client.post("/tasks/999/duplicate")
    assert response.status_code == 404
    assert response.json() == {"detail": "Task not found"}


def test_duplicate_task_null_description(client: TestClient, session: Session):
    """Test duplicating task with null description works correctly"""
    original = Task(title="Task without description", description=None)
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    assert data["description"] is None


def test_duplicate_task_original_unchanged(client: TestClient, session: Session):
    """Test that original task is not modified after duplication"""
    original = Task(title="Original", description="Original Desc", completed=True)
    session.add(original)
    session.commit()
    session.refresh(original)
    original_id = original.id
    
    response = client.post(f"/tasks/{original_id}/duplicate")
    assert response.status_code == 201
    
    # Verify original task is unchanged
    session.expire_all()
    original_after = session.get(Task, original_id)
    assert original_after.title == "Original"
    assert original_after.description == "Original Desc"
    assert original_after.completed is True


def test_duplicate_task_both_in_database(client: TestClient, session: Session):
    """Test that database contains both original and duplicate after operation"""
    original = Task(title="Task", description="Desc")
    session.add(original)
    session.commit()
    session.refresh(original)
    original_id = original.id
    
    response = client.post(f"/tasks/{original_id}/duplicate")
    assert response.status_code == 201
    duplicate_id = response.json()["id"]
    
    # Verify both tasks exist in database
    session.expire_all()
    all_tasks = session.exec(select(Task)).all()
    task_ids = [task.id for task in all_tasks]
    
    assert original_id in task_ids
    assert duplicate_id in task_ids
    assert len([t for t in all_tasks if t.id in [original_id, duplicate_id]]) == 2


def test_duplicate_task_already_copy(client: TestClient, session: Session):
    """Test duplicating a task that was already a copy appends another suffix"""
    original = Task(title="Task (copy)", description="Already a copy")
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    assert data["title"] == "Task (copy) (copy)"


def test_duplicate_task_long_title(client: TestClient, session: Session):
    """Test duplicating a task with a very long title still appends suffix"""
    long_title = "A" * 200
    original = Task(title=long_title, description="Test")
    session.add(original)
    session.commit()
    session.refresh(original)
    
    response = client.post(f"/tasks/{original.id}/duplicate")
    assert response.status_code == 201
    data = response.json()
    
    assert data["title"] == long_title + " (copy)"
