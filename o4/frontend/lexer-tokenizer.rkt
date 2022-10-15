#lang racket/base
; Lexer & Tokenizer Frontend
; ---------------------------------------
(provide integer
         identifier
         (rename-out [reserved-term o4-reserved-term])
         annotation
         o4-lexer
         o4-tokenizer)


; Implementation
; ---------------------------------------
(require brag/support)

; Lexer Abbreviations
; -
; A number of regex-like patterns that match different character sequences.
(define-lex-abbrevs
  [alphabetic (:or (:/ #\a #\z) (:/ #\A #\Z))]
  [numeric (:/ #\0 #\9)]
  [octal (:/ #\0 #\7)]
  [hexadecimal (:or (:/ #\0 #\9) (:/ #\a #\f) (:/ #\A #\F))]
  [binary (:/ #\0 #\1)]
  ; This matches all types of P4 integers, except integers containing underscores as e.g. "8w0b0000_1111".
  [integer (:seq
            (:? (:seq (:+ numeric) (:or #\s #\w)))
            (:or
             (:seq (:? (:or "0d" "0D")) (:+ numeric))
             (:seq (:or "0o" "0O") (:+ octal))
             (:seq (:or "0x" "0X") (:+ hexadecimal))
             (:seq (:or "0b" "0B") (:+ binary))))]
  [identifier (:seq
               (:or alphabetic #\_)
               (:* (:or alphabetic numeric #\_)))]
  [reserved-term (:or
                  ; Brackets
                  #\( #\) #\[ #\] #\{ #\} #\< #\>
                  ; Punctuation Operators
                  #\. #\, #\: #\;
                  ; Arithmetic Operators
                  #\= #\+ #\- #\* #\/ #\% "+=" "-=" "*=" "/=" "%=" "|+|" "|-|"
                  ; Bitwise Operators
                  #\& #\| #\~ #\^ "<<" "&=" "|=" "^="  ; The operator ">>" is represented as a double #\>, as it could lead to confusion in type parametrisation or parser transitions.
                  ; Boolean Operators
                  #\! "&&" "||" "==" "!=" "<=" ">="
                  ; Other Operators
                  "++" ".." "&&&"  ; TODO: #\? #\_ #\@

                  ; Base Types
                  "int" "bit" "varbit" "bool"
                  ; Booleans
                  "true" "false"
                  ; Other Types
                  "const" "typedef" "header" "struct" "enum" "parser" "control" "deparser" "action" "table" "factory" "void"  ; TODO: "string" "type" "header_union" "tuple" "valueset" "match_kind" "error" "extern" "package"
                  ; Direction Keywords
                  "in" "inout" "out"
                  ; Conditional & Loop Keywords
                  "if" "else" "for"
                  ; State Keywords
                  "state" "transition" "select" "default"
                  ; Table Keywords
                  "key" "actions" "entries"
                  ; Other Keywords
                  "apply" "return" "exit"  ; TODO: "switch" "this" "abstract"
                  )]
  [annotation (:seq
               #\@
               (:* whitespace)
               (:+ (:~ whitespace))
               (:? (:seq
                    (:* whitespace)
                    (:or (from/to #\( #\)) (from/to #\[ #\])))))])

; O4 Lexer
; -
; The lexer reads characters from the given input port and divides them into tokens using lexing rules (i.a. using the abbreviations defined above).
; Furthermore, it attaches srcloc entries to the generated tokens.
(define o4-lexer
  (lexer-srcloc
   ; Whitespaces
   [whitespace (token 'WHITESPACE #:skip? #t)]
   ; Comments
   [(from/stop-before "//" "\n") (token 'LINE_COMMENT lexeme #:skip? #t)]
   [(from/to "/*" "*/") (token 'BLOCK_COMMENT lexeme #:skip? #t)]
   ; Annotations
   [annotation (token 'ANNOTATION #:skip? #t)]
   ; Preprocessor Directives
   ; This matches everything from a #\# character to a newline that is not preceded by a #\\ character, meaning it is at the end of the preprocessor directive.
   [(from/stop-before #\# (:seq (:~ #\\) "\n")) (token 'PREPROCESSOR_DIRECTIVE lexeme)]
   ; Reserved Terms
   [reserved-term (token lexeme lexeme)]
   ; Integers
   [integer (token 'INTEGER lexeme)]
   ; Identifiers
   [identifier (token 'IDENTIFIER lexeme)]))

; O4 Tokenizer
; -
; The tokenizer attaches the file path and the line count to the input port before passing it to the lexer, enriching the srcloc entries.
(define (o4-tokenizer ip [path #f])
  (port-count-lines! ip)
  (lexer-file-path path)
  (define (next-token) (o4-lexer ip))
  next-token)
