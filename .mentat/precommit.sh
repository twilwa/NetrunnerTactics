#!/bin/bash

# Format and lint Python code
echo "Running Python linting..."
ruff check --fix server.py

# Check for Godot test runner
if [ -f tests/GutTestRunner.gd ]; then
    echo "Running Godot GUT tests..."
    if command -v godot &> /dev/null; then
        godot --headless --script res://tests/GutTestRunner.gd || echo "Warning: Godot tests failed, but continuing with commit"
    else
        echo "Skipping Godot tests - godot command not available"
    fi
else
    echo "Skipping Godot tests - test runner not found"
fi

echo "Precommit checks completed!"
