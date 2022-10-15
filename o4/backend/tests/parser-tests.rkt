#lang racket/base
; Parser Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/expression o4/backend/name o4/backend/parameter-argument o4/backend/parser o4/backend/type-name o4/utils/error o4/utils/util)

; Parser Declaration
(check-equal?
 (apply-context
  (parser-declaration
   (name "identifier")
   (parameter-list
    (parameter
     (direction)
     (type-name
      (simple-type-name
       "bit"
       (expression
        (logical-or-expression
         (logical-and-expression
          (equality-expression
           (relational-expression
            (bitwise-or-expression
             (bitwise-xor-expression
              (bitwise-and-expression
               (bitshift-expression
                (additive-expression
                 (multiplicative-expression
                  (unary-cast-expression
                   (postfix-expression
                    (primary-expression
                     (integer-primitive "32")))))))))))))))))
     (name "parameter")))
   (parameter-list
    (parameter
     (direction)
     (type-name
      (simple-type-name
       "bit"
       (expression
        (logical-or-expression
         (logical-and-expression
          (equality-expression
           (relational-expression
            (bitwise-or-expression
             (bitwise-xor-expression
              (bitwise-and-expression
               (bitshift-expression
                (additive-expression
                 (multiplicative-expression
                  (unary-cast-expression
                   (postfix-expression
                    (primary-expression
                     (integer-primitive "32")))))))))))))))))
     (name "constructor_parameter")))
   (parser-body)
   (parser-states
    (parser-state
     (name "start")
     (parser-block-statement)))
   (parser-transitions
    (parser-transition
     (transition-source
      (name "start"))
     (simple-transition-expression
      (name "accept")))))
  null)
 (list null "parser identifier(bit<32> parameter)(bit<32> constructor_parameter) {\n\nstate start {\n\ntransition accept;\n}\n}"))

; Parser Declaration with Transitions Superset
(check-exn
 exn:fail:o4:parser-invalid-transition?
 (lambda ()
   (apply-context
    (parser-declaration
     (name "identifier")
     (parameter-list)
     (parser-body)
     (parser-states
      (parser-state
       (name "state1")
       (parser-block-statement)))
     (parser-transitions
      (parser-transition
       (transition-source
        (name "state1"))
       (simple-transition-expression
        (name "state2"))
       (simple-transition-expression
        (name "accept")))))
    null)))

; Parser States with Duplicate State
(check-exn
 exn:fail:o4:parser-invalid-transition?
 (lambda ()
   (apply-context
    (parser-states
     (parser-state
      (name "identifier")
      (parser-block-statement))
     (parser-state
      (name "identifier")
      (parser-block-statement)))
    null)))

