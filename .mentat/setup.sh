#!/bin/bash

# Install Python dependencies
pip3 install -r requirements.txt 2>/dev/null || { 
  echo "No requirements.txt found, installing from pyproject.toml"
  # Install dependencies without version specifiers to avoid issues
  pip3 install psycopg2-binary replit
}

# Install Python development tools for precommit
pip3 install ruff

# Check if Godot executable is available
if ! command -v godot &> /dev/null; then
    echo "Godot executable not found. Godot is required for running tests."
    echo "Please install Godot manually and ensure it's in your PATH."
fi

echo "Note: The server.py script requires a PostgreSQL database. Make sure it's configured in your environment."
echo "Setup completed successfully!"
