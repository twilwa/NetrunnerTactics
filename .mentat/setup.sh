#!/bin/bash

# Install Python dependencies
pip3 install -r requirements.txt 2>/dev/null || { 
  echo "No requirements.txt found, installing from pyproject.toml"
  pip3 install psycopg2-binary>=2.9.10 replit>=4.1.1
}

# Install Python development tools for precommit
pip3 install ruff

# Check if Godot executable is available
if ! command -v godot &> /dev/null; then
    echo "Godot command not found, attempting to install..."
    if [ -f ./install_godot.sh ]; then
        bash ./install_godot.sh
    else
        echo "Warning: install_godot.sh not found. Please install Godot manually."
    fi
fi

echo "Note: The server.py script requires a PostgreSQL database. Make sure it's configured in your environment."
echo "Setup completed successfully!"
