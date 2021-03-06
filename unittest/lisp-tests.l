(deftest fix-previous-pseudo-frame-test ()
  "(previous-pseudo-frame) caused \"appframe not found\" error."
  (previous-pseudo-frame)
  => nil)


;; (make-frame) create strange scratch buffer
;(deftest fix-multiframe-create-strange-buffer-test ()
;; make frame asis cause split-window problem.
;; So I comment out this test now.
(defun dummy-fix-multiframe-create-strange-buffer-test ()
  (let* ((org (length (buffer-list)))
	 frame res)
    (setq frame (make-frame))
    (setq res (= org (length (buffer-list))))
    ;; changing selected-frame cause problem.
    ;; (delete-frame frame)
    res)
  => t)

(defun make-test-package (&rest options)
  (let ((name (format nil "temporary-package-for-test-~D" (test-uid))))
    (apply #'make-package name options)))

(deftest fix-list-all-packages-test ()
  "(list-all-packages) should return 'a copy of' system package list."
  (let* ((pkg (make-test-package))
         (name (package-name pkg))
	 (pkglist (list-all-packages)))
    (delete pkg pkglist)
    (eq pkg (find-package name)))
  => t)

(defmacro with-moved-p (&body body)
  `(let* ((#1=#:point (point)))
     (save-excursion
       ,@body
       (not (eq #1# (point))))))

(defmacro with-c++-bed (&body body)
  `(with-temp-buffer
    (c++-mode)
    ,@body
    ))

(defun setup-text(text)
  (insert text)
  (goto-char 0))

(deftest fix-parenthesis-escape-case-forward ()
  "cc mode goto-matched parentheis does not understand escape for hanlding comment"
  (with-c++-bed
   (setup-text "(hoge\\//)")
   (with-moved-p
    (goto-matched-parenthesis)))
  => t)

(deftest fix-parenthesis-escape-case-backward ()
  "cc mode goto-matched parentheis does not understand escape for hanlding comment, backward"
  (with-c++-bed
   (setup-text "(hoge\\//)")
   (search-forward ")")
   (with-moved-p
    (goto-matched-parenthesis)))
  => t)

(deftest fix-parenthesis-no-escape-case-forward ()
  "cc mode goto-matched parentheis does not understand escape for hanlding comment, not escape case"
  (with-c++-bed
   (setup-text "(hoge\\\\//)")
   (with-moved-p
    (goto-matched-parenthesis)))
  => nil)

(deftest fix-parenthesis-no-escape-case-backward ()
  "cc mode goto-matched parentheis does not understand escape for hanlding comment, not escape case, backward"
  (with-c++-bed
   (setup-text "(hoge\\\\//)")
   (search-forward ")")
   (with-moved-p
    (goto-matched-parenthesis)))
  => nil)

(deftest fix-ole-getmethod-immediate-array ()
  (let ((xhr (ole-create-object "MSXML2.XMLHTTP")))
    (ole-method xhr 'open "GET" "https://github.com/mumurik/xyzzy/" nil) ;; blocking!
    (ole-method xhr 'send nil)
    (ole-method xhr 'responseBody))
  => non-nil)

(defmacro with-lispmode-bed (&body body)
  `(with-temp-buffer
     (lisp-mode)
     ,@body))

(defmacro user::smart-indentation-test (&whole whole &environment env vars &body body)
  `(prog ,vars ,@body))

(deftest lispmode-smart-indentation-for-macro-form-test ()
  "smart indentation for macro function symbol without
lisp-indent-hook property"
  (let ((*lisp-body-indent* 2)
	(*lisp-body-indention* 2))
    (with-lispmode-bed
      (setq *buffer-package* "user")
      (insert "(smart-indentation-test (a b)")
      (goto-char 23)
      #0=(lisp-newline-and-indent)
      (values #1=(current-column)
	      (and (goto-char (point-max)) #0# #1#))))
  => 4
  => 2)

(deftest tags-setup-buffer-for-XTAGS-using-upper-directory ()
  "上位ディレクトリにある XTAGS を参照するのに失敗していたのを修正"
  ;; `ed::tags-setup-buffer` looks at XTAGS file in buffer returned
  ;; by `ed::find-tags-buffer`. If it contains line like "#USE ../../",
  ;; it call `ed::find-tags-buffer` again with relative path in that
  ;; line ("../../" for above example).
  ;; To see if it finds appropriate part of "#USE ../../" line, directory
  ;; name given to `ed::find-tags-buffer` is checked.
  (with-temp-buffer
   (let (referred-dir)
     (insert "#USE ../../\n")
     (with-fake-functions ((ed::find-tags-buffer (&optional dir)
                             (when dir
                               (setf referred-dir dir))
                             (selected-buffer))
                           (namestring (x) x))
       (ed::tags-setup-buffer))
     referred-dir))
  => "../../")
