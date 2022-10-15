#lang racket/base
; Expression Backend Tests
; ---------------------------------------
(require rackunit
         o4/backend/expression o4/backend/name o4/backend/parameter-argument o4/backend/type-name o4/context o4/utils/error o4/utils/util)

; Expression List
(check-equal?
 (apply-context
  (expression
   "{"
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
                  (integer-primitive "1")))))))))))))))
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
   "}")
  null)
 (list null "{ 1, 2 }" #f))
  
; Expression Array
(check-equal?
 (apply-context
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
                   (integer-primitive "3"))))))))))))))))
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
                   (integer-primitive "4"))))))))))))))))
    "]")
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
                   (integer-primitive "5"))))))))))))))))
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
                   (integer-primitive "6"))))))))))))))))
    "]")
   "]")
  null)
 (list
  null
  (list
   (list (list "1") (list "2"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6")))
  (list
   (list (list 1) (list 2))
   (list (list 3) (list 4))
   (list (list 5) (list 6)))))

; Expression Array with Single Element
(check-equal?
 (apply-context
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
  null)
 (list
  null
  (list (list (list "1")))
  (list (list (list 1)))))

; Pass-Through
(check-equal?
 (apply-context
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
  null)
 (list null "1" 1))

; Rightshift Operator
(check-equal?
 (apply-context
  (expression
   (logical-or-expression
    (logical-and-expression
     (equality-expression
      (relational-expression
       (bitwise-or-expression
        (bitwise-xor-expression
         (bitwise-and-expression
          (bitshift-expression
           (bitshift-expression
            (additive-expression
             (multiplicative-expression
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "1")))))))
           ">"
           ">"
           (additive-expression
            (multiplicative-expression
             (unary-cast-expression
              (postfix-expression
               (primary-expression
                (integer-primitive "2")))))))))))))))
  null)
 (list null "1 >> 2" #f))
  
; Value Evaluation Binary +
(check-equal?
 (apply-context
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
            (additive-expression
             (multiplicative-expression
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "1"))))))
            "+"
            (multiplicative-expression
             (unary-cast-expression
              (postfix-expression
               (primary-expression
                (integer-primitive "2")))))))))))))))
  null)
 (list null "1 + 2" 3))

; Value Evaluation Binary -
(check-equal?
 (apply-context
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
            (additive-expression
             (multiplicative-expression
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "1"))))))
            "-"
            (multiplicative-expression
             (unary-cast-expression
              (postfix-expression
               (primary-expression
                (integer-primitive "2")))))))))))))))
  null)
 (list null "1 - 2" -1))

; Value Evaluation %
(check-equal?
 (apply-context
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
            (additive-expression
             (multiplicative-expression
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "1"))))))
            "%"
            (multiplicative-expression
             (unary-cast-expression
              (postfix-expression
               (primary-expression
                (integer-primitive "2")))))))))))))))
  null)
 (list null "1 % 2" 1))

; Value Evaluation Unary +
(check-equal?
 (apply-context
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
              "+"
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "1"))))))))))))))))
  null)
 (list null "+1" 1))

; Value Evaluation Unary -
(check-equal?
 (apply-context
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
              "-"
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "1"))))))))))))))))
  null)
 (list null "-1" -1))

; Value Evaluation Brackets
(check-equal?
 (apply-context
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
                "("
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
                          (additive-expression
                           (multiplicative-expression
                            (unary-cast-expression
                             (postfix-expression
                              (primary-expression
                               (integer-primitive "1"))))))
                          "+"
                          (multiplicative-expression
                           (unary-cast-expression
                            (postfix-expression
                             (primary-expression
                              (integer-primitive "2")))))))))))))))
                ")"))))))))))))))
  null)
 (list null "(1 + 2)" 3))

; Cast Expression
(check-equal?
 (apply-context
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
              "("
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
              ")"
              (unary-cast-expression
               (postfix-expression
                (primary-expression
                 (integer-primitive "1"))))))))))))))))
  null)
 (list null "(bit<32>)1" #f))

; Cast to Array Type
(check-exn
 exn:fail:o4:array-not-allowed?
 (lambda ()
   (apply-context
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
                "("
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
                ")"
                (unary-cast-expression
                 (postfix-expression
                  (primary-expression
                   (integer-primitive "1"))))))))))))))))
    null)))

; Postfix Expression Array Access
(check-equal?
 (apply-context
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
               (postfix-expression
                (postfix-expression
                 (primary-expression
                  (name "identifier")))
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
               "]")))))))))))))
  null)
 (list null "identifier_3_2" #f))

; Postfix Expression Array Access with Compile Time Unknown Index
(check-exn
 exn:fail:o4:array-index-unknown?
 (lambda ()
   (apply-context
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
                 (postfix-expression
                  (primary-expression
                   (name "identifier")))
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
                 "]")))))))))))))
    null)))

