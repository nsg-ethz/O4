#lang racket/base
; Instantiation Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/expression o4/backend/instantiation o4/backend/name o4/backend/parameter-argument o4/backend/type-name o4/context o4/utils/util)

; Instantiation with Array Type
(check-equal?
 (apply-context
  (instantiation
   (type-name
    (simple-type-name "type")
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
                    (name "argument"))))))))))))))))))
   (name "identifier"))
  null)
 (list
  null
  (list
   "type(argument) identifier_0_0;"
   "type(argument) identifier_0_1;"
   "type(argument) identifier_1_0;"
   "type(argument) identifier_1_1;"
   "type(argument) identifier_2_0;"
   "type(argument) identifier_2_1;")))

; Substitute Instantiation Name
(let* ([ctx (add-scope null)]
       [_ (set-variable ctx 'substitute "identifier" #f #t)])
  (check-equal?
   (apply-context
    (instantiation
     (type-name
      (simple-type-name "type"))
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
                      (name "argument"))))))))))))))))))
     (name "substitute"))
    ctx)
   (list ctx (list "type(argument) identifier;"))))

; Instantiation with Body
(check-equal?
 (apply-context
  (instantiation
   (type-name
    (simple-type-name "type"))
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
                    (name "argument"))))))))))))))))))
   (name "identifier")
   (instantiation
    (type-name
     (simple-type-name "type"))
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
                     (name "argument"))))))))))))))))))
    (name "other_identifier")))
  null)
 (list null (list "type(argument) identifier = {\ntype(argument) other_identifier;\n};")))

; Substitute Instantiation Name with Body
(let* ([ctx (add-scope null)]
       [_ (set-variable ctx 'substitute "identifier" #f #t)])
  (check-equal?
   (apply-context
    (instantiation
     (type-name
      (simple-type-name "type"))
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
                      (name "argument"))))))))))))))))))
     (name "substitute")
     (instantiation
      (type-name
       (simple-type-name "type"))
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
                       (name "argument"))))))))))))))))))
      (name "other_identifier")))
    ctx)
   (list ctx (list "type(argument) identifier = {\ntype(argument) other_identifier;\n};"))))
