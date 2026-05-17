#!/bin/bash

select_disk() {
    local disks
    local disk_list=()
    local i=1

    disks=$(lsblk -d -n -o NAME,TYPE,SIZE,MODEL | grep -E 'disk|raid' | grep -v "loop")
    if [ -z "$disks" ]; then
        echo "Disks not found!"
        exit 1
    fi

    while IFS= read -r line; do
        disk_list+=("$line")
        ((i++))
    done <<< "$disks"

    local choice
    while true; do
        echo -e "\n--- Choice disk (1-$i):---"
        echo "0 - cancel, $i - view all disks."
        read choice

        case $choice in
            0)
                echo "Cancel."
                exit 1
                ;;
            "$i")
                echo "========="
                echo "$disks"
                echo "========="
                continue
                ;;
            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
                    selected_disk_info="${disk_list[$((choice-1))]}"
                    selected_disk=$(echo "$selected_disk_info" | awk '{print $1}')
                    if [[ ! "$selected_disk" =~ ^/dev/ ]]; then
                        selected_disk="/dev/$selected_disk"
                    fi

                    echo -e "\n--- Selected disk: $selected_disk. ---"
                    return 0
                else
                    echo "No disk selected, please select from 0 to $i."
                fi
                ;;
        esac
    done
}

confirm_selection() {
    local disk="$1"
    echo "Warning!! all data on $disk will be deleted."
    echo "Enter YES for continue."

    local confirm
    read confirm
    if [ "$confirm" = "YES" ]; then
        return 0
    else
        echo "Cancel."
        return 1
    fi
}

partition_disk() {
    local disk="$1"
    echo -e "\n--- Preparation disk partition ---"
    local disk_scheme

    echo "0 - Cancel."
    echo "1 - (1G efi,4G swap,40 mnt,ALL home)."
    echo "2 - LVM (1G efi,4G swap,30 mnt,ALL home)."

    read disk_scheme
    case $disk_scheme in
        0)
            echo "Cancel."
            return 1
            ;;
        1)
            echo -e "\n--- Please wait until the partition preparation is complete. ---"
            umount "$disk" 2>/dev/null || true
            vgchange -an --noudevsync vg0 2>/dev/null
            wipefs -a "$disk" || exit 1
            dd if=/dev/zero of="$disk" bs=512 count=2048 conv=fsync || exit 1

            parted --script "$disk" mklabel gpt || exit 1
            parted --script "$disk" mkpart fat32 1MiB 1025MiB || exit 1
            parted --script "$disk" set 1 esp on || exit 1
            parted --script "$disk" mkpart linux-swap 1025MiB 5121MiB || exit 1
            parted --script "$disk" set 2 swap on || exit 1
            parted --script "$disk" mkpart ext4 5121MiB 40GiB || exit 1
            parted --script "$disk" mkpart ext4 40GiB 100% || exit 1

            sync && sleep 4
            partprobe "$disk" && sleep 1

            if [ ! -b "${disk}1" ] || [ ! -b "${disk}2" ] || [ ! -b "${disk}3" ] || [ ! -b "${disk}4" ]; then
                echo "ERROR: Failed to create partitions."
                exit 1
            fi

            mkfs.fat -F32 "${disk}1" || exit 1
            mkswap "${disk}2" || exit 1
            swapon "${disk}2" || exit 1
            mkfs.ext4 -F "${disk}3" || exit 1
            mkfs.ext4 -F "${disk}4" || exit 1

            mount "${disk}3" /mnt || exit 1
            mkdir /mnt/home || exit 1
            mount "${disk}4" /mnt/home || exit 1
            ;;
        2)
            if ! command -v pvcreate &> /dev/null; then
                echo "Install LVM..."
                pacman -S --noconfirm lvm2

                if command -v lvm &> /dev/null; then
                    echo "LVM Installed."
                else
                    echo "Installation error LVM."
                    exit 1
                fi
            fi
            echo -e "\n--- Please wait until the partition preparation is complete. ---"
            umount "$disk" 2>/dev/null || true
            vgchange -an --noudevsync vg0 2>/dev/null
            wipefs -a "$disk" || exit 1
            dd if=/dev/zero of="$disk" bs=512 count=2048 conv=fsync || exit 1

            parted --script "$disk" mklabel gpt || exit 1
            parted --script "$disk" mkpart fat32 1MiB 1025MiB || exit 1
            parted --script "$disk" set 1 esp on || exit 1
            parted --script "$disk" mkpart LVM ext4 1025MiB 100% || exit 1
            parted --script "$disk" set 2 lvm on || exit 1

            sync && sleep 4
            partprobe "$disk" && sleep 1

            if [ ! -b "${disk}1" ] || [ ! -b "${disk}2" ]; then
                echo "Error: Failed to create partitions."
                exit 1
            fi

            pvcreate "${disk}2" || exit 1
            vgcreate vg0 "${disk}2" || exit 1
            lvcreate -L 4G vg0 -n swap || exit 1
            lvcreate -L 30G vg0 -n root || exit 1
            lvcreate -l 100%FREE vg0 -n home || exit 1

            mkfs.fat -F32 "${disk}1" || exit 1
            mkswap /dev/vg0/swap || exit 1
            swapon /dev/vg0/swap || exit 1
            mkfs.ext4 -F /dev/vg0/root || exit 1
            mkfs.ext4 -F /dev/vg0/home || exit 1

            mount /dev/vg0/root /mnt || exit 1
            mkdir /mnt/home || exit 1
            mount /dev/vg0/home /mnt/home || exit 1
            ;;
        *)
            echo "Cancel. Choice 0-2."
            return 1
            ;;
    esac
}

