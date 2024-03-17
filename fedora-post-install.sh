#!/bin/bash
echo -e "\n##########################################################\n"
echo -e "⟶ Tweaking DNF\n"

# Tweak dnf settings for optimization
dnf_settings=(
    "fastestmirror=True"
    "max_parallel_downloads=20"
    "defaultyes=True"
)

dnf_conf_file="/etc/dnf/dnf.conf"

# Loop through the array and add settings if they don't exist
for setting in "${dnf_settings[@]}"; do
    if ! grep -q "^$setting" "$dnf_conf_file"; then
        echo "$setting" >> "$dnf_conf_file"
        echo "Added setting: $setting"
    else
        echo "Setting already exists: $setting"
    fi
done

echo -e "➔ Now, let's update the system, here we go!\n"

# Make sure system is up to date
sudo dnf -y update
sudo dnf -y upgrade --refresh

echo -e "\n➔ Distro updated and upgraded. Boom!\n"

echo -e "➔ Let the software installation extravaganza commence!\n"

# Import rpm's key and repository for vscode and update
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf update --refresh

# Install software
sudo dnf -y install fastfetch gnome-tweaks steam-devices code

echo -e "\n ➔The software arsenal just got a powerful boost.\n"

echo -e "➔ Time to bid farewell to some software.\n"

# remove software
sudo dnf -y remove totem rhythmbox gnome-tour yelp simple-scan

echo -e "\n➔ Going, going...gone!\n"

echo -e "➔ Let's install some must-have flatpaks!\n"

# Check for flathub remote
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Define the list of Flatpak applications to check and install
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

# Loop through the list of Flatpak applications
for flatpak_name in "${must_have_flatpaks[@]}"; do
    # Check if the Flatpak application is installed
    if ! flatpak list --app --columns=application | grep -q "$flatpak_name"; then
        echo "➔ Flatpak $flatpak_name is not installed. Installing..."
        flatpak install flathub "$flatpak_name" -y
        need_installation=true
    fi
done

# Add fastfetch in .bashrc
if ! grep -Fxq "fastfetch" "$HOME/.bashrc"; then
    echo "fastfetch" >> "$HOME/.bashrc"
fi

echo -e "➔ You did it, like a boss! High-fives and victory dances are now in order.\n"
echo -e "##########################################################\n"