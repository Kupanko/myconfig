(setq path "~/.emacs.d/")
(setq compile-command "")

(defun yka/lib ()
  "Open YKA Config File"
  (interactive)
  (switch-to-buffer (find-file-noselect (concat path "yka-lib.el"))))
(defun yka/cfg ()
  "Open Config File"
  (interactive)
  (switch-to-buffer (find-file-noselect (concat path "init.el"))))
(defun yka/prj ()
  "Open Projects Folder"
  (interactive)
  (switch-to-buffer (find-file-noselect "~/")))
(defun yka/sudo ()
  "Open file with sudo"
  (interactive)
  (switch-to-buffer (find-file-noselect (concat "/sudo::" buffer-file-name))))

(defun yka/require (package)
  "Install packages"
  (when (not (package-installed-p package))
    (package-refresh-contents)
    (package-install package)))

(add-hook 'dired-mode-hook
          '(lambda ()
             (local-set-key (kbd "C-,") (quote dired-create-empty-file))
             (local-set-key (kbd "C-.") (quote dired-create-directory))))
