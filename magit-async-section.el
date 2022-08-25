;;; magit-async-section.el --- Magit asynchronous section support -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Damien Merenne <dam@cosinux.org>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:
(require 'cl-macs)
(require 'magit)

(defvar-local magit-async-section-inhibit-fetch nil "Prevent async section from fetching data.")

(defun magit-async-section-refresh (fetcher)
  "Redisplay registered section.

This function is called when the magit buffer is refreshed.  It
starts refreshing the async section data using FETCHER and
triggers a buffer redraw without fetching data again."
  (unless magit-async-section-inhibit-fetch
    (funcall fetcher
             (lambda ()
               (let ((magit-async-section-inhibit-fetch t)) (magit-refresh))))))

(defun magit-async-section-register-finish (fetcher inserter at append)
  "Fetch data using FETCHER, run INSERTER after section AT with APPEND."
  (magit-add-section-hook 'magit-status-sections-hook inserter at append t)
  (magit-refresh)
  (add-hook 'magit-refresh-buffer-hook (apply-partially #'magit-async-section-refresh fetcher) nil t))

(defun magit-async-section-register (fetcher inserter at append)
  "Fetch data using FETCHER, register INSERTER function after section AT with APPEND."
  (funcall fetcher
           (apply-partially #'magit-async-section-register-finish fetcher inserter at append)))

(cl-defmacro magit-async-section-define (mode doc &rest body &key fetcher inserter at append &allow-other-keys)
  "Define minor mode MODE to add an asynchronous section to magit status buffer.

DOC is the documentation for the mode toggle command.

FETCHER is a function taking one argument.  It should fetch the
data that is to be displayed, store it in some buffer-local
variable and then invoke the passed argument with `funcall'.

INSERTER should use the `magit' section plumbing function to
insert the section in the buffer.

BODY contains code to execute each time the mode is enabled or disabled."
  (declare (doc-string 1) (indent defun))
  `(define-minor-mode ,mode ,doc nil nil nil
     ,@body
     (if ,mode
         (magit-async-section-register ,fetcher ,inserter ,at ,append)
       (remove-hook 'magit-status-sections-hook ,inserter)
       (remove-hook 'magit-refresh-buffer-hook
                    (apply-partially #'magit-async-section-refresh ,fetcher))
       (magit-refresh))))

(provide 'magit-async-section)

;;; magit-async-section.el ends here
