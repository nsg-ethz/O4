#lang racket/base
; Declaration Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/declaration
         o4/backend/expression
         o4/backend/name
         o4/backend/parameter-argument
         o4/backend/statement
         o4/backend/type-name
         o4/context
         o4/utils/error
         o4/utils/util)

; Constant Declaration
(check-equal?
 (apply-context
  (constant-declaration
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
                   (integer-primitive "32"))))))))))))))))
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
   (name "IDENTIFIER")
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
 (list
  null
  (list
   "const bit<32> IDENTIFIER_0 = 1;"
   "const bit<32> IDENTIFIER_1 = 2;")))

; Constant Declaration with Wrongly Sized Expression Array
(check-exn
 exn:fail:o4:array-wrong-dimensions?
 (lambda ()
   (apply-context
    (constant-declaration
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
                     (integer-primitive "32"))))))))))))))))
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
     (name "IDENTIFIER")
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
    null)))
 
; Action Declaration
(check-equal?
 (apply-context
  (action-declaration
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
     (name "argument")))
   (block-statement))
  null)
 (list null "action identifier(bit<32> argument) {\n\n}"))

; Substitute Action Name
(let* ([ctx (add-scope null)]
       [_ (set-variable ctx 'substitute "identifier" #f #t)])
  (check-equal?
   (apply-context
    (action-declaration
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
       (name "argument")))
     (block-statement))
    ctx)
   (list ctx "action identifier(bit<32> argument) {\n\n}")))

; Function Declaration
(check-equal?
 (apply-context
  (function-declaration
   (type-name-or-void
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
                    (integer-primitive "32"))))))))))))))))))
   (name "identifier")
   (type-parameter-list
    (name "type"))
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
     (name "argument")))
   (block-statement))
  null)
 (list null "bit<32> identifier<type>(bit<32> argument) {\n\n}"))

; Function Declaration with Array Type
(check-exn
 exn:fail:o4:array-not-allowed?
 (lambda ()
   (apply-context
    (function-declaration
     (type-name-or-void
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
                      (integer-primitive "32"))))))))))))))))
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
     (name "identifier")
     (type-parameter-list
      (name "type"))
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
       (name "argument")))
     (block-statement))
    null)))

; Variable Declaration
(check-equal?
 (apply-context
  (variable-declaration
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
                   (integer-primitive "32"))))))))))))))))
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
    "]"))
  null)
 (list null (list
             "bit<32> identifier_0 = 1;"
             "bit<32> identifier_1 = 2;")))

; Variable Declaration with Wrongly Sized Expression Array
(check-exn
 exn:fail:o4:array-wrong-dimensions?
 (lambda ()
   (apply-context
    (variable-declaration
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
                     (integer-primitive "32"))))))))))))))))
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
     (name "identifier")
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
    null)))
