#lang racket/base
; Pretty-Printer
; ---------------------------------------
(provide pretty-print)


; Implementation
; ---------------------------------------
(require racket/string)

; Pretty-Print String
; -
; Expects an output string produced by the O4 compiler and properly indents it.
(define (pretty-print str)
  (let-values ([(_ lines) (pretty-print-fold str)])
    (string-join (reverse lines) "\n")))

(define (pretty-print-fold str)
  (for/fold ([depth 0]
             [lines null])
            ([line (in-list (string-split str #px"\n"))])
    ; If we see a closing brace, we reduce the indentation depth for the current and following lines.
    (if (or (equal? line "}") (equal? line "};") (equal? line "} else {"))
        (values
         ; If we see an opening brace, we increase the indentation depth for the following lines.
         (if (string-suffix? line "{")
             depth
             (sub1 depth))
         (cons (indent-line line (sub1 depth)) lines))
        (values
         ; If we see an opening brace, we increase the indentation depth for the following lines.
         (if (string-suffix? line "{")
             (add1 depth)
             depth)
         (cons (indent-line line depth) lines)))))


; Helper Functions
; ---------------------------------------
; Indent Line
; -
; Inserts a number of spaces at the beginning of the given line.
(define (indent-line line depth [step 4])
  (format "~a~a" (make-string (* depth step) #\space) line))
