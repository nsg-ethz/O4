#lang racket/base
; Subprocess Handling
; ---------------------------------------
(provide run-command
         write-string-to-file)


; Implementation
; ---------------------------------------
(require racket/port racket/string)

; Run Command
(define (run-command cmd args)
  (displayln (format "Running subprocess: ~a ~a" cmd (string-join args)))
  (let-values ([(sub-proc out in err) (apply subprocess #f #f #f cmd args)])
    (subprocess-wait sub-proc)
    (displayln (format "Run terminated with return code ~a\nstdout:~a\nstderr:~a" (subprocess-status sub-proc) (port->string out) (port->string err)))
    (close-input-port out)
    (close-output-port in)
    (close-input-port err)))

; Write String to File
(define (write-string-to-file path str)
  (call-with-output-file*
   path
   (lambda (out)
     (write-string str out))
   #:exists 'truncate))
