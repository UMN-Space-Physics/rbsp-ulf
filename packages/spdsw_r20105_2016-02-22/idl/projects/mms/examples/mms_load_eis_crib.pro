;+
; MMS EIS crib sheet
; 
;  prime EIS scientific products are: 
;    ExTOF proton spectra
;    ExTOF He spectra
;    ExTOF Oxygen spectra
;    PHxTOF proton spectra
;    PHxTOF Oxygen (assumed to be oxygen; not terrifically discriminated)
;    
;  
; do you have suggestions for this crib sheet? 
;   please send them to egrimes@igpp.ucla.edu
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-15 08:21:27 -0800 (Fri, 15 Jan 2016) $
; $LastChangedRevision: 19743 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_eis_crib.pro $
;-
probe = '1'
prefix = 'mms'+probe

tplot_options, 'xmargin', [20, 15]

; load ExTOF data:
mms_load_eis, probes=probe, trange=['2015-08-15', '2015-08-16'], datatype='extof'

; plot the H+ flux for all channels
ylim, '*_extof_proton_flux_omni_spin', 50, 300, 1
zlim, '*_extof_proton_flux_omni_spin', 0, 0, 1

; setting ystyle = 1 forces the max/min of the Y axis to be set
; to the y limits set above
options, '*_extof_proton_flux_omni_spin', ystyle=1

tplot, '*_extof_proton_flux_omni_spin'
stop

; calculate the PAD for 48-106keV protons
mms_eis_pad, probe=probe, species='ion', datatype='extof', ion_type='proton', data_units='flux', energy=[48, 106]

; calculate the PAD for 105-250 keV protons
mms_eis_pad, probe=probe, species='ion', datatype='extof', ion_type='proton', data_units='flux', energy=[105, 250]

; plot the PAD for 48-106keV (top), 105-250 keV (bottom) protons
tplot, '*_epd_eis_extof_*keV_proton_flux_pad_spin'
stop

; plot the He++ flux for all channels
ylim, '*extof_alpha_flux_omni_spin', 80, 600, 1
zlim, '*extof_alpha_flux_omni_spin', 0, 0, 1
tplot, '*extof_alpha_flux_omni_spin'

stop

; plot the O+ flux for all channels
ylim, '*_extof_oxygen_flux_omni_spin', 100, 1000, 1
zlim, '*_extof_oxygen_flux_omni_spin', 0, 0, 1
tplot, '*_extof_oxygen_flux_omni_spin'

stop

; load PHxTOF data:
mms_load_eis, probes=probe, trange=['2015-07-31', '2015-08-01'], datatype='phxtof'

; plot the PHxTOF proton spectra
ylim, '*_phxtof_proton_flux_omni_spin', 10, 50, 1
zlim, '*_phxtof_proton_flux_omni_spin', 0, 0, 1
options, '*_phxtof_proton_flux_omni_spin', ystyle=1
tplot, '*_phxtof_proton_flux_omni_spin'
stop

; calculate the PHxTOF PAD for protons
mms_eis_pad, probe=probe, species='ion', datatype='phxtof', ion_type='proton', data_units='flux', energy=[0, 30]

tplot, ['*_epd_eis_phxtof_proton_flux_omni_spin', $
        '*_epd_eis_phxtof_0-30keV_proton_flux_pad_spin']
stop

; plot the PHxTOF oxygen spectra (note from Barry Mauk: assumed to be oxygen; not terrifically discriminated)
ylim, '*_phxtof_oxygen_flux_omni_spin', 60, 180, 1
zlim, '*_phxtof_oxygen_flux_omni_spin', 0, 0, 1
options, '*_phxtof_oxygen_flux_omni_spin', ystyle=1

; calculate the PHxTOF PAD for oxygen
mms_eis_pad, probe=probe, species='ion', datatype='phxtof', ion_type='oxygen', data_units='flux', energy=[0, 175]

tplot, ['*_phxtof_oxygen_flux_omni_spin', '*_epd_eis_phxtof_0-175keV_oxygen_flux_pad_spin']
stop

; load some electron data; note that the datatype for electron data is "electronenergy"
mms_load_eis, probes=probe, trange=['2015-08-15', '2015-08-16'], datatype='electronenergy'
mms_eis_pad, probe=probe, species='electron', datatype='electronenergy', data_units='flux'

; plot the electron spectra
tplot, ['*_epd_eis_electronenergy_electron_flux_omni_spin', '*_epd_eis_electronenergy_*keV_electron_flux_pad_spin']

stop
end