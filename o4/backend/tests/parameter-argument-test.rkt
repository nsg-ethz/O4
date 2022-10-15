#lang racket/base
; Parameter & Argument Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/expression o4/backend/name o4/backend/parameter-argument o4/backend/type-name o4/context o4/utils/error o4/utils/util)

; Parameter List
(let* ([ctx (add-scope null)]
       [final-ctx (add-scope null)]
       [_ (set-parameter final-ctx 'identifier_0 0 "inout" "1" 1)]
       [_ (set-parameter final-ctx 'identifier_1 1 "inout" "2" 2)]
       [_ (set-parameter final-ctx 'other_identifier 2 "inout" "3" 3)])
  (check-equal?
   (apply-context
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
      (name "other_identifier")
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
                     (integer-primitive "3"))))))))))))))))))
    ctx)
   (list final-ctx "inout bit<32> identifier_0 = 1, inout bit<32> identifier_1 = 2, inout bit<32> other_identifier = 3")))

; Parameter with Array Type
(let* ([ctx (add-scope null)]
       [final-ctx (add-scope null)]
       [_ (set-parameter final-ctx 'identifier_0_0 0 "inout")]
       [_ (set-parameter final-ctx 'identifier_0_1 1 "inout")]
       [_ (set-parameter final-ctx 'identifier_1_0 2 "inout")]
       [_ (set-parameter final-ctx 'identifier_1_1 3 "inout")]
       [_ (set-parameter final-ctx 'identifier_2_0 4 "inout")]
       [_ (set-parameter final-ctx 'identifier_2_1 5 "inout")])
  (check-equal?
   (apply-context
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
     (name "identifier"))
    ctx
    0)
   (list
    final-ctx
    (list
     "inout bit<32> identifier_0_0"
     "inout bit<32> identifier_0_1"
     "inout bit<32> identifier_1_0"
     "inout bit<32> identifier_1_1"
     "inout bit<32> identifier_2_0"
     "inout bit<32> identifier_2_1")
    6)))

; Parameter with Array Type and Default Value
(let* ([ctx (add-scope null)]
       [final-ctx (add-scope null)]
       [_ (set-parameter final-ctx 'identifier_0 0 "inout" "1" 1)]
       [_ (set-parameter final-ctx 'identifier_1 1 "inout" "2" 2)])
  (check-equal?
   (apply-context
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
    ctx
    0)
   (list
    final-ctx
    (list
     "inout bit<32> identifier_0 = 1"
     "inout bit<32> identifier_1 = 2")
    2)))

; Parameter with Wrongly Sized Default Value
(check-exn
 exn:fail:o4:array-wrong-dimensions?
 (lambda ()
   (apply-context
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
                    (integer-primitive "3"))))))))))))))))
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
    null
    0)))

; Type Parameter List
(check-equal?
 (apply-context
  (type-parameter-list
   (name "identifier")
   (name "other_identifier"))
  null)
 (list null "identifier, other_identifier"))

; Argument List
(check-equal?
 (apply-context
  (argument-list
   (argument
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
   (argument
    (name "other_identifier")
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
                   (integer-primitive "3"))))))))))))))))))
  null)
 (list
  null
  "identifier_0 = 1, identifier_1 = 2, other_identifier = 3"
  (list
   (get-argument-metadata "1" 1 "identifier_0")
   (get-argument-metadata "2" 2 "identifier_1")
   (get-argument-metadata "3" 3 "other_identifier"))))

; Argument List with Single Argument
(check-equal?
 (apply-context
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
  null)
 (list null "argument" (list (get-argument-metadata "argument" #f))))

; Argument List with Mixed Named and Unnamed Arguments
(check-exn
 exn:fail:o4:argument-list?
 (lambda ()
   (apply-context
    (argument-list
     (argument
      (name "identifer")
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
                     (integer-primitive "2"))))))))))))))))))
    null)))

; Expression Array Argument
(check-equal?
 (apply-context
  (argument
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
   "1"
   "2")
  (list
   (get-argument-metadata "1" 1)
   (get-argument-metadata "2" 2))))

; Expression Array Argument with Name
(check-equal?
 (apply-context
  (argument
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
 (list
  null
  (list
   "identifier_0 = 1"
   "identifier_1 = 2")
  (list
   (get-argument-metadata "1" 1 "identifier_0")
   (get-argument-metadata "2" 2 "identifier_1"))))

; Wrongly Sized Expression Array Argument with Name
(check-exn
 exn:fail:o4:array-wrong-dimensions?
 (lambda ()
   (apply-context
    (argument
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

; Type Argument List with Array Type
(check-exn
 exn:fail:o4:array-not-allowed?
 (lambda ()
   (apply-context
    (type-name
     (simple-type-name
      "identifier"
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
                      (integer-primitive "4")))))))))))))))))))
    null)))
