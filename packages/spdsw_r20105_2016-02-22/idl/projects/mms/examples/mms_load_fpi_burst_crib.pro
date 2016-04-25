;+
; MMS FPI burst mode crib sheet
;
; do you have suggestions for this crib sheet?
;   please send them to egrimes@igpp.ucla.edu
;
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-10-06 15:46:20 -0700 (Tue, 06 Oct 2015) $
; $LastChangedRevision: 19020 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fpi_burst_crib.pro $
;-
timespan, '2015-09-08', 1, /day

probe = '1'
level = 'l1b'
data_rate = 'brst'
autoscale = 1

; set data type to 'des-moms' or 'dis-moms to get electron or ion data 
datatype = 'des-moms'    ; or 'dis-moms'

mms_load_fpi, trange = trange, probes = probe, datatype = datatype, $
  level = level, data_rate = data_rate, $
  local_data_dir = local_data_dir, source = source, $
  get_support_data = get_support_data, $
  tplotnames = tplotnames, no_color_setup = no_color_setup
        
prefix = 'mms'+probe
if datatype EQ 'des-moms' then prefix=prefix+'_des' else prefix=prefix+'_dis'

; Combine moments

; combine heat into a single tplot variable
join_vec, prefix+['_bulkX', '_bulkY', '_bulkZ'], prefix+'_bulk'
options, prefix+'_bulk', 'labels', ['x', 'y', 'z']
options, prefix+'_bulk', 'labflag', -1
options, prefix+'_bulk', 'colors', [2, 4, 6]

; combine heat into a single tplot variable
join_vec, prefix+['_heatX', '_heatY', '_heatZ'], prefix+'_heat'
options, prefix+'_heat', 'labels', ['x', 'y', 'z']
options, prefix+'_heat', 'labflag', -1
options, prefix+'_heat', 'colors', [2, 4, 6]

; PRESSURE
; combine x pressure into a single tplot variable
join_vec, prefix+['_PresXX', '_PresXY', '_PresXZ'], prefix+'_PresX'
options, prefix+'_PresX', 'labels', ['x', 'y', 'z']
options, prefix+'_PresX', 'labflag', -1
options, prefix+'_PresX', 'colors', [2, 4, 6]

; combine y Presure into a single tplot variable
join_vec, prefix+['_PresYY', '_PresYZ'], prefix+'_PresY'
options, prefix+'_PresY', 'labels', ['y', 'z']
options, prefix+'_PresY', 'labflag', -1
options, prefix+'_PresY', 'colors', [4, 6]

; only one ZZ tplot var (no need to combine)
options, prefix+'_PresZZ', 'labels', ['z']
options, prefix+'_PresZZ', 'labflag', -1
options, prefix+'_PresZZ', 'colors', [6]

; TEMPERATURE
; combine x temperature into a single tplot variable
join_vec, prefix+['_TempXX', '_TempXY', '_TempXZ'], prefix+'_TempX'
options, prefix+'_TempX', 'labels', ['x', 'y', 'z']
options, prefix+'_TempX', 'labflag', -1
options, prefix+'_TempX', 'colors', [2, 4, 6]

; combine y temperature into a single tplot variable
join_vec, prefix+['_TempYY', '_TempYZ'], prefix+'_TempY'
options, prefix+'_TempY', 'labels', ['y', 'z']
options, prefix+'_TempY', 'labflag', -1
options, prefix+'_TempY', 'colors', [4, 6]

; set plot params for temp Z
options, prefix+'_TempZZ', 'labels', ['z']
options, prefix+'_TempZZ', 'labflag', -1
options, prefix+'_TempZZ', 'colors', [ 6]

; load ephemeris data for
mms_load_state, trange = trange, probes = probe, /ephemeris
; get state data and convert the position data into Re
eph_variable = 'mms'+probe+'_defeph_pos'
calc,'"'+eph_variable+'_re" = "'+eph_variable+'"/6371.2'

; split the position into its components
split_vec, eph_variable+'_re'

; set the label to show along the bottom of the tplot
options, eph_variable+'_re_x',ytitle='X (Re)'
options, eph_variable+'_re_y',ytitle='Y (Re)'
options, eph_variable+'_re_z',ytitle='Z (Re)'
position_vars = [eph_variable+'_re_z', eph_variable+'_re_y', eph_variable+'_re_x']

tplot_options,'xmargin',[15,10]              ; Set left/right margins to 10 characters
tplot_options,'ymargin',[4,2]                ; Set top/bottom margins to 4/2 lines

window, 0
window_caption="FPI Burst Data"
tplot_options,'title', window_caption
fpi_moments = prefix+['_numberDensity', '_bulkSpeed' ,'_bulk', '_heat']
tplot, fpi_moments, window=0, var_label=position_vars
stop

; zoom in 
tlimit, '2015-09-08/10:20:00', '2015-09-08/11:20:00'
tplot, fpi_moments, window=0, var_label=position_vars
stop

window, 1
window_caption="FPI Burst Data - Pressure"
tplot_options,'title', window_caption
fpi_moments = prefix+['_PresX', '_PresY', '_PresZZ']
tplot, fpi_moments, window=1, var_label=position_vars
stop

window, 2
window_caption="FPI Burst Data - Temperature"
tplot_options,'title', window_caption
fpi_moments = prefix+['_TempX', '_TempY', '_TempZZ']
tplot, fpi_moments, window=2, var_label=position_vars
stop

tprint, "fpi_moments"

end