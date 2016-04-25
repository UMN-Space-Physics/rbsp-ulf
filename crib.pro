; Charles McEachern
; Adapted from work by Aaron Breneman
; Spring 2016

; Here, we rework the crib sheet from Aaron into a form that's easier for the Python script to handle. 

date = '2014-02-19'
timespan, date

probe = 'a'
rbspx = 'rbsp' + probe

rbsp_efw_init

; Load eclipse times. 
rbsp_load_eclipse_predict, probe, date
get_data, rbspx + '_umbra', data=eu
get_data, rbspx + '_penumbra', data=ep

; Load spinfit MGSE electric and magnetic fields. 
rbsp_efw_spinfit_vxb_subtract_crib, probe, /noplot, ql=0, boom_pair='12'
evar = rbspx + '_efw_esvy_mgse_vxb_removed_spinfit'

; Grab the spinfit Ew and Bw data. 
split_vec, rbspx + '_mag_mgse'
get_data, evar, data=edata
if ~is_struct(edata) then print, 'NO ELECTRIC FIELD DATA! '
tinterpol_mxn, rbspx + '_mag_mgse', edata.x, newname=rbspx + '_mag_mgse'

; Smooth the background magnetic field over 30 min for E dot B calculation. 
rbsp_detrend, rbspx + '_mag_mgse', 60.*30.

get_data, rbspx + '_mag_mgse', data=magmgse
if ~is_struct(magmgse) then print, 'NO MAGNETIC FIELD DATA! '

get_data, rbspx + '_mag_mgse_smoothed', data=magmgse_smoothed
if ~is_struct(magmgse_smoothed) then print, 'NO SMOOTHED MAGNETIC FIELD DATA! '

bmag = sqrt(magmgse.y[*,0]^2 + magmgse.y[*,1]^2 + magmgse.y[*,2]^2)
bmag_smoothed = sqrt(magmgse_smoothed.y[*,0]^2 + magmgse_smoothed.y[*,1]^2 + magmgse_smoothed.y[*,2]^2)

; Replace axial measurement with the values from E dot B calculation. 
edata.y[*,0] = -1*( edata.y[*,1]*magmgse_smoothed.y[*,1] + edata.y[*,2]*magmgse_smoothed.y[*,2] ) / magmgse_smoothed.y[*,0]
store_data, evar, data=edata

; Remove data where the angle between spinplane MGSE and B is less than 15 deg.
; Good data has By/Bx < 3.732   and  Bz/Bx < 3.732
By2Bx = abs( magmgse_smoothed.y[*,1] / magmgse_smoothed.y[*,0] )
Bz2Bx = abs( magmgse_smoothed.y[*,2] / magmgse_smoothed.y[*,0] )
badyx = where(By2Bx gt 3.732)
badzx = where(Bz2Bx gt 3.732)

; Calculate the angles between despun spinplane antennas and B. 
n = n_elements(edata.x)
ang_ey = fltarr(n)
ang_ez = fltarr(n)

for i=0L,n-1 do ang_ey[i] = acos( total( [0,1,0]*magmgse_smoothed.y[i,*] ) / ( bmag_smoothed[i] ) ) / !dtor
for i=0L,n-1 do ang_ez[i] = acos( total( [0,0,1]*magmgse_smoothed.y[i,*] ) / ( bmag_smoothed[i] ) ) / !dtor
store_data, 'angles', data={ x:edata.x, y:[ [ang_ey], [ang_ez] ] }

; Calculate the ratio between spin axis and spinplane components. 
e_sp = sqrt(edata.y[*,1]^2 + edata.y[*,2]^2)
rat = abs( edata.y[*,0] ) / e_sp
store_data, 'rat', data={x:edata.x, y:rat}
store_data,'e_sp', data={x:edata.x, y:e_sp}
store_data,'e_sa', data={ x:edata.x, y:abs( edata.y[*,0] ) }

; Remove bad electric field data. This can mean saturation from the rest of the
; tplot variables, saturation from Ex, or data where E dot B is unreliable. 

get_data, evar, data=tmpp
badsatx = where( abs( tmpp.y[*,0] ) ge 195. )
badsaty = where( abs( tmpp.y[*,1] ) ge 195. )
badsatz = where( abs( tmpp.y[*,2] ) ge 195. )

get_data, evar, data=tmpp
if badyx[0]   ne -1 then tmpp.y[badyx,0]   = !values.f_nan
if badzx[0]   ne -1 then tmpp.y[badzx,0]   = !values.f_nan
if badsatx[0] ne -1 then tmpp.y[badsatx,0] = !values.f_nan
if badsaty[0] ne -1 then tmpp.y[badsaty,1] = !values.f_nan
if badsatz[0] ne -1 then tmpp.y[badsatz,2] = !values.f_nan
store_data, evar, data=tmpp

get_data, 'rat', data=tmpp
if badyx[0]   ne -1 then tmpp.y[badyx]   = !values.f_nan
if badzx[0]   ne -1 then tmpp.y[badzx]   = !values.f_nan
if badsatx[0] ne -1 then tmpp.y[badsatx] = !values.f_nan
if badsaty[0] ne -1 then tmpp.y[badsaty] = !values.f_nan
if badsatz[0] ne -1 then tmpp.y[badsatz] = !values.f_nan
store_data, 'rat', data=tmpp