; Parser State
(let ([hash (make-hasheq)])
  (check-equal?
   ((parser-state
     (name "identifier")
     (parser-block-statement))
    null
    hash)
   null)
  (check-equal?
   hash
   (make-hasheq
    (list
     (cons 'identifier "state identifier {\n\n}")))))

; Parser Transition
(let ([hash (make-hasheq)])
  (check-equal?
   ((parser-transition
     (transition-source
      (name "state1")
      (name "state2"))
     (simple-transition-expression
      (name "state3"))
     (simple-transition-expression
      (name "state4"))
     (select-transition-expression
      (expression-list
       (expression
        (logical-or-expression
         (logical-and-expression
          (equality-expression
           (relational-expression
            (bitwise-or-expression
             (bitwise-xor-expression
              (bitwise-and-expression
               (bitshift-expression
                (additive-expression
                 (multiplicative-expression
                  (unary-cast-expression
                   (postfix-expression
                    (primary-expression
                     (name "expression"))))))))))))))))
      (select-body
       (select-body-line
        (simple-keyset-expression
         (expression
          (logical-or-expression
           (logical-and-expression
            (equality-expression
             (relational-expression
              (bitwise-or-expression
               (bitwise-xor-expression
                (bitwise-and-expression
                 (bitshift-expression
                  (additive-expression
                   (multiplicative-expression
                    (unary-cast-expression
                     (postfix-expression
                      (primary-expression
                       (integer-primitive "1"))))))))))))))))
        (name "state5"))
       (select-body-line
        (simple-keyset-expression
         (expression
          (logical-or-expression
           (logical-and-expression
            (equality-expression
             (relational-expression
              (bitwise-or-expression
               (bitwise-xor-expression
                (bitwise-and-expression
                 (bitshift-expression
                  (additive-expression
                   (multiplicative-expression
                    (unary-cast-expression
                     (postfix-expression
                      (primary-expression
                       (integer-primitive "2"))))))))))))))))
        (name "state6"))))
     (select-transition-expression
      (expression-list
       (expression
        (logical-or-expression
         (logical-and-expression
          (equality-expression
           (relational-expression
            (bitwise-or-expression
             (bitwise-xor-expression
              (bitwise-and-expression
               (bitshift-expression
                (additive-expression
                 (multiplicative-expression
                  (unary-cast-expression
                   (postfix-expression
                    (primary-expression
                     (name "expression"))))))))))))))))
      (select-body
       (select-body-line
        (simple-keyset-expression
         (expression
          (logical-or-expression
           (logical-and-expression
            (equality-expression
             (relational-expression
              (bitwise-or-expression
               (bitwise-xor-expression
                (bitwise-and-expression
                 (bitshift-expression
                  (additive-expression
                   (multiplicative-expression
                    (unary-cast-expression
                     (postfix-expression
                      (primary-expression
                       (integer-primitive "1"))))))))))))))))
        (name "state7"))
       (select-body-line
        (simple-keyset-expression
         (expression
          (logical-or-expression
           (logical-and-expression
            (equality-expression
             (relational-expression
              (bitwise-or-expression
               (bitwise-xor-expression
                (bitwise-and-expression
                 (bitshift-expression
                  (additive-expression
                   (multiplicative-expression
                    (unary-cast-expression
                     (postfix-expression
                      (primary-expression
                       (integer-primitive "2"))))))))))))))))
        (name "state8"))))
     (simple-transition-expression
      (name "state9")))
    null
    hash)
   null)
  (check-equal?
   hash
   (make-hasheq
    (list
     (cons 'state1 "transition state3;")
     (cons 'state2 "transition state3;")
     (cons 'state3 "transition state4;")
     (cons 'state4 "transition select(expression) {\n1 : state5;\n2 : state6;\n}")
     (cons 'state5 "transition select(expression) {\n1 : state7;\n2 : state8;\n}")
     (cons 'state6 "transition select(expression) {\n1 : state7;\n2 : state8;\n}")
     (cons 'state7 "transition state9;")
     (cons 'state8 "transition state9;")))))

; Parser Transition from Sink
(let ([hash (make-hasheq)])
  (check-exn
   exn:fail:o4:parser-invalid-transition?
   (lambda ()
     ((parser-transition
       (transition-source
        (name "accept"))
       (simple-transition-expression
        (name "state")))
      null
      hash))))

; Parser Transition with Duplicate State
(let ([hash (make-hasheq)])
  (check-exn
   exn:fail:o4:parser-invalid-transition?
   (lambda ()
     ((parser-transition
       (transition-source
        (name "state1")
        (name "state1"))
       (simple-transition-expression
        (name "state2")))
      null
      hash))))

; Transition Source
(check-equal?
 (apply-context
  (transition-source
   (name "state1")
   (name "state2"))
  null)
 (list null (list "state1" "state2")))

; Simple Transition Expression
(check-equal?
 (apply-context
  (simple-transition-expression
   (name "identifier"))
  null)
 (list null "transition identifier;" (list "identifier")))

; Select Transition Expression
(check-equal?
 (apply-context
  (select-transition-expression
   (expression-list
    (expression
     (logical-or-expression
      (logical-and-expression
       (equality-expression
        (relational-expression
         (bitwise-or-expression
          (bitwise-xor-expression
           (bitwise-and-expression
            (bitshift-expression
             (additive-expression
              (multiplicative-expression
               (unary-cast-expression
                (postfix-expression
                 (primary-expression
                  (name "expression"))))))))))))))))
   (select-body
    (select-body-line
     (simple-keyset-expression
      (expression
       (logical-or-expression
        (logical-and-expression
         (equality-expression
          (relational-expression
           (bitwise-or-expression
            (bitwise-xor-expression
             (bitwise-and-expression
              (bitshift-expression
               (additive-expression
                (multiplicative-expression
                 (unary-cast-expression
                  (postfix-expression
                   (primary-expression
                    (integer-primitive "1"))))))))))))))))
     (name "state1"))
    (select-body-line
     (simple-keyset-expression
      (expression
       (logical-or-expression
        (logical-and-expression
         (equality-expression
          (relational-expression
           (bitwise-or-expression
            (bitwise-xor-expression
             (bitwise-and-expression
              (bitshift-expression
               (additive-expression
                (multiplicative-expression
                 (unary-cast-expression
                  (postfix-expression
                   (primary-expression
                    (integer-primitive "2"))))))))))))))))
     (name "state2"))))
  null)
 (list null "transition select(expression) {\n1 : state1;\n2 : state2;\n}" (list "state1" "state2")))

; Simple Keyset Expression - Default
(check-equal?
 (apply-context
  (simple-keyset-expression "default")
  null)
 (list null "default"))

; Simple Keyset Expression - Single Expression
(check-equal?
 (apply-context
  (simple-keyset-expression
   (expression
    (logical-or-expression
     (logical-and-expression
      (equality-expression
       (relational-expression
        (bitwise-or-expression
         (bitwise-xor-expression
          (bitwise-and-expression
           (bitshift-expression
            (additive-expression
             (multiplicative-expression
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (name "identifier"))))))))))))))))
  null)
 (list null "identifier"))

; Simple Keyset Expression - Binary Expression
(check-equal?
 (apply-context
  (simple-keyset-expression
   (expression
    (logical-or-expression
     (logical-and-expression
      (equality-expression
       (relational-expression
        (bitwise-or-expression
         (bitwise-xor-expression
          (bitwise-and-expression
           (bitshift-expression
            (additive-expression
             (multiplicative-expression
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "1")))))))))))))))
   ".."
   (expression
    (logical-or-expression
     (logical-and-expression
      (equality-expression
       (relational-expression
        (bitwise-or-expression
         (bitwise-xor-expression
          (bitwise-and-expression
           (bitshift-expression
            (additive-expression
             (multiplicative-expression
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "2"))))))))))))))))
  null)
 (list null "1 .. 2"))

; Tuple Keyset Expression
(check-equal?
 (apply-context
  (tuple-keyset-expression
   (simple-keyset-expression
    (expression
     (logical-or-expression
      (logical-and-expression
       (equality-expression
        (relational-expression
         (bitwise-or-expression
          (bitwise-xor-expression
           (bitwise-and-expression
            (bitshift-expression
             (additive-expression
              (multiplicative-expression
               (unary-cast-expression
                (postfix-expression
                 (primary-expression
                  (integer-primitive "1"))))))))))))))))
   (simple-keyset-expression
    (expression
     (logical-or-expression
      (logical-and-expression
       (equality-expression
        (relational-expression
         (bitwise-or-expression
          (bitwise-xor-expression
           (bitwise-and-expression
            (bitshift-expression
             (additive-expression
              (multiplicative-expression
               (unary-cast-expression
                (postfix-expression
                 (primary-expression
                  (integer-primitive "2")))))))))))))))))
  null)
 (list null "(1, 2)"))

; Combine Parser States with Transitions Subset
(let ([state-hash (make-hasheq
                   (list
                    (cons 'state1 "state state1 {\n\n}")
                    (cons 'state2 "state state2 {\n\n}")))]
      [tran-hash (make-hasheq
                  (list
                   (cons 'state1 "transition accept;")))])
  (check-equal?
   (combine-parser-states-with-transitions state-hash tran-hash)
   "state state1 {\n\ntransition accept;\n}\nstate state2 {\n\n}"))

; Combine Parser States with Transitions Superset
(let ([state-hash (make-hasheq
                   (list
                    (cons 'state1 "state state1 {\n\n}")))]
      [tran-hash (make-hasheq
                  (list
                   (cons 'state1 "transition accept;")
                   (cons 'state2 "transition accept;")))])
  (check-equal?
   (combine-parser-states-with-transitions state-hash tran-hash)
   #f))