base_install() {
    local disk="$1"
    local vendor="unknown"
    if grep -qi "GenuineIntel" /proc/cpuinfo; then
        vendor="intel-ucode"
    elif grep -qi "AuthenticAMD" /proc/cpuinfo; then
        vendor="amd-ucode"
    else
        echo "Skip ucode."
        exit 0
    fi

    pacstrap -K /mnt base base-devel linux linux-headers linux-firmware lvm2 "$vendor" sudo nano || exit 1
    genfstab -U -p /mnt >> /mnt/etc/fstab

    cat > /mnt/chroot.sh <<'MNT_EOF'
    #!/bin/bash
    base_device=$(df -P / | awk 'NR==2 {sub(/[0-9]+$/, "", $1); print $1}')
    echo "$base_device"
    sleep 4

    echo "Enter root passowd:"
    passwd

    echo -e "\nEnter username"
    read username || exit 1
    useradd -m -g users -G wheel -s /bin/bash "$username" || exit 1
    passwd "$username"
    sed -i "/^root\s\+ALL=(ALL:ALL)\s\+ALL\$/a ${username} ALL=(ALL:ALL) ALL" /etc/sudoers
    pacman -Sy

    sed -i 's/^#en_US\.UTF-8/en_US.UTF-8/; s/^#ru_RU\.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
    hwclock --systohc --utc

    echo "Enter host name: (pc name)"
    read hostpc || exit 1
    echo "$hostpc" > /etc/hostname
    pacman -S --noconfirm networkmanager || exit 1
    systemctl enable NetworkManager || exit 1
    mkdir /boot/efi || exit 1
    mount -o uid=0,gid=0,fmask=0077,dmask=0077 "${base_device}1" /boot/efi || exit 1


    pacman -S --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
    grub-mkconfig -o /boot/grub/grub.cfg
    sed -i -e 's/^GRUB_TIMEOUT=.*$/GRUB_TIMEOUT=0/' -e 's/^GRUB_TIMEOUT_STYLE=.*$/GRUB_TIMEOUT_STYLE=hidden/' -e 's/^#*GRUB_DISABLE_OS_PROBER=.*$/GRUB_DISABLE_OS_PROBER=true/' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg

    cat > /home/$username/final.sh <<'FINAL_EOF'
#!/bin/bash

detect_gpu_vendor() {
    if command -v lspci &>/dev/null; then
        if lspci | grep -i "VGA\|3D\|Display" | grep -qi "nvidia"; then
            sudo pacman -S nvidia nvidia-utils lib32-nvidia-utils nvidia-settings
        elif lspci | grep -i "VGA\|3D\|Display" | grep -qi "amd\|radeon\|ati"; then
            sudo pacman -S --noconfirm mesa mesa-utils vulkan-radeon
        else
            echo "Unknown (lspci)"
        fi
    else
        echo "lspci not found."
    fi
}

install_i3() {
    sudo sed -i '/^#[[:space:]]*\[multilib\]$/{s/^#//; n; s/^#//}' /etc/pacman.conf
    sudo pacman -Sy
    sudo pacman -S --noconfirm xorg-server xorg-xinit xorg-setxkbmap xorg-xrandr xorg-xprop xorg-xinput xorg-xwd xdotool
    sudo pacman -S --noconfirm i3-wm i3status rofi
    sudo pacman -S --noconfirm lshw picom udisks2 udiskie unrar unzip ntfs-3g usbutils dosfstools cifs-utils cryptsetup polkit feh alacritty openssh git wget pavucontrol pipewire pipewire-pulse pipewire-alsa ly xdg-user-dirs playerctl ufw man-db man-pages qalculate-gtk imagemagick xclip cups cups-browsed system-config-printer emacs papers
    sudo pacman -S --noconfirm fcitx5 fcitx5-configtool fcitx5-gtk fcitx5-qt fcitx5-mozc

    sudo systemctl enable ufw
    sudo ufw enable
    sudo systemctl enable ly@tty1.service
    sudo usermod -aG audio,video,storage,render,disk $username

    sudo pacman -S --noconfirm lxappearance gtk3 gtk4 kvantum-qt5 qt5ct
    sudo pacman -S --noconfirm materia-gtk-theme adapta-gtk-theme papirus-icon-theme capitaine-cursors ttf-dejavu ttf-freefont ttf-liberation ttf-droid terminus-font noto-fonts noto-fonts-emoji ttf-ubuntu-font-family ttf-roboto ttf-roboto-mono noto-fonts-cjk

    show_menu() {
        echo "Please select one or more options (separated by spaces):"
        echo "1) Firefox"
        echo "2) Chromium"
        echo "3) File manager: thunar."
        echo "4) Steam, Spotify"
        echo "5) Media player: VLC"
        echo "6) Network tools: wireshark-qt traceroute nmap"
    }

    show_menu
    local user_input
    read -r user_input

    if [ -z "$user_input" ]; then
        echo "ERROR: no choice made"
        exit 1
    fi

    IFS=' ' read -ra choices <<< "$user_input"

    valid_choices=()

    for choice in "${choices[@]}"; do
        if [[ "$choice" =~ ^[1-6]$ ]]; then
            valid_choices+=("$choice")
        else
            echo "Warnings: '$choice' - invalid choice (valid numbers are 1-6)"
        fi
    done

    if [ ${#valid_choices[@]} -eq 0 ]; then
        echo "ERROR: No valid selections were made"
        exit 1
    fi

    unique_choices=($(echo "${valid_choices[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    echo ""
    echo "Your choice:"

    for choice in "${unique_choices[@]}"; do
        case $choice in
            1)
                echo "  - install Firefox"
                sudo pacman -S --noconfirm firefox
                ;;
            2)
                echo "  - install Chromium"
                sudo pacman -S --noconfirm chromium
                ;;
            3)
                echo "  - install File manager: thunar."
                sudo pacman -S --noconfirm thunar file-roller tumbler ffmpegthumbnailer thunar-archive-plugin thunar-volman
                ;;
            4)
                echo " - install Steam, Spotify "
                sudo pacman -S --noconfirm steam spotify-launcher
                ;;
            5)
                echo " - install VLC"
                sudo pacman -S --noconfirm vlc vlc-plugins-extra vlc-plugins-video-output vlc-plugin-x264 vlc-plugin-ffmpeg vlc-plugin-x265 vlc-plugin-x265
                ;;
            6)
                echo "  - install Network tools: wireshark-qt traceroute nmap"
                sudo pacman -S wireshark-qt traceroute nmap
                sudo usermod -aG wireshark $username
                ;;
        esac
    done
}

