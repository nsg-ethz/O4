#lang racket/base
; Parse-Only Dialect
; -
; Use the #lang o4/utils/parse-only language to stop the compilation after the parser.
; ---------------------------------------

; Reader
(module+ reader
  (provide read-syntax)

  ; Implementation
  ; ---------------------------------------
  (require br/syntax
           o4/frontend/lexer-tokenizer o4/frontend/parser)
  
  (define (read-syntax path port)
    (define parse-tree (parse path (o4-tokenizer port path)))
    (strip-bindings
     #`(module o4-parser-module o4/utils/parse-only
         #,parse-tree))))


; Expander
(provide (rename-out [parser-only-module-begin #%module-begin]) #%top-interaction)

; Implementation
; ---------------------------------------
(require br/macro
         (for-syntax racket/base))

(define-macro (parser-only-module-begin PARSE-TREE)
  #'(#%module-begin
     'PARSE-TREE))
