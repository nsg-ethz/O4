#lang racket/base
; O4-Halstead Metric
; ---------------------------------------

; Reader
(module+ reader
  (provide read-syntax)

  ; Implementation
  ; ---------------------------------------
  (require br/syntax brag/support
           o4/frontend/lexer-tokenizer)

  ; Lexer Abbreviations
  (define-lex-abbrevs
    [o4-operator o4-reserved-term]
    [o4-operand (:or integer identifier)])
  
  ; Tokenizer
  (define (o4-halstead-tokenizer ip)
    (define (next-token)
      ; Lexer
      (define o4-lexer
        (lexer
         ; Whitespaces
         [whitespace (next-token)]
         ; Comments
         [(from/stop-before "//" "\n") (next-token)]
         [(from/to "/*" "*/") (next-token)]
         ; Annotations
         [annotation (next-token)]
         ; Preprocessor Directives
         [(from/stop-before #\# (:seq (:~ #\\) "\n")) (next-token)]
         ; Operators
         [o4-operator (list 'operator lexeme)]
         ; Operands
         [o4-operand (list 'operand lexeme)]))
      (o4-lexer ip))
    next-token)

  (define (read-syntax path port)
    (define tokens (apply-tokenizer o4-halstead-tokenizer port))
    (strip-bindings
     #`(module o4-halstead-tokenizer-module halstead/o4
         #,@tokens))))


; Expander
(provide (rename-out [o4-halstead-module-begin #%module-begin]) #%app #%datum #%top-interaction
         (all-from-out halstead/util))

; Implementation
; ---------------------------------------
(require br/macro
         halstead/util
         (for-syntax racket/base))

(define-macro (o4-halstead-module-begin TOKENS ...)
  #'(#%module-begin
     (program TOKENS ...)))