custom_config() {
    sudo tee /etc/polkit-1/rules.d/50-udisks2.rules > /dev/null <<'POLKIT_EOF'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.udisks2.filesystem-mount" ||
         action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
         action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
         action.id == "org.freedesktop.udisks2.encrypted-unlock-system" ||
         action.id == "org.freedesktop.udisks2.eject-media" ||
         action.id == "org.freedesktop.udisks2.eject-media-system" ||
         action.id == "org.freedesktop.udisks2.power-off-drive" ||
         action.id == "org.freedesktop.udisks2.loop-setup") &&
        subject.isInGroup("storage")) {
        return polkit.Result.YES;
    }
});
POLKIT_EOF

    sudo mkdir -p /mnt/samba
    sudo cat >> /etc/fstab <<'SMB_EOF'

# smb
//192.168.0.189/Files /mnt/samba cifs noauto,x-systemd.automount,x-systemd.idle-timeout=3min,_netdev,username=user2,password=21121,uid=1000,gid=1000,file_mode=0644,dir_mode=0755,vers=3.0 0 0
SMB_EOF

    sudo cat >> /etc/udisks2/udisks2.conf <<'UD_EOF'
default_modules="ntfs-3g"

mount_options=uid=1000,gid=1000,dmask=022,fmask=133,windows_names

