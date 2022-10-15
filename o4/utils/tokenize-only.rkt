#lang racket/base
; Tokenize-Only Dialect
; -
; Use the #lang o4/utils/tokenizer-only language to stop the compilation after the tokenizer.
; ---------------------------------------

; Reader
(module+ reader
  (provide read-syntax)

  ; Implementation
  ; ---------------------------------------
  (require br/syntax brag/support
           o4/frontend/lexer-tokenizer)
  
  (define (read-syntax path port)
    (define tokens (apply-tokenizer o4-tokenizer port))
    (strip-bindings
     #`(module o4-tokenizer-module o4/utils/tokenize-only
         #,@tokens))))


; Expander
(provide (rename-out [tokenize-only-module-begin #%module-begin]) #%datum #%top-interaction)

; Implementation
; ---------------------------------------
(require br/macro
         (for-syntax racket/base))

(define-macro (tokenize-only-module-begin TOKENS ...)
  #'(#%module-begin
     (list TOKENS ...)))
