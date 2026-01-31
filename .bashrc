#
# ~/.bashrc
#

export GTK_THEME=Materia-dark
export GTK2_RC_FILES=/usr/share/themes/Adwaita-dark/gtk-2.0/gtkrc

export XCURSOR_THEME=Capitaine
export XCURSOR_SIZE=24
export QT_QPA_PLATFORMTHEME=qt5ct

export GDK_BACKEND=x11

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx

[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
