;+
; MMS EIS quick look plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-29 14:54:54 -0800 (Fri, 29 Jan 2016) $
; $LastChangedRevision: 19845 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_eis_crib_qlplots.pro $
;-

probe = '3'
;trange = ['2015-08-15', '2015-08-16']
;timespan, '2015-08-15', 1
timespan, '2016-01-19', 1
iw = 0
width = 850
height = 1000
prefix = 'mms'+probe+'_epd_eis'

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

; load ExTOF and electron data:
mms_load_eis, probes=probe, trange=trange, datatype='extof', level='l1b'
mms_load_eis, probes=probe, trange=trange, datatype='electronenergy', level='l1b'

; load DFG data
mms_load_dfg, probes=probe, trange=trange, level='ql', /no_attitude_data

; setup for plotting the proton flux for all channels
ylim, prefix+'_electronenergy_electron_flux_omni_spin', 30, 1000, 1
zlim, prefix+'_electronenergy_electron_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_proton_flux_omni_spin', 50, 500, 1
zlim, prefix+'_extof_proton_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_oxygen_flux_omni_spin', 150, 1000, 1
zlim, prefix+'_extof_oxygen_flux_omni_spin', 0, 0, 1
ylim, prefix+'_extof_alpha_flux_omni_spin', 80, 800, 1
zlim, prefix+'_extof_alpha_flux_omni_spin', 0, 0, 1

; force the min/max of the Y axes to the limits
options, '*_flux_omni*', ystyle=1

; get ephemeris data for x-axis annotation
;mms_load_state, probes=probe, trange=trange, /ephemeris
;eph_j2000 = 'mms'+probe+'_defeph_pos'
;eph_gei = 'mms'+probe+'defeph_pos_gei'
;eph_gse = 'mms'+probe+'_defeph_pos_gse'
eph_gsm = 'mms'+probe+'_ql_pos_gsm'

; calculate MLT
tgsm2mlt, eph_gsm, 'mms'+probe+'_ql_pos_mlt'

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

; calculate R to spacecraft
;calc, '"mms'+probe+'_defeph_R_gsm" = sqrt("'+eph_gsm+'_re_x'+'"^2+"'+eph_gsm+'_re_y'+'"^2+"'+eph_gsm+'_re_z'+'"^2)'

; set the label to show along the bottom of the tplot
options, eph_gsm+'_re_0',ytitle='X-GSM (Re)'
options, eph_gsm+'_re_1',ytitle='Y-GSM (Re)'
options, eph_gsm+'_re_2',ytitle='Z-GSM (Re)'
options, eph_gsm+'_re_3',ytitle='R-GSM (Re)'
options, 'mms'+probe+'_ql_pos_mlt', ytitle='MLT'
position_vars = ['mms'+probe+'_ql_pos_mlt', eph_gsm+'_re_3', eph_gsm+'_re_2', eph_gsm+'_re_1', eph_gsm+'_re_0']

tplot_options, 'ymargin', [5, 5]
tplot_options, 'xmargin', [15, 15]

; clip the DFG data to -150nT to 150nT
tclip, 'mms'+probe+'_dfg_srvy_dmpa_bvec', -150., 150., /overwrite

spd_mms_load_bss, trange=trange, /include_labels 

panels = ['mms_bss_burst', 'mms_bss_fast', $
  'mms'+probe+'_dfg_srvy_dmpa_bvec', $
  prefix+'_electronenergy_electron_flux_omni_spin', $
  prefix+'_extof_proton_flux_omni_spin', $
  prefix+'_extof_alpha_flux_omni_spin', $
  prefix+'_extof_oxygen_flux_omni_spin']

if ~postscript then window, iw, xsize=width, ysize=height
tplot, panels, var_label=position_vars, window=iw
timebar, 0.0, /databar, varname='mms'+probe+'_dfg_srvy_dmpa_bvec', linestyle=2
title='EIS - Quicklook'
xyouts, .4, .96, title, /normal, charsize=1.5

if postscript then tprint, plot_directory + prefix + "_quicklook_plots"

end