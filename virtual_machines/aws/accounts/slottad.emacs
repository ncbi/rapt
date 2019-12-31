(setq gc-cons-threshold (* 8192 8192))
(add-to-list 'load-path "~/.emacs.d/lisp")
(setq font-lock-maximum-decoration t)
(global-font-lock-mode t)
(global-hi-lock-mode t)
(global-auto-revert-mode t)
(desktop-save-mode 1)
(menu-bar-mode 0)

(setq ispell-program-name "hunspell")

(setq-default apropos-do-all t)
(setq-default tab-width 4)
(setq-default c-basic-offset 4)
(setq-default indent-tabs-mode nil)
(setq-default make-backup-files nil)

;; Improved undo
(setq undo-limit 3600)

;;; Buffers
(ido-mode 'buffer)
(setq ido-enable-flex-matching t)
(setq ibuffer-shrink-to-minimum-size t)
(setq ibuffer-always-show-last-buffer nil)
(setq ibuffer-sorting-mode 'recency)
(setq ibuffer-use-header-line t)
(global-set-key [(f12)] 'ibuffer)
(when (require 'bubble-buffer nil t)
  (global-set-key [f11] 'bubble-buffer-next)
  (global-set-key [(shift f11)] 'bubble-buffer-previous))
(setq bubble-buffer-omit-regexp "\\*.+\\*")

(put 'dired-find-alternate-file 'disabled nil)
(setq efs-generate-anonymous-password "slottad@ncbi.nlm.nih.gov")
;(autoload 'javascript-mode "javascript" nil t)
;(add-to-list 'auto-mode-alist '("\\.js\\'" . javascript-mode))

;;force compilation to scroll
(setq compilation-scroll-output t)
;; Set the size of the compilation window height
(setq compilation-window-height 10)
;; M-g means 'goto-line
(define-key global-map (kbd "M-g") 'goto-line)

(global-set-key [M-left] 'windmove-left)          ; move to left window
(global-set-key [M-right] 'windmove-right)        ; move to right window
(global-set-key [M-up] 'windmove-up)              ; move to upper window
(global-set-key [M-down] 'windmove-down)          ; move to lower window

(global-set-key [f8] 'other-window)                ; move to next window
(global-set-key [f7] 'previous-multiframe-window)  ; move to previous window
