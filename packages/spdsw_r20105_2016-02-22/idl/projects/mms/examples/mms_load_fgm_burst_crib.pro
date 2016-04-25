;+
; PROCEDURE:
;         mms_load_fgm_brst_crib
;
; PURPOSE:
;         Crib sheet showing how to load and plot MMS magnetometer data in burst mode (for afg and dfg) 
;
; NOTES:
;         1) Updated to use the MMS web services API, 6/12/2015
;
;
;$LastChangedBy: crussell $
;$LastChangedDate: 2016-01-13 09:03:40 -0800 (Wed, 13 Jan 2016) $
;$LastChangedRevision: 19722 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fgm_burst_crib.pro $
;-
;----------------------------------------------------------------------------

dprint, "--- Start of MMS FGM burst data crib sheet ---"

; set the time span
timespan, '2015-10-15', 1
tr = timerange()

; load MMS AFG burst data for MMS 1 
mms_load_fgm, probes=['1'], instrument='afg', data_rate='brst', level='ql'

tplot, ['mms1_afg_brst_gse_bvec', 'mms1_afg_brst_gse_btot']
timebar, 0.0, /databar, varname='mms1_afg_brst_gse_bvec', linestyle=2
timebar, 0.0, /databar, varname='mms1_afg_brst_gse_btot', linestyle=2
stop

; zoom in to region of interest 
tlimit, '2015-10-15/06:30','2015-10-15/07:30', window=1
timebar, 0.0, /databar, varname='mms1_afg_brst_gse_bvec', linestyle=2
timebar, 0.0, /databar, varname='mms1_afg_brst_gse_btot', linestyle=2
stop

;----------------------------------------------------------------------------
; do the same for DFG burst data for probes MMS 1 and 2 
; Note the time frame keyword is used
mms_load_fgm, probes=['1','2'], trange=['2015-10-15/00:00','2015-10-16/00:00'], instrument='dfg', data_rate='brst', level='ql'

; add a title
tplot_options, 'title', 'MMS1 and MMS2 DFG FGM Bvec'
tplot, ['mms1_dfg_brst_gse_bvec','mms2_dfg_brst_gse_bvec']
timebar, 0.0, /databar, varname='mms1_dfg_brst_gse_bvec', linestyle=2
timebar, 0.0, /databar, varname='mms2_dfg_brst_gse_btot', linestyle=2
stop

; zoom in and show both afg and dfg with attitude data and add a title
tlimit, '2015-10-15/06:30','2015-10-15/07:30'
tplot_options, 'title', 'MMS1 FGM Bvec, Btotal, Position, and Attitude'
tplot, ['mms1_dfg_brst_gse_bvec','mms1_afg_brst_gse_bvec','mms1_ql_pos_gse','mms1_ql_RADec_gse']
timebar, 0.0, /databar, varname='mms1_dfg_brst_gse_bvec', linestyle=2
timebar, 0.0, /databar, varname='mms1_afg_brst_gse_bvec', linestyle=2
stop

;----------------------------------------------------------------------------
; load DFG burst data for the other MMS probes
mms_load_fgm, probes=['3','4'], instrument='dfg', data_rate='brst', level='ql'

; new window specified so that previous plot window will be preserved.
window, 2
tlimit, '2015-10-15/06:30','2015-10-15/07:30', window=2
tplot_options, 'title', 'MMS FGM data for all Probes'
; tplot accepts wild cards
tplot, 'mms*_dfg_brst_gse_bvec'
timebar, 0.0, /databar, varname='mms1_dfg_brst_gse_bvec', linestyle=2
timebar, 0.0, /databar, varname='mms2_dfg_brst_gse_bvec', linestyle=2
timebar, 0.0, /databar, varname='mms3_dfg_brst_gse_bvec', linestyle=2
timebar, 0.0, /databar, varname='mms4_dfg_brst_gse_bvec', linestyle=2
stop

;-----------------------------------------------------------------------------
; combine the bvector and btotal tplot variables - this pseudo variable 
; is for plotting purposes
pr='mms1'
; tplot variables accept constructed strings
store_data, pr+'_combined_fgm', data=[pr+'_dfg_brst_gse_btot',pr+'_dfg_brst_gse_bvec']
tplot, pr+'_combined_fgm'
timebar, 0.0, /databar, varname=pr+'_combined_fgm', linestyle=2
stop

; check out list of all the tplot variables that were loaded
tplot_names

; clear tplot_options title
tplot_options, 'title', ''

dprint, "--- End of MMS FGM burst data crib sheet ---"

end