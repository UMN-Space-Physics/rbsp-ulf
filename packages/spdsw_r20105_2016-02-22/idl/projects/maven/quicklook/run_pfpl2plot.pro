;+
;NAME:
; run_pfpl2plot
;PURPOSE:
; Designed to run from a cronjob, sets up a lock file, and
; processes. It the lock file exists, no processing
;CALLING SEQUENCE:
; run_pfpl2plot, noffset_sec = noffset_sec
;INPUT:
; none
;OUTPUT:
; none
;KEYWORDS:
; none
;HISTORY:
; 25-jun-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-06-03 13:18:22 -0700 (Wed, 03 Jun 2015) $
; $LastChangedRevision: 17800 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/run_pfpl2plot.pro $
;-

Pro run_pfpl2plot

  test_file = file_search('/tmp/PFPL2PLOTlock.txt')
  If(is_string(test_file[0])) Then Begin
     message, /info, 'Lock file /tmp/PFPL2PLOTlock.txt Exists, Returning'
  Endif Else Begin
     test_file = '/tmp/PFPL2PLOTlock.txt'
     spawn, 'touch '+test_file[0]
     mvn_call_pfpl2plot
     message, /info, 'Removing Lock file /tmp/PFPL2PLOTlock.txt'
     file_delete, test_file[0]
  Endelse

  Return

End

