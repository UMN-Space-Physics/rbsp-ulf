;-------------------------------------------------------------------------------
; Compile options
;-------------------------------------------------------------------------------
COMPILE_OPT strictarr, hidden

;-------------------------------------------------------------------------------
; Debug for Pointer
;-------------------------------------------------------------------------------
;COMMON E_UTILITY_DEBUG, E_UTILITY_DEBUG_ON


DEFSYSV, '!THEMIS', EXISTS=tflag
if tflag eq 0 then begin
  message, 'Please initialize TDAS (thm_init)'
endif
;
; tplot data for et-diagram
in_slice = 'gtl971212.tplot'
;
; lep file
in_lep = '19971212_lep_psd_8532.txt'
