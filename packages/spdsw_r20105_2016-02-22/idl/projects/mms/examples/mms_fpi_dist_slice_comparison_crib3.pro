
pro mms_draw_circle,x0,y0,r=r,fill=fill,_extra=extra
  if n_elements(r) eq 0. then r = 1.
  if n_elements(x0) eq 0. then x0 = 0.
  if n_elements(y0) eq 0. then y0 = 0.
  n = 101
  a = indgen(n)/float(n-1)*2*!pi
  oplot, x0 + r*cos(a), y0 + r*sin(a),_extra=extra
  if keyword_set(fill)then polyfill,  x0 + r*cos(a), y0 + r*sin(a),_extra=extra
end
start_time = systime(/sec)
;setup
;---------------------------------------------
probe='1'
read,'input probe #:',probe
if probe lt 1 or probe gt 4 then probe=1
read,'input 0 for FPI electrons, 1 for FPI ions:',ispecies
if ispecies eq 0 then species='e' else species='i'
olines=20
geometric = 0
read,'input 1 for geometric scaling or 0:', geometric
resolution=500
read,'input integer resolution (defaults:  2D/3D interpolation: 150, geometric: 500)',resolution
if resolution eq 0 and geometric eq 1 then resolution=500
if resolution eq 0 and geometric eq 0 then resolution=150

;subfolder of current directory to place images
folder = 'slice_test/'

trange = ['2015-09-1/12:20:09', '2015-09-1/12:20:09.05'] 

;load particle, field & support data
;---------------------------------------------
mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-dist', $
              probe=probe, trange=trange
mms_load_fgm, probe=probe, trange=trange, instrument='dfg'
mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-moms', $
              probe=probe, trange=trange

  
; b-field vector for data within the last 2 weeks (ql)
; bname = 'mms'+probe+'_dfg_srvy_gse_bvec'
; b-field vector for data older than 2 weeks ago (l2pre)
bname = 'mms'+probe+'_dfg_srvy_l2pre_gse_bvec'
vname = 'mms'+probe+'_d'+species+'s_bulk'
join_vec, vname + ['X','Y','Z'], vname

  
;convert particle data to 3D structures
;     'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;     'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;     'xy':  (default) The x axis is along the data's x axis and y is along the data's y axis
;     'xz':  The x axis is along the data's x axis and y is along the data's z axis
;     'yz':  The x axis is along the data's y axis and y is along the data's z axis
;     'xvel':  The x axis is along the data's x axis; the x-y plane is defined by the bulk velocity
;     'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)

;---------------------------------------------
name =  'mms'+probe+'_d'+species+'s_brstSkyMap_dist'
dist = mms_get_fpi_dist(name, trange=time_double(trange))
errname =  'mms'+probe+'_d'+species+'s_brstSkyMap_distErr'
distErr = mms_get_fpi_dist(errname, trange=time_double(trange))

get_data, 'mms'+probe+'_d'+species+'s_numberDensity', data=density_struct
get_data, 'mms'+probe+'_d'+species+'s_bulkX', data=vel_x
get_data, 'mms'+probe+'_d'+species+'s_bulkY', data=vel_y
get_data, 'mms'+probe+'_d'+species+'s_bulkZ', data=vel_z
get_data, 'mms'+probe+'_d'+species+'s_TempXX', data=tempXX
get_data, 'mms'+probe+'_d'+species+'s_TempXY', data=tempXY
get_data, 'mms'+probe+'_d'+species+'s_TempXZ', data=tempXZ
get_data, 'mms'+probe+'_d'+species+'s_TempYY', data=tempYY
get_data, 'mms'+probe+'_d'+species+'s_TempYZ', data=tempYZ
get_data, 'mms'+probe+'_d'+species+'s_TempZZ', data=tempZZ
get_data, 'mms'+probe+'_d'+species+'s_PresXX', data=presXX
get_data, 'mms'+probe+'_d'+species+'s_PresXY', data=presXY
get_data, 'mms'+probe+'_d'+species+'s_PresXZ', data=presXZ
get_data, 'mms'+probe+'_d'+species+'s_PresYY', data=presYY
get_data, 'mms'+probe+'_d'+species+'s_PresYZ', data=presYZ
get_data, 'mms'+probe+'_d'+species+'s_PresZZ', data=presZZ

