#lang racket/base
; Expression Backend
; ---------------------------------------
(provide expression-list
         expression-array
         expression
         logical-or-expression
         logical-and-expression
         equality-expression 
         relational-expression 
         bitwise-or-expression
         bitwise-xor-expression
         bitwise-and-expression
         bitshift-expression
         additive-expression
         multiplicative-expression
         unary-cast-expression
         postfix-expression
         primary-expression
         integer-primitive
         boolean-primitive
         check-expression-array-dimensions?
         get-expression-array-dimensions
         integer-primitive->number)


; Implementation
; ---------------------------------------
(require br/macro racket/list racket/string
         o4/backend/name o4/context o4/utils/error o4/utils/util
         (for-syntax racket/base))

; Expression List
(define-macro (expression-list EXPRESSIONS ...)
  #'(lambda (ctx)
      (let-values ([(ctx strs vals) (fold-context-3 ctx EXPRESSIONS ...)])
        (values
         ctx
         (string-join strs ", ")
         #f))))

; Expression Array
(define-macro-cases expression-array
  [(expression-array EXPRESSION)
   #'(lambda (ctx)
       (let-values ([(ctx str val) (EXPRESSION ctx)])
         (values
          ctx
          (list str)
          (list val))))]
  [(expression-array "[" EXPRESSION-ARRAYS ... "]")
   #'(lambda (ctx)
       (let-values ([(ctx strs vals) (fold-context-3 ctx EXPRESSION-ARRAYS ...)])
         (values
          ctx
          strs
          vals)))])

; Top-Level Expression
; -
; Expressions do not only return the compiler context and a string representation of itself, but also a value representation of itself (equals to #f if value representation is not available).
(define-macro-cases expression
  [(expression LOGICAL-OR-EXPRESSION)
   #'(lambda (ctx)
       (LOGICAL-OR-EXPRESSION ctx))]
  [(expression "{" EXPRESSION-LIST "}")
   #'(lambda (ctx)
       (let-values ([(ctx str val) (EXPRESSION-LIST ctx)])
         (values
          ctx
          (format "{ ~a }" str)
          #f)))])

; Binary Expressions
; -
; Binary expressions are handled together.
(define-macro logical-or-expression #'binary-expression)
(define-macro logical-and-expression #'binary-expression)
(define-macro equality-expression #'binary-expression)
(define-macro relational-expression #'binary-expression)
(define-macro bitwise-or-expression #'binary-expression)
(define-macro bitwise-xor-expression #'binary-expression)
(define-macro bitwise-and-expression #'binary-expression)
(define-macro bitshift-expression #'binary-expression)
(define-macro additive-expression #'binary-expression)
(define-macro multiplicative-expression #'binary-expression)

(define-macro-cases binary-expression
  [(binary-expression EXPRESSION)
   #'(lambda (ctx)
       (EXPRESSION ctx))]
  [(binary-expression LEFT-EXPRESSION OPERATORS ... RIGHT-EXPRESSION)
   #'(lambda (ctx)
       (let*-values ([(ctx left-str left-val) (LEFT-EXPRESSION ctx)]
                     [(ctx right-str right-val) (RIGHT-EXPRESSION ctx)])
         (values
          ctx
          (format "~a ~a ~a" left-str (string-append OPERATORS ...) right-str)
          ; Compute the value representation of the expression.
          ((hash-ref operator-hash (string->symbol (string-append OPERATORS ...))) left-val right-val))))])

; Unary & Cast Expression
(define-macro-cases unary-cast-expression
  [(unary-cast-expression POSTFIX-EXPRESSION)
   #'(lambda (ctx)
       (POSTFIX-EXPRESSION ctx))]
  [(unary-cast-expression OPERATOR UNARY-CAST-EXPRESSION)
   #'(lambda (ctx)
       (let-values ([(ctx str val) (UNARY-CAST-EXPRESSION ctx)])
         (values
          ctx
          (format "~a~a" OPERATOR str)
          ; Compute the value representation of the expression.
          ((hash-ref operator-hash (string->symbol OPERATOR)) val))))]
  [(unary-cast-expression "(" TYPE-NAME ")" UNARY-CAST-EXPRESSION)
   #'(lambda (ctx)
       (let*-values ([(ctx type-name-str type-name-dims) (TYPE-NAME ctx)]
                     [(ctx exp-str exp-val) (UNARY-CAST-EXPRESSION ctx)])
         ; Cast expressions with array types are not supported
         (if (null? type-name-dims)
             (values
              ctx
              (format "(~a)~a" type-name-str exp-str)
              #f)
             (raise-array-not-allowed-error "cast expressions" #'TYPE-NAME))))])

; Postfix Expression
(define-macro-cases postfix-expression
  [(postfix-expression PRIMARY-EXPRESSION)
   #'(lambda (ctx)
       (PRIMARY-EXPRESSION ctx))]
  [(postfix-expression POSTFIX-EXPRESSION "[" EXPRESSION "]")
   ; TODO: Handle header stacks
   #'(lambda (ctx)
       (let*-values ([(ctx postfix-str postfix-val) (POSTFIX-EXPRESSION ctx)]
                     [(ctx exp-str exp-val) (EXPRESSION ctx)])
         ; The array index has to be compile time known
         (if exp-val
             (values
              ctx
              (format "~a_~a" postfix-str exp-val)
              #f)
             (raise-array-index-unknown-error exp-str #'EXPRESSION))))]
  [(postfix-expression POSTFIX-EXPRESSION "[" START-EXPRESSION ":" END-EXPRESSION "]")
   #'(lambda (ctx)
       (let*-values ([(ctx postfix-str postfix-val) (POSTFIX-EXPRESSION ctx)]
                     [(ctx start-str start-val) (START-EXPRESSION ctx)]
                     [(ctx end-str end-val) (END-EXPRESSION ctx)])
         (values
          ctx
          (format "~a[~a:~a]" postfix-str start-str end-str)
          #f)))]
  [(postfix-expression POSTFIX-EXPRESSION "(" ARGUMENT-LIST ")")
   #'(lambda (ctx)
       (let*-values ([(ctx postfix-str postfix-val) (POSTFIX-EXPRESSION ctx)]
                     [(ctx arg-lst-str arg-lst-vals) (ARGUMENT-LIST ctx)]
                     ; Save factory call to context
                     [(fact-body-str) (set-factory-call ctx (string->symbol postfix-str) arg-lst-vals)])
         (if (equal? postfix-str fact-body-str)
             (values
              ctx
              (format "~a(~a)" fact-body-str arg-lst-str)
              #f)
             (values
              ctx
              ; If the expression is a factory call, we remove the factory call arguments.
              fact-body-str
              #f))))]
  [(postfix-expression POSTFIX-EXPRESSION "." NAME)
   #'(lambda (ctx)
       (let*-values ([(ctx exp-str exp-val) (POSTFIX-EXPRESSION ctx)]
                     [(ctx name-str) (NAME ctx)])
         (values
          ctx
          (format "~a.~a" exp-str name-str)
          #f)))])

; Primary Expression
(define-macro-cases primary-expression
  [(primary-expression (integer-primitive ARGS ...))
   #'(lambda (ctx)
       ((integer-primitive ARGS ...) ctx))]
  [(primary-expression (boolean-primitive ARGS ...))
   #'(lambda (ctx)
       ((boolean-primitive ARGS ...) ctx))]
  [(primary-expression (name ARGS ...))
   #'(lambda (ctx)
       (let*-values ([(ctx name-str) ((name ARGS ...) ctx)]
                     ; Check if identifier has to be replaced by e.g. a loop iterator.
                     [(sub-var-str sub-var-val) (substitute-variable ctx (string->symbol name-str))])
         (values
          ctx
          sub-var-str
          sub-var-val)))]
  [(primary-expression "(" EXPRESSION ")")
   #'(lambda (ctx)
       (let-values ([(ctx str val) (EXPRESSION ctx)])
         (values
          ctx
          (format "(~a)" str)
          val)))])

; Integer Primitive
(define-macro (integer-primitive INTEGER)
  #'(lambda (ctx)
      (values
       ctx
       INTEGER
       ; Convert integer to its value representation.
       (integer-primitive->number INTEGER))))

; Boolean Primitive
(define-macro (boolean-primitive BOOLEAN)
  #'(lambda (ctx)
      (values
       ctx
       BOOLEAN
       #f)))


; Helper Functions
; ---------------------------------------
; Check Expression Array Dimensions
; -
; Make sure that the given expression array is a proper n-D array with the given dimensions.
; This function accepts the string "*" in the list of dims, meaning the given dimension can be anything.
(define (check-expression-array-dimensions? exp-arr dims)
  (if (null? dims)
      (string? (first exp-arr))
      (if (or (equal? (first dims) "*") (= (length exp-arr) (first dims)))
          (for/and ([exp-arr (in-list exp-arr)])
            (if (list? exp-arr)
                (check-expression-array-dimensions? exp-arr (rest dims))
                #f))
          #f)))

; Get Expression Array Dimensions
; -
; Returns a list of dimensions of the given expression array, or #f if the expression array is not a proper n-D array.
(define (get-expression-array-dimensions exp-arr)
  (let ([dims (get-naive-expression-array-dimensions exp-arr)])
    (if (check-expression-array-dimensions? exp-arr dims)
        dims
        #f)))

(define (get-naive-expression-array-dimensions exp-arr)
  (if (list? (first exp-arr))
      (cons
       (length exp-arr)
       (get-naive-expression-array-dimensions (first exp-arr)))
      null))

; Integer Primitive Parser
; -
; Parses the integer primitive to a Racket value.
(define (integer-primitive->number exp)
  ; As the lexer only returns valid integer strings, we can simplify the regex.
  (let* ([match (regexp-match #px"^(?:(\\d+)([ws]))?(?:0([doxbDOXB]))?([\\da-fA-F]+)$" exp)]
         [size (second match)] ; \d+
         [sign (third match)] ; [ws]
         [base (fourth match)] ; [doxbDOXB]
         [val (fifth match)] ;  [\da-fA-F]+
         [val (interpret-base base val)]
         [val (restrict-size-and-apply-sign size sign val)])
    val))

(define (interpret-base base val)
  (if base
      (string->number (format "#~a~a" (string-downcase base) val))
      (string->number val)))

(define (restrict-size-and-apply-sign size sign val)
  (if size
      (let ([size (string->number size)])
        (if (or (equal? sign "w") (not (bitwise-bit-set? val (sub1 size))))
            (bitwise-bit-field val 0 size)
            ; Two's complement
            (- (bitwise-bit-field val 0 size) (arithmetic-shift 1 size))))
      val))

; Value Propagation
; -
; Racket equivalents for binary and unary expressions, allowing to propagate the value representation of their operands.
(define (not-implemented . vals)
  #f)
(define (add left-val [right-val null])
  (if (and left-val right-val)
      (if (null? right-val)
          (+ left-val)
          (+ left-val right-val))
      #f))
(define (sub left-val [right-val null])
  (if (and left-val right-val)
      (if (null? right-val)
          (- left-val)
          (- left-val right-val))
      #f))
(define (mod left-val right-val)
  (if (and left-val right-val)
      (modulo left-val right-val)
      #f))

; We currently only propagate the value representations for unary and binary addition and subtraction, as well as the modulo operator.
(define operator-hash (hasheq
                       '\|\| not-implemented
                       '&& not-implemented
                       '== not-implemented
                       '!= not-implemented
                       '< not-implemented
                       '> not-implemented
                       '<= not-implemented
                       '>= not-implemented
                       '\| not-implemented
                       '^ not-implemented
                       '& not-implemented
                       '<< not-implemented
                       '>> not-implemented
                       '+ add
                       '- sub
                       '++ not-implemented
                       '\|+\| not-implemented
                       '\|-\| not-implemented
                       '* not-implemented
                       '/ not-implemented
                       '% mod
                       '~ not-implemented
                       '! not-implemented))
