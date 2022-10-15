#lang racket/base
; Base Context
; ---------------------------------------
(provide context
         add-scope
         remove-scope
         get-declare
         get-declares-of-scope
         get-calls-of-scope
         set-declare
         set-call
         remove-call)


; Implementation
; ---------------------------------------
(require racket/hash
         o4/utils/util)

; Struct
; -
; In declares, we store declared variables, factories, parameters, etc.
; In calls, we store factory calls.
(struct context (next declares calls) #:mutable #:transparent)

; Constructor
; -
; This function adds a new scope to the context e.g. at the beginning of a block statement.
(define (add-scope ctx)
  (context ctx (make-hasheq) (make-hasheq)))

; Destructor
; -
; This function removes the current scope from the context e.g. at the end of a block statement.
; It also makes sure that calls are passed up to the next higher scope (whereas declares are dropped).
(define (remove-scope ctx)
  ; Pass up calls through context chain
  (let ([next-ctx (context-next ctx)])
    (unless (null? next-ctx)
      ; Calls with the same name refer to the same call
      (hash-union! (context-calls next-ctx) (context-calls ctx)
                   #:combine (lambda (v0 v1)
                               v1)))
    next-ctx))

; Getters
(define (get-declare ctx name)
  (if (null? ctx)
      null
      (let ([res (hash-ref (context-declares ctx) name #f)])
        (if res
            res
            (get-declare (context-next ctx) name)))))

(define (get-declares-of-scope ctx)
  (if (null? ctx)
      null
      (context-declares ctx)))

(define (get-calls-of-scope ctx)
  (if (null? ctx)
      null
      (context-calls ctx)))

; Setters
(define (set-declare ctx name dec)
  ; Set call is silently ignored on empty context
  (unless (null? ctx)
    ; Declares have to have unique names in one scope
    (hash-set-if-not-exists! (context-declares ctx) name dec)))

(define (set-call ctx name call)
  ; Set call is silently ignored on empty context
  (unless (null? ctx)
    ; Calls with the same name refer to the same call
    (hash-set! (context-calls ctx) name call)))

; Remover
(define (remove-call ctx name)
  ; Only existing calls can be removed
  (hash-remove-if-exists! (context-calls ctx) name))
