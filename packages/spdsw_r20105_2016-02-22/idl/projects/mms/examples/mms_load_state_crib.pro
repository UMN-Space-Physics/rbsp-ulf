;+
; MMS State crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-19 10:09:31 -0700 (Wed, 19 Aug 2015) $
; $LastChangedRevision: 18523 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/examples/mms_load_scm_crib.pro $
;-

;;    ============================
;; 1) Select date and time interval
;;    ============================
; download SCM data for 8/2/2015
date = '2015-07-31/00:00:00'
timespan,date,1,/day

;;    ===================================
;; 2) Select probe, level, and datatype
;;    ===================================
probe = '2'
level = 'def'     ; 'pred'
datatypes = 'pos'    ; 'vel', 'spinras', 'spindec'

mms_load_state, probes=probe, level=level, datatypes=datatypes
tplot, 'mms2_defeph_pos'
stop

; load attitude data only
mms_load_state, probes=['1', '2'], level='def', /attitude_only
tplot, ['mms*_defatt_*']
stop

; same with position 
; no probe specified so will get all 4 probes
; no level spefified so will default to definitive data if avaiable
mms_load_state, /ephemeris_only
tplot, ['mms*_defeph_*']
stop

; variables loaded so far
tplot_names
stop

; remove tplot variables created so far
del_data, 'mms*_def*'

; set to future date
date = '2015-11-31/00:00:00'
timespan,date,1,/day

; request definitive data (because date is in the future definitive
; data will not be found. by default the routine will look for predicted
; when definitive is not found).
mms_load_state, probes= ['1'], level='def', datatypes='pos'
tplot, ['mms*_predeph_*']
stop

; requesting predicted this time (result should be the same
; as above)
mms_load_state, probes= ['2'], level='pred', datatypes='pos'
tplot, ['mms*_predeph_*']
stop

; you can turn off automatic definitive or predicted data behavior
; (note that no data will be found since user requested definitive data
; and turned off default behavior 
mms_load_state, probes= ['3'], level='def', datatypes='pos', pred_or_def=0

stop
end