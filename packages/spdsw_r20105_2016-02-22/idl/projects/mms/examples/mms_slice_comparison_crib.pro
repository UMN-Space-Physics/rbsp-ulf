


;subfolder of current directory to place images
folder = 'slice_test/'

probe='3'
species='e'
;timespan,'2015-09-21/13:52', 2, /min
;trange = timerange()
;trange = ['2015-09-19/09:08:13', '2015-09-19/09:09']
;trange = ['2015-09-19/09:08:48', '2015-09-19/09:09:00']
trange = ['2015-09-19/09:08:00', '2015-09-19/09:08:15']
level = 'l1b'

;load particle & support data
mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-dist', $
              probe=probe, trange=trange
mms_load_dfg, probe=probe, trange=trange
mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-moms', $
              probe=probe, trange=trange
; b-field vector for data within the last 2 weeks (ql)
; bname = 'mms'+probe+'_dfg_srvy_gse_bvec'
; b-field vector for data older than 2 weeks ago (l2pre)
bname = 'mms'+probe+'_dfg_srvy_l2pre_gse_bvec'
vname = 'mms'+probe+'_d'+species+'s_bulk'
join_vec, vname + ['X','Y','Z'], vname


;convert particle data to 3D structures
name =  'mms'+probe+'_d'+species+'s_brstSkyMap_dist'
dist = mms_get_fpi_dist(name, trange=time_double(trange), probe=probe, species=species, data_rate='brst', level=level)


;set slice orientation
; (x parralel to B, y defined by vbulk)
rotation = 'bv'

;normal vectors of slices to be produced
; (xy plane, xz pane, yz plane)
norms = [ [0,0,1.], [0,1,0], [1,0,0] ]


;initialize window and get plot positions
win = 2
window, win, xs=1200, ys=400

nx = dimen2(norms)
ny = 1
arrange_plots,x0,y0,x1,y1,nx=nx,ny=ny, $
              ygap=0.08, xgap=0.14, $
              x0margin=0.08, x1margin=0.01,$
              y0margin=0.25, y1margin=0.01


;loop over time samples and slice orientations to create
;a set of plots at each sample
for i=0, n_elements(*dist)-1 do begin

  time = (*dist)[i].time
  end_time = (*dist)[i].end_time

  for j=0, dimen2(norms)-1 do begin
    
    ;use short window to ensure only a single sample is used
    ;use 2D interpolation for speed (uses data within 20 deg of plane)
    slice = spd_slice2d(dist, time=time, window=end_time-time, $
                     rotation=rotation, slice_norm=norms[*,j], /geometric, $
                     mag_data=bname, vel_data=vname)

    spd_slice2d_plot, slice, window=win, $
                 zrange = [1.0e-31, 1.0e-26],$ ;#'s optimized for des for 0815
                 /custom, $ ;suppress automatic window formatting
                 title='', $ ;supress title
                 zprecision = 1, $ ;shorted z axis annotations
                 pos = [ x0[j], y0[j], x1[j], y1[j] ], $
                 noerase = j gt 0

  endfor

  ;place title
  xyouts, 0.5, 0.95, align=0.5, charsize=1.5, /normal, $
    slice.project_name+slice.spacecraft+' '+slice.data_name+' '+ $
    time_string(time, tformat='YYYYMMDD_hhmmss.fff')+' > '+ $ 
    time_string(end_time, tformat='hhmmss.fff')

  ;write png
  makepng, folder+'mms'+probe+'_'+species+'_'+rotation+'_'+ $
           time_string(time, tformat='YYYYMMDD_hhmmss.fff'), $
           /mkdir

endfor



end