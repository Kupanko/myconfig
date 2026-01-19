(package-initialize)

(load "~/.emacs.d/yka-lib.el")
(load "~/.emacs.d/yka-keybinds.el")

(setq inhibit-splash-screen t)
(ido-mode 1)
(ido-everywhere 1)
(scroll-bar-mode 0)
(tool-bar-mode 0)
(menu-bar-mode 0)
(show-paren-mode 1)
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(setq use-dialog-box nil)
(setq redisplay-dont-pause t)
(setq ring-bell-function 'ignore)
(setq frame-title-format "Buffer: %b")
(setq auto-save-default nil)
(setq auto-save-interval 0)
(setq make-backup-files nil)
(setq-default indent-tabs-mode nil)
(setq compilation-scroll-output t)
(global-whitespace-mode 1)
(whitespace-toggle-options 's)

(setq-default whitespace-style '(face tabs spaces trailing space-before-tab newline indentation empty space-after-tab space-mark tab-mark))

(require 'ansi-color)
(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

(setq-default mode-line-format
  '("%e"
    "   File: %z%*%+   Buffer: %b (%l, %c)   Size: %I   Mode: " mode-name
    ))

(set-frame-font "IosevkaSS03" nil t)
(set-fontset-font "fontset-default" 'han "Noto Sans JP")
(set-fontset-font "fontset-default" 'kana "Noto Sans JP")
(set-fontset-font "fontset-default" 'symbol "Noto Sans JP")

(yka/require 'typescript-mode)

(add-to-list 'auto-mode-alist '("\\.js\\'"  . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.cjs\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.mjs\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'"  . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.cts\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.mts\\'" . typescript-mode))
