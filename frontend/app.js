// API base URL - adjust if needed
const API_BASE_URL = '';

// DOM elements
const createTaskForm = document.getElementById('create-task-form');
const taskTitleInput = document.getElementById('task-title');
const taskDescriptionInput = document.getElementById('task-description');
const submitBtn = document.getElementById('submit-btn');
const titleError = document.getElementById('title-error');
const errorContainer = document.getElementById('error-container');
const tasksContainer = document.getElementById('tasks-container');
const taskCounter = document.getElementById('task-counter');
const clearAllBtn = document.getElementById('clear-all-btn');

// Initialize app
document.addEventListener('DOMContentLoaded', () => {
    loadTasks();
    createTaskForm.addEventListener('submit', handleCreateTask);
    clearAllBtn.addEventListener('click', handleClearAllTasks);
});

// Show error message
function showError(message) {
    errorContainer.textContent = message;
    errorContainer.style.display = 'block';
    setTimeout(() => {
        errorContainer.style.display = 'none';
    }, 5000);
}

// Clear error message
function clearError() {
    errorContainer.style.display = 'none';
    titleError.textContent = '';
}

// Update task counter
function updateTaskCounter(count) {
    taskCounter.textContent = `Tasks: ${count}`;
}

// Validate title
function validateTitle(title) {
    if (!title || !title.trim()) {
        titleError.textContent = 'Title must be a non-empty string';
        return false;
    }
    titleError.textContent = '';
    return true;
}

// Load all tasks
async function loadTasks() {
    try {
        const response = await fetch(`${API_BASE_URL}/tasks`);
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        const tasks = await response.json();
        renderTasks(tasks);
        updateTaskCounter(tasks.length);
    } catch (error) {
        console.error('Error loading tasks:', error);
        tasksContainer.innerHTML = '<p class="empty-state">Unable to connect to the API. Please try again later.</p>';
        updateTaskCounter(0);
    }
}

// Render tasks in the DOM
function renderTasks(tasks) {
    if (tasks.length === 0) {
        tasksContainer.innerHTML = '<p class="empty-state">No tasks yet. Create one to get started.</p>';
        return;
    }
    
    tasksContainer.innerHTML = tasks.map(task => createTaskHTML(task)).join('');
    
    // Attach event listeners
    tasks.forEach(task => {
        const checkbox = document.getElementById(`checkbox-${task.id}`);
        const duplicateBtn = document.getElementById(`duplicate-${task.id}`);
        const deleteBtn = document.getElementById(`delete-${task.id}`);
        
        checkbox.addEventListener('change', () => handleToggleComplete(task));
        duplicateBtn.addEventListener('click', () => handleDuplicateTask(task.id));
        deleteBtn.addEventListener('click', () => handleDeleteTask(task.id));
    });
}

// Create HTML for a single task
function createTaskHTML(task) {
    const createdDate = new Date(task.created_at).toLocaleString();
    const titleClass = task.completed ? 'task-title completed' : 'task-title';
    const description = task.description ? `<div class="task-description">${escapeHtml(task.description)}</div>` : '';
    
    return `
        <div class="task-item" id="task-${task.id}">
            <input 
                type="checkbox" 
                class="task-checkbox" 
                id="checkbox-${task.id}"
                ${task.completed ? 'checked' : ''}
            >
            <div class="task-content">
                <div class="${titleClass}">${escapeHtml(task.title)}</div>
                ${description}
                <div class="task-meta">Created: ${createdDate}</div>
            </div>
            <div class="task-actions">
                <button class="duplicate-btn" id="duplicate-${task.id}">Duplicate</button>
                <button class="delete-btn" id="delete-${task.id}">Delete</button>
            </div>
        </div>
    `;
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Handle create task form submission
async function handleCreateTask(event) {
    event.preventDefault();
    clearError();
    
    const title = taskTitleInput.value;
    const description = taskDescriptionInput.value;
    
    // Validate title
    if (!validateTitle(title)) {
        return;
    }
    
    // Disable submit button
    submitBtn.disabled = true;
    submitBtn.textContent = 'Creating...';
    
    try {
        const response = await fetch(`${API_BASE_URL}/tasks`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: title,
                description: description || null,
                completed: false
            })
        });
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.detail || `HTTP error! status: ${response.status}`);
        }
        
        const newTask = await response.json();
        
        // Clear form
        createTaskForm.reset();
        
        // Reload tasks
        await loadTasks();
        
    } catch (error) {
        console.error('Error creating task:', error);
        showError(error.message || 'Unable to create task. Please try again.');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Create Task';
    }
}

