;; Copyright (C) 2013 Free Software Foundation, Inc.

;; Author: Alex Ott <alexott@gmail.com>

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.
;;; jvm-base.el --- 

(require 'ede)
(require 'cedet-files)

;;;###autoload
(defclass ede-single-root-project (ede-project)
  ((file-mod-time :initform 0)
   (current-target :initform ""
		   :initarg :current-target
		   :type string)
   (target-options :initform nil
		   :initarg :target-options
		   :type list)
   (existing-targets :initform nil
		     :initarg :existing-targets
		     :type list)
   )
  "Base project class for projects with project file in root directory."
  :method-invocation-order :depth-first)

(defmethod initialize-instance ((this ede-single-root-project)
                                &rest fields)
  "Make sure the :targets is setup."
  (call-next-method)
  (unless (slot-boundp this 'targets)
    (oset this :targets nil)))

;;; TARGET MANAGEMENT
;;

(defclass ede-single-root-target (ede-target)
  ((project :initform nil
	    :initarg :project)
   )
  "EDE Single Root Project target.
All directories need at least one target.")

(defun ede-single-root-find-matching-target (class dir targets)
  "Find a target that is a CLASS and is in DIR in the list of TARGETS."
  (let ((match nil))
    (dolist (T targets)
      (when (and (object-of-class-p T class)
                 (string= (oref T :path) dir))
        (setq match T)
	))
    match))

(defmethod ede-find-target ((proj ede-single-root-project) buffer)
  "Find an EDE target in PROJ for BUFFER.
If one doesn't exist, create a new one for this directory."
  (let* ((ext (file-name-extension (buffer-file-name buffer)))
         (cls 'ede-single-root-target)
         (targets (oref proj targets))
         (dir default-directory)
         (ans (ede-single-root-find-matching-target cls dir targets))
         )
    (when (not ans)
      (setq ans (make-instance
                 cls
                 :name (file-name-nondirectory (directory-file-name dir))
                 :path dir
                 :source nil
		 :project proj))
      (object-add-to-list proj :targets ans))
    ans))

(defmethod project-compile-target ((obj ede-single-root-target) &optional command)
  "Compile the current target OBJ.
Argument COMMAND is the command to use for compiling the target."
  (when (oref obj :project)
    (project-compile-project (oref obj :project) command)))

;;; File Stuff
;;
(defmethod ede-project-root-directory ((this ede-single-root-project)
                                       &optional file)
  "Return the root for THIS project with file."
  (oref this :directory))

(defmethod ede-project-root ((this ede-single-root-project))
  "Return my root."
  this)

(defmethod ede-find-subproject-for-directory ((proj ede-single-root-project)
                                              dir)
  "Return PROJ, for handling all subdirs below DIR."
  proj)


;;; Utility functions
(defun ede-single-root-get-mod-time (file)
  "Returns modification time for given file"
  (if (file-exists-p file)
      (float-time (nth 5 (file-attributes file)))
    0))

(defun ede-single-root-file-updated-p (proj)
  "Checks, was project file updated since last check or not."
  (when proj
    (> (ede-single-root-get-mod-time (oref proj file))
       (oref proj file-mod-time))))

(provide 'ede/single-root)

;; Local variables:
;; generated-autoload-file: "loaddefs.el"
;; generated-autoload-load-name: "ede/single-root"
;; End:

;;; jvm-base.el ends here
