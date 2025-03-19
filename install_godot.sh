#!/bin/bash

# Create directories
mkdir -p ~/godot_4.4
mkdir -p ~/.local/bin

# Download Godot 4.4 headless version
echo "Downloading Godot 4.4 headless version..."
wget https://github.com/godotengine/godot-builds/releases/download/4.4-stable/Godot_v4.4-stable_linux_headless.64.zip -O godot_4.4_headless.zip

# Extract the archive
echo "Extracting archive..."
unzip -o godot_4.4_headless.zip -d ~/godot_4.4

# Make the binary executable
echo "Setting permissions..."
chmod +x ~/godot_4.4/Godot_v4.4-stable_linux_headless.64

# Create a symbolic link
echo "Creating symlink..."
ln -sf ~/godot_4.4/Godot_v4.4-stable_linux_headless.64 ~/.local/bin/godot

# Add local bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile
    export PATH="$HOME/.local/bin:$PATH"
fi

# Clean up
rm godot_4.4_headless.zip

echo "Godot 4.4 headless has been installed successfully!"
echo "Run 'godot' to start Godot 4.4 headless server"