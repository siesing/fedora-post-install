#!/bin/bash
echo ""
echo -e "########################################################## \n"
echo -e "Let's go! \n"
echo -e "Tweaking dnf\n"

# tweak dnf
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf

echo ""
echo -e "DNF tweaked. Nailed it!\n"
echo -e "Time for a distro update, here we go!\n"
echo -e "##########################################################\n"

# Make sure system is up to date
sudo dnf -y update
sudo dnf -y upgrade --refresh

echo ""
echo -e "Distro updated and upgraded. Boom!\n"
echo -e "Let the software installation extravaganza commence!\n"

# install software
sudo dnf install -y p7zip p7zip-plugins unrar unzip neofetch kitty stacer wget gnome-tweak-tool 

echo ""
echo -e "The software arsenal just got a powerful boost.\n"
echo -e "Time to bid farewell to some software.\n"

# remove software
sudo dnf remove -y libreoffice* rhythmbox evolution

echo ""
echo -e "Going, going...gone!\n"
echo -e "Let's unleash the Flatpak frenzy!\n"

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

echo -e "Let's get those must-have flatpaks up and running!\n"

flatpak install -y flathub com.mattjakeman.ExtensionManager
flatpak install -y flathub org.signal.Signal
flatpak install -y flathub com.visualstudio.code
flatpak install -y flathub io.gitlab.librewolf-community
flatpak install -y flathub com.valvesoftware.Steam
flatpak install -y flathub org.gnome.Extensions
flatpak install -y flathub com.spotify.Client
flatpak install -y flathub org.videolan.VLC
flatpak install -y flathub com.discordapp.Discord

echo ""
echo -e "Flatpaks: installed and ready to rock!\n"
echo -e "Getting ready to unleash the magic of neofetch on your next terminal startup!\n"

# add neofetch in .bashrc
if ! grep -Fxq "neofetch" "$HOME/.bashrc"; then
    echo "neofetch" >> "$HOME/.bashrc"
fi

echo -e "You did it, like a boss! High-fives and victory dances are now in order.\n"
