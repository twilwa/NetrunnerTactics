#!/bin/bash

# Format and lint Python code
echo "Running Python linting..."
if [ -f server.py ]; then
    ruff check --fix server.py
else
    echo "server.py not found, skipping Python linting"
fi

# Skip Godot tests in precommit to avoid issues with headless environment
# These tests are likely run by the CI system
echo "Note: Godot tests are skipped in precommit script to avoid environment issues."
echo "Tests should be run manually or through CI."

echo "Precommit checks completed!"
