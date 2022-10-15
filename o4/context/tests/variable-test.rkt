#lang racket/base
; Variable Context Tests
; ---------------------------------------
(require rackunit
         o4/context/base o4/context/variable o4/utils/util)

; Set & Get Variables
(let* ([ctx (add-scope null)]
       [_ (set-declare ctx 'declare "value")]
       [_ (set-variable ctx 'variable "1" 1)]
       [_ (set-variable ctx 'other_variable "2" 2 #t)]
       [_ (set-variables ctx (list (list 'var1 "value" #f) (list 'var2 "3" 3 #t)))])
  (check-equal?
   (get-variable ctx 'declare)
   null)
  (check-equal?
   (get-variable ctx 'variable)
   (dec-variable "1" 1 #f))
  (check-equal?
   (get-variable ctx 'other_variable)
   (dec-variable "2" 2 #t))
  (check-equal?
   (get-variable ctx 'var1)
   (dec-variable "value" #f #f))
  (check-equal?
   (get-variable ctx 'var2)
   (dec-variable "3" 3 #t)))

; Substitute Variable
(let* ([ctx (add-scope null)]
       [_ (set-variable ctx 'variable "1" 1 #t)]
       [_ (set-variable ctx 'other_variable "2" 2)])
  (check-equal?
   (apply-context
    substitute-variable
    ctx
    'variable)
   (list "1" 1))
  (check-equal?
   (apply-context
    substitute-variable
    ctx
    'other_variable)
   (list "other_variable" #f)))
