(add-hook 'dired-mode-hook
          '(lambda ()
             (local-set-key (kbd "C-,") (quote dired-create-empty-file))
             (local-set-key (kbd "C-.") (quote dired-create-directory))))

(global-set-key (kbd "<f5>") 'compile)
(global-set-key (kbd "<f4>") 'kill-compilation)

(global-set-key (kbd "C-<f1>" ) 'yka/kbd)
(global-set-key (kbd "C-<f2>" ) 'yka/lib)
(global-set-key (kbd "C-<f3>" ) 'yka/cfg)
(global-set-key (kbd "<f6>"   ) 'yka/prj)
(global-set-key (kbd "C-x j") 'yka/sudo)

(global-set-key (kbd "C-;"    ) 'comment-line)
(global-set-key (kbd "C-:"    ) 'comment-or-uncomment-region)
(global-set-key (kbd "C-~"    ) 'mc/edit-lines)
(global-set-key (kbd "C->"    ) 'mc/mark-next-like-this)
(global-set-key (kbd "C-<"    ) 'mc/mark-previous-like-this)
(global-set-key (kbd "C-x C-a") 'mc/mark-all-like-this)
;; (global-set-key (kbd "C-x C->") 'mc/skip-to-next-like-this)     ;
;; (global-set-key (kbd "C-x C-<") 'mc/skip-to-previous-like-this) ;
