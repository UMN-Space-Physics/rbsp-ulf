PRO overlay_map_precal_sdfov, site=site, geo_plot=geo_plot, nh=nh, sh=sh, $
  linethick=linethick, $
  fill=fill, $
  color=color 
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;nh_list = strsplit('bks brt cve cvw ekb fhe fhw gbr han hok inv kap kod ksr mge mgw pgr pyk rkn sas sto wal', /ext )
  nh_list = strsplit('bks cve cvw ekb fhe fhw gbr han hok how inv kap kod ksr pgr pyk rkn sas sto wal ade adw', /ext )
  sh_list = strsplit('fir hal ker mcm san sye sys tig unw zho', /ext )
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;Check the keywords and generate the station list to be plotted
  stns = ''
  if keyword_set(nh) then append_array, stns, nh_list
  if keyword_set(sh) then append_array, stns, sh_list
  if keyword_set(site) then append_array, stns, site 
  if stns[0] eq '' then return
  print, stns 
  
  if ~keyword_set(color) then color = 0 ;default color
  
  
  ;Initialize !sdarn system variable
  sd_init
  
  ;Prepare for AACGM conversion
  if ~keyword_set(geo_plot) then begin
    ts = time_struct( !sdarn.sd_polar.plot_time)
    yrsec = long( (ts.doy-1)*86400L + ts.sod )
    aacgmloadcoef, ts.year 
  endif
  
  ;Obtain the directory path where overlay_map_precal_sdfov.pro and save files are located.
  stack = SCOPE_TRACEBACK(/structure)
  filename = stack[SCOPE_LEVEL()-1].filename
  dir = FILE_DIRNAME(filename)
  
  for i=0, n_elements(stns)-1 do begin
    
    stn = stns[i]
    tblfn = dir +'/sdfovtbl_'+stn+'.sav
    if ~file_test(tblfn) then continue
    restore, tblfn 
    
    bm = n_elements( sdfovtbl.glat[*,0] )-1
    rg = n_elements( sdfovtbl.glat[0,*] )-1
    
    glats = [ sdfovtbl.glat[0:bm,0], reform(sdfovtbl.glat[bm,0:rg]), $
      reverse(sdfovtbl.glat[0:bm,rg]), reverse(reform(sdfovtbl.glat[0,0:rg])) ]
    glons = [ sdfovtbl.glon[0:bm,0], reform(sdfovtbl.glon[bm,0:rg]), $
      reverse(sdfovtbl.glon[0:bm,rg]), reverse(reform(sdfovtbl.glon[0,0:rg])) ]
    
    if keyword_set(geo_plot) then begin
      lats = glats & lons = glons 
    endif else begin
      ;AACGM conversion
      alt = glats & alt[*] = 400. ;[km]
      aacgmconvcoord, glats,glons,alt, mlats,mlons, err, /TO_AACGM
      years = long( glats ) & years[*] = ts.year 
      yrsecs = long( glats) & yrsecs[*] = yrsec
      mlts = aacgmmlt( years, yrsecs,  (mlons+360.) mod 360  )
      
      lats = mlats & lons = mlts /24. * 360.
    endelse
    
    ;Draw the f-o-v with the color given by "color" keyword
    plots, lons, lats, color=color, thick=linethick
    ;Fill the f-o-v with the color given by "color" keyword
    if keyword_set(fill) then polyfill, lons, lats, color=color
    
    
  endfor
  
   
  
  return
end
