;mms_init, local_data_dir='~/Desktop/MMS/data/mms/'
mms_init;, local_data_dir='/MMS/data/mms/'

;cdf_leap_second_init

Re = 6378.137

;timespan, '2015-04-18/12:20:00', 25, /minutes
;timespan, '2015-05-07', 1, /day
timespan, '2015-05-06/23:10:00', 12, /hour

mms_sitl_get_fpi_basic, sc_id='mms3'

options, 'mms1_fpi_eEnergySpectr_omni', 'spec', 1
options, 'mms1_fpi_eEnergySpectr_omni', 'ylog', 1
options, 'mms1_fpi_eEnergySpectr_omni', 'zlog', 1
options, 'mms1_fpi_eEnergySpectr_omni', 'no_interp', 1
options, 'mms1_fpi_eEnergySpectr_omni', 'ytitle', 'elec E, eV'
ylim, 'mms1_fpi_eEnergySpectr_omni', 10, 26000
zlim, 'mms1_fpi_eEnergySpectr_omni', .1, 2000

options, 'mms1_fpi_iEnergySpectr_omni', 'spec', 1
options, 'mms1_fpi_iEnergySpectr_omni', 'ylog', 1
options, 'mms1_fpi_iEnergySpectr_omni', 'zlog', 1
options, 'mms1_fpi_iEnergySpectr_omni', 'no_interp', 1
options, 'mms1_fpi_iEnergySpectr_omni', 'ytitle', 'ion E, eV'
ylim, 'mms1_fpi_iEnergySpectr_omni', 10, 26000
zlim, 'mms1_fpi_iEnergySpectr_omni', .1, 2000

options, 'mms1_fpi_ePitchAngDist_midEn', 'spec', 1
options, 'mms1_fpi_ePitchAngDist_midEn', 'ylog', 0
options, 'mms1_fpi_ePitchAngDist_midEn', 'zlog', 1
options, 'mms1_fpi_ePitchAngDist_midEn', 'no_interp', 1
options, 'mms1_fpi_ePitchAngDist_midEn', 'ytitle', 'ePADM, eV'
ylim, 'mms1_fpi_ePitchAngDist_midEn', 1, 180
zlim, 'mms1_fpi_ePitchAngDist_midEn', 100, 10000

options, 'mms1_fpi_ePitchAngDist_highEn', 'spec', 1
options, 'mms1_fpi_ePitchAngDist_highEn', 'ylog', 0
options, 'mms1_fpi_ePitchAngDist_highEn', 'zlog', 1
options, 'mms1_fpi_ePitchAngDist_highEn', 'no_interp', 1
options, 'mms1_fpi_ePitchAngDist_highEn', 'ytitle', 'ePADH, eV'
ylim, 'mms1_fpi_ePitchAngDist_highEn', 1, 180
zlim, 'mms1_fpi_ePitchAngDist_highEn', 100, 10000

ylim, 'mms1_fpi_DISnumberDensity', 1, 10
options, 'mms1_fpi_DISnumberDensity', 'ylog', 1
options, 'mms1_fpi_DISnumberDensity', 'ytitle', 'n, cm!U-3!N'

options, 'mms1_fpi_iBulkV_DSC', labels=['V!DX!N', 'V!DY!N', 'V!DZ!N']
options, 'mms1_fpi_iBulkV_DSC', 'ytitle', 'V!DDSC!N, km/s'

tplot, [1, 2, 4, 5, 6]

end