[ntfs]
defaults=uid=1000,gid=1000,dmask=022,fmask=133,windows_names
allow=uid=,gid=,dmask=,fmask=,locale=,windows_names,compression,nocompression
UD_EOF

    sudo cat >> /etc/X11/xorg.conf.d/10-extensions.conf <<'XORG1_EOF'
Section "Extensions"
    Option "DPMS" "false"
EndSection
XORG1_EOF

     sudo cat >> /etc/X11/xorg.conf.d/10-serverflags.conf <<'XORG2_EOF'
Section "ServerFlags"
    Option "BlankTime" "0"
EndSection
XORG2_EOF

    sudo cat > /usr/local/bin/custom_screenshot.sh <<'SCREEN_EOF'
#!/bin/bash
mkdir -p "$HOME/Pictures/Screenshots"

tmp_png="/tmp/freeze_$$.png"
import -window root "$tmp_png"

if [ ! -f "$tmp_png" ]; then
    exit 1
fi

if command -v feh >/dev/null 2>&1; then
    feh -FZY "$tmp_png" &
    FEH_PID=$!
    sleep 0.5
fi

filename="$HOME/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png"
import "$filename"

if [ ! -f "$filename" ]; then
    [ ! -z "$FEH_PID" ] && kill $FEH_PID 2>/dev/null
    rm "$tmp_png"
    exit 1
fi

[ ! -z "$FEH_PID" ] && kill $FEH_PID 2>/dev/null

rm "$tmp_png" 2>/dev/null

if command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -t image/png -i "$filename"
    echo -n "$filename" | xclip -selection primary
fi
SCREEN_EOF

    sudo chmod +x /usr/local/bin/custom_screenshot.sh

    sudo tee /usr/share/rofi/themes/kupano-dark.rasi > /dev/null <<'ROFI_EOF'
* {
    bg0: #2d2d2dF2;
    bg1: #7E7E7E80;
    bg2: #464646;

    fg0: #DEDEDE;
    fg1: #464646;

    background-color: transparent;
    text-color: @fg0;

    margin: 0;
    padding: 0;
    spacing: 0;
}

window {
    background-color: @bg0;
    location: center;
    width: 640;
    border-radius: 4;
}

