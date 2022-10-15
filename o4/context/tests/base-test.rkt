#lang racket/base
; Base Context Tests
; ---------------------------------------
(require rackunit
         o4/context/base o4/utils/error)

; Remove Scope with Call Pass-Up
(let* ([ctx (add-scope null)]
       [_ (set-declare ctx 'declare "value")]
       [_ (set-call ctx 'call "value")]
       [ctx (add-scope ctx)]
       [_ (set-declare ctx 'other_declare "other_value")]
       [_ (set-declare ctx 'declare "other_value")]
       [_ (set-call ctx 'other_call "other_value")]
       [_ (set-call ctx 'call "other_value")]
       [ctx (remove-scope ctx)])
  (check-equal?
   ctx
   (context
    null
    (make-hasheq
     (list
      (cons 'declare "value")))
    (make-hasheq
     (list
      (cons 'call "other_value")
      (cons 'other_call "other_value"))))))

; Set & Get Declares
(let* ([ctx (add-scope null)]
       [_ (set-declare ctx 'declare "value")]
       [_ (set-declare ctx 'other_declare "other_value")]
       [ctx (add-scope ctx)]
       [_ (set-declare ctx 'declare "other_value")])
  (check-equal?
   (get-declare ctx 'declare)
   "other_value")
  (check-equal?
   (get-declare ctx 'other_declare)
   "other_value")
  (check-equal?
   (get-declare ctx 'nonexisting_declare)
   null)
  (check-equal?
   (get-declares-of-scope ctx)
   (make-hasheq
    (list
     (cons 'declare "other_value"))))
  (check-exn
   exn:fail:o4:hash-key?
   (lambda ()
     (set-declare ctx 'declare "value"))))

; Set, Get & Remove Call
(let* ([ctx (add-scope null)]
       [_ (set-call ctx 'call "value")]
       [_ (set-call ctx 'other_call "other_value")]
       [_ (set-call ctx 'call "other_value")]
       [_ (remove-call ctx 'other_call)])
  (check-equal?
   (get-calls-of-scope ctx)
   (make-hasheq
    (list
     (cons 'call "other_value"))))
  (check-exn
   exn:fail:o4:hash-key?
   (lambda ()
     (remove-call ctx 'nonexisting_call))))

; Setters on Empty Context
(check-not-exn
 (lambda ()
   (set-declare null 'declare "value")))
(check-not-exn
 (lambda ()
   (set-call null 'call "value")))

; Remover on Empty Context
(check-exn
 exn:fail:contract?
 (lambda ()
   (remove-call null 'call)))
