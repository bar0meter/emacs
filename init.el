;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;; Package setup must happen before loading external packages.
(require 'package)

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))

(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; Emacs 29+ includes use-package.
(require 'use-package)
(require 'project)

;; GUI Emacs does not inherit the shell paths managed by mise.
(dolist (dir (list "/opt/homebrew/bin"
                   (expand-file-name "~/.cargo/bin")
                   (expand-file-name "~/.local/share/mise/shims")))
  (add-to-list 'exec-path dir))
(setenv "PATH" (mapconcat #'identity exec-path path-separator))

;; General settings
(setq ring-bell-function #'ignore
      tab-always-indent 'complete
      scroll-conservatively 0
      scroll-margin 3
      backup-directory-alist
      `(("." . ,(expand-file-name "backups/" "~/.cache/emacs/")))
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "autosave/" "~/.cache/emacs/") t))
      mac-command-modifier 'meta
      mac-option-modifier 'super
      scroll-error-top-bottom t
      completion-styles '(flex)
      zig-format-on-save t
      require-final-newline t
      kill-do-not-save-duplicates t
      compilation-scroll-output t
      compilation-auto-jump-to-first-error t
      auto-save-visited-interval 15)

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80)

(add-to-list 'default-frame-alist '(font . "JetBrains Mono-15"))
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(delete-selection-mode +1)
(electric-pair-mode +1)
(recentf-mode +1)
(global-hl-line-mode +1)
(auto-save-visited-mode +1)
(global-auto-revert-mode +1)
(savehist-mode +1)
(column-number-mode +1)
;; Protect Emacs from generated or minified files with very long lines.
(global-so-long-mode +1)
;; Show available commands after typing a prefix key.
(which-key-mode +1)

(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
(add-hook 'before-save-hook #'delete-trailing-whitespace)

(defconst my-large-file-threshold (* 256 1024))

(defun my-optimize-large-file ()
  "Disable continuous background work in large buffers."
  (when (> (buffer-size) my-large-file-threshold)
    (setq-local auto-save-visited-mode nil)
    (when (bound-and-true-p corfu-mode)
      (corfu-mode -1))))

(add-hook 'find-file-hook #'my-optimize-large-file)

;; Keep M-x available because Command-x is used for cutting text.
(global-set-key (kbd "C-c x") #'execute-extended-command)
(global-set-key (kbd "M-X") #'execute-extended-command)
(global-set-key (kbd "s-<backspace>") #'backward-kill-word)

(windmove-default-keybindings 'control)

;; Evil
(use-package evil
  :ensure t
  :init
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1)
  ;; Paste the latest yank or clipboard text into / searches.
  (define-key evil-ex-search-keymap (kbd "C-y") #'yank)
  (define-key evil-ex-search-keymap (kbd "M-v") #'yank))

(use-package evil-escape
  :ensure t
  :after evil
  :custom
  ;; Leave insert mode by typing jk quickly.
  (evil-escape-key-sequence "jk")
  :config
  (evil-escape-mode +1))

(use-package evil-collection
  :ensure t
  :after evil
  :custom
  ;; Add Vim bindings only where requested.
  (evil-collection-mode-list '(magit))
  :config
  (evil-collection-init))

(defun open-line-below ()
  "Open a new line below the current line."
  (interactive)
  (end-of-line)
  (newline-and-indent))

(global-set-key (kbd "M-<return>") #'open-line-below)

(defun kill-region-smart ()
  "Cut the active region, or the current line if no region is active."
  (interactive)
  (if (use-region-p)
      (call-interactively #'kill-region)
    (kill-whole-line)))

(global-set-key (kbd "M-x") #'kill-region-smart)

(defun kill-ring-save-smart ()
  "Copy the active region, or the current line if no region is active."
  (interactive)
  (if (use-region-p)
      (call-interactively #'kill-ring-save)
    (save-excursion
      (beginning-of-line)
      (copy-region-as-kill
       (line-beginning-position)
       (line-beginning-position 2)))))

(global-set-key (kbd "M-c") #'kill-ring-save-smart)

(defun move-beginning-of-line-smart (arg)
  "Move point to indentation, then to the true beginning of the line."
  (interactive "^p")
  (setq arg (or arg 1))

  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

(global-set-key [remap move-beginning-of-line]
                #'move-beginning-of-line-smart)

(defun switch-project-directory ()
  "Use another known project as the current buffer's directory."
  (interactive)
  (setq default-directory
        (file-name-as-directory (project-prompt-project-dir)))
  (message "Switched project to %s" (abbreviate-file-name default-directory)))

(use-package vertico
  :ensure t
  :bind
  (:map vertico-map
        ("C-n" . vertico-next)
        ("C-p" . vertico-previous)
        ("C-a" . beginning-of-line)
        ("C-e" . end-of-line)
        ("M-b" . backward-word)
        ("M-f" . forward-word)
        ("M-<backspace>" . backward-kill-word)
        ("M-d" . kill-word)
        ("C-d" . delete-char)
        ("C-k" . kill-line)
        ("C-u" . delete-minibuffer-contents))
  :init
  (vertico-mode))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic)))

(use-package embark
  :ensure t
  :bind
  ;; Act on the current completion candidate.
  ("C-." . embark-act)
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :ensure t
  :hook
  ;; Preview Consult results collected by Embark.
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  :init
  (global-corfu-mode))

(use-package consult
  :ensure t
  :bind
  ;; Use searchable previews for buffers, symbols, and lines.
  (("C-x b" . consult-buffer)
   ("M-g i" . consult-imenu)
   ("M-s l" . consult-line)))

(use-package deadgrep
  :ensure t
  :bind
  ("C-S-s" . deadgrep))

(use-package treesit-auto
  :ensure t
  :custom
  ;; Ask before installing a missing language grammar.
  (treesit-auto-install 'prompt)
  ;; Limit grammar management to the languages used by this setup.
  (treesit-auto-langs
   '(bash dockerfile go gomod gowork javascript json lua rust tsx typescript yaml zig))
  :config
  ;; Register only modes whose grammars are already installed.  The global
  ;; mode checks every grammar whenever a file opens and is noticeably slow.
  (treesit-auto-add-to-auto-mode-alist))

(use-package rust-mode
  :ensure t)

(use-package zig-ts-mode
  :ensure t
  :mode "\\.zig\\'")

(use-package magit
  :ensure t
  :custom
  (magit-save-repository-buffers 'dontask)
  (magit-diff-fontify-hunk 'all)
  (magit-diff-specify-hunk-foreground nil)
  (magit-diff-use-indicator-faces t))

(use-package zenburn-theme
  :ensure t
  :config
  (load-theme 'zenburn t))

(use-package eglot
  :ensure nil
  :init
  ;; Large monorepos otherwise exhaust macOS GUI file descriptors.
  (setq eglot-max-file-watches 0)
  :hook
  ((sh-mode bash-ts-mode
            go-mode go-ts-mode go-mod-ts-mode
            js-mode js-ts-mode typescript-ts-mode tsx-ts-mode
            json-mode json-ts-mode
            rust-mode rust-ts-mode
            yaml-mode yaml-ts-mode
            zig-ts-mode)
   . eglot-ensure)
  :config
  ;; Neovim uses tsc's native LSP rather than typescript-language-server.
  (add-to-list
   'eglot-server-programs
   '(((js-mode :language-id "javascript")
      (js-ts-mode :language-id "javascript")
      (tsx-ts-mode :language-id "typescriptreact")
      (typescript-ts-mode :language-id "typescript"))
     "tsc" "--lsp" "--stdio"))
  (add-to-list 'eglot-server-programs '(zig-ts-mode "zls"))
  ;; Match Neovim's format-on-save behavior for LSP buffers.
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (add-hook 'before-save-hook #'eglot-format-buffer nil t))))

;; Comma leader mirroring the useful Neovim project and LSP bindings.
(defvar my-leader-map
  (define-keymap
    :name "leader"
    "<escape>" #'keyboard-quit
    "b" #'consult-buffer
    "l" #'project-find-file
    "w" #'kill-current-buffer
    "h" #'eglot-inlay-hints-mode
    "k" #'flymake-show-diagnostic
    "f" (define-keymap
          :name "find/format"
          "f" #'deadgrep
          "r" #'eglot-format-buffer)
    "p" (define-keymap
          :name "project"
          "p" #'switch-project-directory
          "f" #'project-find-file
          "g" #'project-find-regexp
          "b" #'project-switch-to-buffer
          "d" #'project-dired
          "c" #'project-compile
          "k" #'project-kill-buffers
          "e" #'project-eshell
          "s" #'project-shell)
    "s" (define-keymap
          :name "search"
          "s" #'consult-line
          "r" #'consult-recent-file)
    "g" (define-keymap
          :name "git"
          "g" #'magit-status)
    "r" (define-keymap
          :name "refactor"
          "n" #'eglot-rename)
    "c" (define-keymap
          :name "code"
          "a" #'eglot-code-actions
          "c" #'comment-line)
    "d" (define-keymap
          :name "diagnostics/symbols"
          "s" #'consult-imenu
          "d" #'flymake-show-buffer-diagnostics
          "w" #'flymake-show-project-diagnostics)))

(evil-define-key 'normal 'global
  (kbd ",") my-leader-map
  ;; Use Evil's definition command so the location is added to its jump list.
  (kbd "gd") #'evil-goto-definition
  (kbd "gD") #'xref-find-definitions-other-window
  (kbd "gI") #'eglot-find-implementation
  (kbd "gr") #'xref-find-references
  (kbd "K") #'eldoc-doc-buffer
  (kbd "C-p") #'evil-previous-line
  (kbd "C-n") #'evil-next-line
  (kbd "[ d") #'flymake-goto-prev-error
  (kbd "] d") #'flymake-goto-next-error
  (kbd "-") #'dired-jump)

(defun visit-init-file ()
  "Open the user's Emacs init file."
  (interactive)
  (find-file user-init-file))

(put 'dired-find-alternate-file 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(consult corfu deadgrep embark embark-consult evil evil-collection
             evil-escape magit orderless rust-mode treesit-auto vertico
             zenburn-theme zig-ts-mode)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
