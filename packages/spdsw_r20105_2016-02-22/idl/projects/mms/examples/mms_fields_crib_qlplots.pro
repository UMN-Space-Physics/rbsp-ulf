;+
; MMS FIELDS quicklook plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: crussell $
; $LastChangedDate: 2016-01-13 09:03:40 -0800 (Wed, 13 Jan 2016) $
; $LastChangedRevision: 19722 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_fields_crib_qlplots.pro $
;-


; initialize and define parameters
probes = ['1', '2', '3', '4']
;trange = ['2015-09-05', '2015-09-06']
timespan, '2015-09-05', 1, /day
iw = 0
width = 750
height = 1000

; options for send_plots_to:
;   ps: postscript files
;   png: png files
;   win: creates/opens all of the tplot windows

send_plots_to = 'win'
plot_directory = ''

postscript = send_plots_to eq 'ps' ? 1 : 0

; handle any errors that occur in this script gracefully
catch, errstats
if errstats ne 0 then begin
  error = 1
  dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
  catch, /cancel
endif

;
; START OF FIELDS PLOTS - ALL SPACECRAFT 
;  
; load mms survey Fields data
mms_load_dfg, probes=probes, level='ql', data_rate='srvy'

; DMPA - Handle Btot and Bvec 

; Btot - set title and colors and create psuedo variable
options, 'mms1*_btot', colors=[0]    ; black
options, 'mms2*_btot', colors=[6]    ; red
options, 'mms3*_btot', colors=[4]    ; green
options, 'mms4*_btot', colors=[2]    ; blue
store_data, 'mms_dfg_srvy_dmpa_btot', data = ['mms1_dfg_srvy_dmpa_btot', $
                                       'mms2_dfg_srvy_dmpa_btot', $
                                       'mms3_dfg_srvy_dmpa_btot', $
                                       'mms4_dfg_srvy_dmpa_btot']
options, 'mms_*_btot',ytitle='DFG Btot'
options, 'mms_*_btot',ysubtitle='QL [nT]'

; Bvec - set colors, psuedo variables and titles
options, 'mms1*_bvec', colors=[0]    ; black
options, 'mms2*_bvec', colors=[6]    ; red
options, 'mms3*_bvec', colors=[4]    ; green
options, 'mms4*_bvec', colors=[2]    ; blue
; split into components x, y, z for plotting
split_vec, 'mms*_bvec'
; create psuedo variables for each component x, y, and z
store_data, 'mms_dfg_srvy_dmpa_bvec_x', data = ['mms1_dfg_srvy_dmpa_bvec_x', $
  'mms2_dfg_srvy_dmpa_bvec_x', $
  'mms3_dfg_srvy_dmpa_bvec_x', $
  'mms4_dfg_srvy_dmpa_bvec_x']
store_data, 'mms_dfg_srvy_dmpa_bvec_y', data = ['mms1_dfg_srvy_dmpa_bvec_y', $
    'mms2_dfg_srvy_dmpa_bvec_y', $
    'mms3_dfg_srvy_dmpa_bvec_y', $
    'mms4_dfg_srvy_dmpa_bvec_y']
store_data, 'mms_dfg_srvy_dmpa_bvec_z', data = ['mms1_dfg_srvy_dmpa_bvec_z', $
    'mms2_dfg_srvy_dmpa_bvec_z', $
    'mms3_dfg_srvy_dmpa_bvec_z', $
    'mms4_dfg_srvy_dmpa_bvec_z']
; set titles
options, 'mms_*_bvec_x', ytitle='DFG Bx'
options, 'mms_*_bvec_y', ytitle='DFG By'
options, 'mms_*_bvec_z', ytitle='DFG Bz'
options, 'mms_*_bvec_*', ysubtitle='DMPA [nT]' 

; GSM-DMPA - do the same for gsm_dmpa data, note gsm_dmpa data is not separated into btot and bvec
options, 'mms1*_gsm_dmpa', colors=[0]    ; black
options, 'mms2*_gsm_dmpa', colors=[6]    ; red
options, 'mms3*_gsm_dmpa', colors=[4]    ; green
options, 'mms4*_gsm_dmpa', colors=[2]    ; blue
split_vec, 'mms*_dfg_srvy_gsm_dmpa'
store_data, 'mms_dfg_srvy_gsm_dmpa_x', data = ['mms1_dfg_srvy_gsm_dmpa_0', $
  'mms2_dfg_srvy_gsm_dmpa_0', $
  'mms3_dfg_srvy_gsm_dmpa_0', $
  'mms4_dfg_srvy_gsm_dmpa_0']
store_data, 'mms_dfg_srvy_gsm_dmpa_y', data = ['mms1_dfg_srvy_gsm_dmpa_1', $
  'mms2_dfg_srvy_gsm_dmpa_1', $
  'mms3_dfg_srvy_gsm_dmpa_1', $
  'mms4_dfg_srvy_gsm_dmpa_1']
store_data, 'mms_dfg_srvy_gsm_dmpa_z', data = ['mms1_dfg_srvy_gsm_dmpa_2', $
  'mms2_dfg_srvy_gsm_dmpa_2', $
  'mms3_dfg_srvy_gsm_dmpa_2', $
  'mms4_dfg_srvy_gsm_dmpa_2']
