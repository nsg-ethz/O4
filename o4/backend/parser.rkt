#lang racket/base
; Parser Backend
; ---------------------------------------
(provide parser-declaration
         parser-body
         parser-states
         parser-transitions
         parser-state
         parser-block-statement
         parser-transition
         transition-source
         simple-transition-expression
         select-transition-expression
         select-body
         select-body-line
         simple-keyset-expression
         tuple-keyset-expression
         combine-parser-states-with-transitions)


; Implementation
; ---------------------------------------
(require br/macro racket/set racket/string
         o4/backend/statement o4/context o4/utils/error o4/utils/util
         (for-syntax racket/base))

; Parser Declaration
(define-macro (parser-declaration NAME PARAMETER-LISTS ... PARSER-BODY PARSER-STATES PARSER-TRANSITIONS)
  #'(lambda (ctx)
      (let*-values ([(ctx name-str) (NAME ctx)]
                    [(ctx) (add-scope ctx)]
                    [(ctx param-lsts-str) (fold-string-join-context-2 ctx ")(" PARAMETER-LISTS ...)]
                    [(ctx body-str) (PARSER-BODY ctx)]
                    [(ctx state-hash) (PARSER-STATES ctx)]
                    [(ctx tran-hash) (PARSER-TRANSITIONS ctx)]
                    ; After compiling the parser block, we combine the parser states with its corresponding transitions.
                    [(states-str) (combine-parser-states-with-transitions state-hash tran-hash)]
                    [(ctx) (remove-scope ctx)])
        ; Transition sources have to be a subset of parser states
        (if states-str
            (values
             ctx
             (format "parser ~a(~a) {\n~a\n~a\n}" name-str param-lsts-str body-str states-str))
            (raise-parser-invalid-transition-error "transition sources contain unknown identifiers" #'PARSER-TRANSITIONS)))))

; Parser Body
(define-macro (parser-body PARSER-BODY-LINES ...)
  #'(lambda (ctx)
      (fold-string-join-context-2 ctx "\n" PARSER-BODY-LINES ...)))

; Parser States & Transitions
; -
; Parser states and transitions are handled together.
(define-macro parser-states #'parser-states-transitions)
(define-macro parser-transitions #'parser-states-transitions)

(define-macro (parser-states-transitions FUNCS ...)
  #'(lambda (ctx)
      ; We use a hash to keep track of the already seen parser states and transitions.
      (let* ([hash (make-hasheq)]
             [ctx (parser-states-transitions-fold ctx hash FUNCS ...)])
        (values
         ctx
         hash))))

(define (parser-states-transitions-fold ctx hash . funcs)
  (for/fold ([ctx ctx])
            ([func (in-list funcs)])
    (func ctx hash)))

; Parser State
(define-macro (parser-state NAME PARSER-BLOCK-STATEMENT)
  #'(lambda (ctx hash)
      (let*-values ([(ctx name-str) (NAME ctx)]
                    [(ctx stat-str) (PARSER-BLOCK-STATEMENT ctx)])
        ; State names have to be unique
        (with-handlers ([exn:fail:o4:hash-key? (lambda (exn)
                                                 (raise-parser-invalid-transition-error (format "re-declaration of ~a" name-str) #'NAME))])
          (hash-set-if-not-exists! hash (string->symbol name-str) (format "state ~a ~a" name-str stat-str)))
        ctx)))

; Parser Block Statement
(define-macro parser-block-statement #'block-statement)

; Parser Transition
(define-macro (parser-transition TRANSITION-SOURCE TRANSITION-EXPRESSIONS ...)
  #'(lambda (ctx hash)
      (let*-values ([(ctx src-names) (TRANSITION-SOURCE ctx)]
                    [(ctx _) (parser-transition-fold
                              ctx
                              hash
                              src-names
                              ; We pass the syntax objects of the child nodes, to allow for better error messages.
                              (cons #'TRANSITION-SOURCE (drop-last (list #'TRANSITION-EXPRESSIONS ...)))
                              TRANSITION-EXPRESSIONS ...)])
        ctx)))

(define (parser-transition-fold ctx hash names stxs . tran-exps)
  (for/fold ([ctx ctx]
             [names names])
            ([tran-exp (in-list tran-exps)]
             [stx (in-list stxs)])
    (let-values ([(ctx tran-str tran-names) (tran-exp ctx)])
      (for ([name (in-list names)])
        ; Sinks cannot be transitioned from
        (if (or (equal? name "accept") (equal? name "reject"))
            (raise-parser-invalid-transition-error "sinks (\"accept\", \"reject\") cannot be transitioned from" stx)
            ; Only one transition statement allowed for each state
            (with-handlers ([exn:fail:o4:hash-key? (lambda (exn)
                                                     (raise-parser-invalid-transition-error (format "multiple transition statements for transition source ~a" name) stx))])
              (hash-set-if-not-exists! hash (string->symbol name) tran-str))))
      (values
       ctx
       tran-names))))

; Transition Source
(define-macro (transition-source NAMES ...)
  #'(lambda (ctx)
      (fold-context-2 ctx NAMES ...)))

; Simple Transition Expression
(define-macro (simple-transition-expression NAME)
  #'(lambda (ctx)
      (let-values ([(ctx str) (NAME ctx)])
        (values
         ctx
         (format "transition ~a;" str)
         (list str)))))

; Select Transition Expression
(define-macro (select-transition-expression EXPRESSION-LIST SELECT-BODY)
  #'(lambda (ctx)
      (let*-values ([(ctx exp-lst-str exp-lst-val) (EXPRESSION-LIST ctx)]
                    [(ctx body-str body-names) (SELECT-BODY ctx)])
        (values
         ctx
         (format "transition select(~a) {\n~a\n}" exp-lst-str body-str)
         body-names))))

; Select Body
(define-macro (select-body SELECT-BODY-LINES ...)
  #'(lambda (ctx)
      (let-values ([(ctx strs names) (fold-context-3 ctx SELECT-BODY-LINES ...)])
        (values
         ctx
         (string-join strs "\n")
         names))))

; Select Body Line
(define-macro (select-body-line KEYSET-EXPRESSION NAME)
  #'(lambda (ctx)
      (let*-values ([(ctx exp-str) (KEYSET-EXPRESSION ctx)]
                    [(ctx name-str) (NAME ctx)])
        (values
         ctx
         (format "~a : ~a;" exp-str name-str)
         name-str))))

; Simple Keyset Expression
(define-macro-cases simple-keyset-expression
  [(simple-keyset-expression "default")
   #'(lambda (ctx)
       (values
        ctx
        "default"))]
  [(simple-keyset-expression EXPRESSION)
   #'(lambda (ctx)
       (let-values ([(ctx str val) (EXPRESSION ctx)])
         (values
          ctx
          str)))]
  [(simple-keyset-expression LEFT-EXPRESSION OPERATOR RIGHT-EXPRESSION)
   #'(lambda (ctx)
       (let*-values ([(ctx left-str left-val) (LEFT-EXPRESSION ctx)]
                     [(ctx right-str right-val) (RIGHT-EXPRESSION ctx)])
         (values
          ctx
          (format "~a ~a ~a" left-str OPERATOR right-str))))])