;set slice orientation
; (x parallel to B, y defined by vbulk)
rotation = 'bv'

;normal vectors of slices to be produced
; (xy plane, xz pane, yz plane)
norms = [ [0,0,1], [0,1,0], [1,0,0] ]

; make sure data was loaded
if ~ptr_valid(dist) then stop ; should have thrown an error specifying no data within the range

;initialize window and get plot positions, axis limits
;---------------------------------------------
energyr = minmax((*dist).energy)
vr = 13.8*sqrt(energyr)
if species eq 'e' then vr = vr*sqrt(1836.109)
vmax = max(vr)
vmin = min(vr)
print,'velocity range in km/s:',vr
read,'input max |velocity| in km/s to plot, input 0. for autoscaling:',vmax
if vmax le min(vr) then vr=[0.,0.] else vr = [-1,1]*vmax
if species eq 'e' then zrange = [1.0e-29, 1.0e-25]  ;tmp guess for electrons
if species eq 'i' then zrange = [1.0e-25, 1.0e-21]  ;tmp guess for ions
 

   
win = 9
WINDOW,/free, XSIZE=1400, YSIZE=800, TITLE='MMS FPI Distributions'  
;nx = dimen2(norms)
nx = 4
ny = 3
arrange_plots,x0,y0,x1,y1,nx=nx,ny=ny,ygap=0.056,x1margin=0.1,$
  x0margin=0.1,y1margin=0.02,xgap=0.1,y0margin=0.08
              
;loop over time samples and slice orientations to create a set of plots at each sample
;used short window to ensure only a single sample is used
;OPTION: change to 2D interpolation for speed (uses data within 20 deg of plane)
;geometric interpolation is slow but shows bin boundaries

;---------------------------------------------
for i=0, n_elements(*dist)-1 do begin
  ipos=-1
  time = (*dist)[i].time
  end_time = (*dist)[i].end_time
  
  for j=0, 2 do begin
    ipos=ipos+1
    if j eq 2 then nocolorbar=0 else nocolorbar=1
    if j eq 0 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='xy', geometric=geometric, resolution=resolution)
    if j eq 1 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='xz', geometric=geometric, resolution=resolution)
    if j eq 2 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='yz', geometric=geometric, resolution=resolution)
    spd_slice2d_plot1, slice, window=win, xrange = vr, yrange = vr, zrange = zrange,$
      /custom, title='',charsize=1.15, pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],$
      noerase = ipos gt 0, nocolorbar = nocolorbar,olines=olines
    xyouts,/norm, align=1.0,x1[ipos]-(x1[ipos]-x0[ipos])/2.,y1[ipos]-0.05,'dist_PSD'
    mms_draw_circle,0.,0.,r=vmin,/fill  ;SAB, mask out interpolation below 10 eV
  endfor
  plot,[0,1],[0,1],/nodata,/noerase,pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],xstyle=5,ystyle=5
  ipos=ipos+1
  
  for j=0, 2 do begin
    ipos=ipos+1
    if j eq 2 then nocolorbar=0 else nocolorbar=1
    if j eq 0 then slice = spd_slice2d(distErr, time=time, window=end_time-time, rotation='xy', geometric=geometric, resolution=resolution)
    if j eq 1 then slice = spd_slice2d(distErr, time=time, window=end_time-time, rotation='xz', geometric=geometric, resolution=resolution)
    if j eq 2 then slice = spd_slice2d(distErr, time=time, window=end_time-time, rotation='yz', geometric=geometric, resolution=resolution)
    spd_slice2d_plot1, slice, window=win, xrange = vr, yrange = vr, zrange = zrange,$
      /custom, title='',charsize=1.15, pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],$
      noerase = ipos gt 0, nocolorbar = nocolorbar,olines=olines
    xyouts,/norm, align=1.0,x1[ipos]-(x1[ipos]-x0[ipos])/2.,y1[ipos]-0.05,'dist_Err'
    mms_draw_circle,0.,0.,r=vmin,/fill  ;SAB, mask out interpolation below 10 eV
  endfor
  plot,[0,1],[0,1],/nodata,/noerase,pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],xstyle=5,ystyle=5  
  ipos=ipos+1
 
  
