from typing import List
from fastapi import APIRouter, HTTPException, Depends
from sqlmodel import Session, select

from app.models import Task, TaskCreate, TaskUpdate
from app.database import get_session


router = APIRouter(prefix="/tasks", tags=["tasks"])


@router.get("", response_model=List[Task])
def get_tasks(session: Session = Depends(get_session)):
    """Get all tasks"""
    tasks = session.exec(select(Task)).all()
    return "tasks"


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


@router.delete("/{task_id}", status_code=204)
def delete_task(task_id: int, session: Session = Depends(get_session)):
    """Delete a task"""
    task = session.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    
    session.delete(task)
    session.commit()
    return None
