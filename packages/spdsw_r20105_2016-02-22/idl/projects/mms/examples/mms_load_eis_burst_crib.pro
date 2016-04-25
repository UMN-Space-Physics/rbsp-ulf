;+
; MMS EIS burst data crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-15 08:14:10 -0800 (Fri, 15 Jan 2016) $
; $LastChangedRevision: 19742 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_eis_burst_crib.pro $
;-
probe = '1'
trange = ['2015-08-23', '2015-08-24']
prefix = 'mms'+probe

tplot_options, 'xmargin', [20, 15]

; load ExTOF burst data:
mms_load_eis, probes=probe, trange=trange, $
    datatype='extof', data_rate='brst', level='l1b'

mms_eis_pad, probe=probe, trange=trange, datatype='extof', species='ion', data_rate='brst'

; plot the proton flux spectra
ylim, prefix+'_epd_eis_brst_extof_proton_flux_omni_spin', 30, 500, 1
zlim, prefix+'_epd_eis_brst_extof_proton_flux_omni_spin', 0, 0, 1
tdegap, prefix+'_epd_eis_brst_extof_*keV_proton_flux_pad_spin', /overwrite

tplot, prefix+['_epd_eis_brst_extof_proton_flux_omni_spin', $
               '_epd_eis_brst_extof_*keV_proton_flux_pad_spin']
stop

; load phxtof burst data
mms_load_eis, probes=probe, trange=trange, $
    datatype='phxtof', data_rate='brst', level='l1b'

mms_eis_pad, probe=probe, trange=trange, datatype='phxtof', species='ion', data_rate='brst'

; plot the spectra
ylim, prefix+'_epd_eis_brst_phxtof_proton_flux_omni_spin', 10, 50, 1
zlim, prefix+'_epd_eis_brst_phxtof_proton_flux_omni_spin', 0, 0, 1 
tdegap, prefix+'_epd_eis_brst_phxtof_*keV_proton_flux_pad_spin', /overwrite

tplot, prefix+['_epd_eis_brst_phxtof_proton_flux_omni_spin', $
    '_epd_eis_brst_phxtof_*keV_proton_flux_pad_spin']

; list tplot variables that were loaded
tplot_names
stop

end