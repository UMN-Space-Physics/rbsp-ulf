;+
; MMS HPCA crib sheet
; 
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-10-02 09:07:42 -0700 (Fri, 02 Oct 2015) $
; $LastChangedRevision: 18983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_hpca_crib.pro $
;-

; set some reasonable margins
tplot_options, 'xmargin', [20, 15]

mms_load_hpca, probes='1', trange=['2015-09-01', '2015-09-02'], datatype='moments', data_rate='srvy'

; show H+, O+ and He+ density
tplot, ['mms1_hpca_hplus_number_density', $
        'mms1_hpca_oplus_number_density', $
        'mms1_hpca_heplus_number_density']
stop

window, 1
; show H+, O+ and He+ temperature
tplot, ['mms1_hpca_hplus_scalar_temperature', $
        'mms1_hpca_oplus_scalar_temperature', $
        'mms1_hpca_heplus_scalar_temperature'], window=1
stop

window, 2
tplot_options, 'colors', [2, 4, 6]
; show H+, O+ and He+ flow velocity
tplot, ['mms1_hpca_hplus_ion_bulk_velocity', $
        'mms1_hpca_oplus_ion_bulk_velocity', $
        'mms1_hpca_heplus_ion_bulk_velocity'], window=2
stop

mms_load_hpca, probes='1', trange=['2015-09-1', '2015-09-02'], datatype='rf_corr', level='l1b', data_rate='srvy'

; sum over anodes for the full field of view (0-360)
mms_hpca_calc_anodes, fov=[0, 360], probe='1'
rf_corrected_elev = ['mms1_hpca_hplus_RF_corrected_elev_0-360', $
                'mms1_hpca_oplus_RF_corrected_elev_0-360', $
                'mms1_hpca_heplus_RF_corrected_elev_0-360', $
                'mms1_hpca_heplusplus_RF_corrected_elev_0-360']
                
; show spectra for H+, O+ and He+, He++
window, 3, ysize=600
tplot, rf_corrected_elev, window=3
stop

; repeat above, sum anodes 0 and 15
mms_hpca_calc_anodes, anodes=[0, 15], probe='1'
rf_corrected_anodes = ['mms1_hpca_hplus_RF_corrected_anodes_0_15', $
  'mms1_hpca_oplus_RF_corrected_anodes_0_15', $
  'mms1_hpca_heplus_RF_corrected_anodes_0_15', $
  'mms1_hpca_heplusplus_RF_corrected_anodes_0_15']

; show spectra for H+, O+ and He+, He++
window, 4, ysize=600
tplot, rf_corrected_anodes, window=4
stop
end