;+
; MMS EDP crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-28 10:35:52 -0700 (Fri, 28 Aug 2015) $
; $LastChangedRevision: 18653 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_edp_crib.pro $
;-
timespan, '2015-08-15', 1, /day
mms_load_edp, data_rate='slow', probes=[1, 2, 3, 4], datatype='dce', level='ql'

tplot, 'mms?_edp_slow_dce_dsl'
stop


end