inputbar {
    margin: 10px;
    children: [ entry ];
}

entry {
    font: "Noto Sans JP 14";
    padding: 0 10px;
    placeholder: "Start typing...";
    placeholder-color: @fg1;
    horizontal-align: 0.5;
    blink: false;
    cursor-color: transparent;
}

listview {
    margin: 10px;
    padding: 10px 0 0 0;
    lines: 10;
    columns: 2;
    fixed-height: false;
    border: 1px 0 0;
    border-color: @bg1;
}

element {
    padding: 8px;
    spacing: 8px;
    background-color: transparent;
}

element selected {
    border-radius: 4;
    background-color: @bg2;
}

element-icon {
    size: 1em;
}
element-text {
    font: "Noto Sans JP 12";
}
ROFI_EOF
}

username="$SUDO_USER"

if [[ $EUID -ne 0 ]]; then
    echo "Please run the script from root." >&2
    exit 1
fi

detect_gpu_vendor

if ! install_i3; then
    echo "ERROR: Cancel."
    exit 1
fi

custom_config

cat > /home/$username/user_config.sh <<'CONF_EOF'
#!/bin/bash

xdg-user-dirs-update
systemctl --user enable pipewire pipewire-pulse wireplumber

cat >> /home/$USER/.bash_profile <<'BASHPROF_EOF'
export PATH="~/.local/bin:$PATH"
# cursor
export XCURSOR_THEME=Capitaine
export XCURSOR_SIZE=24

# GTK
export GTK_THEME=Materia-dark
export GTK_ICON_THEME=Papirus-Dark

# QT5
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum-dark
export GTK_APPLICATION_PREFER_DARK_THEME=1

# Fast render
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb

# Electron
export ELECTRON_TRASH=gio
export ELECTRON_FORCE_DARK_MODE=1

# languages
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export INPUT_METHOD=fcitx5
export SDL_IM_MODULE=fcitx5
export GLFW_IM_MODULE=ibus
BASHPROF_EOF

mkdir -p /home/$USER/.local/bin

cat > /home/$USER/.config/picom.conf <<'PICOM_EOF'
shadow = false;
shadow-offset-x = -7;
shadow-offset-y = -7;
frame-opacity = 1.0;
corner-radius = 3;
blur-kern = "3x3box";
backend = "glx"
dithered-present = false;
vsync = true;
detect-rounded-corners = true;
detect-client-opacity = true;
use-ewmh-active-win = true;
detect-transient = true;
use-damage = true;
xrender-sync-fence = true;
PICOM_EOF

mkdir -p /home/$USER/.config/udiskie
cat > /home/$USER/.config/udiskie/config.yml <<'UDISK_EOF'
program_options:
  tray: auto
  menu: flat
  automount: false
  notify: true
  password_cache: false
  password_prompt: builtin:gui
  file_manager: thunar

device_config:
  - ignore: false
    automount: false
    skip: true

  - is_luks: true
    decrypt: true
    ignore: false
    automount: false

  - is_filesystem: true
    ignore: false
    automount: false

notifications:
  timeout: 3
  device_mounted: 3
  device_unmounted: 3
  device_added: 3
  device_removed: 3

quickmenu_actions:
  - mount
  - unmount
  - unlock
  - browse
  - eject
  - detach
UDISK_EOF

mkdir -p /home/$USER/.config/qt5ct
cat > /home/$USER/.config/qt5ct/qt5ct.conf <<'QT_EOF'
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
custom_palette=true
icon_theme=Papirus-Dark
standard_dialogs=default
style=kvantum-dark

[Fonts]
fixed="Sans Serif,9,-1,5,50,0,0,0,0,0"
general="Sans Serif,9,-1,5,50,0,0,0,0,0"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=@Invalid()
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
stylesheets=@Invalid()
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3