options, 'mms_*_gsm_dmpa_x', ytitle='DFG Bx'
options, 'mms_*_gsm_dmpa_y', ytitle='DFG By'
options, 'mms_*_gsm_dmpa_z', ytitle='DFG Bz'
options, 'mms_*_gsm_dmpa_*', ysubtitle='GSM-DMPA [nT]'

;mms_load_dsp, data_rate='fast', probes=[1, 2, 3, 4], datatype='epsd', level='l2'
;mms_load_dsp,  data_rate='srvy', probes=[1, 2, 3, 4], datatype='bpsd', level='l2'

spd_mms_load_bss, /include_labels

; set plot parameters
tplot_options, 'xmargin', [20, 15]
tplot_options, 'ymargin', [5, 5]
tplot_options, 'charsize', 1.
tplot_options, 'panel_size', 0.2
options, 'mms_bss_burst', charsize=2.5

if ~postscript then window, iw, xsize=width, ysize=height
tplot, ['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', $
        'mms_dfg_srvy_dmpa_btot', 'mms_dfg_srvy_gsm_dmpa_*', 'mms_dfg_srvy_dmpa_bvec_*'], window=iw
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_btot', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_x', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_y', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_z', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_bvec_x', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_bvec_y', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_bvec_z', linestyle=2
title= 'MMS Quicklook Plots for Fields Data'
xyouts, .25, .95, title, /normal, charsize=1.5

if postscript then tprint, plot_directory + "mms1_fields_data_quicklook_plots"
iw=iw+1
stop

;
; START OF FIELDS2 E&B PLOTS - ALL SPACECRAFT
;
; Get dec data
mms_load_edp, data_rate='fast', probes=[1, 2, 3, 4], datatype='dce', level='ql'
options, 'mms1*_dce_dsl', colors=[0]    ; black
options, 'mms2*_dce_dsl', colors=[6]    ; red
options, 'mms3*_dce_dsl', colors=[4]    ; green
options, 'mms4*_dce_dsl', colors=[2]    ; blue
split_vec, 'mms*_dce_dsl'
store_data, 'mms_edp_fast_dce_dsl_x', data = ['mms1_edp_fast_dce_dsl_x', $
  'mms2_edp_fast_dce_dsl_x', $
  'mms3_edp_fast_dce_dsl_x', $
  'mms4_edp_fast_dce_dsl_x']
store_data, 'mms_edp_fast_dce_dsl_y', data = ['mms1_edp_fast_dce_dsl_y', $
  'mms2_edp_fast_dce_dsl_y', $
  'mms3_edp_fast_dce_dsl_y', $
  'mms4_edp_fast_dce_dsl_y']
store_data, 'mms_edp_fast_dce_dsl_z', data = ['mms1_edp_fast_dce_dsl_z', $
  'mms2_edp_fast_dce_dsl_z', $
  'mms3_edp_fast_dce_dsl_z', $
  'mms4_edp_fast_dce_dsl_z']
options, 'mms_*_dce_dsl_x', ytitle='EDP Ex'
options, 'mms_*_dce_dsl_y', ytitle='EDP Ey'
options, 'mms_*_dce_dsl_z', ytitle='EDP Ez'

; get scpot
mms_load_aspoc, datatype='asp1', trange=trange, level='l1b', probe=probes
options, 'mms1*_spot*', colors=[0]    ; black
options, 'mms2*_spot*', colors=[6]    ; red
options, 'mms3*_spot*', colors=[4]    ; green
options, 'mms4*_spot*', colors=[2]    ; blue
store_data, 'mms_asp1_spot_l1b', data = ['mms1_asp1_spot_l1b', $
  'mms2_asp1_spot_l1b', $
  'mms3_asp1_spot_l1b', $
  'mms4_asp1_spot_l1b']
options, 'mms_*spot_l1b', ytitle='ASP1 Scpot'

if ~postscript then window, iw, xsize=width, ysize=height
tplot, ['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', $
        'mms_*_dce_dsl_*', 'mms_asp1_spot_l1b', 'mms_*_btot', $
        'mms_*_gsm_dmpa_*'], window=iw, var_label=position_vars
timebar, 0.0, /databar, varname='mms_edp_fast_dce_dsl_x', linestyle=2
timebar, 0.0, /databar, varname='mms_edp_fast_dce_dsl_y', linestyle=2
timebar, 0.0, /databar, varname='mms_edp_fast_dce_dsl_z', linestyle=2
timebar, 0.0, /databar, varname='mms_asp1_spot_l1b', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_dmpa_btot', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_x', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_y', linestyle=2
timebar, 0.0, /databar, varname='mms_dfg_srvy_gsm_dmpa_z', linestyle=2
title='MMS E&B Quicklook Plots'
xyouts, .35, .95, title, /normal, charsize=1.5

if postscript then tprint, plot_directory + "mms1_e&b_quicklook_plots"
iw=iw+1
stop

;
; EDP QuickLook Plots 
;
if ~postscript then window, iw, xsize=width, ysize=height
tplot, ['mms_bss_burst', 'mms_bss_fast', 'mms_bss_status', $
        'mms_asp1_spot_l1b', 'mms_*_dce_dsl_*'], window=iw
for i=3,6 do tplot_panel, oplotvar='dline0', panel=i[0]
title='MMS EDP Quicklook Plots'
xyouts, .35, .95, title, /normal, charsize=1.5

if postscript then tprint, plot_directory + "mms1_edp_quicklook_plots"

stop

end