from typing import List
from fastapi import APIRouter, HTTPException, Depends, Query
from sqlmodel import Session, select, col

from app.models import Task, TaskCreate, TaskUpdate
from app.database import get_session


router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("", response_model=List[Task])
def get_tasks(session: Session = Depends(get_session)):
    """Get all tasks"""
    tasks = session.exec(select(Task)).all()
    return tasks


@router.get("/search", response_model=List[Task])
def search_tasks(title: str = Query(...), session: Session = Depends(get_session)):
    """Search tasks by title with partial, case-insensitive matching"""
    # Validate title is not empty or whitespace-only
    if not title or not title.strip():
        raise HTTPException(
            status_code=422, 
            detail="Title parameter must be a non-empty string"
        )
    
    # Perform case-insensitive partial match search
    search_pattern = f"%{title}%"
    statement = select(Task).where(col(Task.title).ilike(search_pattern))
    tasks = session.exec(statement).all()
    return tasks


@router.get("/{task_id}", response_model=Task)
def get_task(task_id: int, session: Session = Depends(get_session)):
    """Get a specific task by ID"""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@router.post("", response_model=Task, status_code=201)
def create_task(task_data: TaskCreate, session: Session = Depends(get_session)):
    """Create a new task"""
    # Validate title is not empty or whitespace-only
    if not task_data.title or not task_data.title.strip():
        raise HTTPException(
            status_code=422,
            detail="Title must be a non-empty string"
        )
    
    task = Task.model_validate(task_data)
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@router.put("/{task_id}", response_model=Task)
def update_task(task_id: int, task_data: TaskUpdate, session: Session = Depends(get_session)):
    """Update an existing task"""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    task.title = task_data.title
    task.description = task_data.description
    task.completed = task_data.completed
    
    session.add(task)
    session.commit()
    session.refresh(task)
    return task


@router.post("/{task_id}/duplicate", response_model=Task, status_code=201)
def duplicate_task(task_id: int, session: Session = Depends(get_session)):
    """Duplicate an existing task"""
    # Get the original task
    original_task = session.get(Task, task_id)
    if not original_task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Create a new task with modified fields
    new_task = Task(
        title=original_task.title + " (copy)",
        description=original_task.description,
        completed=False
    )
    
    session.add(new_task)
    session.commit()
    session.refresh(new_task)
    return new_task


@router.post("/{task_id}/duplicate", response_model=Task, status_code=201)
def duplicate_task(task_id: int, session: Session = Depends(get_session)):
    """Duplicate an existing task"""
    # Get the original task
    original_task = session.get(Task, task_id)
    if not original_task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    # Create a new task with modified fields
    new_task = Task(
        title=original_task.title + " (copy)",
        description=original_task.description,
        completed=False
    )
    
    session.add(new_task)
    session.commit()
    session.refresh(new_task)
    return new_task


@router.delete("/{task_id}", status_code=204)
def delete_task(task_id: int, session: Session = Depends(get_session)):
    """Delete a task"""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    session.delete(task)
    session.commit()
    return None
