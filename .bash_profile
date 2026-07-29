#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
export PATH="~/.local/bin:$PATH"

export XCURSOR_THEME=Capitaine
export XCURSOR_SIZE=24

export GTK_THEME=Materia-dark
export GTK_ICON_THEME=Papirus-Dark

export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum-dark
export GTK_APPLICATION_PREFER_DARK_THEME=1

export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb

export ELECTRON_TRASH=gio
export ELECTRON_FORCE_DARK_MODE=1

export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export INPUT_METHOD=fcitx5
export SDL_IM_MODULE=fcitx5
export GLFW_IM_MODULE=ibus
