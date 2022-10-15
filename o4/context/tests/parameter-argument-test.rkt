#lang racket/base
; Parameter & Argument Context Tests
; ---------------------------------------
(require rackunit
         o4/context/base o4/context/parameter-argument o4/utils/error)

; Set & Get Parameters
(let* ([ctx (add-scope null)]
       [_ (set-declare ctx 'declare "value")]
       [_ (set-parameter ctx 'parameter 1 #f)]
       [_ (set-parameter ctx 'other_parameter 0 "inout" "1" 1)])
  (check-equal?
   (get-parameters-of-scope ctx)
   (list
    (cons 'other_parameter (dec-parameter 0 "inout" "1" 1))
    (cons 'parameter (dec-parameter 1 #f #f #f)))))

; Get Parameters of Scope with No Parameters
(let* ([ctx (add-scope null)]
       [_ (set-declare ctx 'declare "value")])
  (check-equal?
   (get-parameters-of-scope ctx)
   null))

; Check Parameters Directionless
(check-equal?
 (check-parameters-directionless null)
 #t)
(check-equal?
 (check-parameters-directionless
  (list (cons 'parameter (dec-parameter 0 #f #f #f))))
 #t)
(check-equal?
 (check-parameters-directionless
  (list
   (cons 'parameter (dec-parameter 0 #f #f #f))
   (cons 'other_parameter (dec-parameter 1 #f 1 1))))
 #t)
(check-equal?
 (check-parameters-directionless
  (list (cons 'parameter (dec-parameter 0 "inout" #f #f))))
 #f)
(check-equal?
 (check-parameters-directionless
  (list
   (cons 'parameter (dec-parameter 0 "inout" #f #f))
   (cons 'other_parameter (dec-parameter 1 #f 1 1))))
 #f)

; Check Argument Metadata List
(check-equal?
 (check-argument-metadata-list
  null)
 #t)
(check-equal?
 (check-argument-metadata-list
  (list (get-argument-metadata "1" 1)))
 #t)
(check-equal?
 (check-argument-metadata-list
  (list
   (get-argument-metadata "1" 1)
   (get-argument-metadata "2" 2)))
 #t)
(check-equal?
 (check-argument-metadata-list
  (list (get-argument-metadata "1" 1 "name")))
 #t)
(check-equal?
 (check-argument-metadata-list
  (list
   (get-argument-metadata "1" 1 "name")
   (get-argument-metadata "2" 2 "name")))
 #t)
(check-equal?
 (check-argument-metadata-list
  (list
   (get-argument-metadata "1" 1)
   (get-argument-metadata "2" 2 "name")))
 #f)
(check-equal?
 (check-argument-metadata-list
  (list
   (get-argument-metadata "1" 1 "name")
   (get-argument-metadata "2" 2)))
 #f)

; Get Parameter Argument Map with Named & Excess Arguments
(check-equal?
 (get-parameter-argument-map
  (list
   (cons 'parameter (dec-parameter 0 #f #f #f))
   (cons 'other_parameter (dec-parameter 1 #f "1" 1))
   (cons 'even_another_parameter (dec-parameter 2 #f "2" 2)))
  (list
   (get-argument-metadata "3" 3 "parameter")
   (get-argument-metadata "4" 4 "other_parameter")
   (get-argument-metadata "4" 4 "excess_argument")))
 (list
  (list 'parameter "3" 3)
  (list 'other_parameter "4" 4)
  (list 'even_another_parameter "2" 2)))

; Get Parameter Argument Map with Positional Arguments
(check-equal?
 (get-parameter-argument-map
  (list
   (cons 'parameter (dec-parameter 0 #f #f #f))
   (cons 'other_parameter (dec-parameter 1 #f "1" 1))
   (cons 'even_another_parameter (dec-parameter 2 #f "2" 2)))
  (list
   (get-argument-metadata "3" 3)
   (get-argument-metadata "4" 4)))
 (list
  (list 'parameter "3" 3)
  (list 'other_parameter "4" 4)
  (list 'even_another_parameter "2" 2)))

; Get Parameter Argument Map with Positional & Excess Arguments
(check-equal?
 (get-parameter-argument-map
  (list
   (cons 'parameter (dec-parameter 0 #f #f #f)))
  (list
   (get-argument-metadata "1" 1)
   (get-argument-metadata "2" 2)))
 (list (list 'parameter "1" 1)))

; Get Parameter Argument Map with No Arguments and Missing Default Value
(check-exn
 exn:fail:o4:argument-list?
 (lambda ()
   (get-parameter-argument-map (list (cons 'parameter (dec-parameter 0 #f #f #f))) null)))

; Get Parameter Argument Map with Named Arguments and Missing Default Value
(check-exn
 exn:fail:o4:argument-list?
 (lambda ()
   (get-parameter-argument-map (list (cons 'parameter (dec-parameter 0 #f #f #f))) (list (get-argument-metadata "1" 1 "other_parameter")))))

; Get Parameter Argument Map with Positional Arguments and Missing Default Value
(check-exn
 exn:fail:o4:argument-list?
 (lambda ()
   (get-parameter-argument-map
    (list
     (cons 'parameter (dec-parameter 0 #f #f #f))
     (cons 'parameter (dec-parameter 1 #f #f #f)))
    (list (get-argument-metadata "1" 1)))))
