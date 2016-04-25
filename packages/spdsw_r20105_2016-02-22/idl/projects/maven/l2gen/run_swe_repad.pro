;+
;NAME:
; run_swe_repad
;PURPOSE:
; Designed to run from a cronjob, sets up a lock file, and
; processes. It the lock file exists, no processing
;CALLING SEQUENCE:
; run_swe_repad
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; none
;HISTORY:
; 13-Oct-2015, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-10-13 16:11:03 -0700 (Tue, 13 Oct 2015) $
; $LastChangedRevision: 19067 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/l2gen/run_swe_repad.pro $
;-

Pro run_swe_repad

  test_file = file_search('/tmp/SWEREPADlock.txt')
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /tmp/SWEREPADlock.txt Exists, Returning'
  Endif Else Begin
     test_file = '/tmp/SWEREPADlock.txt'
     spawn, 'touch '+test_file[0]
     mvn_call_swe_resample_pad_daily
     message, /info, 'Removing Lock file /tmp/SWEREPADlock.txt'
     file_delete, test_file[0]
  Endelse

  Return

End

