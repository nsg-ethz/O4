#lang racket/base
; Name Backend
; ---------------------------------------
(provide name
         table-name
         array-names)


; Implementation
; ---------------------------------------
(require br/macro racket/list
         (for-syntax racket/base))

; Name
(define-macro (name IDENTIFIER)
  #'(lambda (ctx)
      (values
       ctx
       IDENTIFIER)))

; Table Name
(define-macro (table-name IDENTIFIER)
  #'(lambda (ctx)
      (values
       ctx
       IDENTIFIER)))


; Helper Functions
; ---------------------------------------
; Array Names
; -
; Creates a list of numbered names for array-type variables given a base name and a the dimensions of the array.
(define (array-names name dims)
  (for/list ([ending (in-list (array-name-endings dims))])
    (format "~a~a" name ending)))

(define (array-name-endings dims)
  (if (null? dims)
      (list "")
      (flatten
       (for/list ([index (in-range (first dims))])
         (for/list ([ending (in-list (array-name-endings (rest dims)))])
           (format "_~a~a" index ending))))))
