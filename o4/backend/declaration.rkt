#lang racket/base
; Declaration Backend
; ---------------------------------------
(provide preprocessor-declaration
         constant-declaration
         action-declaration
         function-declaration
         variable-declaration)


; Implementation
; ---------------------------------------
(require br/macro racket/list
         o4/backend/expression o4/backend/name o4/context o4/utils/error
         (for-syntax racket/base))

; Preprocessor Declaration
(define-macro (preprocessor-declaration PREPROCESSOR-DIRECTIVE)
  #'(lambda (ctx)
      (values
       ctx
       PREPROCESSOR-DIRECTIVE)))

; Constant Declaration
(define-macro (constant-declaration TYPE-NAME NAME EXPRESSION-ARRAY)
  #'(lambda (ctx)
      (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                    [(ctx name-str) (NAME ctx)]
                    [(ctx exp-strs exp-vals) (EXPRESSION-ARRAY ctx)])
        ; The array size has to match the expression array size
        (if (check-expression-array-dimensions? exp-strs type-name-dims)
            (values
             ctx
             ; In case the constant declaration has an array type, we need to create multiple new declarations.
             (for/list ([name (in-list (array-names name-str type-name-dims))]
                        [exp (in-list (flatten exp-strs))])
               (format "const ~a ~a = ~a;" type-name-str name exp)))
            (raise-array-wrong-dimensions-error "type and initializer dimensions do not match" #'TYPE-NAME #'EXPRESSION-ARRAY)))))

; Action Declaration
(define-macro (action-declaration NAME PARAMETER-LIST BLOCK-STATEMENT)
  #'(lambda (ctx)
      (let*-values ([(ctx name-str) (NAME ctx)]
                    ; An action can be a factory body, so we might need to replace its name.
                    [(sub-var-str sub-var-val) (substitute-variable ctx (string->symbol name-str))]
                    [(ctx) (add-scope ctx)]
                    [(ctx param-lst-str) (PARAMETER-LIST ctx)]
                    [(ctx stat-str) (BLOCK-STATEMENT ctx)]
                    [(ctx) (remove-scope ctx)])
        (values
         ctx
         (format "action ~a(~a) ~a" sub-var-str param-lst-str stat-str)))))

; Function Declaration
(define-macro-cases function-declaration
  [(function-declaration TYPE-NAME-OR-VOID NAME PARAMETER-LIST BLOCK-STATEMENT)
   #'(lambda (ctx)
       (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME-OR-VOID ctx)]
                     [(ctx name-str) (NAME ctx)]
                     [(ctx) (add-scope ctx)]
                     [(ctx param-lst-str) (PARAMETER-LIST ctx)]
                     [(ctx stat-str) (BLOCK-STATEMENT ctx)]
                     [(ctx) (remove-scope ctx)])
         ; Function declarations with array types are not supported
         (if (null? type-name-dims)
             (values
              ctx
              (format "~a ~a(~a) ~a" type-name-str name-str param-lst-str stat-str))
             (raise-array-not-allowed-error "function declarations" #'TYPE-NAME-OR-VOID))))]
  [(function-declaration TYPE-NAME-OR-VOID NAME TYPE-PARAMETER-LIST PARAMETER-LIST BLOCK-STATEMENT)
   #'(lambda (ctx)
       (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME-OR-VOID ctx)]
                     [(ctx name-str) (NAME ctx)]
                     [(ctx) (add-scope ctx)]
                     [(ctx type-param-lst-str) (TYPE-PARAMETER-LIST ctx)]
                     [(ctx param-lst-str) (PARAMETER-LIST ctx)]
                     [(ctx stat-str) (BLOCK-STATEMENT ctx)]
                     [(ctx) (remove-scope ctx)])
         ; Function declarations with array types are not supported
         (if (null? type-name-dims)
             (values
              ctx
              (format "~a ~a<~a>(~a) ~a" type-name-str name-str type-param-lst-str param-lst-str stat-str))
             (raise-array-not-allowed-error "function declarations" #'TYPE-NAME-OR-VOID))))])

; Variable Declaration
(define-macro-cases variable-declaration
  [(variable-declaration TYPE-NAME NAME)
   #'(lambda (ctx)
       (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                     [(ctx name-str) (NAME ctx)])
         (values
          ctx
          ; In case the variable declaration has an array type, we need to create multiple new declarations.
          (for/list ([name (in-list (array-names name-str type-name-dims))])
            (format "~a ~a;" type-name-str name)))))]
  [(variable-declaration TYPE-NAME NAME EXPRESSION-ARRAY)
   #'(lambda (ctx)
       (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                     [(ctx name-str) (NAME ctx)]
                     [(ctx exp-strs exp-vals) (EXPRESSION-ARRAY ctx)])
         ; The array size has to match the expression array size
         (if (check-expression-array-dimensions? exp-strs type-name-dims)
             (values
              ctx
              ; In case the variable declaration has an array type, we need to create multiple new declarations.
              (for/list ([name (in-list (array-names name-str type-name-dims))]
                         [exp (in-list (flatten exp-strs))])
                (format "~a ~a = ~a;" type-name-str name exp)))
             (raise-array-wrong-dimensions-error "type and initializer dimensions do not match" #'TYPE-NAME #'EXPRESSION-ARRAY))))])
