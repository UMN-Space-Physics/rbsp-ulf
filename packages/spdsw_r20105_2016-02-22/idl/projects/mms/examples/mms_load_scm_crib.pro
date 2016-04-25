;+
; MMS SCM crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; Note:
;       L2 SCM data have not been fully validated yet. Please contact 
;       the SCM instrument team or PI before using these data.
; 
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-08-19 10:09:31 -0700 (Wed, 19 Aug 2015) $
; $LastChangedRevision: 18523 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_scm_crib.pro $
;-

;;    ============================
;; 1) Select date and time interval
;;    ============================
; download SCM data for 8/2/2015
; example of slow survey L1a cdf file (uncalibrated data in ADC units): mms1_scm_slow_l1a_scs_20150802_v0.8.0.cdf
; example of fast survey L1b cdf file (calibrated data in scm123 sensor spinning frame): mms1_scm_fast_l1b_scf_20150802_v0.1.0.cdf
; example of sc256 L2 cdf file during commissioning (in gse): mms1_scm_comm_l2_sc256_20150609_v0.1.0.cdf
; example of burst L1a cdf file (uncalibrated data in ADC units): mms1_scm_brst_l1a_scb_20150612161005_v0.8.0.cdf
 
 
 date = '2015-07-31/00:00:00'
  
  ;'2015-08-02/00:00:00' 
  ;'2015-06-09/00:00:00'
  ;'2015-06-12/00:00:00'
  timespan,date,1,/day

;;    =====================
;; 2) Select probe and mode
;;    =====================

;; Select SATNAME ('1','2','3', or '4')
  satname = '4'
  
;; Select Data rate (slow, fast, burst or comm for commissioning period from March 13 to Aug. 31)
  data_rate = 'brst' ;'slow';'comm' ;'slow'  

;; Select MODE ('scs' for slow survey data rate, 'scf' for fast survey data rate , 'scb' or 'schb' for burst data rate, 
;;              during commissioning period can be 'sc32', 'sc128', 'sc256')
  scm_mode = 'scb'
  
;; Select data level ('l1a' uncalibrated or 'l1b' calibrated data in scm123 sensor spinning system or 'l2' for calibrated data in gse)
  scm_level_input = 'l1a'

;; Select coordinate frame ('123' for l1a data, 'scm123' for l1b in sensor spinning system or 'gse' for l2 data)

if scm_level_input eq 'l1a' then scm_coord = '123'
if scm_level_input eq 'l1b' then scm_coord = 'scm123'
if scm_level_input eq 'l2'  then scm_coord = 'gse'

scm_name = 'mms'+satname+'_scm_'+scm_mode+'_'+scm_coord

;; To impose by hand t1 and t2 :
starting_date =strmid(date,0,10)
;20150612 burst mode mms1,mms2,mms3,mms4
;  starting_time='16:00:00.0'
;  ending_time  ='16:10:00.0'
;20150731 burst mode  mms1,mms2,mms3,mms4
  ;starting_time='13:40:00.0'
  ;ending_time  ='13:50:00.0'

  starting_time='00:00:00.0'
  ending_time  ='24:00:00.0'
  trange = [starting_date+'/'+starting_time, $
            starting_date+'/'+ending_time]
            
mms_load_scm, trange=trange, probes=satname, level=scm_level_input, data_rate=data_rate, datatype=scm_mode, tplotnames=tplotnames

options, scm_name, colors=[2, 4, 6]
options, scm_name, labels=['X', 'Y', 'Z']
options, scm_name, labflag=-1


window, 0, ysize=650
tplot_options, 'xmargin', [15, 15]
tplot_options,title= 'MMS'+satname+' '+ data_rate+' period, '+scm_mode +' SCM data in '+scm_coord +' frame'

; plot the SCM data
tplot, scm_name
tlimit,trange

;; zoom into a time in the afternoon
;;tlimit, ['2015-08-02/16:00', '2015-08-02/18:00']

; calculate the dynamic power spectra
if scm_mode eq 'scb'then nboxpoints_input = 8192L else nboxpoints_input = 512
tdpwrspc, scm_name, nboxpoints=nboxpoints_input

options, scm_name+'_?_dpwrspc', 'ytitle', 'MMS'+satname+' '+scm_mode
options, scm_name+'_x_dpwrspc', 'ysubtitle', 'dynamic power!CX!C[Hz]'
options, scm_name+'_y_dpwrspc', 'ysubtitle', 'dynamic power!CY!C[Hz]'
options, scm_name+'_z_dpwrspc', 'ysubtitle', 'dynamic power!CZ!C[Hz]'

tplot, [scm_name, scm_name+'_?_dpwrspc']
stop
end