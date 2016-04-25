;+
; spd_mms_load_bss_crib  
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; See also "spd_mms_load_bss", "mms_load_bss", and "mms_load_bss_crib".
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-11-24 13:31:05 -0800 (Tue, 24 Nov 2015) $
; $LastChangedRevision: 19465 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/spd_mms_load_bss_crib.pro $
;-


; set time range 
timespan, '2015-10-01', 1, /day

; get data availability for burst and survey data (note that the labels flag
; is set so that the display bars will be labeled)
spd_mms_load_bss, datatype=['fast', 'burst'], /include_labels

; now plot bars with some data 
mms_load_dfg, probe=3, data_rate='brst'

; degap the mag data to avoid tplot connecting the lines between
; burst segments
tdegap, 'mms3_dfg_brst_l2pre_gse_bvec', /overwrite


tplot,['mms_bss_fast','mms_bss_burst', 'mms3_dfg_brst_l2pre_gse_bvec']
stop

; Get all BSS data types (Fast, Burst, Status, and FOM)
; if no data type is provided all data types will be returned
spd_mms_load_bss, /include_labels

; plot bss bars and fom at top of plot
tplot,['mms_bss_fast','mms_bss_burst','mms_bss_status', 'mms_bss_fom', $
       'mms3_dfg_brst_l2pre_gse_bvec']
stop

end
