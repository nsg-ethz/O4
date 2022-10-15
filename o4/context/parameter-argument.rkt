#lang racket/base
; Parameter & Argument Context
; ---------------------------------------
(provide dec-parameter
         get-parameters-of-scope
         set-parameter
         check-parameters-directionless
         get-argument-metadata
         check-argument-metadata-list
         get-parameter-argument-map)


; Implementation
; ---------------------------------------
(require racket/list
         o4/context/base o4/utils/error o4/utils/util)


; Parameters
; ---------------------------------------
; Struct
; -
; For parameters, we store its position in the parameter list, its direction and the string and value representations of its default value.
(struct dec-parameter (position direction default-string default-value) #:transparent)

; Getter
(define (get-parameters-of-scope ctx)
  (let ([decs (get-declares-of-scope ctx)])
    (if (null? decs)
        null
        ; Sort parameters by position
        (sort 
         ; Throw out null values from list of parameters
         (filter
          pair?
          ; Create list of name-parameter-pairs for all parameters in scope
          (hash-map decs (lambda (k v)
                           (if (dec-parameter? v)
                               (cons k v)
                               null))))
         <
         #:key (lambda (param)
                 (dec-parameter-position (cdr param)))))))

; Setter
(define (set-parameter ctx name pos dir [expr-str #f] [exp-val #f])
  (set-declare ctx name (dec-parameter pos dir expr-str exp-val)))

; Check Parameters Directionless
; -
; Checks that the given parameters are directionless.
(define (check-parameters-directionless params)
  (for/and ([param (in-list params)])
    (not (dec-parameter-direction (cdr param)))))


; Arguments
; ---------------------------------------
; Struct
; -
; The argument metadata stores the string and value representations of an argument, as well as its name (if it is a named argument).
(struct argument-metadata (string value name) #:transparent)

; Getter
(define (get-argument-metadata str val [name #f])
  (argument-metadata str val name))

; Check Argument Metadata List
; -
; Checks if either all or no of the given arguments are named.
; TODO: Check that argument names are unique
(define (check-argument-metadata-list vals)
  (let ([vals (map argument-metadata-name vals)])
    ; Check that either no arguments or all arguments are named
    (or (not (apply applyable-or vals)) (apply applyable-and vals))))


; Helper Functions
; ---------------------------------------
; Get Parameter Argument Map
; -
; This function maps arguments to parameters.
; It supports both named and unnamed arguments, as well as parameters with and without default values.
; If there are excess arguments, they are silently ignored.
; It returns a list containing the parameter name and its string and value representation for each parameter in the given parameter list.
(define (get-parameter-argument-map params args)
  (for/list ([param (in-list params)]
             [pos (in-naturals)])
    (let* ([param-name (car param)]
           [param (cdr param)]
           [arg (get-parameter-argument param-name pos args)])
      (if arg
          (list
           param-name
           (argument-metadata-string arg)
           (argument-metadata-value arg))
          ; Parameters without assigned argument must have a default value
          (if (dec-parameter-default-string param)
              (list
               param-name
               (dec-parameter-default-string param)
               (dec-parameter-default-value param))
              (raise-argument-list-error "too few arguments"))))))

(define (get-parameter-argument param-name pos args)
  (if (null? args)
      #f
      ; Check if arguments are named
      (if (argument-metadata-name (first args))
          (findf
           (lambda (arg)
             (equal? (argument-metadata-name arg) (symbol->string param-name)))
           args)
          (with-handlers ([exn:fail:contract? (lambda (exn) #f)])
            (list-ref args pos)))))
