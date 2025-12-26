(package-initialize)

(load "~/.emacs.d/yka-lib.el")
(load "~/.emacs.d/yka-keybinds.el")

(setq inhibit-splash-screen 0)
(ido-mode 1)
(ido-everywhere 1)
(scroll-bar-mode 0)
(tool-bar-mode 0)
(show-paren-mode 1)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(setq display-line-numbers-type 'relative)
(setq use-dialog-box 0)
(setq redisplay-dont-pause 1)
(setq ring-bell-function 'ignore)
(setq frame-title-format "Buffer: %b")
(setq auto-save-mode 0)
(setq auto-save-interval 0)
(setq-default indent-tabs-mode nil)
(setq default-frame-alist '((height . 45)(width . 140)(left . 440)(top . 140)))

(require 'ansi-color)
(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

(setq compilation-scroll-output t)

(setq make-backup-files nil)
(global-whitespace-mode 1)
(whitespace-toggle-options 's)

(setq-default whitespace-style '(face tabs spaces trailing space-before-tab newline indentation empty space-after-tab space-mark tab-mark))

(yka/require 'typescript-mode)

(add-to-list 'auto-mode-alist '("\\.js\\'"  . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.cjs\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.mjs\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'"  . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.cts\\'" . typescript-mode))
(add-to-list 'auto-mode-alist '("\\.mts\\'" . typescript-mode))
