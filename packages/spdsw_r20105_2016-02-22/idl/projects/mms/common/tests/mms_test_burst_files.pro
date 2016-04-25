;+
; PROCEDURE:
;         mms_test_burst_files
;         
; PURPOSE:
;         script to test special cases for loading burst data
; 
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:24:15 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19590 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/tests/mms_test_burst_files.pro $
;- 

; user requests a few seconds after file start time
mms_load_fpi, trange=['2015-10-15/6:45:21', '2015-10-15/6:51:21'], data_rate='brst', level='l1b'

if ~spd_data_exists('mms3_dis_bulkSpeed','2015-10-15/06:47:23','2015-10-15/06:54:59') then begin
    dprint, dlevel = 0, 'Error! Not grabbing the correct data from the SDC???'
    stop
endif

; user requests a few seconds after file end time
mms_load_fpi, trange=['2015-10-15/6:49:21', '2015-10-15/6:54:01'], data_rate='brst', level='l1b'

if ~spd_data_exists('mms3_dis_bulkSpeed','2015-10-15/06:47:23','2015-10-15/06:54:59') then begin
    dprint, dlevel = 0, 'Error! Not grabbing the correct data from the SDC???'
    stop
endif

; user requests a time interval without any CDF files inside
mms_load_fpi, trange=['2015-10-15/6:46:21', '2015-10-15/6:49:01'], data_rate='brst', level='l1b'

if ~spd_data_exists('mms3_dis_bulkSpeed','2015-10-15/06:47:23','2015-10-15/06:49:59') then begin
    dprint, dlevel = 0, 'Error! Not grabbing the correct data from the SDC???'
    stop
endif

; user requests a time interval just beyond start time (but inside the interval) 
; of last burst-mode file for the day
mms_load_fpi, trange=['2015-10-16/13:07', '2015-10-16/13:09'], data_rate='brst', level='l1b'

if ~spd_data_exists('mms3_dis_bulkSpeed','2015-10-16/13:07','2015-10-16/13:09') then begin
    dprint, dlevel = 0, 'Error! Not grabbing the correct data from the SDC???'
    stop
endif


print, 'Done running the tests! '
end