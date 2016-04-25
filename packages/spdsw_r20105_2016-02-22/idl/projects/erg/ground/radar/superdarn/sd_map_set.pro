;+
; PROCEDURE/FUNCTION sd_map_set
;
; :DESCRIPTION:
;		A wrapper routine for the IDL original "map_set" enabling some
;		annotations regarding the visualization of SD data.
;
;	:PARAMS:
;    time:   time (in double Unix time) for which the magnetic local time for the
;            world map is calculated. In AACGM plots, the magnetic local noon comes
;            on top in plot.
;
;	:KEYWORDS:
;    erase:   set to erase pre-existing graphics on the plot window.
;    clip:    set to zoom in roughly to a region encompassing a field of view of one radar.
;             Actually 30e+6 (clip is on) or 50e+6 (off) is put is "scale" keyword of map_set.
;    position:  gives the position of a plot panel on the plot window as the normal coordinates.
;    center_glat: geographical latitude at which a plot region is centered.
;    center_glon: geographical longitude at which a plot region is centered.
;                 (both center_glat and center_glon should be given, otherwise ignored)
;    mltlabel:    set to draw the MLT labels every 2 hour.
;    lonlab:      a latitude from which (toward the poles) the MLT labels are drawn.
;    force_scale:   Forcibly put a given value in "scale" of map_set.
;    stereo: Use the stereographic projection, instead of satellite projection (default)
;    nogrid: Set to prevent from drawing the lat-lon mesh
;    twohourmltgrid: Set to draw the MLT lines for every other hour, instead of every hour (default)
;
; :EXAMPLES:
;    sd_map_set
;    sd_map_set, /clip, center_glat=70., center_glon=180., /mltlabel, lonlab=74.
;
; :AUTHOR:
; 	Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/01/11: Created
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-02-10 16:54:11 -0800 (Mon, 10 Feb 2014) $
; $LastChangedRevision: 14265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/sd_map_set.pro $
;-
PRO sd_map_set, time, erase=erase, clip=clip, position=position, $
    center_glat=glatc, center_glon=glonc, $
    mltlabel=mltlabel, lonlab=lonlab, $
    force_scale=force_scale, $
    geo_plot=geo_plot, $
    stereo=stereo, $
    charscale=charscale, $
    nogrid=nogrid, twohourmltgrid=twohourmltgrid
    
  ;Initialize the SD plot environment
  sd_init
  
  npar = N_PARAMS()
  IF npar LT 1 THEN time = !sdarn.sd_polar.plot_time
  
  IF ((size(glatc, /type) gt 0) AND (size(glatc, /type) lt 6)) AND $
   ((size(glonc, /type) gt 0) AND (size(glonc, /type) lt 6)) THEN BEGIN
    glonc = (glonc+360.) MOD 360.
    IF glonc GT 180. THEN glonc -= 360.
  ENDIF ELSE BEGIN
    glatc = 89. & glonc = 0.
  ENDELSE
  
  ;Hemisphere flag
  IF glatc GT 0 THEN hemis = 1 ELSE hemis = -1
  
  ;Calculate the rotation angle regarding MLT
  IF ~KEYWORD_SET(geo_plot) THEN BEGIN
    aacgmconvcoord, glatc, glonc,0.1, mlatc,mlonc,err, /TO_AACGM
    ts = time_struct(time) & yrsec = (ts.doy-1)*86400L + LONG(ts.sod)
    tmltc = aacgmmlt(ts.year, yrsec, mlonc)
    mltc = ( tmltc + 24. ) MOD 24.
    mltc_lon = 360./24.* mltc
    
    rot_angle = (-mltc_lon*hemis +360.) MOD 360.
    IF rot_angle GT 180. THEN rot_angle -= 360.
    
    ;Rotate oppositely for the S. hemis.
    if hemis lt 0 then begin 
      rot_angle = ( rot_angle + 180. ) mod 360.
      ;rot_angle *= (-1.)
      rot_angle = (rot_angle+360.) mod 360.
      if rot_angle gt 180. then rot_angle -= 360.
    endif
  ENDIF ELSE rot_angle = 0.
  
  ;Calculate the rotation angle of the north dir in a polar plot
  ;ts = time_struct(time)
  ;aacgm_conv_coord, 60., 0., 400., mlat,mlon,err, /TO_AACGM
  ;mlt = aacgm_mlt( ts.year, long((ts.doy-1)*86400.+ts.sod), mlon)
  
  ;Set the plot position
  pre_pos = !p.position
  IF KEYWORD_SET(position) THEN BEGIN
    !p.position = position
  ENDIF ELSE BEGIN
    nopos = 1
    position = !p.position
  ENDELSE
  IF position[0] GE position[2] OR position[1] GE position[3] THEN BEGIN
    PRINT, '!p.position is not set, temporally use [0,0,1,1]'
    position = [0.,0.,1.,1.]
    !p.position = position
  ENDIF
  
  ;Set the scale for drawing the map_set canvas
  IF KEYWORD_SET(clip) THEN scale=30e+6 ELSE scale=50e+6
  IF KEYWORD_SET(force_scale) THEN scale = force_scale
  
  ;Resize the canvas size for the position values
  IF ~KEYWORD_SET(nopos) THEN BEGIN
    scl = (position[2]-position[0]) < (position[3]-position[1])
  ENDIF ELSE BEGIN
    scl = 1.
    IF !x.window[1]-!x.window[0] GT 0. THEN $
      scl = (!x.window[1]-!x.window[0]) < (!y.window[1]-!y.window[0])
  ENDELSE
  scale /= scl
  
  
  ;Set the lat-lon canvas and draw the continents
  IF ~KEYWORD_SET(geo_plot) THEN BEGIN
    IF ~KEYWORD_SET(stereo) THEN BEGIN
      map_set, mlatc, mltc_lon, rot_angle, $
        /satellite, sat_p=[6.6, 0., 0.], scale=scale, $
        /isotropic, /horizon, noerase=~KEYWORD_SET(erase)
    ENDIF ELSE BEGIN
      map_set, mlatc, mltc_lon, rot_angle, $
        /stereo, sat_p=[6.6, 0., 0.], scale=scale, $
        /isotropic, /horizon, noerase=~KEYWORD_SET(erase)
    ENDELSE
  ENDIF ELSE BEGIN
    IF ~KEYWORD_SET(stereo) THEN BEGIN
      map_set, glatc, glonc, rot_angle, $
        /satellite, sat_p=[6.6, 0., 0.], scale=scale, $
        /isotropic, /horizon, noerase=~KEYWORD_SET(erase)
    ENDIF ELSE BEGIN
      map_set, glatc, glonc, rot_angle, $
        /stereo, sat_p=[6.6, 0., 0.], scale=scale, $
        /isotropic, /horizon, noerase=~KEYWORD_SET(erase)
    ENDELSE
  ENDELSE
  
  if ~keyword_set(nogird) then begin
    if ~keyword_set(twohourmltgrid) then sd_latlt_grid, dlat=10., dlt=1  $
      else sd_latlt_grid, dlat=10., dlt=2
  endif
  
  ;Resize the canvas size for the position values
  scl = (!x.window[1]-!x.window[0]) < (!y.window[1]-!y.window[0])
  scale /= scl
  ;Set charsize used for MLT labels and so on
  charsz = 1.4 * (KEYWORD_SET(clip) ? 50./30. : 1. ) * scl
  !sdarn.sd_polar.charsize = charsz
  
  ;Scale for characters applied only in sd_map_set
  IF ~KEYWORD_SET(charscale) THEN charscale=1.0
  
  IF KEYWORD_SET(mltlabel) THEN BEGIN
    ;Write the MLT labels
    mlts = 15.*FINDGEN(24) ;[deg]
    lonnames=['00hMLT','','02hMLT','','04hMLT','','06hMLT','','08hMLT','','10hMLT','','12hMLT','', $
      '14hMLT','','16hMLT','','18hMLT','','20hMLT','','22hMLT','']
    IF ~KEYWORD_SET(lonlab) THEN lonlab = 77.
    
    ;Calculate the orientation of the MTL labels
    lonlabs0 = replicate(lonlab,n_elements(mlts))
    if hemis eq 1 then lonlabs1 = replicate( (lonlab+10.) < 89.5,n_elements(mlts)) $
    else lonlabs1 = replicate( (lonlab-10.) > (-89.5),n_elements(mlts))
    nrmcord0 = CONVERT_COORD(mlts,lonlabs0,/data,/to_device)
    nrmcord1 = CONVERT_COORD(mlts,lonlabs1,/data,/to_device)
    ori = transpose( atan( nrmcord1[1,*]-nrmcord0[1,*], nrmcord1[0,*]-nrmcord0[0,*] )*!radeg )
    ori = ( ori + 360. ) mod 360. 
    
    ;ori = lons + 90 & ori[WHERE(ori GT 180)] -= 360.
    
    ;idx=WHERE(lons GT 180. ) & lons[idx] -= 360.
    
    nrmcord0 = CONVERT_COORD(mlts,lonlabs0,/data,/to_normal)
    FOR i=0,N_ELEMENTS(mlts)-1 DO BEGIN
      
      nrmcord = reform(nrmcord0[*,i])
      pos = [!x.window[0],!y.window[0],!x.window[1],!y.window[1]]
      IF nrmcord[0] LE pos[0] OR nrmcord[0] GE pos[2] OR $
        nrmcord[1] LE pos[1] OR nrmcord[1] GE pos[3] THEN CONTINUE
      XYOUTS, mlts[i], lonlab, lonnames[i], orientation=ori[i], $
        font=1, charsize=charsz*charscale
        
    ENDFOR
    
  ENDIF
  
  ;Restore the original position setting
  !p.position = pre_pos
  
  RETURN
END
