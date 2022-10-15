#lang racket/base
; Variable Context
; ---------------------------------------
(provide dec-variable
         get-variable
         set-variable
         set-variables
         substitute-variable)


; Implementation
; ---------------------------------------
(require o4/context/base)

; Struct
; -
; For variables, we store its string and value representation, as well as a flag denoting if the variable should be in-place replaced.
(struct dec-variable (string value f-replace) #:transparent)

; Getter
(define (get-variable ctx name)
  (let ([dec (get-declare ctx name)])
    ; Check that returned declare is of type variable
    (if (dec-variable? dec)
        dec
        null)))

; Setter
(define (set-variable ctx name str val [f-replace #f])
  (set-declare ctx name (dec-variable str val f-replace)))

(define (set-variables ctx vars)
  (for ([var (in-list vars)])
    (apply set-variable ctx var)))

; Substitute Variable
; -
; This function checks if a variable with a given name is present in the given context.
; If not, it simply returns the variable.
; Otherwise, if the replace flag on the found variable is set, it returns the string and value representations of the context variable.
(define (substitute-variable ctx name)
  (let ([var (get-variable ctx name)])
    (if (or (null? var) (not (dec-variable-f-replace var)))
        (values
         (symbol->string name)
         #f)
        (values
         (dec-variable-string var)
         (dec-variable-value var)))))
