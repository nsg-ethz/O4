#lang racket/base
; O4 Language
; ---------------------------------------

; Reader
(module+ reader
  (provide read-syntax)

  ; Implementation
  ; ---------------------------------------
  (require br/syntax racket/format
           o4/frontend/lexer-tokenizer o4/frontend/parser o4/utils/error)
  
  (define (read-syntax path port)
    ; Error Handling
    (with-handlers ([exn:fail? exception-handler])
      (let ([start (current-milliseconds)]
            [parse-tree (parse path (o4-tokenizer port path))]
            [end (current-milliseconds)])
        (displayln (format "Finished lexing and parsing of source in ~a seconds" (~r (/ (- end start) 1000) #:precision 3)))
        (strip-bindings
         #`(module o4-module o4/main
             #,parse-tree))))))


; Expander
(provide (rename-out [o4-module-begin #%module-begin]) #%top #%app #%datum #%top-interaction
         (all-from-out
          o4/backend/control
          o4/backend/declaration
          o4/backend/expression
          o4/backend/instantiation
          o4/backend/name
          o4/backend/o4-program
          o4/backend/parameter-argument
          o4/backend/parser
          o4/backend/statement
          o4/backend/type-declaration
          o4/backend/type-name))

; Implementation
; ---------------------------------------
(require br/macro
         racket/format
         o4/backend/control
         o4/backend/declaration
         o4/backend/expression
         o4/backend/instantiation
         o4/backend/name
         o4/backend/o4-program
         o4/backend/parameter-argument
         o4/backend/parser
         o4/backend/statement
         o4/backend/type-declaration
         o4/backend/type-name
         o4/utils/config
         o4/utils/error
         o4/utils/pretty-printer
         o4/utils/subprocess
         (for-syntax racket/base))

(define-macro (o4-module-begin PARSE-TREE)
  (define start (current-milliseconds))
  #`(#%module-begin
     ; Error Handling
     (with-handlers ([exn:fail? exception-handler])
       (let*-values ([(ctx str) PARSE-TREE]
                     [(end) (current-milliseconds)]
                     ; Pretty-print compiler output
                     [(str) (pretty-print str)]
                     ; Read configuration file
                     [(config-hash) (get-config-hash (build-path (current-directory) "code/o4/config.json"))])
         (displayln (format "Finished back end compilation in ~a seconds" (~r (/ (- end #,start) 1000) #:precision 3)))
         ; Write compiler output to file
         (write-string-to-file (hash-ref config-hash 'output_file) str)
         (displayln (format "Finished writing compilation output to file ~a" (hash-ref config-hash 'output_file)))
         ; Run P4 compiler command
         (when (hash-ref config-hash 'run_p4_compiler)
           (run-command (hash-ref config-hash 'p4_compiler_executable) (hash-ref config-hash 'p4_compiler_arguments)))))))
