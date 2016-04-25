
mms_init, local_data_dir='/Volumes/MMS/data/mms/'

timespan, '2015-05-13/00:00:00', 24, /hour

mms_load_epd_eis, sc='mms1'

options, 'mms1_epd_eis_electronenergy_electron_cps_t1', 'ytitle', 'electrons'
options, 'mms1_epd_eis_electronenergy_electron_cps_t1', 'ylog', 1
ylim, 'mms1_epd_eis_electronenergy_electron_cps_t1', 0.8, 1e5

tplot, ['mms1_epd_eis_electronenergy_electron_cps_t1']

end