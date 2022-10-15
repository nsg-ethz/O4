#lang racket/base
; O4 Program Backend
; ---------------------------------------
(provide o4-program)


; Implementation
; ---------------------------------------
(require br/macro
         o4/context o4/utils/util
         (for-syntax racket/base))

; O4 Program
(define-macro (o4-program DECLARATIONS ...)
  #'(fold-string-join-context-2 (add-scope null) "\n" DECLARATIONS ...))
