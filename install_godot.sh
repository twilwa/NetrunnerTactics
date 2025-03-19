#!/bin/bash

# Script to download and install Godot engine for the project

# Create the binary directory
mkdir -p ~/.local/bin

# Output directory for downloaded files
mkdir -p godot_bin

# Download Godot 4.4 (headless version)
echo "Downloading Godot 4.4 headless version..."
wget -O godot_bin/godot_headless.zip "https://github.com/godotengine/godot/releases/download/4.4-stable/Godot_v4.4-stable_linux_headless.64.zip"

# Unzip the download
echo "Extracting Godot..."
unzip -o godot_bin/godot_headless.zip -d godot_bin

# Move the binary to a standard location
echo "Installing Godot to ~/.local/bin..."
cp godot_bin/Godot_v4.4-stable_linux_headless.64 ~/.local/bin/godot
chmod +x ~/.local/bin/godot

# Clean up
echo "Cleaning up..."
rm -f godot_bin/godot_headless.zip

echo "Godot 4.4 installed successfully!"