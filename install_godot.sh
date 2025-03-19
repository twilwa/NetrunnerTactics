#!/bin/bash

# Create directories
mkdir -p ~/godot_4.4
mkdir -p ~/.local/bin

# Download Godot 4.2 headless version (more stable version)
echo "Downloading Godot 4.2 headless version..."
wget https://github.com/godotengine/godot/releases/download/4.2-stable/Godot_v4.2-stable_linux.x86_64.zip -O godot_4.2_linux.zip

# Extract the archive
echo "Extracting archive..."
unzip -o godot_4.2_linux.zip -d ~/godot_4.4

# Make the binary executable
echo "Setting permissions..."
chmod +x ~/godot_4.4/Godot_v4.2-stable_linux.x86_64

# Create a symbolic link
echo "Creating symlink..."
ln -sf ~/godot_4.4/Godot_v4.2-stable_linux.x86_64 ~/.local/bin/godot

# Add local bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile
    export PATH="$HOME/.local/bin:$PATH"
fi

# Clean up
rm godot_4.2_linux.zip

echo "Godot 4.2 has been installed successfully!"
echo "Run 'godot' to start Godot 4.2 server"