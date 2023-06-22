#!/bin/bash

# Set the owner and repository name of the GitHub project
OWNER="ryanoasis"
REPO="nerd-fonts"

# Declare an array of font names to download
declare -a fonts=(
    FiraCode
    JetBrainsMono
    Mononoki
    Ubuntu
    UbuntuMono
)

# Set the directory where the fonts will be installed
fonts_dir="${HOME}/.local/share/fonts"

# Get the latest release information
response=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest")

# Extract the tag_name field from the response using awk
latest_version=$(echo "$response" | awk -F'"' '/tag_name/ {print $4}')

# Create the fonts directory if it doesn't exist
if [[ ! -d "$fonts_dir" ]]; then
    mkdir -p "$fonts_dir"
fi

# Loop through each font in the array and download it
for font in "${fonts[@]}"; do
    zip_file="${font}.zip"
    
    download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${latest_version}/${zip_file}"
    echo "Downloading $download_url"
    wget "$download_url"

    # Extract the contents of the downloaded zip file to the fonts_dir.
    unzip "$zip_file" -d "$fonts_dir"
    
    # Remove the downloaded zip file to clean up the directory.
    rm "$zip_file"
done

# Remove any Windows-compatible font files from the fonts directory
find "$fonts_dir" -name '*Windows Compatible*' -delete

# Refresh the font cache
fc-cache -fv
