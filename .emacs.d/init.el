;; Kupano Config 25/03/23 - 26/~/~

(setq custom-file "~/.emacs.d/custom.el")

(package-initialize)

(load "~/.emacs.d/yka-lib.el")             ; load yka/lib

(setq inhibit-splash-screen t)             ; hide start screen

(scroll-bar-mode 0)                        ; disable scrollbar
(tool-bar-mode 0)                          ; disable tool bar
(menu-bar-mode 0)                          ; disable menu bar

(show-paren-mode 1)                        ; enable highlighting parentheses {},[],()
(setq display-line-numbers-type 'relative) ; relative line numbers
(global-display-line-numbers-mode 1)       ; display line numbers
(column-number-mode 1)                     ; column number in mode line

(setq use-dialog-box nil)                  ; minibuffer instead of GUI dialogs
(setq redisplay-dont-pause t)              ; smooth scrolling
(setq ring-bell-function 'ignore)          ; disable bell/beep
(setq frame-title-format "Buffer: %b")     ; set frame title

(setq auto-save-default nil)               ; disable auto-saving
(setq auto-save-interval 0)                ; never auto-save
(setq make-backup-files nil)               ; stop creating ~ files
(setq tramp-auto-save-directory "/tmp")    ; auto-save for tramp mode

(setq compilation-scroll-output t)         ; autoscroll for compilation

(setq-default tab-width 4)                 ; tab size - 4 spaces
(setq-default indent-tabs-mode nil)        ; spaces instead of tabs
(global-whitespace-mode 1)                 ; highlights for spaces
(whitespace-toggle-options 's)             ; specify highlighted elements

(setq-default whitespace-style '(face tabs spaces trailing space-before-tab newline indentation empty space-after-tab space-mark tab-mark))

(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :config
  (setq vertico-cycle t)
  (setq vertico-resize nil))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil) ;; Disable defaults, use our settings
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring

(use-package marginalia
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

(require 'ansi-color) ; colors for console
(add-hook 'compilation-filter-hook 'ansi-color-compilation-filter)

(setq-default mode-line-format
  '("%e"
    "   File: %z%*%+   Buffer: %b (%l, %c)   Size: %I   Mode: " mode-name))

(set-frame-font "IosevkaSS03" nil t)                        ; global font
(set-fontset-font "fontset-default" 'han "Noto Sans JP")    ; for japanese: わたし・ワタシ・私
(set-fontset-font "fontset-default" 'kana "Noto Sans JP")   ; for japanese: わたし・ワタシ・私
(set-fontset-font "fontset-default" 'symbol "Noto Sans JP") ; for japanese: わたし・ワタシ・私

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
