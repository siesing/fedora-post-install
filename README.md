# fedora-post-install

Life is not always the way we want it to be, but at least your Fedora distro can be.

Voilà! My ideal post-install Fedora setup awaits you, fresh out of the digital oven. It's crafted to perfection, tailored to my needs, and ready to deliver an exceptional computing experience. Sit back, relax, and enjoy the wonders of my Fedora configuration.

> :heart: **Remember Sharing Is Caring**

## How to use

Clone, conquer, and make things happen! Get your hands on the repository like a pro,

```console
git clone https://github.com/siesing/fedora-post-install.git
```

then sprinkle some magic dust on the `fedora-post-install.sh` file with a little command called `chmod +x`.

```console
chmod +x fedora-post-install.sh
```

Before kicking off the script, make sure to ajust the variable "user_home_folder" to match your home folder.

Optionally: Feel free to swap out all those packages and flatpaks to fit your vibe. After all, your digital kingdom should reflect your style, not mine.

Now give that script a high-five and hit the runway by running it like there's no tomorrow.

```console
sudo ./fedora-post-install.sh
```

This script performs a symphony of digital wonders—a thrilling ride as it optimizes the speed of the package manager, updates Fedora, installs essential software, bids farewell to the unnecessary software, sets up the Flathub repository, installs must-have Flatpaks, and adds a touch of enchantment to the Terminal with the mesmerizing `fastfetch`.

## Setup Btrfs Snapshots with Snapper

Ready to add time-travel capabilities to your Fedora system? :rocket: Behold the magnificent `setup-snapper.sh` - your personal DeLorean for system snapshots!

Never again fear the dreaded system updates or experimental package installations. With Snapper at your command, you'll have the power to roll back time itself! Experience the zen of knowing that every system change can be undone with the grace of a digital time wizard.

First, bestow upon the script the ancient powers of executability:

```console
chmod +x setup-snapper.sh
```

Then, with the confidence of a thousand sys admins, unleash the snapshot sorcery:

```console
sudo ./setup-snapper.sh
```

This mystical script will:
- :camera: Configure automatic snapshots before and after every DNF transaction
- :clock1: Set up hourly timeline snapshots (because why not?)
- :boot: Integrate snapshots into your GRUB menu for emergency time travel
- :sparkles: Install the beautiful Btrfs Assistant GUI for point-and-click snapshot management
- :shield: Keep your last 5 kernels safe (because rolling back with missing kernels is no fun)

Remember: While snapshots are magical, they're not a replacement for proper backups! Keep your precious data safe with an external backup strategy too. :floppy_disk:

## Install Nerd Fonts

If you also want to embrace the geek and indulge in the irresistible allure of Nerd Fonts! Feast your eyes on `install-nerd-fonts.sh`, your gateway to fontastic greatness.

Discover the wonders of Nerd Fonts at [nerdfonts.com](https://www.nerdfonts.com/) and pick your typographic soulmate. From Fira Code's elegance to JetBrains Mono's sophistication, the possibilities are endless. Your text will never be boring again!

Pick your own favs or go with mine below. :point_down:

```console
declare -a fonts=(
    FiraCode
    JetBrainsMono
    Mononoki
    Ubuntu
    UbuntuMono
)
```

then sprinkle some more magic dust on the `install-nerd-fonts.sh` file with the command `chmod +x`.

```console
chmod +x install-nerd-fonts.sh
```

Sit back, relax, and let the magic unfold! Run the script, and watch as the enchanting Nerd Fonts effortlessly weave their way into your system.

```console
./install-nerd-fonts.sh
```

Kudos for choosing the efficient path to digital bliss! :beer: