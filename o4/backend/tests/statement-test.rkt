#lang racket/base
; Statement Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/expression o4/backend/name o4/backend/parameter-argument o4/backend/statement o4/backend/type-name o4/context o4/utils/error o4/utils/util)

; Block Statement
(check-equal?
 (apply-context
  (block-statement
   (empty-statement)
   (empty-statement)
   (empty-statement))
  null)
 (list null "{\n;\n;\n;\n}"))

; Block Statement with No Statement
(check-equal?
 (apply-context
  (block-statement)
  null)
 (list null "{\n\n}"))

; Simple Assignment Statement
(check-equal?
 (apply-context
  (assignment-statement
   (lvalue
    (name "identifier"))
   "="
   (expression-array
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
                  (integer-primitive "1")))))))))))))))))
  null)
 (list null (list "identifier = 1;")))

; Simple Assignment Statement with Expression Array
(check-equal?
 (apply-context
  (assignment-statement
   (lvalue
    (name "identifier"))
   "="
   (expression-array
    "["
    (expression-array
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
    (expression-array
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
    "]"))
  null)
 (list null (list "identifier_0 = 1;" "identifier_1 = 2;")))

; Simple Assignment Statement with Wrongly Sized Expression Array
(check-exn
 exn:fail:o4:array-wrong-dimensions?
 (lambda ()
   (apply-context
    (assignment-statement
     (lvalue (name "identifier"))
     "="
     (expression-array
      "["
      (expression-array
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
      (expression-array
       "["
       (expression-array
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
       (expression-array
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
                      (integer-primitive "3"))))))))))))))))
       "]")
      "]"))
    null)))

; Compound Assignment Statement
(check-equal?
 (apply-context
  (assignment-statement
   (lvalue
    (name "identifier"))
   "+="
   (expression-array
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
                  (integer-primitive "1")))))))))))))))))
  null)
 (list null (list "identifier = identifier + (1);")))

; Call Statement
(check-equal?
 (apply-context
  (call-statement
   (lvalue
    (lvalue
     (name "identifier"))
    "."
    (name "call"))
   (type-argument-list
    (type-name-or-void
     (type-name
      (simple-type-name "type"))))
   (argument-list
    (argument
     (expression-array
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
                    (name "argument")))))))))))))))))))
  null)
 (list null "identifier.call<type>(argument);"))

; Factory Call Statement
(let* ([ctx (add-scope null)]
       [_ (set-factory ctx 'identifier "body_name" null null)]
       [final-ctx (add-scope null)]
       [_ (set-factory final-ctx 'identifier "body_name" null null)]
       [_ (set-factory-call final-ctx 'identifier null)])
  (check-equal?
   (apply-context
    (call-statement
     (lvalue
      (name "identifier"))
     (argument-list))
    ctx)
   (list final-ctx "body_name_call;")))

; Factory Call Statement with Type Arguments
(let* ([ctx (add-scope null)]
       [_ (set-factory ctx 'identifier "body_name" null null)])
  (check-exn
   exn:fail:o4:factory-call?
   (lambda ()
     (apply-context
      (call-statement
       (lvalue
        (name "identifier"))
       (type-argument-list
        (type-name-or-void
         (type-name
          (simple-type-name "type"))))
       (argument-list))
      ctx))))

; L-Value Array Access
(check-equal?
 (apply-context
  (lvalue
   (lvalue
    (lvalue
     (name "identifier"))
    "["
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
                  (integer-primitive "3")))))))))))))))
    "]")
   "["
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
                 (integer-primitive "2")))))))))))))))
   "]")
  null)
 (list null "identifier_3_2"))

; L-Value Array Access with Compile Time Unknown Index
(check-exn
 exn:fail:o4:array-index-unknown?
 (lambda ()
   (apply-context
    (lvalue
     (lvalue
      (name "identifier"))
     "["
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
                   (name "expression")))))))))))))))
     "]")
    null)))

; L-Value Factory Call
(let* ([ctx (add-scope null)]
       [_ (set-factory ctx 'identifier "body_name" null null)]
       [final-ctx (add-scope null)]
       [_ (set-factory final-ctx 'identifier "body_name" null null)]
       [_ (set-factory-call final-ctx 'identifier null)])
  (check-equal?
   (apply-context
    (lvalue
     (lvalue
      (name "identifier"))
     "("
     (argument-list)
     ")")
    ctx)
   (list final-ctx "body_name_call")))

; Substitute L-Value
(let* ([ctx (add-scope null)]
       [_ (set-variable ctx 'substitute "identifier" #f #t)])
  (check-equal?
   (apply-context
    (lvalue
     (name "substitute"))
    ctx)
   (list ctx "identifier")))

; Conditional Statement
(check-equal?
 (apply-context
  (conditional-statement
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
   (empty-statement)
   (empty-statement))
  null)
 (list null "if (1) {\n;\n} else {\n;\n}"))

; Loop Statement
(check-equal?
 (apply-context
  (loop-statement
   (type-name
    (simple-type-name "int"))
   (name "identifier")
   (expression-array
    "["
    (expression-array
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
    (expression-array
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
    "]")
   (assignment-statement
    (lvalue (name "other_identifier"))
    "="
    (expression-array
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
                   (name "identifier"))))))))))))))))))
  null)
 (list null (list "{\nother_identifier = 1;\n}" "{\nother_identifier = 2;\n}")))

; Loop Statement with Array Type Iterator
(check-exn
 exn:fail:o4:array-not-allowed?
 (lambda ()
   (apply-context
    (loop-statement
     (type-name
      (simple-type-name "int")
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
     (name "identifier")
     (expression-array
      "["
      (expression-array
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
      "]")
     (empty-statement))
    null)))

; Loop Statement with 2D Expression Array
(check-exn
 exn:fail:o4:array-wrong-dimensions?
 (lambda ()
   (apply-context
    (loop-statement
     (type-name
      (simple-type-name "int"))
     (name "identifier")
     (expression-array
      "["
      (expression-array
       "["
       (expression-array
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
       "]")
      "]")
     (empty-statement))
    null)))

; Return Statement
(check-equal?
 (apply-context
  (return-statement
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
  null)
 (list null "return 1;"))


; Exit Statement
(check-equal?
 (apply-context
  (exit-statement)
  null)
 (list null "exit;"))
