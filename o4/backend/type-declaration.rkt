#lang racket/base
; Type Declaration Backend
; ---------------------------------------
(provide typedef-declaration
         header-declaration
         struct-declaration
         struct-body-line
         enum-declaration
         enum-body
         specified-enum-body
         specified-enum-body-line)


; Implementation
; ---------------------------------------
(require br/macro
         o4/backend/name o4/utils/error o4/utils/util
         (for-syntax racket/base))

; Typedef Declaration
(define-macro (typedef-declaration TYPE-NAME NAME)
  #'(lambda (ctx)
      (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                    [(ctx name-str) (NAME ctx)])
        ; Typedef declarations with array types are not supported
        (if (null? type-name-dims)
            (values
             ctx
             (format "typedef ~a ~a;" type-name-str name-str))
            (raise-array-not-allowed-error "typedef declarations" #'TYPE-NAME)))))

; Header & Struct Declarations
; -
; Struct and header declarations are handled together.
(define-macro header-declaration #'structure-type-declaration)
(define-macro struct-declaration #'structure-type-declaration)

(define-macro (structure-type-declaration TYPE NAME STRUCT-BODY-LINES ...)
  #'(lambda (ctx)
      (let*-values ([(ctx name-str) (NAME ctx)]
                    [(ctx body-str) (fold-string-join-context-2 ctx "\n" STRUCT-BODY-LINES ...)])
        (values
         ctx
         (format "~a ~a {\n~a\n}" TYPE name-str body-str)))))

; Struct Body Line
(define-macro (struct-body-line TYPE-NAME NAME)
  #'(lambda (ctx)
      (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                    [(ctx name-str) (NAME ctx)])
        (values
         ctx
         ; In case the struct body line has an array type, we need to create multiple new struct body lines.
         (for/list ([name (in-list (array-names name-str type-name-dims))])
           (format "~a ~a;" type-name-str name))))))

; Enum Declaration
(define-macro-cases enum-declaration
  [(enum-declaration NAME ENUM-BODY)
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) (NAME ctx)]
                     [(ctx body-str) (ENUM-BODY ctx)])
         (values
          ctx
          (format "enum ~a {\n~a\n}" name-str body-str))))]
  [(enum-declaration TYPE-NAME NAME SPECIFIED-ENUM-BODY)
   #'(lambda (ctx)
       (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                     [(ctx name-str) (NAME ctx)]
                     [(ctx body-str) (SPECIFIED-ENUM-BODY ctx)])
         ; Enum declarations with array types are not supported
         (if (null? type-name-dims)
             (values
              ctx
              (format "enum ~a ~a {\n~a\n}" type-name-str name-str body-str))
             (raise-array-not-allowed-error "enum declarations" #'TYPE-NAME))))])

; Enum & Specified Enum Bodies
(define-macro enum-body #'enum-type-body)
(define-macro specified-enum-body #'enum-type-body)

(define-macro (enum-type-body ENUM-BODY-LINES ...)
  #'(lambda (ctx)
      (fold-string-join-context-2 ctx ",\n" ENUM-BODY-LINES ...)))

; Specified Enum Body Line
(define-macro (specified-enum-body-line NAME EXPRESSION)
  #'(lambda (ctx)
      (let*-values ([(ctx name-str) (NAME ctx)]
                    [(ctx exp-str exp-val) (EXPRESSION ctx)])
        (values
         ctx
         (format "~a = ~a" name-str exp-str)))))
