#|
 This file is a part of Dissect
 (c) 2014 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.tymoonnext.dissect)

(defclass restart ()
  ((name :initarg :name :accessor name)
   (report :initarg :report :accessor report)
   (restart :initarg :restart :accessor restart)
   (object :initarg :object :accessor object)
   (interactive :initarg :interactive :accessor interactive)
   (test :initarg :test :accessor test))
  (:documentation "Class container for restart information."))

(defmethod print-object ((restart restart) stream)
  (print-unreadable-object (restart stream :type T)
    (format stream "[~s] ~s"
            (name restart) (report restart))))

(defclass unknown-arguments ()
  ()
  (:documentation "Used to represent an unknown list of arguments."))

(defmethod print-object ((args unknown-arguments) stream)
  (format stream "#<Unknown Arguments>"))

(defclass unavailable-argument ()
  ()
  (:documentation "Used to represent an argument that isn't available in the environment."))

(defmethod print-object ((arg unavailable-argument) stream)
  (format stream "#<Unavailable>"))

(defclass call ()
  ((pos :initarg :pos :accessor pos)
   (call :initarg :call :accessor call)
   (args :initarg :args :accessor args)
   (file :initarg :file :accessor file)
   (line :initarg :line :accessor line)
   (form :initarg :form :accessor form))
  (:documentation "Class container for stack call information."))

(defmethod print-object ((call call) stream)
  (print-unreadable-object (call stream :type T)
    (format stream "[~a] ~a~@[ | ~a~@[:~a~]~]"
            (pos call) (call call) (file call) (line call))))

(declaim (ftype (function () list) stack restarts)
         (notinline stack restarts))
(defun stack ())

(defun restarts ())

(defgeneric present (thing &optional stream)
  (:documentation "Prints a neat representation of THING to STREAM.
STREAM can be a format destination.
THING can be a list of either RESTARTs or CALLs,a  restart, a call, a condition, or T.
In the last case, the current RESTARTS and STACK are PRESENTed."))

(defmethod present ((condition condition) &optional (stream T))
  (format stream "~a" condition)
  (format stream "~&   [Condition of type ~s]" (type-of condition))
  (format stream "~&~%")
  (present T stream))

(defmethod present ((thing (eql T)) &optional (stream T))
  (present (restarts) stream)
  (format stream "~&~%")
  (present (stack) stream))

(defmethod present ((list list) &optional (stream T))
  (when list
    (etypecase (first list)
      (restart (format stream "~&Available restarts:")
       (loop for i from 0
             for item in list
             do (format stream "~& ~d: " i)
                (present item stream)))
      (call (format stream "~&Backtrace:")
       (loop for item in list
             do (format stream "~& ")
                (present item stream))))))

(defmethod present ((restart restart) &optional (stream T))
  (format stream "[~a] ~a" (name restart) (report restart)))

(defmethod present ((call call) &optional (stream T))
  (let ((*print-pretty* NIL))
    (format stream "~d: ~:[~s ~s~;(~s~{ ~s~})~]"
            (pos call) (listp (args call)) (call call) (args call))))

(declaim (notinline stack-truncator))
(defun stack-truncator (function)
  (funcall function))

(defmacro with-truncated-stack (() &body body)
  `(stack-truncator (lambda () ,@body)))

(declaim (notinline stack-capper))
(defun stack-capper (function)
  (funcall function))

(defmacro with-capped-stack (() &body body)
  `(stack-capper (lambda () ,@body)))