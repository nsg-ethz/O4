#lang racket/base
; Configuration Handling
; ---------------------------------------
(provide get-config-hash)


; Implementation
; ---------------------------------------
(require json)

; Get Config Hash
(define (get-config-hash path)
  ; TODO: Allow overwriting values with environment variables
  (call-with-input-file* path read-json))
