#lang racket/base
; P4-Halstead Metric
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
    [p4-operator (:or "]" "." "?" "<=" "+" "}" "~" ":" "," ">=" ">>" "&&&" "(" ".." "&" "!" "|+|" "|" "{" "-" "*"
                      "=" "==" "<<" "++" "[" "%" "!=" "_" ";" ">" "&&" "/" ")" "^" "||" "|-|" "@" "<" "switch"
                      "package" "valueset" "return" "if" "exit" "const" "bit" "header" "string" "false" "typedef"
                      "int" "this" "else" "header_union" "varbit" "abstract" "type" "parser" "bool" "error" "struct"
                      "match_kind" "actions" "entries" "apply" "control" "enum" "out" "true" "action" "table"
                      "inout" "extern" "state" "void" "select" "default" "in" "transition" "tuple" "key")]
    [p4-operand (:or integer identifier)])
  
  ; Tokenizer
  (define (p4-halstead-tokenizer ip)
    (define (next-token)
      ; Lexer
      (define p4-lexer
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
         [p4-operator (list 'operator lexeme)]
         ; Operands
         [p4-operand (list 'operand lexeme)]))
      (p4-lexer ip))
    next-token)

  (define (read-syntax path port)
    (define tokens (apply-tokenizer p4-halstead-tokenizer port))
    (strip-bindings
     #`(module p4-halstead-tokenizer-module halstead/p4
         #,@tokens))))


; Expander
(provide (rename-out [p4-halstead-module-begin #%module-begin]) #%app #%datum #%top-interaction
         (all-from-out halstead/util))

; Implementation
; ---------------------------------------
(require br/macro
         halstead/util
         (for-syntax racket/base))

(define-macro (p4-halstead-module-begin TOKENS ...)
  #'(#%module-begin
     (program TOKENS ...)))
