;; Kupano Config 25/03/23 - 26/~/~

(setq custom-file "~/.emacs.d/custom.el")

(package-initialize)

(load "~/.emacs.d/yka-lib.el")

(setq inhibit-splash-screen t)

(scroll-bar-mode 0)
(tool-bar-mode 0)
(menu-bar-mode 0)
(show-paren-mode 1)
(global-display-line-numbers-mode t)
(setq display-line-numbers-type 'relative)
(setq column-number-mode t)

(setq use-dialog-box nil)
(setq redisplay-dont-pause t)
(setq ring-bell-function 'ignore)
(setq frame-title-format "Buffer: %b")

(setq auto-save-default t)
(setq auto-save-interval 300)
(setq make-backup-files nil)
(setq tramp-auto-save-directory "/tmp")

(setq compilation-scroll-output t)

(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)
(global-whitespace-mode t)
(whitespace-toggle-options 's)

(setq-default whitespace-style '(
  face tabs spaces trailing
  space-before-tab newline
  indentation empty space-after-tab
  space-mark tab-mark))

(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :config
  (setq vertico-cycle t)
  (setq vertico-resize nil))

(use-package vertico-directory
  :after vertico
  :ensure nil
  :bind (:map vertico-map
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil)
  (completion-pcm-leading-wildcard t))

(use-package marginalia
  :ensure t
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))
  :init
  (marginalia-mode))

(yka/require 'company)
(global-company-mode)

(setq-default company-minimum-prefix-length 2)
(setq-default company-tooltip-limit 12)
(setq-default company-idle-delay 0.3)
(setq-default company-selection-wrap-around t)
(setq-default company-etags-use-main-table-list t)
(setq company-backends '((company-capf company-dabbrev-code) company-etags))

(require 'ansi-color)
(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

(setq-default mode-line-format
  '("%e"
    "   File: %z%*%+   Buffer: %b (%l, %c)   Size: %I   Mode: " mode-name))

(set-frame-font "IosevkaSS03" nil t)                        ; Text - Текст
(set-fontset-font "fontset-default" 'han "Noto Sans JP")    ; わたし・ワタシ・私
(set-fontset-font "fontset-default" 'kana "Noto Sans JP")   ; わたし・ワタシ・私
(set-fontset-font "fontset-default" 'symbol "Noto Sans JP") ; わたし・ワタシ・私

(yka/require 'gruber-darker-theme)
(load-theme 'gruber-darker t)

(yka/require 'multiple-cursors)
(yka/require 'typescript-mode)
(yka/require 'markdown-mode)
(yka/require 'magit)

(dolist (ext '(".js" ".cjs" ".mjs" ".ts" ".cts" ".mts"))
  (add-to-list 'auto-mode-alist
               (cons (concat "\\" ext "\\'") 'typescript-mode)))

(global-set-key (kbd "<f5>")    'compile)
(global-set-key (kbd "<f4>")    'kill-compilation)
(global-set-key (kbd "<f7>")    'shell)

(global-set-key (kbd "C-<f1>")  'yka/sudo)
(global-set-key (kbd "C-<f2>")  'yka/lib)
(global-set-key (kbd "C-<f3>")  'yka/cfg)
(global-set-key (kbd "<f6>")    'yka/prj)

(global-set-key (kbd "C-;")     'comment-line)
(global-set-key (kbd "C-:")     'comment-or-uncomment-region)

(global-set-key (kbd "C-~")     'mc/edit-lines)
(global-set-key (kbd "C->")     'mc/mark-next-like-this)
(global-set-key (kbd "C-<")     'mc/mark-previous-like-this)
(global-set-key (kbd "C-x C-a") 'mc/mark-all-like-this)
(global-set-key (kbd "C-x C->") 'mc/skip-to-next-like-this)
(global-set-key (kbd "C-x C-<") 'mc/skip-to-previous-like-this)

(global-set-key (kbd "C-c w")   'whitespace-cleanup)
(global-set-key (kbd "C-x j")   'replace-string)

(add-hook 'dired-mode-hook
          '(lambda ()
             (local-set-key (kbd "C-,") (quote dired-create-empty-file))
             (local-set-key (kbd "C-.") (quote dired-create-directory))))

(load-file custom-file)
