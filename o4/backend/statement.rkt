#lang racket/base
; Statement Backend
; ---------------------------------------
(provide block-statement
         assignment-statement
         call-statement
         lvalue
         conditional-statement
         loop-statement
         return-statement
         exit-statement
         empty-statement)


; Implementation
; ---------------------------------------
(require br/macro racket/list racket/string
         o4/backend/expression o4/backend/name o4/context o4/utils/error
         (for-syntax racket/base))

; Block Statement
(define-macro (block-statement STATEMENT-OR-DECLARATIONS ...)
  #'(lambda (ctx)
      (let-values ([(ctx strs) (block-statement-fold ctx STATEMENT-OR-DECLARATIONS ...)])
        (values
         ctx
         (string-join (flatten (reverse strs)) "\n"
                      #:before-first "{\n"
                      #:after-last "\n}")))))

(define (block-statement-fold ctx . stat-or-decs)
  (for/fold ([ctx ctx]
             [strs null])
            ([stat-or-dec (in-list stat-or-decs)])
    (let*-values ([(ctx) (add-scope ctx)]
                  [(ctx str) (stat-or-dec ctx)]
                  [(ctx) (remove-scope ctx)])
      (values
       ctx
       (cons str strs)))))

; Assignment Statement
(define-macro (assignment-statement LVALUE OPERATOR EXPRESSION-ARRAY)
  #'(lambda (ctx)
      (let*-values ([(ctx lvalue-str) (LVALUE ctx)]
                    [(ctx exp-strs exp-vals) (EXPRESSION-ARRAY ctx)]
                    [(exp-arr-dims) (get-expression-array-dimensions exp-strs)])
        ; Expression Array does not have proper structure
        (if exp-arr-dims
            (values
             ctx
             ; In case the assignment statement has an array type, we need to create multiple new assignment statements.
             (for/list ([name (in-list (array-names lvalue-str exp-arr-dims))]
                        [exp (in-list (flatten exp-strs))])
               ; Compound operators need to be expanded with the second operand in brackets, as it could be a sub-expression with lower precedence than the compound operator.
               (if (equal? OPERATOR "=")
                   (format "~a = ~a;" name exp)
                   (format "~a = ~a ~a (~a);" name name (substring OPERATOR 0 1) exp))))
            (raise-array-wrong-dimensions-error "expression array does not have proper structure" #'EXPRESSION-ARRAY)))))

; Call Statement
(define-macro-cases call-statement
  [(call-statement LVALUE ARGUMENT-LIST)
   #'(lambda (ctx)
       (let*-values ([(ctx lvalue-str) (LVALUE ctx)]
                     [(ctx arg-lst-str arg-lst-vals) (ARGUMENT-LIST ctx)]
                     ; Save factory call to context
                     [(fact-body-str) (set-factory-call ctx (string->symbol lvalue-str) arg-lst-vals)])
         (if (equal? lvalue-str fact-body-str)
             (values
              ctx
              (format "~a(~a);" fact-body-str arg-lst-str))
             (values
              ctx
              ; If the call statement is a factory call, we remove the factory call arguments.
              (format "~a;" fact-body-str)))))]
  [(call-statement LVALUE TYPE-ARGUMENT-LIST ARGUMENT-LIST)
   #'(lambda (ctx)
       (let*-values ([(ctx lvalue-str) (LVALUE ctx)]
                     [(fact) (get-factory ctx (string->symbol lvalue-str))]
                     [(ctx type-arg-lst-str) (TYPE-ARGUMENT-LIST ctx)]
                     [(ctx arg-lst-str arg-lst-vals) (ARGUMENT-LIST ctx)])
         ; Factories do not support type parameters
         (if (null? fact)
             (values
              ctx
              (format "~a<~a>(~a);" lvalue-str type-arg-lst-str arg-lst-str))
             (raise-factory-call-error "type arguments do not match type parameters" #'TYPE-ARGUMENT-LIST))))])

; L-Value
(define-macro-cases lvalue
  ; TODO: Check that loop variable is not written
  [(lvalue NAME)
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) (NAME ctx)]
                     ; Check if identifier has to be replaced by e.g. a loop iterator.
                     [(sub-var-str sub-var-val) (substitute-variable ctx (string->symbol name-str))])
         (values
          ctx
          sub-var-str)))]
  [(lvalue LVALUE "[" EXPRESSION "]")
   ; TODO: Handle header stacks
   #'(lambda (ctx)
       (let*-values ([(ctx lvalue-str) (LVALUE ctx)]
                     [(ctx exp-str exp-val) (EXPRESSION ctx)])
         ; The array index has to be compile time known
         (if exp-val
             (values
              ctx
              (format "~a_~a" lvalue-str exp-val))
             (raise-array-index-unknown-error exp-str #'EXPRESSION))))]
  [(lvalue LVALUE "[" START-EXPRESSION ":" END-EXPRESSION "]")
   #'(lambda (ctx)
       (let*-values ([(ctx lvalue-str) (LVALUE ctx)]
                     [(ctx start-str start-val) (START-EXPRESSION ctx)]
                     [(ctx end-str end-val) (END-EXPRESSION ctx)])
         (values
          ctx
          (format "~a[~a:~a]" lvalue-str start-str end-str))))]
  [(lvalue LVALUE "(" ARGUMENT-LIST ")")
   #'(lambda (ctx)
       (let*-values ([(ctx lvalue-str) (LVALUE ctx)]
                     [(ctx arg-lst-str arg-lst-vals) (ARGUMENT-LIST ctx)]
                     ; Save factory call to context
                     [(fact-body-str) (set-factory-call ctx (string->symbol lvalue-str) arg-lst-vals)])
         (if (equal? lvalue-str fact-body-str)
             (values
              ctx
              (format "~a(~a)" fact-body-str arg-lst-str))
             (values
              ctx
              ; If the lvalue is a factory call, we remove the factory call arguments.
              fact-body-str))))]
  [(lvalue LVALUE "." NAME)
   #'(lambda (ctx)
       (let*-values ([(ctx lvalue-str) (LVALUE ctx)]
                     [(ctx name-str) (NAME ctx)])
         (values
          ctx
          (format "~a.~a" lvalue-str name-str))))])

; Conditional Statement
(define-macro-cases conditional-statement
  [(conditional-statement EXPRESSION STATEMENT)
   #'(lambda (ctx)
       (let*-values ([(ctx exp-str exp-val) (EXPRESSION ctx)]
                     ; We wrap the body statement with a block statement, to make sure that expanded statements, such as array type assignment statements are properly scoped.
                     [(ctx stat-str) ((block-statement STATEMENT) ctx)])
         (values
          ctx
          (format "if (~a) ~a" exp-str stat-str))))]
  [(conditional-statement EXPRESSION STATEMENT ELSE-STATEMENT)
   #'(lambda (ctx)
       (let*-values ([(ctx exp-str exp-val) (EXPRESSION ctx)]
                     ; We wrap the body statements with a block statement, to make sure that expanded statements, such as array type assignment statements are properly scoped.
                     [(ctx stat-str) ((block-statement STATEMENT) ctx)]
                     [(ctx else-stat-str) ((block-statement ELSE-STATEMENT) ctx)])
         (values
          ctx
          (format "if (~a) ~a else ~a" exp-str stat-str else-stat-str))))])

; Loop Statement
(define-macro (loop-statement TYPE-NAME NAME EXPRESSION-ARRAY STATEMENT)
  #'(lambda (ctx)
      (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                    [(ctx name-str) (NAME ctx)]
                    [(ctx exp-strs exp-vals) (EXPRESSION-ARRAY ctx)])
        ; Loop iterators with array types are not supported
        (if (null? type-name-dims)
            ; The expression array has to be 1D
            (if (check-expression-array-dimensions? exp-strs (list "*"))
                ; We wrap the body statement with a block statement, to make sure that expanded statements, such as array type assignment statements are properly scoped.
                (let-values ([(ctx stat-strs) (loop-statement-fold ctx name-str exp-strs exp-vals (block-statement STATEMENT))])
                  (values
                   ctx
                   (reverse stat-strs)))
                (raise-array-wrong-dimensions-error "expression array has to be one dimensional" #'EXPRESSION-ARRAY))
            (raise-array-not-allowed-error "loop iterators" #'TYPE-NAME)))))

(define (loop-statement-fold ctx name-str exp-strs exp-vals statement)
  (for/fold ([ctx ctx]
             [stat-strs null])
            ([str (in-list exp-strs)]
             [val (in-list exp-vals)])
    (let*-values ([(ctx) (add-scope ctx)]
                  ; Save variable to context
                  [(_) (set-variable ctx (string->symbol name-str) (first str) (first val) #t)]
                  [(ctx stat-str) (statement ctx)]
                  [(ctx) (remove-scope ctx)])
      (values
       ctx
       (cons stat-str stat-strs)))))

; Return Statement
(define-macro-cases return-statement
  [(return-statement)
   #'(lambda (ctx)
       (values
        ctx
        "return;"))]
  [(return-statement EXPRESSION)
   #'(lambda (ctx)
       (let-values ([(ctx str val) (EXPRESSION ctx)])
         (values
          ctx
          (format "return ~a;" str))))])

; Exit Statement
(define-macro (exit-statement)
  #'(lambda (ctx)
      (values
       ctx
       "exit;")))

; Empty Statement
(define-macro (empty-statement)
  #'(lambda (ctx)
      (values
       ctx
       ";")))
