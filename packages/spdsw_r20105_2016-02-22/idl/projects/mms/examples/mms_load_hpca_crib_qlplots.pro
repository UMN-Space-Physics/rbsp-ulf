;+
; MMS HPCA quick look plots crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-02-03 14:42:31 -0800 (Wed, 03 Feb 2016) $
; $LastChangedRevision: 19895 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_hpca_crib_qlplots.pro $
;-

; initialize and define parameters
probes = ['1', '2', '3', '4']
species = ['H+', 'He+', 'He++', 'O+']
tplotvar_species = ['hplus', 'heplus', 'heplusplus', 'oplus']

; set parameters  
pid = probes[0]      ; set probe to mms1
sid = species[0]     ; set species to H+
tsid = tplotvar_species[0]    

;timespan, '2015-08-15', 1
timespan, '2015-11-13', 1
;trange = ['2015-11-02', '2015-11-03']
tplotvar = 'mms'+pid + '_hpca_' + tsid + '_RF_corrected'

iw = 2
width = 800
height = 900

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

; load mms survey HPCA data
mms_load_hpca, probes=pid, trange=trange, datatype='rf_corr', level='l1b', data_rate='srvy', suffix='_srvy'

; load QL FGM data, currently only for ephemeris data 
mms_load_fgm, instrument='dfg', trange=trange, probes=pid, level='ql', /no_attitude_data

; sum over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=pid, suffix='_srvy'
mms_hpca_calc_anodes, anode=[13, 14], probe=pid, suffix='_srvy'
mms_hpca_calc_anodes, anode=[0, 15], probe=pid, suffix='_srvy'

; do the same for burst data
mms_load_hpca, probes=pid, trange=trange, datatype='rf_corr', level='l1b', data_rate='brst', suffix='_brst'

; sum over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=pid, suffix='_brst'
mms_hpca_calc_anodes, anode=[13, 14], probe=pid, suffix='_brst'
mms_hpca_calc_anodes, anode=[0, 15], probe=pid, suffix='_brst'

; create pseudo variables for the combined burst and survey data
store_data, tplotvar+'_brst_srvy_0_15', data=[tplotvar+'_brst_anodes_0_15', tplotvar+'_srvy_anodes_0_15'], dlimits=dl, limits=l
store_data, tplotvar+'_brst_srvy_5_6', data=[tplotvar+'_brst_anodes_5_6', tplotvar+'_srvy_anodes_5_6'], dlimits=dl, limits=l
store_data, tplotvar+'_brst_srvy_13_14', data=[tplotvar+'_brst_anodes_13_14', tplotvar+'_srvy_anodes_13_14'], dlimits=dl, limits=l

;options, tplotvar+'_brst_srvy_0_15', 'labels'

; get ephemeris data for x-axis annotation
;mms_load_state, probes=pid, trange = trange, /ephemeris
;eph_j2000 = 'mms'+pid+'_defeph_pos'
;eph_gei = 'mms'+pid+'_defeph_pos_gei'
;eph_gse = 'mms'+pid+'_defeph_pos_gse'
eph_gsm = 'mms'+pid+'_ql_pos_gsm'

; convert from J2000 to gsm coordinates
;cotrans, eph_j2000, eph_gei, /j20002gei
;cotrans, eph_gei, eph_gse, /gei2gse
;cotrans, eph_gse, eph_gsm, /gse2gsm

; convert km to re
calc,'"'+eph_gsm+'_re" = "'+eph_gsm+'"/6378.'

; split the position into its components
split_vec, eph_gsm+'_re'

; set the label to show along the bottom of the tplot
options, eph_gsm+'_re_0',ytitle='X-GSM (Re)'
options, eph_gsm+'_re_1',ytitle='Y-GSM (Re)'
options, eph_gsm+'_re_2',ytitle='Z-GSM (Re)'
options, eph_gsm+'_re_3',ytitle='R (Re)'
position_vars = [eph_gsm+'_re_0', eph_gsm+'_re_1', eph_gsm+'_re_2', eph_gsm+'_re_3']

; create a tplot variable with flags for burst and survey data
;mode_var=mms_hpca_mode(tplotvar+'_brst', tplotvar+'_srvy')
; use bss routine to create tplot variables for fast, burst, status, and/or FOM
spd_mms_load_bss, trange=trange, /include_labels, datatype=['fast', 'burst']

; set up some plotting parameters
tplot_options, 'xmargin', [20, 15]
tplot_options, 'ymargin', [5, 5]
;tplot_options, 'title', 'Quicklook Plots for HPCA '+sid+' Data'
;panels=['mms_bss_burst', 'mms_bss_fast','mms_bss_status', $
;  'mms1_hpca_hplus_RF_corrected_brst_srvy_anodes_0_15', $
;  'mms1_hpca_hplus_RF_corrected_brst_srvy_anodes_5_6', $
;  'mms1_hpca_hplus_RF_corrected_brst_srvy_anodes_13_14']

; don't interpolate through the gaps for burst mode data
tdegap, 'mms1_hpca_hplus_RF_corrected_brst_anodes_*', /overwrite

panels=['mms_bss_burst', 'mms_bss_fast','mms_bss_status', $
   'mms1_hpca_hplus_RF_corrected_brst_anodes_0_15', $
   'mms1_hpca_hplus_RF_corrected_brst_anodes_5_6', $
   'mms1_hpca_hplus_RF_corrected_brst_anodes_13_14', $
   'mms1_hpca_hplus_RF_corrected_srvy_anodes_0_15', $
   'mms1_hpca_hplus_RF_corrected_srvy_anodes_5_6', $
   'mms1_hpca_hplus_RF_corrected_srvy_anodes_13_14']
   
if ~postscript then window, iw, xsize=width, ysize=height
tplot, panels, var_label=position_vars, window=iw
title= 'Quicklook Plots for HPCA '+sid+' Data'
xyouts, .33, .96, title, /normal, charsize=2

if postscript then tprint, plot_directory + "mms1_hpca_hplus_RF_corrected"
stop

end