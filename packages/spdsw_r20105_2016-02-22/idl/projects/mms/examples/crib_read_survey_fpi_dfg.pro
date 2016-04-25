mms_init

;device,true=24,decompose=0,retain=2
;loadct,39


;timespan,'2015-10-05/11:40',7,/min

;timespan,'2015-09-30/16:40',4,/min

;timespan,'2015-09-19/09:59', 15, /min

;timespan,'2015-08-15/0:', 24, /hour

timespan,'2015-10-03/0:', 24, /hour

;timespan,'2015-09-19/0:', 24, /hour

;timespan,'2015-10-16/0:', 24, /hour ; Df candidate

probe_id=1


sc_id='mms'+string(probe_id,format='(I1)')

mms_load_fpi, probes=probe_id, level='sitl', data_rate='fast'

mms_load_dfg, probes=probe_id, level='ql', data_rate='brst', /no_attitude_data 

;mms_load_data, instrument='fpi',probes=probe_id, level='sitl', data_rate='fast'
mms_load_data, instrument='dfg',probes=probe_id, datatype='',  data_rate='srvy'; 7 samples/s
mms_load_data, instrument='edp',probes=probe_id, level='ql', data_rate='fast', datatype='dce'

;mms_load_data, instrument='dfg',probes=probe_id, datatype='', level='l2pre', data_rate='brst'; 128 samples/s

;copy_data,sc_id+'_dfg_brst_l2pre_dmpa','B_burst'
copy_data,sc_id+'_dfg_brst_dmpa_bvec','B_burst'
copy_data,sc_id+'_dfg_brst_dmpa_btot','Bmag_burst'
copy_data,sc_id+'_fpi_DISnumberDensity','Ni'
copy_data,sc_id+'_fpi_DESnumberDensity','Ne'
copy_data,sc_id+'_fpi_iBulkV_X_DSC','Vix'
copy_data,sc_id+'_fpi_iBulkV_Y_DSC','Viy'
copy_data,sc_id+'_fpi_iBulkV_Z_DSC','Viz'
copy_data,sc_id+'_fpi_eBulkV_X_DSC','Vex'
copy_data,sc_id+'_fpi_eBulkV_Y_DSC','Vey'
copy_data,sc_id+'_fpi_eBulkV_Z_DSC','Vez'
copy_data,sc_id+'_edp_dce_xyz_dsl','E'
copy_data,sc_id+'_dfg_srvy_dmpa','B'

;get_data,'B_burst',data=d ; to use as marker for when burst data are available
;store_data,'B_burst',data={x:d.x-0.00390625d,y:d.y(*,0:2)}
;store_data,'Bmag_burst',data={x:d.x-0.00390625d,y:d.y(*,3)}

get_data,'B',data=d
store_data,'B',data={x:d.x-0.00390625d,y:d.y(*,0:2)}


get_data,'B',data=d
store_data,'B_mag',data={x:d.x,y:sqrt(d.y(*,0)^2+d.y(*,1)^2+d.y(*,2)^2)}
get_data,'B_mag',data=d2

index=where(d.y gt 100 or d.y lt -100)
if (index(0) ne -1) then d.y(index)=float('NaN')
store_data,'B',data=d

index=where(d2.y gt 100)
if (index(0) ne -1) then d2.y(index)=float('NaN')
store_data,'B_mag',data=d2

options, 'B', labels=['B!DX!N', 'B!DY!N', 'B!DZ!N']
options, 'B', 'labflag',-1

get_data,'Vix',data=vix
get_data,'Viy',data=viy
get_data,'Viz',data=viz
vi=fltarr(n_elements(vix.x),3)
vi(*,0)=vix.y
vi(*,1)=viy.y
vi(*,2)=viz.y
store_data,'vi',data={x:vix.x,y:vi}
store_data,'vi_mag',data={x:vix.x,y:sqrt(vi(*,0)^2+vi(*,1)^2+vi(*,2)^2)}

get_data,'Vex',data=vex
get_data,'Vey',data=vey
get_data,'Vez',data=vez
ve=fltarr(n_elements(vex.x),3)
ve(*,0)=vex.y
ve(*,1)=vey.y
ve(*,2)=vez.y
store_data,'ve',data={x:vex.x,y:ve}
store_data,'ve_mag',data={x:vex.x,y:sqrt(ve(*,0)^2+ve(*,1)^2+ve(*,2)^2)}

; combine the perp and parallel temperatures into a single tplot variable
join_vec,  [sc_id+'_fpi_DEStempPara', $
        sc_id+'_fpi_DEStempPerp'], sc_id+'_fpi_DEStemp'

options, sc_id+'_fpi_DEStemp', 'colors', [6,2]

; combine the perp and parallel temperatures into a single tplot variable
join_vec,  [sc_id+'_fpi_DIStempPara', $
        sc_id+'_fpi_DIStempPerp'], sc_id+'_fpi_DIStemp'

options, sc_id+'_fpi_DIStemp', 'colors', [6,2]

; combine ion and electron densities into a single tplot variable
join_vec,  [sc_id+'_fpi_DISnumberDensity', $
        sc_id+'_fpi_DESnumberDensity'], sc_id+'_fpi_numberDensity'

options, sc_id+'_fpi_numberDensity', 'colors', [2,6]
store_data,'v_mag',data=['Vi_mag','Ve_mag']
options,'v_mag','colors',[2,6]

store_data,'N',data=['Ni','Ne']
options,'N','colors',[2,6]

store_data,'v_mag',data=['vi_mag','ve_mag']
options,'ve_mag','colors',6
ylim,'v_mag',0,500,0

ylim,'vi',-400,400,0
ylim,'ve',-400,400,0
ylim,sc_id+'_fpi_DIStemp',0,0,1
ylim,sc_id+'_fpi_DEStemp',0,0,1

