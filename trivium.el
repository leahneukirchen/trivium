;;; trivium.el --- convenience functions for the Trivium blogging system
;; 04oct2008  +chris+

(defface trivium-field-face
  '((t (:bold t :underline t :background "grey25")))
  "Face to use for RFC822 header fields in trivium-mode."
  :group 'font-lock-highlighting-faces)

(defface trivium-value-face
  '((t (:bold t :background "grey25")))
  "Face to use for RFC822 header values in trivium-mode."
  :group 'font-lock-highlighting-faces)

(defface trivium-leading-space-face
  '((t (:background "grey40")))
  "Face to use for leading space in trivium-mode."
  :group 'font-lock-highlighting-faces)

(defface trivium-trailing-space-face
  '((t (:background "grey40")))
  "Face to use for trailing space in trivium-mode."
  :group 'font-lock-highlighting-faces)

(defun trivium-update-blog ()
  "Update the blog."
  (interactive)
  (let ((process-connection-type nil))
    (compile "cd .. ; ruby trivium.rb")))

(defun trivium-upload-blog ()
  "Upload the blog."
  (interactive)
  (let ((process-connection-type nil))
    (compile "cd .. ; ruby trivium.rb && ./upload")))

(defun trivium-insert-link-markup ()
  "Insert a '.link'."
  (interactive)
  (insert ".link \n")
  (save-excursion
    (insert "\n.link.\n")))

(defun trivium-find-highest-link ()
  (save-excursion
    (goto-char (point-min))
    (let ((highest 0))
      (while (re-search-forward "\\[\\([0-9]+\\)\\]:" nil t)
        (setq highest (max highest (string-to-number (match-string 1)))))
      highest)))

(defun trivium-insert-link (region-as-id)
  "Insert a Markdown link.
With prefix argument, the region is used as link id, else a
unique number will be used.

Enter the URL, press C-x C-x to get back to the text."
  (interactive "N")
  (let ((id (if region-as-id
                (buffer-substring (region-beginning) (region-end))
              (int-to-string (1+ (trivium-find-highest-link)))))
        (start (region-beginning))
        (end (region-end)))
    (when region-as-id
      (goto-char start))
    (insert "[")
    (if region-as-id
        (progn
          (goto-char (1+ end))
          (insert "][]")
          (push-mark))
      (push-mark)
      (insert "][" id "]"))

    (forward-paragraph)

    (if (looking-at "\n  \\[")
        (forward-paragraph)
      (when (eobp)
        (insert "\n"))
      (insert "\n"))

    (insert "  [" id "]: ")
    (save-excursion
      (unless (looking-at "\n\n")
        (insert "\n")))
    (message "Enter the URL, press C-x C-x to get back to the text.")))

(defun trivium-new-blog-entry ()
  "Start a new blog entry.\n
Call this function inside an empty buffer."
  (interactive)
  (goto-char (point-min))
  (insert "Date: " (format-time-string "%a, %_d %b %Y %H:%M:%S %z" (current-time))
	  "\n\n")
  (goto-char (point-max))
  (trivium-mode))

(define-derived-mode trivium-mode
  text-mode "Trivium"
  "Major mode for editing Trivium weblog entries."
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults
	'((("^\\([A-Z][A-Za-z0-9_]*:\\)\\(.*\n\\)"
	    (1 'trivium-field-face)
	    (2 'trivium-value-face))
	   ("^\t" . 'trivium-leading-space-face)
	   ("^    " . 'trivium-leading-space-face)
	   ("  $" . 'trivium-trailing-space-face)
	   )
	  t nil))
  (make-local-variable 'paragraph-separate)
  (make-local-variable 'paragraph-start)
  (setq paragraph-separate "[ \t\f]*$\\|\\.")
  (setq paragraph-start "\f\\|[ 	]*$\\|\\.")
  (font-lock-mode 1)
  (set-buffer-file-coding-system 'utf-8 nil t))

(define-key trivium-mode-map (kbd "C-c C-c") 'trivium-update-blog)
(define-key trivium-mode-map (kbd "C-c C-u") 'trivium-upload-blog)

(define-key trivium-mode-map (kbd "C-c C-l") 'trivium-insert-link-markup)
(define-key trivium-mode-map (kbd "C-c l") 'trivium-insert-link)

(global-set-key (kbd "C-x M") 'trivium-new-blog-entry)

(provide 'trivium)
