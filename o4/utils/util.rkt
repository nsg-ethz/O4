#lang racket/base
; Utility Functions
; ---------------------------------------
(provide applyable-and
         applyable-or
         fold-context-2
         fold-string-join-context-2
         fold-context-3
         apply-context
         hash-set-if-not-exists!
         hash-remove-if-exists!
         drop-last)


; Implementation
; ---------------------------------------
(require racket/list racket/string
         o4/utils/error)

; Applyable `and` Function (does not do short-circuit evaluation and only returns #t or #f)
(define (applyable-and . vals)
  (if (null? vals)
      #t
      (if (first vals)
          (apply applyable-and (rest vals))
          #f)))

; Applyable `or` Function (does not do short-circuit evaluation and only returns #t or #f)
(define (applyable-or . vals)
  (if (null? vals)
      #f
      (if (first vals)
          #t
          (apply applyable-or (rest vals)))))

; Fold Context with Two Return Values
(define (fold-context-2 ctx . funcs)
  (let-values ([(ctx vals) (for/fold ([ctx ctx]
                                      [vals null])
                                     ([func (in-list funcs)])
                             (let-values ([(ctx val) (func ctx)])
                               (values
                                ctx
                                (cons val vals))))])
    (values
     ctx
     (reverse vals))))

; Fold Context with Two Return Values and String Join Outputs
(define (fold-string-join-context-2 ctx str . funcs)
  (let-values ([(ctx vals) (apply fold-context-2 ctx funcs)])
    (values
     ctx
     (string-join (flatten vals) str))))

; Fold Context with Three Return Values
(define (fold-context-3 ctx . funcs)
  (let-values ([(ctx vals1 vals2) (for/fold ([ctx ctx]
                                             [vals1 null]
                                             [vals2 null])
                                            ([func (in-list funcs)])
                                    (let-values ([(ctx val1 val2) (func ctx)])
                                      (values
                                       ctx
                                       (cons val1 vals1)
                                       (cons val2 vals2))))])
    (values
     ctx
     (reverse vals1)
     (reverse vals2))))

; Apply Context
(define (apply-context func . vals)
  (call-with-values (lambda ()
                      (apply func vals)) list))

; Hash Set with Existence Check
(define (hash-set-if-not-exists! hash key val)
  ; Check if key already exists in hash
  (if (hash-ref hash key #f)
      (raise-hash-key-error (format "hash-set-if-not-exists!: key ~a already exists" (symbol->string key)))
      (hash-set! hash key val)))

; Hash Remove with Existence Check
(define (hash-remove-if-exists! hash key)
  ; Check if key exists in hash
  (if (hash-ref hash key #f)
      (hash-remove! hash key)
      (raise-hash-key-error (format "hash-remove-if-exists!: key ~a does not exist" (symbol->string key)))))

; Drop Last Element of List
(define (drop-last lst)
  (reverse (rest (reverse lst))))
