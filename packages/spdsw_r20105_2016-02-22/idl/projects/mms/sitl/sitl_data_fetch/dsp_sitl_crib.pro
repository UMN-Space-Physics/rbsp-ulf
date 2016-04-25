mms_init

timespan, '2015-11-06/03:10:00', 12, /hour

sc_id = 'mms3'

; New way to plot improved spectral products.

; Get e-field spectrum
mms_sitl_get_edp, sc_id = sc_id, datatype='hfesp', level = 'l1b', data_rate='srvy'

espec = sc_id + '_edp_srvy_EPSD_x'

options, espec, 'spec', 1
ylim, espec, 0, 64000
options, espec, 'zlog', 1
options, espec, 'ylog', 1
ylim, espec, 600, 65536

; Get b-field spectrum

mms_sitl_get_dsp, sc_id = sc_id, datatype = 'bpsd', level = 'l2', data_rate='fast'
bspec = sc_id + '_dsp_bpsd_omni'
options, bspec, 'spec', 1
options, bspec, 'zlog', 1
options, bspec, 'ylog', 1
ylim, bspec, 32, 4000

tplot, [espec, bspec]

; Old way to plot L1 spectra 
;options, ['mms3_dsp_lfe_x', 'mms3_dsp_lfe_y', 'mms3_dsp_lfe_z', $
;         'mms3_dsp_mfe_x', 'mms3_dsp_mfe_y', 'mms3_dsp_mfe_z'], $
;         'ylog', 1
;
;options, ['mms3_dsp_lfe_x', 'mms3_dsp_lfe_y', 'mms3_dsp_lfe_z', $
;         'mms3_dsp_mfe_x', 'mms3_dsp_mfe_y', 'mms3_dsp_mfe_z'], $
;         'zlog', 1
;         
;ylim, ['mms3_dsp_lfe_x', 'mms3_dsp_lfe_y', 'mms3_dsp_lfe_z'], 10, 10000
;
;ylim, ['mms3_dsp_mfe_x', 'mms3_dsp_mfe_y', 'mms3_dsp_mfe_z'], 100, 100000
;     
;tplot, ['mms3_dsp_lfe_x', 'mms3_dsp_lfe_y', 'mms3_dsp_lfe_z', $
;         'mms3_dsp_mfe_x', 'mms3_dsp_mfe_y', 'mms3_dsp_mfe_z']
;
;; Now lets do bspec
;
;mms_sitl_get_dsp, sc_id = 'mms3', datatype='bpsd'
;
;options, ['mms3_dsp_lfb_x', 'mms3_dsp_lfb_y','mms3_dsp_lfb_z'], 'ylog', 1
;
;options, ['mms3_dsp_lfb_x', 'mms3_dsp_lfb_y','mms3_dsp_lfb_z'], 'zlog', 1
;
;ylim, ['mms3_dsp_lfb_x', 'mms3_dsp_lfb_y','mms3_dsp_lfb_z'], 10, 10000
;
;
;window, 1
;
;tplot, ['mms3_dsp_lfb_x', 'mms3_dsp_lfb_y','mms3_dsp_lfb_z'], window=1

end