; Postfix Expression Factory Call
(let* ([ctx (add-scope null)]
       [_ (set-factory ctx 'identifier "body_name" null null)]
       [final-ctx (add-scope null)]
       [_ (set-factory final-ctx 'identifier "body_name" null null)]
       [_ (set-factory-call final-ctx 'identifier null)])
  (check-equal?
   (apply-context
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
                 (postfix-expression
                  (primary-expression (name "identifier")))
                 "("
                 (argument-list)
                 ")")))))))))))))
    ctx)
   (list final-ctx "body_name_call" #f)))

; Substitute Expression
(let* ([ctx (add-scope null)]
       [_ (set-variable ctx 'substitute "1" 1 #t)])
  (check-equal?
   (apply-context
    (primary-expression
     (name "substitute"))
    ctx)
   (list ctx "1" 1)))

; Check Expression Array Dimensions
(check-equal?
 (check-expression-array-dimensions?
  (list "1")
  null)
 #t)
(check-equal?
 (check-expression-array-dimensions?
  (list "1")
  (list 1))
 #f)
(check-equal?
 (check-expression-array-dimensions?
  (list (list "1"))
  null)
 #f)
(check-equal?
 (check-expression-array-dimensions?
  (list (list "1"))
  (list 1))
 #t)
(check-equal?
 (check-expression-array-dimensions?
  (list (list "1"))
  (list 1 1))
 #f)
(check-equal?
 (check-expression-array-dimensions?
  (list
   (list (list "1") (list "2"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6")))
  (list 3 2))
 #t)
(check-equal?
 (check-expression-array-dimensions?
  (list
   (list (list "1"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6")))
  (list 3 2))
 #f)
(check-equal?
 (check-expression-array-dimensions?
  (list
   (list (list "1") (list "2") (list "2"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6")))
  (list 3 2))
 #f)

; Check Expression Array Dimensions with Kleene Star
(check-equal?
 (check-expression-array-dimensions?
  (list "1")
  (list "*"))
 #f)
(check-equal?
 (check-expression-array-dimensions?
  (list (list "1"))
  (list "*"))
 #t)
(check-equal?
 (check-expression-array-dimensions?
  (list (list (list "1")))
  (list "*"))
 #f)
(check-equal?
 (check-expression-array-dimensions?
  (list
   (list "1")
   (list "2"))
  (list "*"))
 #t)
(check-equal?
 (check-expression-array-dimensions?
  (list
   (list (list "1") (list "2"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6")))
  (list "*" 2))
 #t)
(check-equal?
 (check-expression-array-dimensions?
  (list
   (list (list "1") (list "2") (list "2"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6")))
  (list "*" 2))
 #f)

; Get Expression Array Dimensions
(check-equal?
 (get-expression-array-dimensions
  (list "1"))
 null)
(check-equal?
 (get-expression-array-dimensions
  (list
   (list (list "1") (list "2"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6"))))
 (list 3 2))
(check-equal?
 (get-expression-array-dimensions
  (list
   (list (list "1"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6"))))
 #f)
(check-equal?
 (get-expression-array-dimensions
  (list
   (list (list "1") (list "2"))
   (list (list "3"))
   (list (list "5") (list "6"))))
 #f)
(check-equal?
 (get-expression-array-dimensions
  (list
   (list (list "1") (list "2") (list "2"))
   (list (list "3") (list "4"))
   (list (list "5") (list "6"))))
 #f)
(check-equal?
 (get-expression-array-dimensions
  (list
   (list (list "1") (list "2"))
   (list (list "3") (list "4") (list "4"))
   (list (list "5") (list "6"))))
 #f)

; Integer Primitive Parser
(check-equal?
 (integer-primitive->number "10")
 10)
(check-equal?
 (integer-primitive->number "8w10")
 10)
(check-equal?
 (integer-primitive->number "8s10")
 10)
(check-equal?
 (integer-primitive->number "2s3")
 -1)
(check-equal?
 (integer-primitive->number "1w10")
 0)
(check-equal?
 (integer-primitive->number "1s1")
 -1)
(check-equal?
 (integer-primitive->number "32w255")
 255)
(check-equal?
 (integer-primitive->number "32w0d255")
 255)
(check-equal?
 (integer-primitive->number "32w0xFF")
 255)
(check-equal?
 (integer-primitive->number "32s0xFF")
 255)
(check-equal?
 (integer-primitive->number "8w0b10101010")
 170)
(check-equal?
 (integer-primitive->number "8w170")
 170)
(check-equal?
 (integer-primitive->number "8s0b10101010")
 -86)
(check-equal?
 (integer-primitive->number "16w0377")
 377)
(check-equal?
 (integer-primitive->number "16w0o377")
 255)