[SettingsWindow]
geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\x4\x92\0\0\0\0\0\0\t\xff\0\0\x5\x88\0\0\0\x2\0\0\0\x14\0\0\t\xfd\0\0\x5\x86\0\0\0\0\x2\0\0\0\n\0\0\0\x4\x94\0\0\0\x14\0\0\t\xfd\0\0\x5\x86)

[Troubleshooting]
force_raster_widgets=1
ignored_applications=@Invalid()
QT_EOF

mkdir -p /home/$USER/.config/gtk-3.0
cat > /home/$USER/.config/gtk-3.0/settings.ini <<'GTK_EOF'
[Settings]
gtk-theme-name=Materia-dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Adwaita Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintmedium
GTK_EOF

mkdir -p /home/$USER/.config/rofi
cat > /home/$USER/.config/rofi/config.rasi <<'ROFIHOME_EOF'
@theme "/usr/share/rofi/themes/kupano-dark.rasi"
ROFIHOME_EOF

cat > /home/$USER/.config/i3status.conf <<'I3STAT_EOF'
# The following line should contain a sharp s:
# ß
# If the above line is not correctly displayed, fix your editor first!

general {
    markup = "pango"
    colors = true
    interval = 3
}

order += "read_file projects"
order += "disk /home"
order += "cpu_usage"
order += "memory"
order += "tztime moscow"

read_file projects {
    path = "/tmp/i3status/projects.txt"
    format = "%content"
    format_bad = "<span font='Material Icons' rise='-2000' color='#ffb748'>error</span>"
}

disk "/home" {
    prefix_type = custom
    format = "<span font='Material Icons' rise='-2000' color='#ffb748'>home_work</span> %free"
}

cpu_usage {
    format = "<span font='Material Icons' rise='-2000' color='#ffb748'>developer_board</span> %usage"
}

memory {
    decimals = 0
    format = "<span font='Material Icons' rise='-2000' color='#ffb748'>memory</span> %percentage_used"
    threshold_degraded = "1G"
    format_degraded = "MEMORY < %available"
}

tztime moscow {
    timezone = "Europe/Moscow"
    format = "<span font='Material Icons' rise='-2000' color='#ffb748'>event_note</span> %Y.%m.%d (%a) <span color='#464646'>⋮</span> <span font='Material Icons' rise='-2000' color='#ffb748'>access_time</span> %I:%M <span color='#ffb748'>%p</span> <span color='#464646'>⋮</span>"
}
I3STAT_EOF

mkdir -p /home/$USER/.config/i3
cat > /home/$USER/.config/i3/config <<'I3_EOF'
# Set mod key as <Win>
    set $mod Mod4
# Base i3 font
    font pango: Ubuntu Mono 10
# Center window title
    title_align center
# Gaps between windows
    gaps inner 8px
# Thin window borders
    for_window [all] border normal 0
# Change window title to app name
    for_window [all] title_format "<b>%class</b>"
# Change emacs window title to "Buffer: %b"
    for_window [class="Emacs"] title_format "<b>%title</b>"

bindsym Ctrl+space exec --no-startup-id fcitx5-remote -t

############################
    ###    BINDS     ###
############################
# Open terminal (autosearch for terminal and run it)
    bindsym $mod+Return exec i3-sensible-terminal
# Kill Window
    bindsym $mod+Shift+q kill
# Focus Window Left (Cycle)
    bindsym $mod+j focus left
    bindsym $mod+Left focus left
# Focus Window Down (Cycle)
    bindsym $mod+k focus down
    bindsym $mod+Down focus down
# Focus Window Up (Cycle)
    bindsym $mod+l focus up
    bindsym $mod+Up focus up
# Focus Window Right (Cycle)
    bindsym $mod+semicolon focus right
    bindsym $mod+Right focus right
# Move Window Left
    bindsym $mod+Shift+j move left
    bindsym $mod+Shift+Left move left
# Move Window Down
    bindsym $mod+Shift+k move down
    bindsym $mod+Shift+Down move down
# Move Window Up
    bindsym $mod+Shift+l move up
    bindsym $mod+Shift+Up move up
