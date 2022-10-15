#lang racket/base
; Halstead Metric Utils
; ---------------------------------------
(provide program operator operand)


; Implementation
; ---------------------------------------
(require racket/format)

; Operator/Operand Dictionaries
(define op-hash (make-hash))
(define od-hash (make-hash))

; Program
(define (program . args)
  (define uop (hash-count op-hash))
  (define uod (hash-count od-hash))
  (define vocabulary (+ uop uod))
  (define op (apply + (hash-values op-hash)))
  (define od (apply + (hash-values od-hash)))
  (define length (+ op od))

  (define volume (* length (log vocabulary 2)))
  (define difficulty (* (/ uop 2) (/ od uod)))
  (define effort (* difficulty volume))
  (displayln (format "Volume ~ak, Difficulty ~a, Effort ~aM"
                     (~r (/ volume 1000) #:precision 2)
                     (~r difficulty #:precision 2)
                     (~r (/ effort 1000000) #:precision 2))))

; Operator
(define (operator op)
  (if (hash-has-key? op-hash op)
      (hash-update! op-hash op (lambda (x)
                                 (add1 x)))
      (hash-set! op-hash op 1)))

; Operand
(define (operand od)
  (if (hash-has-key? od-hash od)
      (hash-update! od-hash od (lambda (x)
                                 (add1 x)))
      (hash-set! od-hash od 1)))