; Tuple Keyset Expression
(define-macro (tuple-keyset-expression SIMPLE-KEYSET-EXPRESSIONS ...)
  #'(lambda (ctx)
      (let-values ([(ctx strs) (fold-context-2 ctx SIMPLE-KEYSET-EXPRESSIONS ...)])
        (values
         ctx
         (string-join strs ", "
                      #:before-first "("
                      #:after-last ")")))))


; Helper Functions
; ---------------------------------------
; Combine Parser States with Transitions
; -
; This function takes in two hashes, containing the declared parser states and their corresponding transitions.
; We first make sure that there are no transitions with undefined sources and then add the transition expressions to the end of their corresponding states.
(define (combine-parser-states-with-transitions state-hash tran-hash)
  (if (subset? (list->set (hash-keys tran-hash)) (list->set (hash-keys state-hash)))
      (string-join
       (hash-map
        state-hash
        (lambda (k v)
          (combine-parser-state-with-transitions k v tran-hash))
        #t)
       "\n")
      #f))

(define (combine-parser-state-with-transitions state-name state-str tran-hash)
  (let ([tran-str (hash-ref tran-hash state-name #f)])
    (if tran-str
        (format "~a~a\n}" (substring state-str 0 (sub1 (string-length state-str))) tran-str)
        state-str)))
