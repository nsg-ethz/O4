#lang racket/base
; Lexer & Tokenizer Frontend Tests
; ---------------------------------------
(require brag/support rackunit
         o4/frontend/lexer-tokenizer)

(define (lex str)
  (apply-lexer o4-lexer str))

; Empty
(check-equal?
 (lex "")
 null)

; Whitespaces
(check-equal?
 (lex " \n\t")
 (list
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 0 1 1))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 1 2 1))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 2 0 3 1))))

; Comments
(check-equal?
 (lex "// This is a line comment\n")
 (list
  (srcloc-token (token-struct 'LINE_COMMENT "// This is a line comment" #f #f #f #f #t) (srcloc 'string 1 0 1 25))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 25 26 1))))
(check-equal?
 (lex "/* This is a block comment\nEven if it includes multiple\nLines. */")
 (list (srcloc-token (token-struct 'BLOCK_COMMENT "/* This is a block comment\nEven if it includes multiple\nLines. */" #f #f #f #f #t) (srcloc 'string 1 0 1 65))))

; Annotations
(check-equal?
 (lex "@annotation(something with even a few whitespaces, numbers and special characters like 1,2,3,!) identifier")
 (list
  (srcloc-token (token-struct 'ANNOTATION #f #f #f #f #f #t) (srcloc 'string 1 0 1 95))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 95 96 1))
  (srcloc-token (token-struct 'IDENTIFIER "identifier" #f #f #f #f #f) (srcloc 'string 1 96 97 10))))
(check-equal?
 (lex "@ annotation identifier")
 (list
  (srcloc-token (token-struct 'ANNOTATION #f #f #f #f #f #t) (srcloc 'string 1 0 1 12))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 12 13 1))
  (srcloc-token (token-struct 'IDENTIFIER "identifier" #f #f #f #f #f) (srcloc 'string 1 13 14 10))))
(check-equal?
 (lex "@ annotation () identifier")
 (list
  (srcloc-token (token-struct 'ANNOTATION #f #f #f #f #f #t) (srcloc 'string 1 0 1 15))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 15 16 1))
  (srcloc-token (token-struct 'IDENTIFIER "identifier" #f #f #f #f #f) (srcloc 'string 1 16 17 10))))
(check-equal?
 (lex "@ annotation [] identifier")
 (list
  (srcloc-token (token-struct 'ANNOTATION #f #f #f #f #f #t) (srcloc 'string 1 0 1 15))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 15 16 1))
  (srcloc-token (token-struct 'IDENTIFIER "identifier" #f #f #f #f #f) (srcloc 'string 1 16 17 10))))
  
; Preprocessor Directives
(check-equal?
 (lex "#include <something.o4>\n")
 (list
  (srcloc-token (token-struct 'PREPROCESSOR_DIRECTIVE "#include <something.o4>" #f #f #f #f #f) (srcloc 'string 1 0 1 23))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 23 24 1))))
(check-equal?
 (lex "#include <something_with_a_very_ \\nvery_very_very_very_long_name.o4>\n")
 (list
  (srcloc-token (token-struct 'PREPROCESSOR_DIRECTIVE "#include <something_with_a_very_ \\nvery_very_very_very_long_name.o4>" #f #f #f #f #f) (srcloc 'string 1 0 1 68))
  (srcloc-token (token-struct 'WHITESPACE #f #f #f #f #f #t) (srcloc 'string 1 68 69 1))))

; Reserved Terms
(check-equal?
 (lex ";")
 (list (srcloc-token (token-struct '|;| ";" #f #f #f #f #f) (srcloc 'string 1 0 1 1))))

; Integers
(check-equal?
 (lex "16w0x0Fa2")
 (list (srcloc-token (token-struct 'INTEGER "16w0x0Fa2" #f #f #f #f #f) (srcloc 'string 1 0 1 9))))
(check-equal?
 (lex "16wOx0Fa2")
 (list
  (srcloc-token (token-struct 'INTEGER "16" #f #f #f #f #f) (srcloc 'string 1 0 1 2))
  (srcloc-token (token-struct 'IDENTIFIER "wOx0Fa2" #f #f #f #f #f) (srcloc 'string 1 2 3 7))))

; Identifiers
(check-equal?
 (lex "_identifier42")
 (list (srcloc-token (token-struct 'IDENTIFIER "_identifier42" #f #f #f #f #f) (srcloc 'string 1 0 1 13))))
(check-exn
 exn:fail:read?
 (lambda ()
   (lex "_idëntifier42")))
