;+
;NAME:
; mms_set_verbose
;PURPOSE:
; Sets verbose level in !mms.verbose and in tplot_options
;CALLING SEQUENCE:
; mms_set_verbose, vlevel
;INPUT:
; vlevel = a verbosity level, if not set then !mms.verbose is used
;          (this is how you would propagate the !mms.verbose value
;          into tplot options)
;HISTORY:
; 21-aug-2012, jmm, jimm@ssl.berkeley.edu
; 12-oct-2012, jmm, Added this comment to test SVN
; 12-oct-2012, jmm, Added this comment to test SVN, again
; 18-oct-2012, jmm, Another SVN test
; 10-apr-2015, moka, adapted for MMS from 'thm_set_verbose'
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2015-04-10 16:29:01 -0700 (Fri, 10 Apr 2015) $
; $LastChangedRevision: 17296 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/mms_set_verbose.pro $
;-
Pro mms_set_verbose, vlevel

  ;Need to check for !themis
  defsysv,'!mms',exists=exists
  if not keyword_set(exists) then begin
    mms_init
  endif

  If(n_elements(vlevel) Eq 0) Then vlev = !mms.verbose Else vlev = vlevel[0]

  !mms.verbose = vlev

  tplot_options, 'verbose', vlev

  Return
End
