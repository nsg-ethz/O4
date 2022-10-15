#lang racket/base
; Control Backend
; ---------------------------------------
(provide control-declaration
         deparser-declaration
         control-body
         table-declaration
         key-property
         actions-property
         entries-property
         key-property-body-line
         action-reference
         entries-property-body-line
         custom-property
         factory-declaration)


; Implementation
; ---------------------------------------
(require br/macro
         o4/backend/statement o4/context o4/utils/error o4/utils/util
         (for-syntax br/syntax racket/base))

; Control & Deparser Declaration
; -
; Control and deparser declarations are handled together.
(define-macro control-declaration #'control-deparser-declaration)
(define-macro deparser-declaration #'control-deparser-declaration)

(define-macro (control-deparser-declaration NAME PARAMETER-LISTS ... CONTROL-BODY BLOCK-STATEMENT)
  #'(lambda (ctx)
      (let*-values ([(ctx name-str) (NAME ctx)]
                    [(ctx) (add-scope ctx)]
                    [(ctx param-lsts-str) (fold-string-join-context-2 ctx ")(" PARAMETER-LISTS ...)]
                    [(ctx body-str) (CONTROL-BODY ctx)]
                    [(ctx stat-str) (BLOCK-STATEMENT ctx)]
                    ; After compiling the control block, we recursively expand the collected factory calls.
                    [(ctx body-str) (handle-factory-calls ctx body-str)]
                    [(ctx) (remove-scope ctx)])
        ; Missing or unhandled factory placeholder
        (if body-str
            (values
             ctx
             (format "control ~a(~a) {\n~a\napply ~a\n}" name-str param-lsts-str body-str stat-str))
            (raise-factory-definition-error "missing or unhandled factory placeholder" #'CONTROL-BODY)))))

; Control Body
(define-macro (control-body CONTROL-BODY-LINES ...)
  #'(lambda (ctx)
      (fold-string-join-context-2 ctx "\n" CONTROL-BODY-LINES ...)))

; Table Declaration
(define-macro (table-declaration NAME TABLE-BODY-LINES ...)
  #'(lambda (ctx)
      (let*-values ([(ctx name-str) (NAME ctx)]
                    ; A table can be a factory body, so we might need to replace its name.
                    [(sub-var-str sub-var-val) (substitute-variable ctx (string->symbol name-str))]
                    [(ctx body-str) (fold-string-join-context-2 ctx "\n" TABLE-BODY-LINES ...)])
        (values
         ctx
         (format "table ~a {\n~a\n}" sub-var-str body-str)))))

; Key, Actions & Entries Property
; -
; Key, actions and const entries properties are handled together.
(define-macro key-property #'key-actions-entries-property)
(define-macro actions-property #'key-actions-entries-property)
(define-macro entries-property #'key-actions-entries-property)

(define-macro (key-actions-entries-property PROPERTY PROPERTY-BODY-LINES ...)
  #'(lambda (ctx)
      (let-values ([(ctx body-str) (fold-string-join-context-2 ctx "\n" PROPERTY-BODY-LINES ...)])
        (values
         ctx
         (if (equal? PROPERTY "entries")
             (format "const ~a = {\n~a\n}" PROPERTY body-str)
             (format "~a = {\n~a\n}" PROPERTY body-str))))))

; Key Property Body Line
(define-macro (key-property-body-line EXPRESSION NAME)
  #'(lambda (ctx)
      (let*-values ([(ctx exp-str exp-val) (EXPRESSION ctx)]
                    [(ctx name-str) (NAME ctx)])
        (values
         ctx
         (format "~a : ~a;" exp-str name-str)))))

; Action Reference
(define-macro-cases action-reference
  [(action-reference NAME)
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) (NAME ctx)]
                     ; Save factory call to context
                     [(fact-body-str) (set-factory-call ctx (string->symbol name-str) null)])
         (values
          ctx
          (format "~a;" fact-body-str))))]
  [(action-reference NAME ARGUMENT-LIST)
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) (NAME ctx)]
                     [(ctx arg-lst-str arg-lst-vals) (ARGUMENT-LIST ctx)]
                     ; Save factory call to context
                     [(fact-body-str) (set-factory-call ctx (string->symbol name-str) arg-lst-vals)])
         ; If the action reference is a factory call, we remove the factory call arguments.
         (if (equal? name-str fact-body-str)
             (values
              ctx
              (format "~a(~a);" fact-body-str arg-lst-str))
             (values
              ctx
              (format "~a;" fact-body-str)))))]
  [(action-reference NAME FACTORY-ARGUMENT-LIST ARGUMENT-LIST)
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) (NAME ctx)]
                     [(ctx fact-arg-lst-str fact-arg-lst-vals) (FACTORY-ARGUMENT-LIST ctx)]
                     [(ctx arg-lst-str arg-lst-vals) (ARGUMENT-LIST ctx)]
                     ; Save factory call to context
                     [(fact-body-str) (set-factory-call ctx (string->symbol name-str) fact-arg-lst-vals)])
         ; Double-parametrization on non-factory types is not supported
         (if (equal? name-str fact-body-str)
             (raise-factory-call-error "double-parametrization on non-factory types is not supported" #'FACTORY-ARGUMENT-LIST)
             (values
              ctx
              (format "~a(~a);" fact-body-str arg-lst-str)))))])

