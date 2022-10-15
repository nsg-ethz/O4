#lang racket/base
; Type Declaration Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/expression o4/backend/name o4/backend/type-declaration o4/backend/type-name o4/utils/error o4/utils/util)

; Typedef Declaration
(check-equal?
 (apply-context
  (typedef-declaration
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
   (name "identifier"))
  null)
 (list null "typedef bit<32> identifier;"))

; Typedef Declaration with Array Type
(check-exn
 exn:fail:o4:array-not-allowed?
 (lambda ()
   (apply-context
    (typedef-declaration
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
     (name "identifier"))
    null)))

; Header Declaration
(check-equal?
 (apply-context
  (header-declaration
   "header"
   (name "identifier")
   (struct-body-line
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
    (name "other_identifier")))
  null)
 (list null "header identifier {\nbit<32> other_identifier;\n}"))

; Struct Declaration
(check-equal?
 (apply-context
  (struct-declaration
   "struct"
   (name "identifier")
   (struct-body-line
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
    (name "other_identifier")))
  null)
 (list null "struct identifier {\nbit<32> other_identifier_0;\nbit<32> other_identifier_1;\n}"))

; Enum Declaration
(check-equal?
 (apply-context
  (enum-declaration
   (name "identifier")
   (enum-body
    (name "other_identifier")))
  null)
 (list null "enum identifier {\nother_identifier\n}"))

; Specified Enum Declaration
(check-equal?
 (apply-context
  (enum-declaration
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
   (name "identifier")
   (specified-enum-body
    (specified-enum-body-line
     (name "field")
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
    (specified-enum-body-line
     (name "other_field")
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
                   (integer-primitive "2"))))))))))))))))))
  null)
 (list null "enum bit<32> identifier {\nfield = 1,\nother_field = 2\n}"))

; Specified Enum Declaration with Array Type
(check-exn
 exn:fail:o4:array-not-allowed?
 (lambda ()
   (apply-context
    (enum-declaration
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
     (specified-enum-body-line
      (name "field")
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
