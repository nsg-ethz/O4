#lang racket/base
; Instantiation Backend
; ---------------------------------------
(provide instantiation)


; Implementation
; ---------------------------------------
(require br/macro
         o4/backend/name o4/context o4/utils/util
         (for-syntax racket/base))

; Instantiation
(define-macro-cases instantiation
  [(instantiation TYPE-NAME ARGUMENT-LIST NAME)
   #'(lambda (ctx)
       (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                     [(ctx arg-lst-str arg-lst-vals) (ARGUMENT-LIST ctx)]
                     [(ctx name-str) (NAME ctx)]
                     ; An extern instance can be a factory body, so we might need to replace its name.
                     [(sub-var-str sub-var-val) (substitute-variable ctx (string->symbol name-str))])
         (values
          ctx
          ; In case the instantiation has an array type, we need to create multiple new instances.
          (for/list ([name (in-list (array-names sub-var-str type-name-dims))])
            (format "~a(~a) ~a;" type-name-str arg-lst-str name)))))]
  [(instantiation TYPE-NAME ARGUMENT-LIST NAME INSTANTIATION-BODY-LINES ...)
   #'(lambda (ctx)
       (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                     [(ctx arg-lst-str arg-lst-vals) (ARGUMENT-LIST ctx)]
                     [(ctx name-str) (NAME ctx)]
                     ; An extern instance can be a factory body, so we might need to replace its name.
                     [(sub-var-str sub-var-val) (substitute-variable ctx (string->symbol name-str))]
                     [(ctx) (add-scope ctx)]
                     [(ctx body-str) (fold-string-join-context-2 ctx "\n" INSTANTIATION-BODY-LINES ...)]
                     [(ctx) (remove-scope ctx)])
         (values
          ctx
          ; In case the instantiation has an array type, we need to create multiple new instances.
          (for/list ([name (in-list (array-names sub-var-str type-name-dims))])
            (format "~a(~a) ~a = {\n~a\n};" type-name-str arg-lst-str name body-str)))))])
