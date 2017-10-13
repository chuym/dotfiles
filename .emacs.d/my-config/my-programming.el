;;; my-programming.el -- Misc settings related to programming
;;; Commentary:
;;; Code:

;;; projectile with helm
(projectile-global-mode)
(defvar projectile-completion-system)
(setq projectile-completion-system 'helm)
(helm-projectile-on)

;; Enable flycheck globally
(require 'flycheck)
(global-flycheck-mode)

;; Company mode
(require 'company)
(add-hook 'after-init-hook 'global-company-mode)


;; Display flycheck errors at the bottom on a small-ish window
(add-to-list 'display-buffer-alist
             `(,(rx bos "*Flycheck errors*" eos)
               (display-buffer-reuse-window
                display-buffer-in-side-window)
               (reusable-frames . visible)
               (side            . bottom)
               (window-height   . 0.12)))

;; Javascript configs
(require 'js2-mode)
(setq js2-basic-offset 2)

(defun js2-highlight-undeclared-vars ()
  "Override js2-mode undeclared vars feature, I use eslint and jshint anyway."
  (lambda ()))

;; I need to figure out how to make this configurable per project.
;; (setq-default flycheck-disabled-checkers
;;  (append flycheck-disabled-checkers
;;    '(javascript-eslint)))

(add-to-list 'auto-mode-alist '("\\.js\\'"    . js2-mode))
(add-to-list 'auto-mode-alist '("\\.pac\\'"   . js2-mode))
(add-to-list 'interpreter-mode-alist '("node" . js2-mode))

(add-hook 'js2-mode-hook
          '(lambda()
             (tern-mode t)
             (unless (member 'company-tern 'company-backends)
               (add-to-list 'company-backends 'company-tern))))
(provide 'my-programming)

;;; my-programming.el ends here
