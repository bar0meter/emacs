;; GUI Emacs inherits a minimal environment, so libgccjit's gcc driver
;; can't find its runtime libs (ld: library 'emutls_w' not found).
;; Point LIBRARY_PATH at Homebrew's gcc before any native compilation runs.
(when (eq system-type 'darwin)
  (setenv "LIBRARY_PATH"
          (string-join
           (append '("/opt/homebrew/opt/gcc/lib/gcc/current"
                     "/opt/homebrew/opt/libgccjit/lib/gcc/current")
                   (file-expand-wildcards
                    "/opt/homebrew/opt/gcc/lib/gcc/current/gcc/aarch64-apple-darwin*/*" t))
           ":")))
