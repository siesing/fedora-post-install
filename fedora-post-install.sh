#!/bin/bash
echo ""
echo -e "########################################################## \n"
echo -e "Tweaking DNF\n"

# tweak dnf
if grep -q '^max_parallel_downloads=10$' /etc/dnf/dnf.conf; then
    echo -e "Whoa, hold your horses! The configuration gods have already fixed it.\n"
else
    echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf
    echo -e "Setting added to DNF.\n"
fi

echo -e "##########################################################\n"
echo -e "Time for a distro update, here we go!\n"
echo -e "##########################################################\n"

# Make sure system is up to date
sudo dnf -y update
sudo dnf -y upgrade --refresh

echo ""
echo -e "Distro updated and upgraded. Boom!\n"
echo -e "##########################################################\n"
echo -e "Let the software installation extravaganza commence!\n"
echo -e "##########################################################\n"

# add rpm's key and repository for vscode and update
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf update --refresh

# install software
sudo dnf install -y p7zip p7zip-plugins unrar unzip neofetch wget gnome-tweak-tool steam-devices code

echo ""
echo -e "The software arsenal just got a powerful boost.\n"
echo -e "##########################################################\n"
echo -e "Time to bid farewell to some software.\n"
echo -e "##########################################################\n"

# remove software
sudo dnf remove -y libreoffice* rhythmbox evolution

echo ""
echo -e "Going, going...gone!\n"
echo -e "##########################################################\n"
echo -e "Let's unleash the Flatpak frenzy!\n"
echo -e "##########################################################\n"

# Check if Flathub remote is added to Fedora
# Run flatpak remote-list command to get the list of remotes
remotes=$(flatpak remote-list)

# Check if Flathub remote is present in the list
if [[ $remotes =~ "flathub" ]]; then
    echo -e "Flathub remote already in place.\n"
else
    echo "Adding Flathub remote to Fedora."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo -e "Flathub remote added.\n"
fi

echo -e "##########################################################\n"
echo -e "Let's get those must-have flatpaks up and running!\n"
echo -e "##########################################################\n"

flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub org.signal.Signal
flatpak install -y flathub io.gitlab.librewolf-community
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub org.gnome.Extensions
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub org.videolan.VLC
flatpak install -y flathub com.discordapp.Discord
flatpak install -y flathub com.bitwarden.desktop

echo ""
echo -e "Flatpaks: installed and ready to rock!\n"
echo -e "##########################################################\n"
echo -e "Splashing the magic of neofetch on your next terminal startup!\n"
echo -e "##########################################################\n"

# add neofetch in .bashrc
if ! grep -Fxq "neofetch" "$HOME/.bashrc"; then
    echo "neofetch" >> "$HOME/.bashrc"
fi

echo -e "You did it, like a boss! High-fives and victory dances are now in order.\n"
