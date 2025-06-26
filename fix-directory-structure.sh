#!/bin/bash

echo "=== Fixing Directory Structure ==="

# Check if nested Redis_demo directory exists
if [ -d "Redis_demo" ]; then
    echo "Found nested Redis_demo directory. This can cause confusion."
    echo "The nested directory appears to be a duplicate. Removing it..."
    
    # Create backup first
    if [ ! -d "backup_nested_dir" ]; then
        echo "Creating backup of nested directory..."
        cp -r Redis_demo backup_nested_dir
        echo "Backup created at: backup_nested_dir"
    fi
    
    # Remove the nested directory
    rm -rf Redis_demo
    echo "Nested Redis_demo directory removed."
else
    echo "No nested directory structure found. Directory structure is clean."
fi

# Check for any .DS_Store files and remove them
echo "Cleaning up .DS_Store files..."
find . -name ".DS_Store" -type f -delete 2>/dev/null || true

echo "Directory structure cleanup completed!"
