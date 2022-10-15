#lang racket/base
; Utility Tests
; ---------------------------------------
(require rackunit
         o4/utils/error o4/utils/util)

; Applyable `and` Function
(check-equal?
 (apply applyable-and null)
 #t)
(check-equal?
 (apply applyable-and (list 0 #t null))
 #t)
(check-equal?
 (apply applyable-and (list #f #t))
 #f)
(check-equal?
 (apply applyable-and (list #t #f))
 #f)
(check-exn
 exn:fail?
 (lambda ()
   (applyable-and #f (error 'this-will-be-evaluated))))

; Applyable `or` Function
(check-equal?
 (apply applyable-or null)
 #f)
(check-equal?
 (apply applyable-or (list #f))
 #f)
(check-equal?
 (apply applyable-or (list #f #f))
 #f)
(check-equal?
 (apply applyable-or (list #t #f))
 #t)
(check-equal?
 (apply applyable-or (list #f #t))
 #t)
(check-equal?
 (apply applyable-or (list 0))
 #t)
(check-equal?
 (apply applyable-or (list null))
 #t)
(check-exn
 exn:fail?
 (lambda ()
   (applyable-or #t (error 'this-will-be-evaluated))))

; Hash Set & Remove with Existence Check
(let* ([hash (make-hasheq)]
       [_ (hash-set-if-not-exists! hash 'key "value")]
       [_ (hash-set-if-not-exists! hash 'other_key "other_value")]
       [_ (hash-remove-if-exists! hash 'other_key)])
  (check-equal?
   hash
   (make-hasheq
    (list
     (cons 'key "value"))))
  (check-exn
   exn:fail:o4:hash-key?
   (lambda ()
     (hash-set-if-not-exists! hash 'key "other_value")))
  (check-exn
   exn:fail:o4:hash-key?
   (lambda ()
     (hash-remove-if-exists! hash 'other_key))))

; Drop Last Element of List
(check-equal?
 (drop-last (list 1))
 null)
(check-equal?
 (drop-last (list 1 2 3))
 (list 1 2))
(check-exn
 exn:fail:contract?
 (lambda ()
   (drop-last null)))
