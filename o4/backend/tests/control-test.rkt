#lang racket/base
; Control Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/control
         o4/backend/declaration
         o4/backend/expression
         o4/backend/name
         o4/backend/parameter-argument
         o4/backend/parser
         o4/backend/statement
         o4/backend/type-name
         o4/context
         o4/utils/error
         o4/utils/util)

; Control Declaration
(check-equal?
 (apply-context
  (control-declaration
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
   (control-body)
   (block-statement))
  null)
 (list null "control identifier(bit<32> parameter)(bit<32> constructor_parameter) {\n\napply {\n\n}\n}"))

; Control Declaration with Factory
(check-equal?
 (apply-context
  (control-declaration
   (name "identifier")
   (parameter-list)
   (control-body
    (factory-declaration
     (name "other_identifier")
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
     (action-declaration
      (name "even_another_identifier")
      (parameter-list)
      (block-statement
       (assignment-statement
        (lvalue
         (lvalue
          (name "identifier"))
         "."
         (name "field"))
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
                       (name "parameter")))))))))))))))))))
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
                    (name "even_another_identifier"))))))))))))))))))
   (block-statement
    (call-statement
     (lvalue
      (name "other_identifier"))
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
                      (integer-primitive "1")))))))))))))))))))))
  null)
 (list null "control identifier() {\naction even_another_identifier_call_1() {\nidentifier.field = 1;\n}\napply {\neven_another_identifier_call_1;\n}\n}"))

; Deparser Declaration
(check-equal?
 (apply-context
  (deparser-declaration
   (name "identifier")
   (parameter-list)
   (control-body)
   (block-statement))
  null)
 (list null "control identifier() {\n\napply {\n\n}\n}"))

; Table Declaration
(check-equal?
 (apply-context
  (table-declaration
   (name "identifier")
   (key-property
    "key"
    (key-property-body-line
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
     (name "exact")))
   (entries-property
    "entries"
    (entries-property-body-line
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
     (action-reference
      (name "other_identifier"))))
   (custom-property
    "const"
    (table-name "const_custom_property")
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
                  (name "other_identifier"))))))))))))))))
   (custom-property
    (table-name "custom_property")
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
                  (name "other_identifier")))))))))))))))))
  null)
 (list null "table identifier {\nkey = {\nexpression : exact;\n}\nconst entries = {\n2 : other_identifier;\n}\nconst const_custom_property = other_identifier;\ncustom_property = other_identifier;\n}"))

; Substitute Table Name
(let* ([ctx (add-scope null)]
       [_ (set-variable ctx 'substitute "identifier" #f #t)])
  (check-equal?
   (apply-context
    (table-declaration
     (name "substitute")
     (key-property
      "key"
      (key-property-body-line
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
       (name "exact"))))
    ctx)
   (list ctx "table identifier {\nkey = {\nexpression : exact;\n}\n}")))

; Actions Property
(let* ([ctx (add-scope null)]
       [_ (set-factory ctx 'identifier "body_name" null null)]
       [final-ctx (add-scope null)]
       [_ (set-factory final-ctx 'identifier "body_name" null null)]
       [_ (set-factory-call final-ctx 'identifier null)])
  (check-equal?
   (apply-context
    (actions-property
     "actions"
     (action-reference
      (name "action"))
     (action-reference
      (name "identifier"))
     (action-reference
      (name "action")
      (argument-list))
     (action-reference
      (name "identifier")
      (argument-list))
     (action-reference
      (name "identifier")
      (argument-list)
      (argument-list)))
    ctx)
   (list final-ctx "actions = {\naction;\nbody_name_call;\naction();\nbody_name_call;\nbody_name_call();\n}")))

; Action Reference with Non-Factory Double Parametrization
(check-exn
 exn:fail:o4:factory-call?
 (lambda ()
   (apply-context
    (action-reference
     (name "identifier")
     (argument-list)
     (argument-list))
    null)))

; Factory Declaration
(let* ([ctx (add-scope null)]
       [final-ctx (add-scope null)]
       [_ (set-factory final-ctx 'identifier "body_name" void (list (cons 'parameter (dec-parameter 0 #f #f #f))))])
  (check-equal?
   (apply-context
    (factory-declaration
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
     void
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
                    (name "body_name")))))))))))))))))
    ctx)
   (list final-ctx "$$$identifier$$$")))

; Factory Declaration with Return Statement without Expression
(check-exn
 exn:fail:o4:factory-definition?
 (lambda ()
   (apply-context
    (factory-declaration
     (name "identifier")
     (parameter-list)
     void
     (return-statement))
    null)))

; Factory Declaration with Parameters with Direction
(check-exn
 exn:fail:o4:factory-definition?
 (lambda ()
   (apply-context
    (factory-declaration
     (name "identifier")
     (parameter-list
      (parameter
       (direction "inout")
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
     void
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
                    (name "body_name")))))))))))))))))
    null)))