# Move Window Right
    bindsym $mod+Shift+semicolon move right
    bindsym $mod+Shift+Right move right
############################
    ###   LAYOUTS    ###
############################
# Stack verticaly
    bindcode $mod+s layout stacking
# Stack horizontaly
    bindsym $mod+w layout tabbed
# Change split type
    bindsym $mod+e layout toggle split
# Toggle fullscreen
    bindsym $mod+f fullscreen toggle
# Toggle floating window
    bindsym $mod+Shift+space floating toggle
# Change window split type
    bindsym $mod+h split h
    bindsym $mod+v split v
# Focus parent container
    bindsym $mod+a focus parent
#
    bindsym $mod+space focus mode_toggle

###
# Allow dragging windows
floating_modifier $mod
# Allow dragging windows with mouse
tiling_drag modifier titlebar

# Disable mouse focus
focus_follows_mouse no
# Mouse Key - Next song
bindsym XF86AudioNext exec --no-startup-id playerctl --ignore-player=chromium next
# Mouse Key - Play/Pause song
bindsym XF86AudioPlay exec --no-startup-id playerctl --ignore-player=chromium play-pause
# Screenshot
# bindsym Print exec --no-startup-id gnome-screenshot -i
  bindsym Print exec --no-startup-id ~/Projects/Bash/yany_screenshot.sh
# Personal Files (replace with systemctl)
exec --no-startup-id ~/Projects/Bash/projects.sh
# Launch picom
exec_always --no-startup-id picom -b --config ~/.config/picom.conf
# Launch udiskie
exec --no-startup-id udiskie -t -c ~/.config/udiskie/config.yml

# Launch ibus-daemon
exec --no-startup-id fcitx5 -d
bindsym $mod+Ctrl+j exec --no-startup-id fcitx5 -d

# Open Rofi ($mod+d)
bindcode $mod + 40 exec --no-startup-id rofi -show drun -icon-theme "Papirus" -show-icons

    ####################
    ###   CHECKOUT   ###
    ####################
# dex - utility to run desktop entry files
    exec --no-startup-id dex --autostart --environment i3
# block screen, when inactive/pause
    exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork
# nm-applet - NetworkManager
    exec --no-startup-id nm-applet
# set var with command to kill all i3status proccess
# not uses in this config, so might be deleted
    set $refresh_i3status killall -SIGUSR1 i3status

# Reload I3
bindsym $mod+Shift+c reload
# Restart I3
bindsym $mod+Shift+r restart
# Log Out
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"


############################
    ###  WORKSPACE   ###
############################
# Set names for workspace
    set $ws1 "1"
    set $ws2 "2"
    set $ws3 "3"
    set $ws4 "4"
    set $ws5 "5"
    set $ws6 "6"
    set $ws7 "7"
    set $ws8 "8"
    set $ws9 "9"
    set $ws10 "10"
# Open workspace by number
    bindsym $mod+1 workspace number $ws1
    bindsym $mod+2 workspace number $ws2
    bindsym $mod+3 workspace number $ws3
    bindsym $mod+4 workspace number $ws4
    bindsym $mod+5 workspace number $ws5
    bindsym $mod+6 workspace number $ws6
    bindsym $mod+7 workspace number $ws7
    bindsym $mod+8 workspace number $ws8
    bindsym $mod+9 workspace number $ws9
    bindsym $mod+0 workspace number $ws10
# Move window to N workspace
    bindsym $mod+Shift+1 move container to workspace number $ws1
    bindsym $mod+Shift+2 move container to workspace number $ws2
    bindsym $mod+Shift+3 move container to workspace number $ws3
    bindsym $mod+Shift+4 move container to workspace number $ws4
    bindsym $mod+Shift+5 move container to workspace number $ws5
    bindsym $mod+Shift+6 move container to workspace number $ws6
    bindsym $mod+Shift+7 move container to workspace number $ws7
    bindsym $mod+Shift+8 move container to workspace number $ws8
    bindsym $mod+Shift+9 move container to workspace number $ws9
    bindsym $mod+Shift+0 move container to workspace number $ws10
