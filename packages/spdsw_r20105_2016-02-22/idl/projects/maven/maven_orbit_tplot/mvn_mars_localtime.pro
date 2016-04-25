;+
;PROCEDURE:   mvn_mars_localtime
;PURPOSE:
;  Uses SPICE to determine the local solar time over the current tplot
;  time range (full).  The result is stored as a tplot variable and 
;  optionally returned via keyword.
;
;  It is assumed that you have already initialized SPICE.  (See 
;  mvn_swe_spice_init for an example.)
;
;USAGE:
;  mvn_mars_localtime, result=dat
;
;INPUTS:
;       None:      All necessary data are obtained from the common block.
;
;KEYWORDS:
;       RESULT:    Structure containing the result:
;
;                    time  : unix time for used for calculation
;                    lst   : local solar time (hrs)
;                    s_lon : sub-solar point longitude (deg)
;                    s_lat : sub-solar point latitude (deg)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-08-21 14:39:10 -0700 (Fri, 21 Aug 2015) $
; $LastChangedRevision: 18563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mvn_mars_localtime.pro $
;
;CREATED BY:	David L. Mitchell
;-
pro mvn_mars_localtime, result=result

  @maven_orbit_common

  from_frame = 'MAVEN_MSO'
  to_frame = 'IAU_MARS'

  if (size(state,/type) eq 0) then maven_orbit_tplot, /current, /loadonly

  tplot_options, get=topt
  tsp = topt.trange_full
  indx = where((time ge tsp[0]) and (time le tsp[1]), count)
  if (count eq 0L) then begin
    print,"Tplot time range contains no ephemeris data!"
    return
  endif

; Sun is at MSO coordinates of [X, Y, Z] = [1, 0, 0]

  s_mso = [1D, 0D, 0D] # replicate(1D, n_elements(count))
  s_geo = spice_vector_rotate(s_mso, time[indx], from_frame, to_frame)
  s_lon = reform(atan(s_geo[1,*], s_geo[0,*])*!radeg)
  s_lat = reform(asin(s_geo[2,*])*!radeg)
  
  jndx = where(s_lon lt 0., count)
  if (count gt 0L) then s_lon[jndx] = s_lon[jndx] + 360.

; Local time is IAU_MARS longitude relative to sub-solar longitude

  lst = (lon[indx] - s_lon)*(12D/180D)

  jndx = where(lst lt 0., count)
  if (count gt 0L) then lst[jndx] = lst[jndx] + 24.
  jndx = where(lst gt 24., count)
  if (count gt 0L) then lst[jndx] = lst[jndx] - 24.
  
  store_data,'lst',data={x:time[indx], y:lst}
  ylim,'lst',0,24,0
  options,'lst','yticks',4
  options,'lst','yminor',6
  options,'lst','psym',3
  options,'lst','ytitle','LST (hrs)'
  
  store_data,'Lss',data={x:time[indx], y:s_lat}
  options,'Lss','ytitle','Sub-solar!CLat (deg)'
  
  result = {time:time[indx], lst:lst, slon:s_lon, slat:s_lat}

  return

end
