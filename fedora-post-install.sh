#!/bin/bash

# Set home folder.
# Change the value to match your home folder
user_home_folder=/home/user-name

# Define a list of Flatpaks to install
must_have_flatpaks=(
"org.gnome.Extensions"
"com.mattjakeman.ExtensionManager"
"org.signal.Signal"
"io.gitlab.librewolf-community"
"com.valvesoftware.Steam"
"com.spotify.Client"
"org.videolan.VLC"
"com.discordapp.Discord"
"com.bitwarden.desktop"
"io.github.peazip.PeaZip"
)

# Tweak dnf with these settings for optimization
dnf_settings=(
    "fastestmirror=True"
    "max_parallel_downloads=20"
    "defaultyes=True"
)

echo -e "\n##########################################################\n"

echo -e "⟹ Tweaking DNF\n"

# Loop through the array and add settings if they don't exist
dnf_conf_file="/etc/dnf/dnf.conf"
for setting in "${dnf_settings[@]}"; do
    if ! grep -q "^$setting" "$dnf_conf_file"; then
        echo "$setting" >> "$dnf_conf_file"
        echo "Added setting: $setting"
    else
        echo "Setting already exists: $setting"
    fi
done

echo -e "\n⟹ Now, let's update the system, here we go!\n"

# Make sure system is up to date
sudo dnf -y update
sudo dnf -y upgrade --refresh

echo -e "\n⟹ System updated and upgraded. Boom!\n"

echo -e "⟹ Let the software installation extravaganza commence!\n"

# Add repository and import rpm's key for vscode
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

# Add repository and import rpm's key for Brave Browser
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

sudo dnf update --refresh

# Install software
sudo dnf -y install dnf-plugins-core fastfetch gnome-tweaks steam-devices code brave-browser

echo -e "\n⟹ The software arsenal just got a powerful boost.\n"

echo -e "⟹ Time to bid farewell to some software.\n"

# remove software
sudo dnf -y remove totem rhythmbox gnome-tour yelp simple-scan

echo -e "\n⟹ Going, going...gone!\n"

echo -e "⟹ Let's install some must-have flatpaks!\n"

# Check/Add flathub remote
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Loop through the list of Flatpak applications
for flatpak_name in "${must_have_flatpaks[@]}"; do
    # Check if the Flatpak application is installed
    if ! flatpak list --app --columns=application | grep -q "$flatpak_name"; then
        echo "⟹ Flatpak $flatpak_name is not installed. Installing..."
        flatpak install flathub "$flatpak_name" -y
        need_installation=true
    fi
done

echo -e "\n⟹ Splashing the magic of fastfetch on your next terminal startup!\n"

# Add fastfetch in .bashrc
if ! grep -Fxq "fastfetch" "$user_home_folder/.bashrc"; then
    echo "fastfetch" >> "$user_home_folder/.bashrc"
fi

echo -e "\n⟹ You did it, like a boss! High-fives and victory dances are now in order.\n"

echo -e "##########################################################\n"
