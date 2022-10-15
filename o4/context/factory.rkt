#lang racket/base
; Factory Context
; ---------------------------------------
(provide dec-factory
         factory-call
         get-factory
         get-factories-of-scope
         get-factory-calls-of-scope
         set-factory
         set-factory-call
         remove-factory-call
         handle-factory-calls
         handle-factory-calls-fold
         get-factory-call-name
         format-body-string)


; Implementation
; ---------------------------------------
(require racket/list racket/string
         o4/context/base o4/context/parameter-argument o4/context/variable)

; Structs
; -
; For factories, we store the name of its body action/table/instance, the body function itself, as well as the list of factory parameters.
(struct dec-factory (body-name body parameters) #:transparent)
; For factory calls, we store the name of the factory that was called, the factory body and its name (copied from the factory), and a mapping from the factory call arguments to the factory parameters.
(struct factory-call (factory-name body-name body parameter-argument-map) #:transparent)

; Getters
(define (get-factory ctx name)
  (let ([dec (get-declare ctx name)])
    ; Check that returned declare is of type factory
    (if (dec-factory? dec)
        dec
        null)))

(define (get-factories-of-scope ctx)
  (let ([decs (get-declares-of-scope ctx)])
    (if (null? decs)
        null 
        ; Throw out null values from list of factories
        (filter
         pair?
         ; Create list of name-null-pairs for all factories in scope (sorted lexically by name)
         (hash-map
          decs
          (lambda (k v)
            (if (dec-factory? v)
                (cons k null)
                null))
          #t)))))

(define (get-factory-calls-of-scope ctx)
  (let ([calls (get-calls-of-scope ctx)])
    (if (null? calls)
        null
        ; Create list of name-factory-call-pairs of all factory calls in scope (sorted lexically by name)
        (hash-map calls cons #t))))

; Setters
(define (set-factory ctx name body-name body params)
  (set-declare ctx name (dec-factory body-name body params)))

(define (set-factory-call ctx name args)
  (let ([fact (get-factory ctx name)])
    (if (null? fact)
        ; Return name if call is not a factory call
        (symbol->string name)
        (let* ([param-arg-map (get-parameter-argument-map (dec-factory-parameters fact) args)]
               [fact-call-name (get-factory-call-name (dec-factory-body-name fact) param-arg-map)])
          (set-call ctx (string->symbol fact-call-name) (factory-call
                                                         (symbol->string name)
                                                         (dec-factory-body-name fact)
                                                         (dec-factory-body fact)
                                                         param-arg-map))
          fact-call-name))))

; Remover
(define (remove-factory-call ctx name)
  (remove-call ctx name))

; Handle Factory Calls
; -
; Given a context object and control body string, this function recursively expands all factory calls in the compiler context and splices the factory body instances into the control body string.
; TODO: Handle recursion loops
(define (handle-factory-calls ctx body-str)
  (let*-values ([(facts) (make-hasheq (get-factories-of-scope ctx))]
                [(hand-calls) (make-hasheq)]
                [(ctx _) (for/fold ([ctx ctx]
                                    [fact-calls (get-factory-calls-of-scope ctx)])
                                   ([_ (in-naturals)])
                           #:break (empty? fact-calls)
                           (let ([ctx (handle-factory-calls-fold facts hand-calls ctx fact-calls)])
                             (values
                              ctx
                              (get-factory-calls-of-scope ctx))))])
    (values
     ctx
     (format-body-string body-str (hash->list facts)))))

; Given a hash containing all declared factories, a hash of already handled factory calls, the compiler context and a list of factory calls, this function expands the factory calls.
(define (handle-factory-calls-fold facts hand-calls ctx fact-calls)
  (for/fold ([ctx ctx])
            ([fact-call (in-list fact-calls)])
    (let ([fact-call-name (car fact-call)]
          [fact-call (cdr fact-call)])
      ; Remove factory call from context if it was handled already
      (if (hash-ref hand-calls fact-call-name #f)
          (let ([_ (remove-factory-call ctx fact-call-name)])
            ctx)
          (let*-values ([(ctx) (add-scope ctx)]
                        ; Set body name as a variable to be replaced
                        [(_) (set-variable ctx (string->symbol (factory-call-body-name fact-call)) (symbol->string fact-call-name) #f #t)]
                        ; Set parameters as variables to be replaced
                        [(_) (set-variables ctx (map
                                                 (lambda (var)
                                                   (append var (list #t)))
                                                 (factory-call-parameter-argument-map fact-call)))]
                        [(ctx body-str) ((factory-call-body fact-call) ctx)]
                        [(ctx) (remove-scope ctx)])
            (hash-set! hand-calls fact-call-name #t)
            (hash-update! facts (string->symbol (factory-call-factory-name fact-call)) (lambda (fact)
                                                                                         (cons body-str fact)))
            (remove-factory-call ctx fact-call-name)
            ctx)))))


; Helper Functions
; ---------------------------------------
; Get Factory Call Name
; -
; This function generates a deterministic body name for a given factory call.
; This is done by appending a string representations of the factory call arguments to the given factory body name.
(define (get-factory-call-name name param-arg-map)
  (for/fold ([str (format "~a_call" name)])
            ([param-arg (in-list param-arg-map)])
    (let ([val (third param-arg)])
      (if val
          (format "~a_~a" str val)
          ; Replace all non-alphanumeric characters with underscore character
          (format "~a_~a" str (regexp-replace* #px"\\W" (second param-arg) "_"))))))

; Format Body String
; -
; This function splices the given factory body instances into the given control body string.
(define (format-body-string body-str facts)
  (let/cc return
    (let ([body-str (for/fold ([body-str body-str])
                              ([fact (in-list facts)])
                      ; Factory placeholder has to be present in body string
                      (if (regexp-match (regexp (format "\\$\\$\\$~a\\$\\$\\$" (symbol->string (car fact)))) body-str)
                          (string-replace body-str (format "$$$~a$$$" (symbol->string (car fact))) (string-join (flatten (cdr fact)) "\n"))
                          (return #f)))])
      ; Check that all factory placeholders were filled
      (if (regexp-match #rx"\\$\\$\\$.*?\\$\\$\\$" body-str)
          #f
          body-str))))
