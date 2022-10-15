#lang racket/base
; Type Name Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/expression o4/backend/name o4/backend/type-name o4/backend/parameter-argument o4/utils/error o4/utils/util)

; Type Name
(check-equal?
 (apply-context
  (type-name
   (simple-type-name
    "identifier"
    (type-argument-list
     (type-name
      (simple-type-name
       "other_identifier"
       (type-argument-list
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
                        (integer-primitive "32"))))))))))))))))))))
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
                     (integer-primitive "16")))))))))))))))))
     (type-name
      (simple-type-name "int"))))
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
 (list null "identifier<other_identifier<bit<32>>, bit<16>, int>" (list 3 2)))

; Type Name with Compile Time Unknown Array Size
(check-exn
 exn:fail:o4:array-index-unknown?
 (lambda ()
   (apply-context
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
                   (name "expression"))))))))))))))))
    null)))

; Type Name or Void - Void
(check-equal?
 (apply-context
  (type-name-or-void "void")
  null)
 (list null "void" null))

; Type Name or Void - Type Name
(check-equal?
 (apply-context
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
  null)
 (list null "bit<32>" null))
