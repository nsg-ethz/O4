#lang racket/base
; Type Name Backend
; ---------------------------------------
(provide type-name
         type-name-or-void
         simple-type-name)


; Implementation
; ---------------------------------------
(require br/macro
         o4/backend/expression o4/backend/parameter-argument o4/utils/error o4/utils/util
         (for-syntax racket/base))

; Type Name
(define-macro (type-name SIMPLE-TYPE-NAME EXPRESSIONS ...)
  ; TODO: Handle header stacks
  #'(lambda (ctx)
      (let*-values ([(ctx type-name-str) (SIMPLE-TYPE-NAME ctx)]
                    [(ctx exp-strs exp-vals) (fold-context-3 ctx EXPRESSIONS ...)])
        ; Array sizes have to be compile time known
        (if (apply applyable-and exp-vals)
            (values
             ctx
             type-name-str
             exp-vals)
            (for ([exp-str (in-list exp-strs)]
                  [exp-val (in-list exp-vals)]
                  [stx (in-list (list #'EXPRESSIONS ...))])
              (unless exp-val
                (raise-array-index-unknown-error exp-str stx)))))))

; Type Name or Void
(define-macro-cases type-name-or-void
  [(type-name-or-void "void")
   #'(lambda (ctx)
       (values
        ctx
        "void"
        null))]
  [(type-name-or-void TYPE-NAME)
   #'(lambda (ctx)
       (TYPE-NAME ctx))])
  
; Simple Type Name
(define-macro-cases simple-type-name
  [(simple-type-name IDENTIFIER)
   #'(lambda (ctx)
       (values
        ctx
        IDENTIFIER))]
  [(simple-type-name IDENTIFIER (expression ARGS ...))
   #'(lambda (ctx)
       (let-values ([(ctx str val) ((expression ARGS ...) ctx)])
         (values
          ctx
          (format "~a<~a>" IDENTIFIER str))))]
  [(simple-type-name IDENTIFIER (type-argument-list ARGS ...))
   #'(lambda (ctx)
       (let-values ([(ctx str) ((type-argument-list ARGS ...) ctx)])
         (values
          ctx
          (format "~a<~a>" IDENTIFIER str))))])
