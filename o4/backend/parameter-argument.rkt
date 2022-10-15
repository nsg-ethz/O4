#lang racket/base
; Parameter & Argument Backend
; ---------------------------------------
(provide parameter-list
         parameter
         direction
         type-parameter-list
         argument-list
         argument
         type-argument-list)


; Implementation
; ---------------------------------------
(require br/macro racket/list racket/string
         o4/backend/expression o4/backend/name o4/context o4/utils/error o4/utils/util
         (for-syntax racket/base))

; Parameter List
(define-macro (parameter-list PARAMETERS ...)
  #'(lambda (ctx)
      (let-values ([(ctx strs _) (parameter-fold ctx PARAMETERS ...)])
        (values
         ctx
         (string-join (flatten (reverse strs)) ", ")))))

(define (parameter-fold ctx . params)
  (for/fold ([ctx ctx]
             [strs null]
             ; We need to manually keep track of the position of individual parameters, as certain parameters might have array types.
             [pos 0])
            ([param (in-list params)])
    (let-values ([(ctx str pos) (param ctx pos)])
      (values
       ctx
       (cons str strs)
       pos))))

; Parameter
(define-macro-cases parameter
  [(parameter DIRECTION TYPE-NAME NAME)
   #'(lambda (ctx pos)
       (let*-values ([(ctx dir) (DIRECTION ctx)]
                     [(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                     [(ctx name-str) (NAME ctx)]
                     [(arr-names) (array-names name-str type-name-dims)])
         (values
          ctx
          ; In case the parameter has an array type, we need to create multiple new parameters.
          (for/list ([name (in-list arr-names)]
                     [pos-offset (in-naturals)])
            ; Save parameter to context
            (set-parameter ctx (string->symbol name) (+ pos pos-offset) dir)
            (if dir
                (format "~a ~a ~a" dir type-name-str name)
                (format "~a ~a" type-name-str name)))
          ; Increase the parameter position.
          (+ pos (length arr-names)))))]
  [(parameter DIRECTION TYPE-NAME NAME EXPRESSION-ARRAY)
   #'(lambda (ctx pos)
       (let*-values ([(ctx dir) (DIRECTION ctx)]
                     [(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                     [(ctx name-str) (NAME ctx)]
                     [(ctx exp-strs exp-vals) (EXPRESSION-ARRAY ctx)])
         ; The array size has to match the expression array size
         (if (check-expression-array-dimensions? exp-strs type-name-dims)
             (let ([arr-names (array-names name-str type-name-dims)])
               (values
                ctx
                ; In case the parameter has an array type, we need to create multiple new parameters.
                (for/list ([name (in-list arr-names)]
                           [exp-str (in-list (flatten exp-strs))]
                           [exp-val (in-list (flatten exp-vals))]
                           [pos-offset (in-naturals)])
                  ; Save parameter to context
                  (set-parameter ctx (string->symbol name) (+ pos pos-offset) dir exp-str exp-val)
                  (if dir
                      (format "~a ~a ~a = ~a" dir type-name-str name exp-str)
                      (format "~a ~a = ~a" type-name-str name exp-str)))
                ; Increase the parameter position.
                (+ pos (length arr-names))))
             (raise-array-wrong-dimensions-error "type and initializer dimensions do not match" #'TYPE-NAME #'EXPRESSION-ARRAY))))])

; Direction
(define-macro-cases direction
  [(direction)
   #'(lambda (ctx)
       (values
        ctx
        #f))]
  [(direction DIRECTION)
   #'(lambda (ctx)
       (values
        ctx
        DIRECTION))])

; Type Parameter List
(define-macro (type-parameter-list NAMES ...)
  #'(lambda (ctx)
      (fold-string-join-context-2 ctx ", " NAMES ...)))

; Argument List
; -
; Arguments do not only return the compiler context and a string representation of itself, but also a list of argument metadata.
(define-macro (argument-list ARGUMENTS ...)
  #'(lambda (ctx)
      (let-values ([(ctx strs vals) (fold-context-3 ctx ARGUMENTS ...)])
        ; Check argument metadata list
        (if (check-argument-metadata-list (flatten vals))
            (values
             ctx
             (string-join (flatten strs) ", ")
             (flatten vals))
            (raise-argument-list-error "either no or all arguments must be named" #'ARGUMENTS ...)))))

; Argument
(define-macro-cases argument
  [(argument EXPRESSION-ARRAY)
   #'(lambda (ctx)
       (let-values ([(ctx strs vals) (EXPRESSION-ARRAY ctx)])
         (values
          ctx
          ; In case the argument has an array type, we need to create multiple new arguments.
          (flatten strs)
          ; Create argument metadata list
          (map get-argument-metadata (flatten strs) (flatten vals)))))]
  [(argument NAME EXPRESSION-ARRAY)
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) (NAME ctx)]
                     [(ctx exp-strs exp-vals) (EXPRESSION-ARRAY ctx)]
                     [(exp-arr-dims) (get-expression-array-dimensions exp-strs)])
         ; Expression Array does not have proper structure
         (if exp-arr-dims
             (let ([arr-names (array-names name-str exp-arr-dims)])
               (values
                ctx
                ; In case the argument has an array type, we need to create multiple new arguments.
                (for/list ([name (in-list arr-names)]
                           [exp-str (in-list (flatten exp-strs))])
                  (format "~a = ~a" name exp-str))
                ; Create argument metadata list
                (map get-argument-metadata (flatten exp-strs) (flatten exp-vals) arr-names)))
             (raise-array-wrong-dimensions-error "expression array does not have proper structure" #'EXPRESSION-ARRAY))))])

; Type Argument List
(define-macro (type-argument-list TYPE-NAME-OR-VOIDS ...)
  #'(lambda (ctx)
      (let-values ([(ctx strs dims-lst) (fold-context-3 ctx TYPE-NAME-OR-VOIDS ...)])
        ; Type arguments with array types are not supported
        (if (apply applyable-and (map null? dims-lst))
            (values
             ctx
             (string-join strs ", "))
            (for ([dims (in-list dims-lst)]
                  [stx (in-list (list #'TYPE-NAME-OR-VOIDS ...))])
              (unless (null? dims)
                (raise-array-not-allowed-error "type arguments" stx)))))))
