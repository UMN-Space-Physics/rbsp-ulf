;+
; MMS FPI crib sheet
; 
; do you have suggestions for this crib sheet?  
;   please send them to egrimes@igpp.ucla.edu
; 
; 
; 
; HISTORY:
;     8/28/15: added modifications from Barbara Giles
; 
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-15 08:50:35 -0800 (Fri, 15 Jan 2016) $
; $LastChangedRevision: 19745 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_load_fpi_crib.pro $
;-
timespan, '2015-08-15', 1, /day

probe = '4'

datatype = '*' ; grab all data in the CDF
level = 'sitl'
data_rate = 'fast'
autoscale = 1

mms_load_fpi, trange = trange, probes = probe, datatype = datatype, $
  level = level, data_rate = data_rate, $
  local_data_dir = local_data_dir, source = source, $
  get_support_data = get_support_data, $
  tplotnames = tplotnames, no_color_setup = no_color_setup

prefix = 'mms'+strcompress(string(probe), /rem)
; combine bent pipe B DSC into a single tplot variable
join_vec, prefix+['_fpi_bentPipeB_X_DSC', '_fpi_bentPipeB_Y_DSC', '_fpi_bentPipeB_Z_DSC'], prefix+'_fpi_bentPipeB_DSC'
options, prefix+'_fpi_bentPipeB_DSC', 'labels', ['Bx', 'By', 'Bz']
options, prefix+'_fpi_bentPipeB_DSC', 'labflag', -1
options, prefix+'_fpi_bentPipeB_DSC', 'colors', [2, 4, 6]

; combine electron energy spectra into a pair of tplot variables
get_data, prefix+'_fpi_eEnergySpectr_pX', data=pX
get_data, prefix+'_fpi_eEnergySpectr_mX', data=mX
get_data, prefix+'_fpi_eEnergySpectr_pY', data=pY
get_data, prefix+'_fpi_eEnergySpectr_mY', data=mY
get_data, prefix+'_fpi_eEnergySpectr_pZ', data=pZ
get_data, prefix+'_fpi_eEnergySpectr_mZ', data=mZ
e_omni_sum=(pX.Y+mX.Y+pY.Y+mY.Y+pZ.Y+mZ.Y)
e_omni_avg=e_omni_sum/6.
store_data, prefix+'_fpi_eEnergySpectr_omni_sum', data = {x:pX.X, y:e_omni_sum, v:pX.V}
store_data, prefix+'_fpi_eEnergySpectr_omni_avg', data = {x:pX.X, y:e_omni_avg, v:pX.V}

options, prefix+'_fpi_eEnergySpectr_omni_sum', spec=1, ylog=1, zlog=1
options, prefix+'_fpi_eEnergySpectr_omni_avg', spec=1, ylog=1, zlog=1

; combine ion energy spectra into a pair of tplot variables
get_data, prefix+'_fpi_iEnergySpectr_pX', data=pX
get_data, prefix+'_fpi_iEnergySpectr_mX', data=mX
get_data, prefix+'_fpi_iEnergySpectr_pY', data=pY
get_data, prefix+'_fpi_iEnergySpectr_mY', data=mY
get_data, prefix+'_fpi_iEnergySpectr_pZ', data=pZ
get_data, prefix+'_fpi_iEnergySpectr_mZ', data=mZ
i_omni_sum=(pX.Y+mX.Y+pY.Y+mY.Y+pZ.Y+mZ.Y)
i_omni_avg=i_omni_sum/6.
store_data, prefix+'_fpi_iEnergySpectr_omni_sum', data = {x:pX.X, y:i_omni_sum, v:pX.V}
store_data, prefix+'_fpi_iEnergySpectr_omni_avg', data = {x:pX.X, y:i_omni_avg, v:pX.V}

; combine electron PAD into one tplot variables
get_data, prefix+'_fpi_ePitchAngDist_lowEn', data=lowEn
get_data, prefix+'_fpi_ePitchAngDist_midEn', data=midEn
get_data, prefix+'_fpi_ePitchAngDist_highEn', data=highEn
e_PAD_sum=(lowEn.Y+midEn.Y+highEn.Y)
e_PAD_avg=e_PAD_sum/3.
store_data, prefix+'_fpi_ePitchAngDist_sum', data = {x:lowEn.X, y:e_PAD_sum, v:lowEn.V}
store_data, prefix+'_fpi_ePitchAngDist_avg', data = {x:lowEn.X, y:e_PAD_avg, v:lowEn.V}


espec_omni = prefix+['_fpi_eEnergySpectr_omni_sum','_fpi_eEnergySpectr_omni_avg', $
              '_fpi_iEnergySpectr_omni_sum','_fpi_iEnergySpectr_omni_avg']
electron_espec = prefix+['_fpi_eEnergySpectr_pX', '_fpi_eEnergySpectr_mX',$
                  '_fpi_eEnergySpectr_pY', '_fpi_eEnergySpectr_mY',$
                  '_fpi_eEnergySpectr_pZ', '_fpi_eEnergySpectr_mZ']
