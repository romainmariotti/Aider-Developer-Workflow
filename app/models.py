from datetime import UTC, datetime
from typing import Optional
from sqlmodel import Field, SQLModel


class Task(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str
    description: Optional[str] = None
    completed: bool = False
    created_at: datetime = Field(default_factory=lambda: datetime.now(UTC))


class TaskCreate(SQLModel):
    title: str
    description: Optional[str] = None
    completed: bool = False


class TaskUpdate(SQLModel):
    title: str
    description: Optional[str] = None
    completed: bool