;  for j=0, dimen2(norms)-1 do begin
;    ipos=ipos+1
;    if j eq dimen2(norms)-1 then nocolorbar=0 else nocolorbar=1
;    slice = spd_slice2d(dist, time=time, window=end_time-time, $
;      rotation=rotation, slice_norm=norms[*,j],  geometric=geometric, $
;      resolution=1000,$
;      mag_data=bname, vel_data=vname)
;    spd_slice2d_plot1, slice, window=win, xrange = vr, yrange = vr, zrange = zrange,$
;      /custom, title='',charsize=1.15, pos = [ x0[ipos], y0[ipos], x1[ipos], y1[ipos] ],$
;      noerase = ipos gt 0, nocolorbar=nocolorbar
;    mms_draw_circle,0.,0.,r=vmin,/fill  ;SAB, mask out interpolation below 10 eV 
;  endfor
;  plot,[0,1],[0,1],/nodata,/noerase,pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],xstyle=5,ystyle=5
;  ipos=ipos+1

  for j=0, 3 do begin
    ipos=ipos+1
    if j eq 3 then nocolorbar=0 else nocolorbar=1
    if j eq 0 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='BV', geometric=geometric, mag_data=bname, vel_data=vname, resolution=resolution) ;geometric interpolation
    if j eq 1 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='BE', geometric=geometric, mag_data=bname, vel_data=vname, resolution=resolution) ;geometric interpolation
    if j eq 2 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='perp', geometric=geometric, mag_data=bname, vel_data=vname, resolution=resolution) ;geometric interpolation
    if j eq 3 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='xvel', geometric=geometric, mag_data=bname, vel_data=vname, resolution=resolution) ;geometric interpolation
    spd_slice2d_plot1, slice, window=win, xrange = vr, yrange = vr, zrange = zrange,$
      /custom, title='',charsize=1.15, pos = [ x0[ipos], y0[ipos], x1[ipos], y1[ipos] ],$
      noerase = ipos gt 0, nocolorbar = nocolorbar
    xyouts,/norm, align=1.0,x1[ipos]-(x1[ipos]-x0[ipos])/2.,y1[ipos]-0.05,'dist_PSD'
    mms_draw_circle,0.,0.,r=vmin,/fill  ;SAB, mask out interpolation below 10 eV
  endfor
  plot,[0,1],[0,1],/nodata,/noerase,pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],xstyle=5,ystyle=5; plot,[0,1],[0,1],/nodata,/noerase,pos = [min(x0),min(y0[0]),max(x1),max(y1)],xstyle=5,ystyle=5


  plot,[0,1],[0,1],/nodata,/noerase,pos = [min(x0),min(y0[0]),max(x1),max(y1)],xstyle=5,ystyle=5    
  plot,[0,1],[0,1],/nodata,/noerase,pos = [0., 0.,1.,1.],xstyle=5,ystyle=5
  xyouts,/norm,0.02,0.01,'created by mms_slice_comparison_crib3.pro'

  ;place title
  xyouts, x0[0],y1[0]+0.025, align=0.0, charsize=1.5, /normal, $
    slice.project_name+slice.spacecraft+' '+slice.data_name+' '+ $
    time_string(time, tformat='YYYYMMDD hh:mm:ss.fff')+' -> '+ $
    time_string(end_time, tformat='hh:mm:ss.fff')

  ; moments closest to this time
  closest_time = find_nearest_neighbor(density_struct.X, time)
  closest_idx = where(density_struct.X eq closest_time)
  density_at_this_time = density_struct.Y[closest_idx]
  
  ; bulk velocity closest to this time
  closest_time_x = find_nearest_neighbor(vel_x.X, time)
  closest_idx_x = where(vel_x.X eq closest_time_x)
  closest_time_y = find_nearest_neighbor(vel_y.X, time)
  closest_idx_y = where(vel_y.X eq closest_time_y)
  closest_time_z = find_nearest_neighbor(vel_z.X, time)
  closest_idx_z = where(vel_z.X eq closest_time_z)
  
  ; plot density
  xyouts, 0.85, 0.9, align=0.5, charsize=1.5, /normal, 'Density: '+$
    strcompress(string(density_at_this_time),/rem) + ' [cm^-3]'
  
  ; plot temperature tensor
  xyouts, 0.85, 0.85, align=0.5, charsize=1.5, /normal, 'Txx: '+strcompress(string(tempXX.Y[closest_idx_x]),/rem)+'  Tyy: '+strcompress(string(tempYY.Y[closest_idx_x]),/rem)
  xyouts, 0.85, 0.80, align=0.5, charsize=1.5, /normal, 'Txy: '+strcompress(string(tempXY.Y[closest_idx_x]),/rem)+'  Tyz: '+strcompress(string(tempYZ.Y[closest_idx_x]),/rem)
  xyouts, 0.85, 0.75, align=0.5, charsize=1.5, /normal, 'Txz: '+strcompress(string(tempXZ.Y[closest_idx_x]),/rem)+'  Tzz: '+strcompress(string(tempZZ.Y[closest_idx_x]),/rem)
  
  ; plot pressure tensor
  xyouts, 0.85, 0.7, align=0.5, charsize=1.5, /normal, 'Pxx: '+strcompress(string(presXX.Y[closest_idx_x]),/rem)+'  Pyy: '+strcompress(string(presYY.Y[closest_idx_x]),/rem)
  xyouts, 0.85, 0.65, align=0.5, charsize=1.5, /normal, 'Pxy: '+strcompress(string(presXY.Y[closest_idx_x]),/rem)+'  Pyz: '+strcompress(string(presYZ.Y[closest_idx_x]),/rem)
  xyouts, 0.85, 0.6, align=0.5, charsize=1.5, /normal, 'Pxz: '+strcompress(string(presXZ.Y[closest_idx_x]),/rem)+'  Pzz: '+strcompress(string(presZZ.Y[closest_idx_x]),/rem)
  
    
  ; plot components of bulk velocity   
  xyouts, 0.85, 0.55, align=0.5, charsize=1.5, /normal, slice.data_name + ' bulk velocity'
  xyouts, 0.85, 0.50, align=0.5, charsize=1.5, /normal, 'Vx: '+$
    strcompress(string(vel_x.Y[closest_idx_x]),/rem) + ' [km/s]'
  xyouts, 0.85, 0.45, align=0.5, charsize=1.5, /normal, 'Vy: '+$
    strcompress(string(vel_y.Y[closest_idx_y]),/rem) + ' [km/s]'
  xyouts, 0.85, 0.40, align=0.5, charsize=1.5, /normal, 'Vz: '+$
    strcompress(string(vel_z.Y[closest_idx_z]),/rem) + ' [km/s]'

  ;write png
  makepng, folder+'mms'+probe+'_'+species+'_'+rotation+'_'+ $
           time_string(time, tformat='YYYYMMDD_hhmmss.fff'), $
           /mkdir

endfor
print, 'took: ' + string(systime(/seconds)-start_time) + ' seconds to run'
end