ion_espec = prefix+['_fpi_iEnergySpectr_pX', '_fpi_iEnergySpectr_mX', $
                  '_fpi_iEnergySpectr_pY', '_fpi_iEnergySpectr_mY', $
                  '_fpi_iEnergySpectr_pZ', '_fpi_iEnergySpectr_mZ']
e_pad = prefix+['_fpi_ePitchAngDist_lowEn', '_fpi_ePitchAngDist_midEn', $
          '_fpi_ePitchAngDist_highEn', '_fpi_ePitchAngDist_sum',  $
          '_fpi_ePitchAngDist_avg'] 
                        
options, electron_espec, spec=1, zlog=1, no_interp=1 
options, ion_espec, spec=1, zlog=1, no_interp=1
options, espec_omni, spec=1, zlog=1, ylog=1, no_interp=1
options, e_pad, spec=1, zlog=1, no_interp=1
if autoscale eq 0 then zlim, electron_espec, .1, 10000
if autoscale eq 0 then zlim, ion_espec, .1, 10000
ylim, electron_espec, 0, 0, 1
ylim, ion_espec, 0, 0, 1

tplot_options,'xmargin',[15,10]              ; Set left/right margins to 10 characters
;tplot_options,'ymargin',[4,2]                ; Set top/bottom margins to 4/2 lines

window, 0
window_caption="Electron energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
tplot_options,'title', window_caption
tplot, electron_espec, window=0
tprint, "electron_espec"

window, 1
window_caption="Ion energy spectra:  Counts, summed over DSC velocity-dirs +/- X, Y, & Z"
tplot_options,'title', window_caption
tplot, ion_espec, window=1
tprint, "ion_espec"

window, 2
window_caption="Energy spectra:  Counts, summed/averaged over all directions
tplot_options,'title', window_caption
tplot, espec_omni, window=2
tprint, "espec_omni"

window, 3
window_caption="Electron PAD:  Counts, summed/averaged over energy bands
tplot_options,'title', window_caption
tplot, e_pad, window=3
tprint, "e_pad"
      
; plot the moments
; combine the densities into a single tplot variable
join_vec, prefix+['_fpi_DESnumberDensity', '_fpi_DISnumberDensity'], prefix+'_fpi_numberDensity'
options, prefix+'_fpi_numberDensity', 'labels', ['electrons', 'ions']
options, prefix+'_fpi_numberDensity', 'labflag', -1
options, prefix+'_fpi_numberDensity', 'colors', [2, 4]


; combine the bulk electron velocity into a single tplot variable
join_vec, prefix+['_fpi_eBulkV_X_DSC', '_fpi_eBulkV_Y_DSC', $
  '_fpi_eBulkV_Z_DSC'], prefix+'_fpi_eBulkV_DSC'
options, prefix+'_fpi_eBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz']
options, prefix+'_fpi_eBulkV_DSC', 'labflag', -1
options, prefix+'_fpi_eBulkV_DSC', 'colors', [2, 4, 6]


; combine the bulk ion velocity into a single tplot variable
join_vec, prefix+['_fpi_iBulkV_X_DSC', '_fpi_iBulkV_Y_DSC', $
           '_fpi_iBulkV_Z_DSC'], prefix+'_fpi_iBulkV_DSC'
options, prefix+'_fpi_iBulkV_DSC', 'labels', ['Vx', 'Vy', 'Vz']
options, prefix+'_fpi_iBulkV_DSC', 'labflag', -1
options, prefix+'_fpi_iBulkV_DSC', 'colors', [2, 4, 6]


; combine the parallel and perpendicular temperature for DES into a single tplot variable
join_vec, prefix+['_fpi_DEStempPara', '_fpi_DEStempPerp'], prefix+'_fpi_DEStemp'
options, prefix+'_fpi_DEStemp', 'labels', ['Tpara', 'Tperp']
options, prefix+'_fpi_DEStemp', 'labflag', -1
options, prefix+'_fpi_DEStemp', 'colors', [2, 4]


; combine the parallel and perpendicular temperature for DIS into a single tplot variable
join_vec, prefix+['_fpi_DIStempPara', '_fpi_DIStempPerp'], prefix+'_fpi_DIStemp'
options, prefix+'_fpi_DIStemp', 'labels', ['Tpara', 'Tperp']
options, prefix+'_fpi_DIStemp', 'labflag', -1
options, prefix+'_fpi_DIStemp', 'colors', [2, 4]

fpi_moments = prefix+['_fpi_numberDensity','_fpi_eBulkV_DSC', '_fpi_iBulkV_DSC', $
                      '_fpi_DEStemp','_fpi_DIStemp', '_fpi_bentPipeB_DSC']
 
window, 4
window_caption="FPI Moments: Density, BulkV, Temp, Bent pipe B"
tplot_options,'title', window_caption
tplot, fpi_moments, window=4
tprint, "fpi_moments"
stop
end