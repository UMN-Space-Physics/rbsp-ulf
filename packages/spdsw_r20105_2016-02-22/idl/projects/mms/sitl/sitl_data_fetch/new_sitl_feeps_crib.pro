pro new_sitl_feeps_crib

mms_init, local_data_dir='/Volumes/MMS/data/mms/'

timespan, '2015-05-05/00:00:00', 24, /hour

mms_load_epd_feeps, sc='mms3'

options, 'mms3_epd_feeps_TOP_counts_per_accumulation_sensorID_4', 'ytitle', 'electrons'
options, 'mms3_epd_feeps_TOP_counts_per_accumulation_sensorID_4', 'ylog', 1

tplot, ['mms3_epd_feeps_TOP_counts_per_accumulation_sensorID_4']

end