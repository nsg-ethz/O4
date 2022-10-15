#lang racket/base
; Factory Context Tests
; ---------------------------------------
(require rackunit
         o4/context/base o4/context/factory o4/context/parameter-argument o4/utils/util)

(define body-proc
  (lambda (ctx)
    (values
     ctx
     "body")))

; Set & Get Factories
(let* ([ctx (add-scope null)]
       [_ (set-declare ctx 'declare "value")]
       [_ (set-factory ctx 'other_factory "identifier" body-proc null)]
       [_ (set-factory ctx 'factory "identifier" body-proc null)])
  (check-equal?
   (get-factory ctx 'declare)
   null)
  (check-equal?
   (get-factory ctx 'factory)
   (dec-factory "identifier" body-proc null))
  (check-equal?
   (get-factories-of-scope ctx)
   (list
    (cons 'factory null)
    (cons 'other_factory null))))


; Get Factories of Scope with No Factories
(let* ([ctx (add-scope null)]
       [_ (set-declare ctx 'declare "value")])
  (check-equal?
   (get-factories-of-scope ctx)
   null))

; Set, Get & Remove Factory Calls
(let* ([ctx (add-scope null)]
       [_ (set-factory ctx 'factory "identifier" body-proc (list (cons 'parameter (dec-parameter 0 #f "1" 1))))])
  (check-equal?
   (set-factory-call ctx 'other_factory null)
   "other_factory")
  (check-equal?
   (get-factory-calls-of-scope ctx)
   null)
  (check-equal?
   (set-factory-call ctx 'factory null)
   "identifier_call_1")
  (check-equal?
   (set-factory-call ctx 'factory null)
   "identifier_call_1")
  (check-equal?
   (set-factory-call ctx 'factory (list (get-argument-metadata "1" 1 #f)))
   "identifier_call_1")
  (check-equal?
   (set-factory-call ctx 'factory (list (get-argument-metadata "2" 2 #f)))
   "identifier_call_2")
  (check-not-exn
   (lambda ()
     (remove-factory-call ctx 'identifier_call_1)))
  (check-equal?
   (get-factory-calls-of-scope ctx)
   (list (cons 'identifier_call_2 (factory-call "factory" "identifier" body-proc (list (list 'parameter "2" 2)))))))

; Handle Factory Calls
(let ([ctx (context
            null
            (make-hasheq
             (list
              (cons 'factory (dec-factory null null null))
              (cons 'other_factory (dec-factory null null null))))
            (make-hasheq
             (list
              (cons 'identifier_call (factory-call "factory" "identifier" body-proc null)))))])
  (check-equal?
   (apply-context
    handle-factory-calls
    ctx
    "There are two factories in control: $$$factory$$$ and $$$other_factory$$$")
   (list
    (context
     null
     (make-hasheq
      (list
       (cons 'factory (dec-factory null null null))
       (cons 'other_factory (dec-factory null null null))))
     (make-hasheq))
    "There are two factories in control: body and ")))

; Handle Factory Calls with Nested Factory Calls
(let* ([body-proc (lambda (ctx)
                    (set-factory-call ctx 'factory (list (get-argument-metadata "1" 1)))
                    (set-factory-call ctx 'factory (list (get-argument-metadata "2" 2)))
                    (values
                     ctx
                     "body"))]
       [ctx (context
             null
             (make-hasheq
              (list
               (cons 'factory (dec-factory "identifier" body-proc (list (cons 'parameter (dec-parameter 0 #f #f #f)))))))
             (make-hasheq
              (list
               (cons 'identifier_call_1 (factory-call "factory" "identifier" body-proc (list (list 'parameter "1" 1)))))))])
  (check-equal?
   (apply-context
    handle-factory-calls
    ctx
    "There is only one factory in control: $$$factory$$$")
   (list
    (context
     null
     (make-hasheq
      (list
       (cons 'factory (dec-factory "identifier" body-proc (list (cons 'parameter (dec-parameter 0 #f #f #f)))))))
     (make-hasheq))
    "There is only one factory in control: body\nbody")))

; Handle Factory Calls with Empty Scope
(check-equal?
 (apply-context
  handle-factory-calls
  null
  "No factories in control")
 (list null "No factories in control"))

; Handle Factory Calls Fold
(let* ([facts (make-hasheq
               (list
                (cons 'factory null)))]
       [hand-calls (make-hasheq)]
       [ctx (context
             null
             (make-hasheq)
             (make-hasheq
              (list
               (cons 'identifier_call (factory-call "factory" "identifier" body-proc null)))))]
       [fact-calls (list (cons 'identifier_call (factory-call "factory" "identifier" body-proc null)))])
  (check-equal?
   (handle-factory-calls-fold facts hand-calls ctx fact-calls)
   (context null (make-hasheq) (make-hasheq)))
  (check-equal?
   facts
   (make-hasheq
    (list
     (cons 'factory (list "body")))))
  (check-equal?
   hand-calls
   (make-hasheq
    (list
     (cons 'identifier_call #t)))))

; Handle Factory Calls Fold with Already Handled Call
(let ([facts null]
      [hand-calls (make-hasheq
                   (list
                    (cons 'identifier_call #t)))]
      [ctx (context
            null
            null
            (make-hasheq
             (list
              (cons 'identifier_call null))))]
      [fact-calls (list (cons 'identifier_call null))])
  (check-equal?
   (handle-factory-calls-fold facts hand-calls ctx fact-calls)
   (context null null (make-hasheq))))

; Get Factory Call Name
(check-equal?
 (get-factory-call-name
  "identifier"
  null)
 "identifier_call")
(check-equal?
 (get-factory-call-name
  "identifier"
  (list
   (list 'parameter "not_1" 1)
   (list 'other_parameter "(bit<32>)identifier.field" #f)
   (list 'even_another_parameter "3" 3)))
 "identifier_call_1__bit_32__identifier_field_3")

; Format Body String
(check-equal?
 (format-body-string
  "No factories in control"
  null)
 "No factories in control")
(check-equal?
 (format-body-string
  "There are two factories in control: $$$factory$$$ and $$$other_factory$$$"
  (list
   (cons 'factory null)
   (cons 'other_factory (list "something" "something_else"))))
 "There are two factories in control:  and something\nsomething_else")
(check-equal?
 (format-body-string
  "There are two factories in control: $$$factory$$$ and $$$other_factory$$$"
  (list (cons 'factory null)))
 #f)
(check-equal?
 (format-body-string
  "There is only one factory in control: $$$factory$$$"
  (list
   (cons 'factory null)
   (cons 'other_factory null)))
 #f)