get_data, 'e_sa', data=tmpp
if badyx[0]   ne -1 then tmpp.y[badyx]   = !values.f_nan
if badzx[0]   ne -1 then tmpp.y[badzx]   = !values.f_nan
if badsatx[0] ne -1 then tmpp.y[badsatx] = !values.f_nan
if badsaty[0] ne -1 then tmpp.y[badsaty] = !values.f_nan
if badsatz[0] ne -1 then tmpp.y[badsatz] = !values.f_nan
store_data, 'e_sa', data=tmpp

get_data, 'e_sp', data=tmpp
if badyx[0]   ne -1 then tmpp.y[badyx]   = !values.f_nan
if badzx[0]   ne -1 then tmpp.y[badzx]   = !values.f_nan
if badsatx[0] ne -1 then tmpp.y[badsatx] = !values.f_nan
if badsaty[0] ne -1 then tmpp.y[badsaty] = !values.f_nan
if badsatz[0] ne -1 then tmpp.y[badsatz] = !values.f_nan
store_data, 'e_sp', data=tmpp

; Remove corotation electric field. 
dif_data, evar, rbspx + '_E_coro_mgse', newname=rbspx + '_efw_esvy_mgse_vxb_removed_coro_removed_spinfit'

; Grab the electric and magnetic fields and rotate them to GSE. 
get_data, rbspx + '_Lvec', data=wgse
wgse = wgse.y
rbsp_mgse2gse, rbspx + '_efw_esvy_mgse_vxb_removed_spinfit', wgse, newname='egse'
rbsp_mgse2gse, rbspx + '_mag_mgse', wgse, newname='bfield_gse'

; Interpolate magnetic field and position to match electric field time steps. 
tinterpol_mxn, 'bfield_gse', 'egse', newname='bgse'
tinterpol_mxn, rbspx + '_state_pos_gse', 'egse', newname='xgse'
tinterpol_mxn, rbspx + '_state_lshell', 'egse', newname='lshell'
tinterpol_mxn, rbspx + '_state_mlt', 'egse', newname='mlt'
tinterpol_mxn, rbspx + '_state_mlat', 'egse', newname='mlat'

; Grab final values, print out the properties of each, and save them. 
get_data, 'egse', time, egse
get_data, 'bgse', time, bgse
get_data, 'xgse', time, xgse
get_data, 'lshell', time, lshell
get_data, 'mlt', time, mlt
get_data, 'mlat', time, mlat

help, time, /st
help, egse, /st
help, bgse, /st
help, xgse, /st
help, lshell, /st
help, mlt, /st
help, mlat, /st

save, time, xgse, lshell, mlt, mlat, egse, bgse, filename='temp.sav'

;; -----------------------------------------------------------------------------
;; -------------------------------------------------------------------- Plotting
;; -----------------------------------------------------------------------------
;
;store_data, 'B2Bx_ratio', data={ x:edata.x, y:[ [By2Bx], [Bz2Bx] ] }
;!p.charsize = 1.2
;tplot_options, 'xmargin', [20., 15.]
;tplot_options, 'ymargin', [3, 6]
;tplot_options, 'xticklen', 0.08
;tplot_options, 'yticklen', 0.02
;tplot_options, 'xthick', 2
;tplot_options, 'ythick', 2
;tplot, rbspx + '_' + ['vxb_mgse', evar]
;ylim, 'B2Bx_ratio', 0, 10
;options, 'B2Bx_ratio', 'ytitle', 'By/Bx (black)!CBz/Bx (red)'
;options, 'rat', 'ytitle', '|Espinaxis|/!C|Espinplane|'
;options, 'e_sp', 'ytitle', '|Espinplane|'
;options, 'e_sa', 'ytitle', '|Espinaxis|'
;options, 'angles', 'ytitle', 'angle b/t Ey & Bo!CEz & Bo (red)'
;ylim, evar, -10, 10
;ylim, rbspx + '_mag_mgse', -200,200
;ylim, ['e_sa', 'e_sp', 'rat'], 0, 10
;options, evar, 'labels', ['xMGSE', 'yMGSE', 'zMGSE']
;tplot_options, 'title', 'RBSP-' + probe + ' ' + date
;tplot,[rbspx + '_mag_mgse', $
;       rbspx + '_mag_mgse_smoothed', $
;       rbspx + '_efw_esvy_mgse_vxb_removed_spinfit', $
;       rbspx + '_efw_esvy_mgse_vxb_removed_coro_removed_spinfit', $
;       rbspx + '_E_coro_mgse', $
;       'angles', $
;       'rat', $
;       'e_sa', $
;       'e_sp']
;if keyword_set(eu) then timebar, eu.x
;if keyword_set(eu) then timebar, eu.x + eu.y
;tplot,[rbspx + '_state_pos_gse','efield_spinfit_gse','bfield_gse']
;wait, 10


