#!/bin/bash
echo "Setting up..."

# Create virtual environment
python3.12 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
  echo "Creating .env file..."
  cat <<EOL > .env
ANTHROPIC_API_KEY=your-api-key-here
EOL
  echo ".env file created. Please edit it with your actual API key."
else
  echo ".env file already exists, skipping creation."
fi

# Run the API
echo "Starting API with uvicorn..."
uvicorn app.main:app --reload &

# Start Aider on specific files
echo "Starting Aider on project files..."
aider app/main.py app/models.py app/routes.py app/database.py