// Handle toggle task completion
async function handleToggleComplete(task) {
    const checkbox = document.getElementById(`checkbox-${task.id}`);
    const deleteBtn = document.getElementById(`delete-${task.id}`);
    
    // Disable controls during API call
    checkbox.disabled = true;
    deleteBtn.disabled = true;
    
    try {
        const response = await fetch(`${API_BASE_URL}/tasks/${task.id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: task.title,
                description: task.description,
                completed: !task.completed
            })
        });
        
        if (!response.ok) {
            if (response.status === 404) {
                throw new Error('Task not found');
            }
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        // Reload tasks to reflect changes
        await loadTasks();
        
    } catch (error) {
        console.error('Error toggling task:', error);
        showError(error.message || 'Unable to update task. Please try again.');
        
        // Revert checkbox state
        checkbox.checked = task.completed;
    } finally {
        checkbox.disabled = false;
        deleteBtn.disabled = false;
    }
}

// Handle duplicate task
async function handleDuplicateTask(taskId) {
    const duplicateBtn = document.getElementById(`duplicate-${taskId}`);
    const checkbox = document.getElementById(`checkbox-${taskId}`);
    const deleteBtn = document.getElementById(`delete-${taskId}`);
    
    // Disable controls during API call
    duplicateBtn.disabled = true;
    checkbox.disabled = true;
    deleteBtn.disabled = true;
    duplicateBtn.textContent = 'Duplicating...';
    
    try {
        const response = await fetch(`${API_BASE_URL}/tasks/${taskId}/duplicate`, {
            method: 'POST'
        });
        
        if (!response.ok) {
            if (response.status === 404) {
                throw new Error('Task not found');
            }
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        // Reload tasks to show the duplicate
        await loadTasks();
        
    } catch (error) {
        console.error('Error duplicating task:', error);
        showError(error.message || 'Unable to duplicate task. Please try again.');
        
        // Re-enable controls
        duplicateBtn.disabled = false;
        checkbox.disabled = false;
        deleteBtn.disabled = false;
        duplicateBtn.textContent = 'Duplicate';
    }
}

// Handle delete task
async function handleDeleteTask(taskId) {
    const deleteBtn = document.getElementById(`delete-${taskId}`);
    const checkbox = document.getElementById(`checkbox-${taskId}`);
    
    // Disable controls during API call
    deleteBtn.disabled = true;
    checkbox.disabled = true;
    deleteBtn.textContent = 'Deleting...';
    
    try {
        const response = await fetch(`${API_BASE_URL}/tasks/${taskId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            if (response.status === 404) {
                throw new Error('Task not found or already deleted');
            }
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        // Remove task from DOM
        const taskElement = document.getElementById(`task-${taskId}`);
        taskElement.remove();
        
        // Check if there are no more tasks
        if (tasksContainer.children.length === 0) {
            tasksContainer.innerHTML = '<p class="empty-state">No tasks yet. Create one to get started.</p>';
        }
        
    } catch (error) {
        console.error('Error deleting task:', error);
        showError(error.message || 'Unable to delete task. Please try again.');
        
        // Re-enable controls
        deleteBtn.disabled = false;
        checkbox.disabled = false;
        deleteBtn.textContent = 'Delete';
    }
}

// Handle clear all tasks
async function handleClearAllTasks() {
    // Show confirmation dialog
    const confirmed = confirm('Are you sure you want to delete all tasks?');
    if (!confirmed) {
        return;
    }
    
    // Disable button during API call
    clearAllBtn.disabled = true;
    clearAllBtn.textContent = 'Clearing...';
    
    try {
        const response = await fetch(`${API_BASE_URL}/tasks`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        
        // Reload tasks to show empty state
        await loadTasks();
        
    } catch (error) {
        console.error('Error clearing tasks:', error);
        showError(error.message || 'Unable to clear tasks. Please try again.');
    } finally {
        clearAllBtn.disabled = false;
        clearAllBtn.textContent = 'Clear all';
    }
}
