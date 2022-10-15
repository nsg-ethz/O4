#lang racket/base
; Error Handing
; ---------------------------------------
(provide exn:fail:o4:array-index-unknown?
         raise-array-index-unknown-error
         exn:fail:o4:array-not-allowed?
         raise-array-not-allowed-error
         exn:fail:o4:array-wrong-dimensions?
         raise-array-wrong-dimensions-error
         exn:fail:o4:parser-invalid-transition?
         raise-parser-invalid-transition-error
         exn:fail:o4:argument-list?
         raise-argument-list-error
         exn:fail:o4:factory-definition?
         raise-factory-definition-error
         exn:fail:o4:factory-call?
         raise-factory-call-error
         exn:fail:o4:hash-key?
         raise-hash-key-error
         exception-handler)


; Implementation
; ---------------------------------------
(require brag/support racket/list)

; O4 Error
(struct exn:fail:o4 exn:fail (srclocs)
  #:property prop:exn:srclocs (lambda (instance)
                                (exn:fail:o4-srclocs instance)))
(define (raise-o4-error exn
                        #:message [msg #f]
                        #:continuation-marks [cont-marks #f]
                        #:srclocs [srclocs #f])
  (let ([srclocs (if srclocs
                     srclocs
                     (if (exn:srclocs? exn)
                         ((exn:srclocs-accessor exn) exn)
                         null))])
    (raise (exn:fail:o4
            (let ([msg (if msg
                           msg
                           (exn-message exn))])
              (if (null? srclocs)
                  (format "error: ~a" msg)
                  (format "~a: error: ~a" (srcloc->string (first srclocs)) msg)))
            (if cont-marks
                cont-marks
                (exn-continuation-marks exn))
            srclocs))))

; Array Errors
(struct exn:fail:o4:array-index-unknown exn:fail:o4 ())
(define (raise-array-index-unknown-error exp-str . stxs)
  (raise (exn:fail:o4:array-index-unknown
          (format "array index ~a could not be expanded at compile time" exp-str)
          (current-continuation-marks)
          (get-srclocs-from-syntaxes stxs))))

(struct exn:fail:o4:array-not-allowed exn:fail:o4 ())
(define (raise-array-not-allowed-error name . stxs)
  (raise (exn:fail:o4:array-not-allowed
          (format "~a with array types are not supported" name)
          (current-continuation-marks)
          (get-srclocs-from-syntaxes stxs))))

(struct exn:fail:o4:array-wrong-dimensions exn:fail:o4 ())
(define (raise-array-wrong-dimensions-error msg . stxs)
  (raise (exn:fail:o4:array-wrong-dimensions
          msg
          (current-continuation-marks)
          (get-srclocs-from-syntaxes stxs))))

; Parser Invalid Transition Error
(struct exn:fail:o4:parser-invalid-transition exn:fail:o4 ())
(define (raise-parser-invalid-transition-error msg . stxs)
  (raise (exn:fail:o4:parser-invalid-transition
          msg
          (current-continuation-marks)
          (get-srclocs-from-syntaxes stxs))))

; Argument List Error
(struct exn:fail:o4:argument-list exn:fail:o4 ())
(define (raise-argument-list-error msg . stxs)
  (raise (exn:fail:o4:argument-list
          msg
          (current-continuation-marks)
          (get-srclocs-from-syntaxes stxs))))

; Factory Errors
(struct exn:fail:o4:factory-definition exn:fail:o4 ())
(define (raise-factory-definition-error msg . stxs)
  (raise (exn:fail:o4:factory-definition
          msg
          (current-continuation-marks)
          (get-srclocs-from-syntaxes stxs))))

(struct exn:fail:o4:factory-call exn:fail:o4 ())
(define (raise-factory-call-error msg . stxs)
  (raise (exn:fail:o4:factory-call
          msg
          (current-continuation-marks)
          (get-srclocs-from-syntaxes stxs))))

; Hash Key Error
(struct exn:fail:o4:hash-key exn:fail:o4 ())
(define (raise-hash-key-error msg)
  (raise (exn:fail:o4:hash-key
          msg
          (current-continuation-marks)
          null)))


; Helper Functions
; ---------------------------------------
; Exception Handler
(define (exception-handler exn)
  (cond
    [(exn:fail:o4? exn)
     (raise-o4-error exn)]
    [(exn:fail:parsing? exn)
     (let ([parsing-error (regexp-match #rx"^Encountered parsing error near (.*) \\(" (exn-message exn))]
           [unexp-token (regexp-match #rx"^Encountered unexpected token of type .* \\(value (.*)\\)" (exn-message exn))])
       (raise-o4-error exn
                       #:message (cond
                                   [parsing-error (format "parsing error near ~a" (second parsing-error))]
                                   [unexp-token (format "unexpected token ~a" (second unexp-token))]
                                   [else (format "unkown error: ~a" (exn-message exn))])))]
    [(exn:fail? exn)
     (raise-o4-error exn
                     #:message (format "unkown error: ~a" (exn-message exn)))]))

; Get Srclocs from Syntaxes
(define (get-srclocs-from-syntaxes stxs)
  (map
   (lambda (stx)
     (srcloc (syntax-source stx)
             (syntax-line stx)
             (syntax-column stx)
             (syntax-position stx)
             (syntax-span stx)))
   stxs))