; Entries Property Body Line
(define-macro (entries-property-body-line KEYSET-EXPRESSION ACTION-REFERENCE)
  #'(lambda (ctx)
      (let*-values ([(ctx exp-str) (KEYSET-EXPRESSION ctx)]
                    [(ctx act-ref-str) (ACTION-REFERENCE ctx)])
        (values
         ctx
         (format "~a : ~a" exp-str act-ref-str)))))

; Custom Property
(define-macro-cases custom-property
  [(custom-property TABLE-NAME EXPRESSION)
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) (TABLE-NAME ctx)]
                     [(ctx exp-str exp-val) (EXPRESSION ctx)])
         (values
          ctx
          (format "~a = ~a;" name-str exp-str))))]
  [(custom-property "const" TABLE-NAME EXPRESSION)
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) (TABLE-NAME ctx)]
                     [(ctx exp-str exp-val) (EXPRESSION ctx)])
         (values
          ctx
          (format "const ~a = ~a;" name-str exp-str))))])

; Factory Declaration
(define-macro (factory-declaration NAME PARAMETER-LIST DECLARATION RETURN-STATEMENT)
  (pattern-case #'RETURN-STATEMENT
                [(return-statement) 
                 #'(lambda (ctx)
                     ; Missing expression in return statement
                     (raise-factory-definition-error "missing expression in return statement" #'RETURN-STATEMENT))]
                [(return-statement EXPRESSION)
                 ; TODO: Check that body name matches return expression
                 #'(lambda (ctx)
                     (let*-values ([(ctx name-str) (NAME ctx)]
                                   [(ctx) (add-scope ctx)]
                                   [(ctx param-lst-str) (PARAMETER-LIST ctx)]
                                   [(ctx exp-str exp-val) (EXPRESSION ctx)]
                                   ; We need a list of the factory parameters to match the factory call arguments against them.
                                   [(param-lst) (get-parameters-of-scope ctx)]
                                   [(ctx) (remove-scope ctx)])
                       ; Factory parameters must be directionless
                       (if (check-parameters-directionless param-lst)
                           ; Save factory to context
                           (let ([_ (set-factory ctx (string->symbol name-str) exp-str DECLARATION param-lst)])
                             (values
                              ctx
                              ; Set placeholder to allow for placement of factories
                              (format "$$$~a$$$" name-str)))
                           (raise-factory-definition-error "factory parameters must be directionless" #'PARAMETER-LIST))))]))
