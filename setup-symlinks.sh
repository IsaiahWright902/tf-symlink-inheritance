#!/bin/bash
# Setup symlinks from _base/ to all environment folders

# Loop through all directories except _base
for env_dir in */; do
    # Skip _base directory
    if [ "$env_dir" = "_base/" ]; then
        continue
    fi

    echo "Setting up symlinks in $env_dir"

    # Symlink each .tf file from _base
    for base_file in _base/*.tf; do
        filename=$(basename "$base_file")
        ln -sf "../_base/$filename" "$env_dir$filename"
    done
done

echo "Done!"
