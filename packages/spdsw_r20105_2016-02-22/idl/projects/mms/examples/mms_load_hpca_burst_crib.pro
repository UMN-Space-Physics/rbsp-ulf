;+
; MMS HPCA burst data crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-15 09:11:22 -0800 (Fri, 15 Jan 2016) $
; $LastChangedRevision: 19746 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_hpca_burst_crib.pro $
;-

mms_load_hpca, probes='1',  trange=['2015-09-03', '2015-09-04'], datatype='moments', data_rate='brst'

window, 1
; show H+, O+ and He+ density
tplot, ['mms1_hpca_hplus_number_density', $
  'mms1_hpca_oplus_number_density', $
  'mms1_hpca_heplus_number_density'], window=1
stop

; show H+, O+ and He+ temperature
tplot, ['mms1_hpca_hplus_scalar_temperature', $
  'mms1_hpca_oplus_scalar_temperature', $
  'mms1_hpca_heplus_scalar_temperature']
stop

; set the colors
tplot_options, 'colors', [2, 4, 6]
; set some reasonable margins
tplot_options, 'xmargin', [20, 15]
; show H+, O+ and He+ flow velocity
tplot, 'mms1_hpca_*_ion_bulk_velocity'
stop

mms_load_hpca, probes='1', trange=['2015-09-03', '2015-09-04'], datatype='rf_corr', data_rate='brst'
; sum over nodes
mms_hpca_calc_anodes, anode=[5, 6], probe=pid
mms_hpca_calc_anodes, anode=[13, 14], probe=pid
mms_hpca_calc_anodes, anode=[0, 15], probe=pid

rf_corrected = ['mms1_hpca_hplus_RF_corrected_anodes_0_15', $
  'mms1_hpca_oplus_RF_corrected_anodes_0_15', $
  'mms1_hpca_heplus_RF_corrected_anodes_0_15', $
  'mms1_hpca_heplusplus_RF_corrected_anodes_0_15']

; don't interpolate through the gaps
tdegap, rf_corrected, /overwrite

; show spectra for H+, O+ and He+, He++
tplot, rf_corrected
stop

; sum over FOV's 
mms_hpca_calc_anodes, fov=[0, 360], probe='1'
mms_hpca_calc_anodes, fov=[0, 180], probe='1'
mms_hpca_calc_anodes, fov=[180, 360], probe='1'

; don't interpolate through the gaps
tdegap, 'mms1_hpca_*plus_RF_corrected_elev_*', /overwrite

; plot each view
tplot, ['mms1_hpca_hplus_RF_corrected_elev_*']  
stop

; plot each species
tplot, ['mms1_hpca_*plus_RF_corrected_elev_0-360']
stop
end