;To arrange 3D data from the structure of data[time,phi,theta,energy]
;to data[time,phi and theta, energy], for the whole interval loaded in
;the tplot variable
;The tplot variable from the 3D counts file is required to be loaded
;in advance
;update history
;10/19/2015 store parity table, get_fpi_3dflux_2dbin.pro will set the
;energy table according to the parity
Pro fpi_3dflux_2dbin,sat,specie,resolution=resolution,rmsun=rmsun,$
    units_name=units_name,thebdata=thebdata,scp=scp

sat_str=string(sat,format='(I1)')
if ~keyword_set(resolution) then resolution='fast'
if ~keyword_set(units_name) then units_name='counts'
case strlowcase(units_name) of
  'counts':units_str='cnts'
  'df':units_str='dist'
endcase 
varname='mms'+sat_str+'_d'+specie+'s_'+resolution+'SkyMap_'+units_str

if ~keyword_set(thebdata) then $
  ;thebdata='mms'+sat_str+'_d'+specie+'s_bentPipeB_DSC_rmsunpulse'
  thebdata = 'mms'+sat_str+'_dfg_srvy_l2pre_dmpa_xyz'
;tplot_names,thebdata,names=nb
;if ~keyword_set(nb) then thebdata='mms'+sat_str+'_dfg_srvy_dmpa_xyz'
get_data,thebdata,data=ddb

get_data,varname,data=dd
get_timespan,t
ind=where(dd.x ge t[0] and dd.x le t[1],cnt)
d={x:dd.x[ind],y:dd.y[ind,*,*,*]}

get_data,'mms'+sat_str+'_d'+specie+'s_stepTable_parity',data=dparity
parity = dparity.y[ind]

magf= fltarr(cnt,3)
dt = dd.x[ind[1]] - dd.x[ind[0]]
for it=0,cnt-1 do begin
  ind1=where(ddb.x ge dd.x[ind[it]] and ddb.x lt dd.x[ind[it]]+dt,cc)
  if cc eq 0 then begin
    ;print,'B data not available at time '+time_string(d.x[it],precision=3)
    ;print,'interpolate..'
    magf[it,0]=interpol(ddb.y[*,0], ddb.x, dd.x[ind[it]]+0.5*dt)
    magf[it,1]=interpol(ddb.y[*,1], ddb.x, dd.x[ind[it]]+0.5*dt)
    magf[it,2]=interpol(ddb.y[*,2], ddb.x, dd.x[ind[it]]+0.5*dt)
    continue
  endif
  magf[it,0]=mean(ddb.y[ind1,0],/nan)
  magf[it,1]=mean(ddb.y[ind1,1],/nan)
  magf[it,2]=mean(ddb.y[ind1,2],/nan)
endfor


name_scp = 'mms'+sat_str+'_edp_scpot'
tplot_names,name_scp,names=name_scp
if keyword_set(name_scp) then begin
  interpolate,varname,name_scp,name_scp+'_interp'
  get_data,name_scp+'_interp',data=dscp
  scp = dscp.y[ind]
endif else begin
  scp = fltarr(cnt)
  dprint,'Warning: no scp data are loaded, scp is set to be zero'
endelse

yy=d.y
size = size(yy)
;size[1]: time, size[2]: phi, size[3]: theta, size[4]:energy
d1=reform(yy,size[1],size[2]*size[3],size[4])
d2=transpose(d1)

del_phi = 360./size[2]
del_theta = 180./size[3]
one_en = fltarr(size[4])+1
one_phi = fltarr(size[2])+1
one_theta = fltarr(size[3])+1

if keyword_set(rmsun) then rmang=-76.0 else rmang=0.0
phi0 = findgen(size[2])*del_phi-180. + rmang+0.5*del_phi
;-180- 180, remove sunpulse
theta0 = -(90.0-findgen(size[3])*del_theta-0.5*del_theta)
;-90-90

phi1 = reform(phi0#one_theta,size[2]*size[3])
phi = one_en#phi1
theta1 = reform(one_phi#theta0,size[2]*size[3])
theta = one_en#theta1

dphi = replicate(del_phi,size[4],size[2]*size[3])
dtheta = replicate(del_theta,size[4],size[2]*size[3])

IF 0 THEN BEGIN
;average energy table
if specie eq 'i' then begin
  energy = [11.32541789,14.54730661,18.68576787,24.00155096,$
     30.82958391,39.60007608, 50.86562406, 65.33602881,$
     83.92301755, 107.7976884,138.4642969, 177.8550339,$
     228.4517655,293.4424065,376.9217793,484.1496135,$
     621.8819424,798.7967759,1026.04087,1317.932043,$
     1692.861289,2174.451528,2793.045997,3587.62007,$
     4608.236949,5919.201968,7603.114233,9766.070893,$
     12544.35193,16113.00665,20696.88294,26584.79405]
endif
if specie eq 'e' then begin
  energy = [11.66161217,14.95286673,19.17301144,$
    24.58420677, 31.52260272, 40.41922083,51.82672975,$
    66.45377773,85.20901465, 109.2575384,140.0932726,$
    179.63177, 230.3292099, 295.3349785, 378.6873127,$
    485.5641602, 622.6048397, 798.322484, 1023.632885,$
    1312.532598, 1682.968421, 2157.952275, 2766.99073,$
    3547.917992, 4549.246205, 5833.179086, 7479.476099,$
    9590.4072, 12297.10598, 15767.71584, 20217.83525,$
    25923.91101]
endif
loge = alog10(energy)
del_v = replicate(loge[1]-loge[0],size[4])
denergy = energy*del_v/alog10(exp(1))
ENDIF



one_bins = fltarr(size[2]*size[3])+1
;energy = energy#one_bins
;denergy = denergy#one_bins
bins = replicate(1,size[4],size[2]*size[3])

if specie eq 'e' then begin
   mass = 9.1e-31*6.2508206e24
   charge = -1
endif
if specie eq 'i' then begin
   mass = 1.67e-27*6.2508206e24
   charge = 1
endif
delta_t = -ts_diff(d.x,1)
delta_t[size[1]-1] = delta_t[size[1]-2]
integ_t = delta_t/size[4]
delta_t=delta_t[0]
integ_t=integ_t[0]
geom_factor = bins

dt_arr = bins
eff = bins
gf = bins*0.002
dead=1.7e-7

store_data,varname+'_2dbin',$
           data={spacecraft:sat,$
                 project_name: 'MMS',$
                 data_name: varname,$;*
                 units_name:units_name,$
                 ;units_procedure: 'mms_fpi_convert_units',$;*
                 valid: 1,$;*
                 time:d.x,$
                 end_time: d.x+delta_t,$;*
                 delta_t: delta_t,$;*
                 integ_t: integ_t,$;*
                 dt_arr: dt_arr,$;*
                 geom_factor: geom_factor,$;*
                 gf: gf,$;*
                 eff:eff,$;*
                 nenergy: size[4],$
                 nbins: size[2]*size[3],$
                 bins: bins,$
                 ;energy: energy,$
                 ;denergy: denergy,$
                 parity: parity,$
                 theta: theta,$
                 phi: phi,$
                 dtheta: dtheta,$
                 dphi: dphi,$
                 data: d2,$
                 ;dead: dead,$;*
                 mass: mass,$;*
                 charge: charge,$
                 magf:magf,$
                 sc_pot:scp};*
;entries with * at the end may need modifications later
tplot_names,varname+'_2dbin.*',names=names
store_data,names,/del

END