# Resize Mode

set $mode_resize <span font='Material Icons' rise='-2000'>pinch</span> <b>Resize</b>

mode --pango_markup "$mode_resize" {
    # Resize Width (shrink)
    bindsym j resize shrink width 10 px or 10 ppt
    bindsym Left resize shrink width 10 px or 10 ppt
    # Resize Width (grow)
    bindsym semicolon resize grow width 10 px or 10 ppt
    bindsym Right resize grow width 10 px or 10 ppt
    # Resize Height (shrink)
    bindsym l resize shrink height 10 px or 10 ppt
    bindsym Up resize shrink height 10 px or 10 ppt
    # Resize Height (grow)
    bindsym k resize grow height 10 px or 10 ppt
    bindsym Down resize grow height 10 px or 10 ppt
    # Return To Default Mode
    bindsym Return mode "default"
    bindsym Escape mode "default"
    bindsym $mod+r mode "default"
}

# Open Resize Mode
bindsym $mod+r mode "$mode_resize"

############################
    ###    STYLE     ###
############################
# class                 mBorder   bg        fg        ind-spl   cBorder
client.focused          #ffb748   #ffb748   #000000   #81bcd3   #464646
client.focused_inactive #2d2d2d   #2d2d2d   #cdcdcd   #ffcd93   #464646
client.unfocused        #464646   #464646   #cdcdcd   #ffcd93   #464646
client.urgent           #464646   #464646   #cdcdcd   #ffcd93   #464646
############################
    ###     BAR      ###
############################
bar {
    id bar-1
    mode dock
    modifier none
    status_command i3status -c ~/.config/i3/status-main.conf
    font pango: Ubuntu Mono 9
    separator_symbol "⋮"
    height 20
    tray_padding 4
    workspace_min_width 16
    strip_workspace_numbers yes

    colors {
        background #000000
        statusline #ffffff
        separator  #2d2d2d
        #                  #border #bg     #fg
        focused_workspace  #000000 #000000 #ffb748
        inactive_workspace #000000 #000000 #cdcdcd
        urgent_workspace   #464646 #464646 #cdcdcd
        binding_mode       #81bcd3 #81bcd3 #000000
    }
}
I3_EOF

mkdir -p /home/$USER/.emacs.d
wget -P /home/$USER/.emacs.d https://raw.githubusercontent.com/Kupanko/myconfig/refs/heads/main/.emacs.d/{init,yka-lib}.el

CONF_EOF

chown $username:users /home/$username/user_config.sh
chmod +x /home/$username/user_config.sh

runuser -l $username -c '/home/$USER/user_config.sh'

rm /home/$username/user_config.sh
rm /home/$username/final.sh

echo "Installation is complete, please reboot your PC."
FINAL_EOF

    chmod +x /home/$username/final.sh
    sleep 5
    exit
MNT_EOF
    chmod +x /mnt/chroot.sh
    arch-chroot -S /mnt /bin/bash -c "/chroot.sh"
    rm /mnt/chroot.sh
    umount -R /mnt
}

echo "---Start install---"

if ! ping -c 3 -w 3 8.8.8.8 &> /dev/null; then
    echo "Internet is not connected, check your connection!"
    exit 1
fi

echo "Internet connected"
echo -e "\n--- Select Disk ---"
select_disk

if [ -z "${selected_disk:-}" ]; then
    echo "ERROR: No disk selected!" >&2
    exit 1
fi

if ! confirm_selection "$selected_disk"; then
    echo "Operation cancelled by user."
    exit 0
fi

if ! partition_disk "$selected_disk"; then
    echo "ERROR: Disk partitioning failed!" >&2
    exit 1
fi

if ! base_install "$selected_disk"; then
    echo "ERROR: Cancel."
    exit 1
fi

echo -e "\n--- Installation is complete. Restart PC. ---"
lsblk
