(in-package :llama)

(defvar *lib* (asdf:system-relative-pathname "llama" "llama.cpp/libllama.so"))

(unless (probe-file *lib*)
  (error "to build the library execute 'make clean libllama.so' in the llama.cpp subdirectory"))

#-(or lispworks allegro)
(progn
  (cffi:load-foreign-library *lib*)
  (format t "~%~%   Foreign library ~A loaded~%~%~%" *lib*))

#-(or lispworks allegro) (load (asdf:system-relative-pathname "llama" "llama-cffi.lisp"))

#+lispworks
(progn
  (fli:register-module "libllama.so" :file-name *lib*)
  (format cl:t "~%~%   Foreign library ~A loaded~%~%~%" *lib*))

#+lispworks (assert (not (eq lw:*default-character-element-type* 'base-char)))

#|
(require "foreign-parser")

(defun pretty-name (name) (string-upcase (substitute #\- #\_ name)))

(foreign-parser:process-foreign-file (asdf:system-relative-pathname "llama" "llama.cpp/llama.h")
				     :dff (asdf:system-relative-pathname "llama" "llama-dff-original.lisp")
				     :package "LLAMA" :case-sensitive '(:user-routine pretty-name))

;; make a copy of llama-dff-original.lisp as llama-dff.lisp
;; keep only the definitions of size-t (derived from stddef.h)
;; and uint8-t (derived from _uint8_t.h) and the whole
;; last section derived from llama.h changing occurrences of
;;   (:pointer (:const :char))
;; in function arguments only (without modifying result types) to
;;   (:reference-pass :ef-mb-string)
;; except for argument text in llama-tokenize that should have the form
;;   (:reference-pass (:ef-mb-string :external-format :utf-8))
|#

#+lispworks (load (asdf:system-relative-pathname "llama" "llama-dff.lisp"))

#+allegro
(progn
  (load *lib* :foreign t) ;;"libllama.so" :file-name library)
  (format cl:t "~%~%   Foreign library ~A loaded~%~%~%" *lib*))

#+allegro (load (asdf:system-relative-pathname "llama" "llama-ff.lisp"))

(defclass context-params ()
  ((seed :initarg :seed)
   (n-ctx :initarg :n-ctx)
   (n-batch :initarg :n-batch)
   (n-gpu-layers :initarg :n-gpu-layers)
   (main-gpu :initarg :main-gpu)
   (tensor-split :initarg :tensor-split)
   (rope-freq-base :initarg :rope-freq-base)
   (rope-freq-scale :initarg :rope-freq-scale)
   (progress-callback :initarg :progress-callback)
   (progress-callback-user-data :initarg :progress-callback-user-data)
   (low-vram :initarg :low-vram)
   (mul-mat :initarg :mul-mat)
   (f16-kv :initarg :f16-kv)
   (logits-all :initarg :logits-all)
   (vocab-only :initarg :vocab-only)
   (use-mmap :initarg :use-mmap)
   (use-mlock :initarg :use-mlock)
   (embedding :initarg :embedding)
   #+(or lispworks allegro) foreign-struct))

(defun context-default-params ()
  #+lispworks (let ((ptr (fli:allocate-foreign-object :pointer-type '(:pointer (:struct llama-context-params)))))
		(llama-context-default-params :result-pointer ptr))
  #-lispworks (llama-context-default-params))

(defun max-devices ()
  (llama-max-devices))

(defun mmap-supported ()
  (llama-mmap-supported))

(defun mlock-supported ()
  (llama-mlock-supported))

(defun model-from-file (filename &optional (params (context-default-params)))
  (let ((file (namestring (probe-file (namestring filename)))))
    (assert file)
    (llama-load-model-from-file file params)))

(defun context-from-model (model &optional (params (context-default-params)))
  (assert model)
  (llama-new-context-with-model model params))

#+lispworks
(defmethod initialize-instance :after ((obj context-params) &key)
  (let ((params (context-default-params)))
    (loop for foreign-slot in (fli:foreign-slot-names params)
	  for slot = (intern (string-upcase (substitute #\- #\_ (symbol-name foreign-slot))) "LLAMA")
	  if (slot-boundp obj slot)
	    do (setf (fli:foreign-slot-value params foreign-slot) (slot-value obj slot))
	  else
	    do (setf (slot-value obj slot) (fli:foreign-slot-value params foreign-slot)))
    (setf (slot-value obj 'foreign-struct) params)
    (tg:finalize obj (lambda () (fli:free params)))
    obj))

(defun context-parameters (&rest args)
  #+lispworks (apply #'make-instance 'context-params args)
  #-lispworks (let ((params (context-default-params)))
		(loop for (key value) on args by #'cddr
		      do #+allegro (setf (ff:fslot-value params (intern (symbol-name key) "LLAMA"))
					  (if (numberp value) value (if value 1 0)))
		      #-allegro (setf (slot-value params (intern (symbol-name key) "LLAMA")) value))
		params))

(defclass mdl ()
  ((file :initarg :file :accessor file)
   (params :initarg :params :accessor params
	   :initform #+lispworks (make-instance 'context-params)
		     #-lispworks (context-default-params))
   (foreign-pointer :accessor ptr)))

(defmethod initialize-instance :after ((mdl mdl) &key)
  (let ((ptr (model-from-file (file mdl)
			      #+lispworks (slot-value (params mdl) 'foreign-struct)
			      #-lispworks (params mdl))))
    (setf (slot-value mdl 'foreign-pointer) ptr)
    (tg:finalize mdl (lambda () (llama-free-model ptr))))
  mdl)

(defmethod n-vocab ((mdl mdl))
  (llama-model-n-vocab (ptr mdl)))

(defmethod n-ctx ((mdl mdl))
  (llama-model-n-ctx (ptr mdl)))

(defmethod n-embd ((mdl mdl))
  (llama-model-n-embd (ptr mdl)))

(defmethod size ((mdl mdl))
  (llama-model-size (ptr mdl)))

(defmethod n-params ((mdl mdl))
  (llama-model-n-params (ptr mdl)))

(defmethod desc ((mdl mdl))
  #+lispworks
  (fli:with-dynamic-foreign-objects ()
    (let ((c-string (fli:allocate-dynamic-foreign-object :type :char :nelems 100)))
      (llama-model-desc (ptr mdl) c-string 100)
      (fli:convert-from-foreign-string c-string)))
  #+allegro
  (let ((c-string (ff:allocate-fobject :char :c 100)))
    (unwind-protect
	 (progn (llama-model-desc (ptr mdl) c-string 100)
		(excl:native-to-string c-string))
      (ff:free-fobject c-string)))
  #-(or lispworks allegro)
  (cffi:with-foreign-pointer-as-string ((buf buf-size) 100)
    (llama-model-desc (ptr mdl) buf buf-size)
    (cffi:foreign-string-to-lisp buf)))

(defmethod print-object ((obj mdl) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~A ~A" (desc obj) (file obj))))

(defclass ctx ()
  ((model :initarg :model :accessor model)
   (params :initarg :params :accessor params
	   :initform #+lispworks (make-instance 'context-params)
		     #-lispworks (context-default-params))
   (foreign-pointer :accessor ptr)))

(defmethod initialize-instance :after ((ctx ctx) &key)
  (let ((ptr (context-from-model (ptr (model ctx))
				 #+lispworks (slot-value (params ctx) 'foreign-struct)
				 #-lispworks (params ctx))))
    (setf (ptr ctx) ptr)
    (tg:finalize ctx (lambda () (llama-free ptr))))
  ctx)

(defmethod n-vocab ((ctx ctx))
  (llama-n-vocab (ptr ctx)))

(defmethod n-ctx ((ctx ctx))
  (llama-n-ctx (ptr ctx)))

(defmethod n-embd ((ctx ctx))
  (llama-n-embd (ptr ctx)))

(defmethod vocab-type ((ctx ctx))
  (llama-vocab-type (ptr ctx)))

(defmethod print-object ((obj ctx) stream)
  (print-unreadable-object (obj stream :type t)
    (format stream "~A ~A" (model obj) (params obj))))

(defmethod evaluate ((ctx ctx) tokens n-past &optional (threads 4))
  (llama-eval (ptr ctx) (ptr tokens) (n tokens) n-past threads))

(defclass tokens ()
  ((n :accessor n :initform 0)
   (size :initarg :size :initform (error "specify :size (buffer size)") :accessor size)
   (foreign-pointer :accessor ptr)))

(defmethod initialize-instance :after ((tok tokens) &key)
  (let ((ptr #+lispworks (fli:allocate-foreign-object :type :int :nelems (size tok))
	     #+allegro (ff:allocate-fobject (list :array :int (size tok)))
	     #-(or lispworks allegro) (cffi::foreign-alloc :int :count (size tok))))
    (setf (ptr tok) ptr)
    (tg:finalize tok (lambda () #+lispworks (fli:free ptr)
			     ;;#+allegro (ff:free-fobject ptr)
			     #-(or lispworks allegro) (cffi:foreign-free ptr))))
  tok)

(defmethod list-tokens ((tok tokens) &key (limit 10) context)
  (let ((ids (loop for i below (n tok)
		   repeat (or limit (n tok))
		   collect
		   #+lispworks (fli:dereference (ptr tok) :index i)
		   #+allegro (ff:fslot-value (ptr tok) i)
		   #-(or lispworks allegro) (cffi:mem-aref (ptr tok) :int i))))
    (if context
	(mapcar (lambda (id) (get-token context id)) ids)
	ids)))

(defmethod subset ((tok tokens) start length &key change-first-to-bos)
  (let ((out (make-instance 'tokens :size length)))
    (setf (n out) length)
    (loop for tgt below length
	  for src from start
	  do #+lispworks (setf (fli:dereference (ptr out) :index tgt)
			       (fli:dereference (ptr tok) :index src))
	  #+allegro (setf (ff:fslot-value (ptr out) tgt)
			  (ff:fslot-value (ptr tok) src))
	  #-(or lispworks allegro) (setf (cffi:mem-aref (ptr out) :int tgt)
					 (cffi:mem-aref (ptr tok) :int src)))
    (when change-first-to-bos (setf #+lispworks (fli:dereference (ptr out) :index 0)
				    #+allegro (ff:fslot-value (ptr out) 0)
				    #-(or lispworks allegro) (cffi:mem-aref (ptr out) :int 0)
				    (token-bos change-first-to-bos)))
    out))

(defmethod print-object ((obj tokens) stream)
  (print-unreadable-object (obj stream :type t)
    (let* ((limit 10)
	   (ids (list-tokens obj :limit limit))
	   (add (max 0 (- (n obj) limit))))
      (format stream "~A and ~D tokens more" ids add))))

(defmethod tokenize ((ctx ctx) (tok fixnum) text &key add-beginning-of-sentence)
  (tokenize ctx (make-instance 'tokens :size tok)
	    text :add-beginning-of-sentence add-beginning-of-sentence))

(defmethod tokenize ((ctx ctx) (tok tokens) text &key add-beginning-of-sentence)
  (let ((res (llama-tokenize (ptr ctx) text (length text)
			     (ptr tok) (size tok) add-beginning-of-sentence)))
    (when (minusp res) (error "returned ~D, more than buffer size ~D" (- res) (size tok)))
    (setf (n tok) res)
    tok))

(defmethod get-embeddings ((ctx ctx))
  (let ((ptr (llama-get-embeddings (ptr ctx))))
    (if #+lispworks (fli:null-pointer-p ptr) #+allegro (zerop ptr) #-(or allegro lispworks) (cffi:null-pointer-p ptr)
	(values nil t)
	(let ((out (make-array (list (n-embd ctx)) :initial-element 0.0 :element-type 'float)))
	  (loop for i below (length out)
		do (setf (aref out i)
			 #+lispworks (fli:dereference ptr :index i)
			 #+allegro (ff:fslot-value-typed '(:array :float) :c ptr i)
			 #-(or lispworks allegro) (cffi:mem-aref ptr :float i)))
	  out))))

(defmethod get-logits ((ctx ctx) &optional (n 1))
  (let ((ptr (llama-get-logits (ptr ctx))))
    (unless #+lispworks (fli:null-pointer-p ptr) #+allegro (zerop ptr) #-(or lispworks allegro) (cffi:null-pointer-p ptr)
	    (let ((out (make-array (if (= n 1) (list (n-vocab ctx)) (list n (n-vocab ctx)))
				   :initial-element 0.0 :element-type 'single-float)))
	      (loop for i below (array-total-size out)
		    do (setf (row-major-aref out i)
			     #+lispworks (fli:dereference ptr :index i)
			     #+allegro (ff:fslot-value-typed '(:array :float) :c ptr i)
			     #-(or lispworks allegro) (cffi:mem-aref ptr :float i)))
	      out))))

(defmethod get-token ((ctx ctx) id)
  (ignore-errors 
   #+lispworks (fli:convert-from-foreign-string (llama-token-get-text (ptr ctx) id)
						:external-format :utf-8)
   #-lispworks (llama-token-get-text (ptr ctx) id)))

(defmethod get-vocab ((ctx ctx))
  (loop for id below (n-vocab ctx) collect (get-token ctx id)))

(defmethod token-bos ((ctx ctx))
  (llama-token-bos (ptr ctx)))

(defmethod token-eos ((ctx ctx))
  (llama-token-eos (ptr ctx)))

(defmethod token-nl ((ctx ctx))
  (llama-token-nl (ptr ctx)))

(defmethod sample-repetition-penalty ((ctx ctx) candidates last-tokens penalty)
  (let ((ptr #+lispworks (fli:allocate-foreign-object :type :int :nelems (length last-tokens))
	     #+allegro (ff:allocate-fobject (list :array :int  (length last-tokens)))
	     #-(or lispworks allegro) (cffi::foreign-alloc :int :count (length last-tokens))))
    (unwind-protect
	 (progn
	   (loop for i below (length last-tokens)
		 do (setf #+lispworks (fli:dereference ptr :index i)
			  #+allegro (ff:fslot-value ptr i)
			  #-(or lispworks allegro) (cffi:mem-aref ptr :int i)
			  (elt last-tokens i)))
	   (llama-sample-repetition-penalty (ptr ctx) candidates ptr (length last-tokens)
					    (coerce penalty 'single-float)))
      #+lispworks (fli:free ptr)
      ;;#+allegro (ff:free-fobject ptr)
      #-(or lispworks allegro) (cffi:foreign-free ptr))))

(defmethod sample-frequency-and-presence-penalties ((ctx ctx) candidates last-tokens alpha-frequency alpha-presence)
  (let ((ptr #+lispworks (fli:allocate-foreign-object :type :int :nelems (length last-tokens))
	     #+allegro (ff:allocate-fobject (list :array :int  (length last-tokens)))
	     #-(or lispworks allegro) (cffi::foreign-alloc :int :count (length last-tokens))))
    (unwind-protect
	 (progn
	   (loop for i below (length last-tokens)
		 do (setf #+lispworks (fli:dereference ptr :index i)
			  #+allegro (ff:fslot-value ptr i)
			  #-(or lispworks allegro) (cffi:mem-aref ptr :int i)
			  (elt last-tokens i)))
	   (llama-sample-frequency-and-presence-penalties (ptr ctx) candidates ptr (length last-tokens)
							  (coerce alpha-frequency 'single-float) (coerce alpha-presence 'single-float)))
      #+lispworks (fli:free ptr)
      ;;#+allegro (ff:free-fobject ptr)
      #-(or lispworks allegro) (cffi:foreign-free ptr))))
  
(defmethod sample-softmax ((ctx ctx) candidates)
  (llama-sample-softmax (ptr ctx) candidates))

(defmethod sample-top-k ((ctx ctx) candidates top-k &optional (min-keep 1))
  (llama-sample-top-k (ptr ctx) candidates top-k min-keep))

(defmethod sample-tail-free ((ctx ctx) candidates tfs-z &optional (min-keep 1))
  (llama-sample-tail-free (ptr ctx) candidates tfs-z min-keep))

(defmethod sample-typical ((ctx ctx) candidates typical-p &optional (min-keep 1))
  (llama-sample-typical (ptr ctx) candidates (coerce typical-p 'single-float) min-keep))

(defmethod sample-top-p ((ctx ctx) candidates top-p &optional (min-keep 1))
  (llama-sample-top-p (ptr ctx) candidates (coerce top-p 'single-float) min-keep))

(defmethod sample-temperature ((ctx ctx) candidates temp)
  (llama-sample-temperature (ptr ctx) candidates (coerce temp 'single-float)))

(defmethod sample-token ((ctx ctx) candidates)
  (llama-sample-token (ptr ctx) candidates))

(defmethod sample-token-greedy ((ctx ctx) candidates)
  (llama-sample-token-greedy (ptr ctx) candidates))

(defmethod print-timings ((ctx ctx))
  (llama-print-timings(ptr ctx)))

(defmethod reset-timings ((ctx ctx))
  (llama-reset-timings (ptr ctx)))

(defun system-info ()
  #+lispworks (fli:convert-from-foreign-string (llama-print-system-info))
  #-lispworks (llama-print-system-info))