options,'Bmag_burst','psym',2 ; Marker for when burst data are available
options,'Bmag_burst','symsize',0.02 ; Marker for when burst data are available
options,'Bmag_burst','panel_size',1

get_data,'E',data=d
store_data,'Exy',data={x:d.x,y:d.y(*,0:1)}

options,'Exy',colors=[2,4]

if sc_id eq 'mms1' then begin

calc, ' "mms1_fpi_iEnergySpectr_omni" = ("mms1_fpi_iEnergySpectr_mX" + "mms1_fpi_iEnergySpectr_mY" + "mms1_fpi_iEnergySpectr_mZ"+"mms1_fpi_iEnergySpectr_pX" + "mms1_fpi_iEnergySpectr_pY" + "mms1_fpi_iEnergySpectr_pZ")/6. '

calc, ' "mms1_fpi_eEnergySpectr_omni" = ("mms1_fpi_eEnergySpectr_mX" + "mms1_fpi_eEnergySpectr_mY" + "mms1_fpi_eEnergySpectr_mZ"+"mms1_fpi_eEnergySpectr_pX" + "mms1_fpi_eEnergySpectr_pY" + "mms1_fpi_eEnergySpectr_pZ")/6. '

endif

if sc_id eq 'mms2' then begin

calc, ' "mms2_fpi_iEnergySpectr_omni" = ("mms2_fpi_iEnergySpectr_mX" + "mms2_fpi_iEnergySpectr_mY" + "mms2_fpi_iEnergySpectr_mZ"+"mms2_fpi_iEnergySpectr_pX" + "mms2_fpi_iEnergySpectr_pY" + "mms2_fpi_iEnergySpectr_pZ")/6. '

calc, ' "mms2_fpi_eEnergySpectr_omni" = ("mms2_fpi_eEnergySpectr_mX" + "mms2_fpi_eEnergySpectr_mY" + "mms2_fpi_eEnergySpectr_mZ"+"mms2_fpi_eEnergySpectr_pX" + "mms2_fpi_eEnergySpectr_pY" + "mms1_fpi_eEnergySpectr_pZ")/6. '

endif

if sc_id eq 'mms3' then begin

calc, ' "mms3_fpi_iEnergySpectr_omni" = ("mms3_fpi_iEnergySpectr_mX" + "mms3_fpi_iEnergySpectr_mY" + "mms3_fpi_iEnergySpectr_mZ"+"mms3_fpi_iEnergySpectr_pX" + "mms3_fpi_iEnergySpectr_pY" + "mms3_fpi_iEnergySpectr_pZ")/6. '

calc, ' "mms3_fpi_eEnergySpectr_omni" = ("mms3_fpi_eEnergySpectr_mX" + "mms3_fpi_eEnergySpectr_mY" + "mms3_fpi_eEnergySpectr_mZ"+"mms3_fpi_eEnergySpectr_pX" + "mms3_fpi_eEnergySpectr_pY" + "mms3_fpi_eEnergySpectr_pZ")/6. '

endif

if sc_id eq 'mms4' then begin

calc, ' "mms4_fpi_iEnergySpectr_omni" = ("mms4_fpi_iEnergySpectr_mX" + "mms4_fpi_iEnergySpectr_mY" + "mms4_fpi_iEnergySpectr_mZ"+"mms4_fpi_iEnergySpectr_pX" + "mms4_fpi_iEnergySpectr_pY" + "mms4_fpi_iEnergySpectr_pZ")/6. '

calc, ' "mms4_fpi_eEnergySpectr_omni" = ("mms4_fpi_eEnergySpectr_mX" + "mms4_fpi_eEnergySpectr_mY" + "mms4_fpi_eEnergySpectr_mZ"+"mms4_fpi_eEnergySpectr_pX" + "mms4_fpi_eEnergySpectr_pY" + "mms4_fpi_eEnergySpectr_pZ")/6. '

endif

  options, sc_id+'_fpi_iEnergySpectr_omni', 'spec', 1 ; 1= spectrogram, 0= line plot
  options, sc_id+'_fpi_iEnergySpectr_omni', 'no_interp', 1
  options, sc_id+'_fpi_iEnergySpectr_omni', 'ytitle', 'ion E, eV' ; define y label. tplot name used if not defined.

; define y axis limits (optional)
  ylim, sc_id+'_fpi_iEnergySpectr_omni', 10, 26000,1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear y axis
; define color range limits (optional)
  zlim, sc_id+'_fpi_iEnergySpectr_omni', 0, 0, 1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear
;  zlim, sc_id+'_fpi_iEnergySpectr_omni', .1, 2000, 1 ; or 0,0,1 if auto-scaling (log) and 0,0,0 for linear
  options, sc_id+'_fpi_eEnergySpectr_omni', 'spec', 1
  options, sc_id+'_fpi_eEnergySpectr_omni', 'no_interp', 1
  options, sc_id+'_fpi_eEnergySpectr_omni', 'ytitle', 'Electron E, eV'
  ylim, sc_id+'_fpi_eEnergySpectr_omni', 10, 26000, 1 ; the 3rd number specifies log (1) or linear (0) scale
  zlim, sc_id+'_fpi_eEnergySpectr_omni', 0,0, 1 ; the 3rd number specifies log (1) or linear (0) scale


tplot,['B','Bmag_burst','B_mag',sc_id+'_fpi_iEnergySpectr_omni',sc_id+'_fpi_eEnergySpectr_omni',sc_id+'_fpi_numberDensity','vi','ve','v_mag','Exy',sc_id+'_fpi_DIStemp',sc_id+'_fpi_DEStemp'],title=sc_id

;tplot,['N','v_mag','vi','ve','E','B','B_i','B_e']

stop

end


