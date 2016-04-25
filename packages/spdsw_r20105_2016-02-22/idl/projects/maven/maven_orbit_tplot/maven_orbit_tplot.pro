;+
;PROCEDURE:   maven_orbit_tplot
;PURPOSE:
;  Loads MAVEN ephemeris information, currently in the form of IDL save files produced
;  with maven_spice_eph.pro using spk predict kernels, and plots the spacecraft 
;  trajectory as a function of time (using tplot).  The plots are color-coded 
;  according to the nominal plasma regime, based on conic fits to the bow shock and 
;  MPB from Trotignon et al. (PSS 54, 357-369, 2006).  The wake region is simply the 
;  optical shadow in MSO coordinates (sqrt(y*y + z*z) < Rm ; x < 0).
;
;  The available coordinate frames are:
;
;   GEO = body-fixed Mars geographic coordinates (non-inertial) = IAU_MARS
;
;              X ->  0 deg E longitude, 0 deg latitude
;              Y -> 90 deg E longitude, 0 deg latitude
;              Z -> 90 deg N latitude (= X x Y)
;              origin = center of Mars
;              units = kilometers
;
;   MSO = Mars-Sun-Orbit coordinates (approx. inertial)
;
;              X -> from center of Mars to center of Sun
;              Y -> opposite to Mars' orbital angular velocity vector
;              Z = X x Y
;              origin = center of Mars
;              units = kilometers
;
;USAGE:
;  maven_orbit_tplot
;INPUTS:
;
;KEYWORDS:
;       STAT:     Named variable to hold the plasma regime statistics.
;
;       DOMEX:    Use a MEX predict ephemeris, instead of one for MAVEN.
;
;       SWIA:     Calculate viewing geometry for SWIA, based on nominal s/c
;                 pointing.
;
;       IALT:     Ionopause altitude.  Highly variable, but nominally ~400 km.
;                 For display only - not included in statistics.  Default is NaN.
;
;       RESULT:   Named variable to hold the MSO ephemeris with some calculated
;                 quantities.
;
;       EPH:      Named variable to hold the MSO and GEO state vectors.
;
;       CURRENT:  Load the ephemeris from MOI to the current date + 2 weeks.  This
;                 uses reconstructed SPK kernels, as available, then predicts.
;                 This is the default.  OBSOLETE.
;
;       EXTENDED: Load the long-term predict ephemeris (out to Nov. 2018).
;
;       HIRES:    Only works when EXTENDED is set.  If set, load the 20-sec ephemeris;
;                 otherwise, load the 60-sec ephemeris.
;
;       LOADONLY: Create the TPLOT variables, but do not plot.
;
;       RESET_TRANGE: If set, then reset the time span to cover the entire ephemeris
;                     time range, overwriting any existing time range.  This will
;                     affect any routines that use timespan for determining what
;                     data to process.  Use with caution.
;
;       TIMECROP: An array with at least two elements, in any format accepted by 
;                 time_double.  Only ephemeris data between the earliest and
;                 latest times in this array are retained.  Default is to crop
;                 data to current timespan, if it exists -- otherwise, load and
;                 display all available ephemeris data (same as NOCROP).
;
;       NOCROP:   Load and display all available ephemeris data.  Overrides TIMECROP.
;
;       COLORS:   Color indices the nominal plasma regimes: [sheath, pileup, wake].
;                 The solar wind is always plotted in the default foreground color,
;                 typically white or black.  For other regimes, the defaults are:
;
;                   regime       index       color (table 34)
;                   -----------------------------------------
;                   sheath         4         green
;                   pileup         5         yellow
;                   wake           2         blue
;                   -----------------------------------------
;
;       VARS:     Array of TPLOT variables created.
;
;       NOW:      Plot a vertical dotted line at the current time.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-17 09:08:55 -0800 (Tue, 17 Nov 2015) $
; $LastChangedRevision: 19385 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_tplot.pro $
;
;CREATED BY:	David L. Mitchell  10-28-11
;-
pro maven_orbit_tplot, stat=stat, domex=domex, swia=swia, ialt=ialt, result=result, $
                       extended=extended, eph=eph, current=current, loadonly=loadonly, $
                       vars=vars, ellip=ellip, hires=hires, timecrop=timecrop, now=now, $
                       colors=colors, reset_trange=reset_trange, nocrop=nocrop

  @maven_orbit_common

  R_m = 3389.9D
  R_equ = 3396.2D
  R_pol = 3376.2D
  R_vol = (R_equ*R_equ*R_pol)^(1D/3D)

  rootdir = 'maven/anc/spice/sav/'
  ssrc = mvn_file_source(archive_ext='')  ; don't archive old files

  treset = 0  
  tplot_options, get=topt
  if (max(topt.trange_full) eq 0D) then treset = 1
  if keyword_set(reset_trange) then treset = 1

  if keyword_set(domex) then domex = 1 else domex = 0
  if not keyword_set(ialt) then ialt = !values.f_nan
  if keyword_set(ellip) then eflg = 1 else eflg = 0
  if keyword_set(hires) then res = '20sec' else res = '60sec'
  if keyword_set(extended) then begin
    cflg = 0
    msoext = 'maven_spacecraft_mso_ref_' + res + '.sav'
    geoext = 'maven_spacecraft_geo_ref_' + res + '.sav'
    if (size(extended,/type) eq 7) then begin
      i = strpos(extended,'mso')
      j = where(i ge 0, count)
      if (count gt 0L) then msoext = extended[j[0]]
      i = strpos(extended,'geo')
      j = where(i ge 0, count)
      if (count gt 0L) then geoext = extended[j[0]]
    endif
  endif else cflg = 1

  if (n_elements(timecrop) gt 1L) then begin
    tspan = minmax(time_double(timecrop))
    docrop = 1
  endif else begin
    tplot_options, get_opt=topt
    tspan_exists = (max(topt.trange_full) gt time_double('2013-11-18'))
    if (tspan_exists) then begin
      tspan = topt.trange_full
      docrop = 1
    endif else docrop = 0
  endelse  
  if keyword_set(nocrop) then docrop = 0

; Pad time span by one UT day on both sides (guarantees > 10 orbits)

  if (docrop) then tspan += [-86400D, 86400D]

  case n_elements(colors) of
    0 : rcols = [4, 5, 2]
    1 : rcols = [round(colors), 5, 2]
    2 : rcols = [round(colors), 2]
    3 : rcols = round(colors)
    else : rcols = round(colors[0:2])
  endcase
  if keyword_set(now) then donow = 1 else donow = 0
  
; Restore the orbit ephemeris

  if (domex) then begin
    pathname = rootdir + 'mex_traj_mso_june2010.sav'
    file = mvn_pfp_file_retrieve(pathname,source=ssrc)
    finfo = file_info(file)
    if (~finfo.exists) then begin
      print,"File not found: ",pathname
      return
    endif else print, "Using ephemeris: ", file_basename(file[0])

    restore, file[0]
    
    time = mex.t
    dt = median(time - shift(time,1))

    x = mex.x/R_m
    y = mex.y/R_m
    z = mex.z/R_m
    vx = 0.  ; no velocities for MEX
    vy = 0.
    vz = 0.

    r = sqrt(x*x + y*y + z*z)
    s = sqrt(y*y + z*z)
    sza = atan(s,x)
    hgt = (r - 1.)*R_m
    
    lon = 0.  ; no GEO coordinates for MEX
    lat = 0.
    
    mso_x = fltarr(n_elements(mex.x),3)
    mso_x[*,0] = mex.x
    mso_x[*,1] = mex.y
    mso_x[*,2] = mex.z
    
    mso_v = mso_x
    mso_v[*,0] = mex.vx
    mso_v[*,1] = mex.vy
    mso_v[*,2] = mex.vz
    
    geo_x = 0.  ; no GEO coordinates for MEX
    geo_v = 0.

    eph = {time:time, mso_x:mso_x, mso_v:mso_v, geo_x:geo_x, geo_v:geo_v}

  endif else begin
    if (cflg) then fname = 'maven_spacecraft_mso_??????' + '.sav' $
              else fname = msoext

    file = mvn_pfp_file_retrieve(rootdir+fname,last_version=0,source=ssrc)
    nfiles = n_elements(file)
    
    if (docrop) then begin
      year = strmid(file,9,4,/rev)
      month = strmid(file,5,2,/rev)
      date = time_double(year + '-' + month + '-01')
      i = (min(where(date ge tspan[0])) - 1) > 0
      j = (max(where(date le tspan[1])) + 1) < (nfiles - 1)
      file = file[i:j]
      nfiles = n_elements(file)
    endif

	eph = [{t:0D, x:0D, y:0D, z:0D, vx:0D, vy:0D, vz:0D}]
    for i=0,(nfiles-1) do begin
      finfo = file_info(file[i])
      if (finfo.exists) then begin
        print, "Loading: ", file_basename(file[i])
        restore, file[i]
        eph = [temporary(eph), maven_mso]
      endif else print, "File not found: ", file[i]
    endfor
    maven = temporary(eph[1:*])

    time = maven.t
    dt = median(time - shift(time,1))

    x = maven.x/R_m
    y = maven.y/R_m
    z = maven.z/R_m
    vx = maven.vx
    vy = maven.vy
    vz = maven.vz

    r = sqrt(x*x + y*y + z*z)
    s = sqrt(y*y + z*z)
    sza = atan(s,x)
    hgt = (r - 1.)*R_m

    mso_x = fltarr(n_elements(maven.x),3)
    mso_x[*,0] = maven.x
    mso_x[*,1] = maven.y
    mso_x[*,2] = maven.z
    
    mso_v = mso_x
    mso_v[*,0] = maven.vx
    mso_v[*,1] = maven.vy
    mso_v[*,2] = maven.vz
    
    maven = 0

    if (cflg) then fname = 'maven_spacecraft_geo_??????' + '.sav' $
              else fname = geoext

    file = mvn_pfp_file_retrieve(rootdir+fname,last_version=0,source=ssrc)
    nfiles = n_elements(file)
    
    if (docrop) then begin
      year = strmid(file,9,4,/rev)
      month = strmid(file,5,2,/rev)
      date = time_double(year + '-' + month + '-01')
      i = (min(where(date ge tspan[0])) - 1) > 0
      j = (max(where(date le tspan[1])) + 1) < (nfiles - 1)
      file = file[i:j]
      nfiles = n_elements(file)
    endif

	eph = [{t:0D, x:0D, y:0D, z:0D, vx:0D, vy:0D, vz:0D}]
    for i=0,(nfiles-1) do begin
      finfo = file_info(file[i])
      if (finfo.exists) then begin
        print, "Loading: ", file_basename(file[i])
        restore, file[i]
        eph = [temporary(eph), maven_geo]
      endif else print, "File not found: ", file[i]
    endfor
    maven_g = temporary(eph[1:*])

    lon = atan(maven_g.y, maven_g.x)*!radeg
    lat = asin(maven_g.z/(R_m*r))*!radeg
    
    indx = where(lon lt 0., count)
    if (count gt 0L) then lon[indx] = lon[indx] + 360.
    
    geo_x = fltarr(n_elements(maven_g.x),3)
    geo_x[*,0] = maven_g.x
    geo_x[*,1] = maven_g.y
    geo_x[*,2] = maven_g.z
    
    geo_v = mso_x
    geo_v[*,0] = maven_g.vx
    geo_v[*,1] = maven_g.vy
    geo_v[*,2] = maven_g.vz

    maven_g = 0
    
    eph = {time:time, mso_x:mso_x, mso_v:mso_v, geo_x:geo_x, geo_v:geo_v}

  endelse
  
  if (docrop) then begin
    indx = where((time ge tspan[0]) and (time le tspan[1]), count)
    if (count gt 0L) then begin
      eph = {time:time[indx], mso_x:mso_x[indx,*], mso_v:mso_v[indx,*]}
      if (n_elements(geo_x[*,0]) eq n_elements(time)) then begin
        str_element, eph, 'geo_x', geo_x[indx,*], /add
        str_element, eph, 'geo_v', geo_v[indx,*], /add
      endif
      time = temporary(time[indx])
      x = temporary(x[indx])
      y = temporary(y[indx])
      z = temporary(z[indx])
      vx = temporary(vx[indx])
      vy = temporary(vy[indx])
      vz = temporary(vz[indx])
      r = temporary(r[indx])
      s = temporary(s[indx])
      sza = temporary(sza[indx])
      hgt = temporary(hgt[indx])
      if (n_elements(lon) ge count) then begin
        lon = temporary(lon[indx])
        lat = temporary(lat[indx])
      endif
    endif else begin
      print,"No ephemeris data within requested range: ",time_string(tspan)
      print,"Retaining all ephemeris data."
    endelse
  endif
  
  npts = n_elements(time)
  state = eph

  result = {t   : time  , $   ; time (UTC)
            x   : x     , $   ; MSO X
            y   : y     , $   ; MSO Y
            z   : z     , $   ; MSO Z
            vx  : vx    , $   ; MSO Vx
            vy  : vy    , $   ; MSO Vy
            vz  : vz    , $   ; MSO Vz
            r   : r     , $   ; sqrt(x*x + y*y + z*z)
            s   : s     , $   ; sqrt(y*y + z*z)
            sza : sza   , $   ; atan(s,x)
            hgt : hgt   , $   ; aerocentric altitude
            lon : lon   , $   ; GEO longitude
            lat : lat      }  ; GEO latitude
  
; Shock conic (Trotignon)

  x0  = 0.600
  ecc = 1.026
  L   = 2.081

  phm = 160.*!dtor

  phi   = atan(s,(x - x0))
  rho_s = sqrt((x - x0)^2. + s*s)
  shock = L/(1. + ecc*cos(phi < phm))

; MPB conic (2-conic model of Trotignon)

  rho_p = x
  MPB   = x

; First conic (x > 0)

  indx = where(x ge 0)

  x0  = 0.640
  ecc = 0.770
  L   = 1.080

  phi = atan(s,(x - x0))

  rho_p[indx] = sqrt((x[indx] - x0)^2. + s[indx]*s[indx])
  MPB[indx] = L/(1. + ecc*cos(phi[indx]))

; Second conic (x < 0)

  indx = where(x lt 0)

  x0  = 1.600
  ecc = 1.009
  L   = 0.528

  phm = 160.*!dtor

  phi = atan(s,(x - x0))

  rho_p[indx] = sqrt((x[indx] - x0)^2. + s[indx]*s[indx])
  MPB[indx] = L/(1. + ecc*cos(phi[indx] < phm))

; Define the regions

  ss = dblarr(npts, 4)
  ss[*,0] = x
  ss[*,1] = y
  ss[*,2] = z
  ss[*,3] = r

  indx = where(rho_s ge shock, count)
  sheath = ss
  if (count gt 0L) then begin
    sheath[indx,0] = !values.f_nan
    sheath[indx,1] = !values.f_nan
    sheath[indx,2] = !values.f_nan
    sheath[indx,3] = !values.f_nan
  endif

  indx = where(rho_p ge MPB, count)
  pileup = ss
  if (count gt 0L) then begin
    pileup[indx,0] = !values.f_nan
    pileup[indx,1] = !values.f_nan
    pileup[indx,2] = !values.f_nan
    pileup[indx,3] = !values.f_nan
  endif

  indx = where((x gt 0D) or (s gt 1D), count)
  wake = ss
  if (count gt 0L) then begin
    wake[indx,0] = !values.f_nan
    wake[indx,1] = !values.f_nan
    wake[indx,2] = !values.f_nan
    wake[indx,3] = !values.f_nan
  endif

  indx = where(finite(sheath[*,0]) eq 1, count)
  wind = ss
  if (count gt 0L) then begin
    wind[indx,0] = !values.f_nan
    wind[indx,1] = !values.f_nan
    wind[indx,2] = !values.f_nan
    wind[indx,3] = !values.f_nan
  endif
  
  indx = where(finite(pileup[*,0]) eq 1, count)
  if (count gt 0L) then begin
    sheath[indx,0] = !values.f_nan
    sheath[indx,1] = !values.f_nan
    sheath[indx,2] = !values.f_nan
    sheath[indx,3] = !values.f_nan
  endif
  
  indx = where(finite(wake[*,0]) eq 1, count)
  if (count gt 0L) then begin
    sheath[indx,0] = !values.f_nan
    sheath[indx,1] = !values.f_nan
    sheath[indx,2] = !values.f_nan
    sheath[indx,3] = !values.f_nan

    pileup[indx,0] = !values.f_nan
    pileup[indx,1] = !values.f_nan
    pileup[indx,2] = !values.f_nan
    pileup[indx,3] = !values.f_nan
  endif

  tmin = min(time, max=tmax)

; Make the time series plot

  store_data,'alt',data={x:time, y:(ss[*,3] - 1D)*R_m}

  store_data,'sza',data={x:time, y:sza*!radeg}
  ylim,'sza',0,180,0
  options,'sza','yticks',6
  options,'sza','yminor',3
  options,'sza','panel_size',0.5
  options,'sza','ytitle','Solar Zenith Angle'

  store_data,'sheath',data={x:time, y:(sheath[*,3] - 1D)*R_m}
  options,'sheath','color',rcols[0]

  store_data,'pileup',data={x:time, y:(pileup[*,3] - 1D)*R_m}
  options,'pileup','color',rcols[1]

  store_data,'wake',data={x:time, y:(wake[*,3] - 1D)*R_m}
  options,'wake','color',rcols[2]

  store_data,'wind',data={x:time, y:(wind[*,3] - 1D)*R_m}

  store_data,'iono',data={x:[tmin,tmax], y:[ialt,ialt]}
  options,'iono','color',6
  options,'iono','linestyle',2
  options,'iono','thick',2
  
  store_data,'alt_lab',data={x:minmax(time), y:replicate(-1.,2,4), v:indgen(4)}
  options,'alt_lab','labels',['SHADOW','PILEUP','SHEATH','WIND']
  options,'alt_lab','colors',[reverse(rcols),!p.color]
  options,'alt_lab','labflag',1

  store_data,'alt2',data=['alt_lab','alt','sheath','pileup','wake','wind','iono']
  ylim, 'alt2', 0, 0, 0
  options,'alt2','ytitle','Altitude (km)'

; Calculate statistics (orbit by orbit)

  alt = (ss[*,3] - 1D)*R_m
  palt = min(alt)
  gndx = where(alt lt palt*2.)
  di = gndx - shift(gndx,1)
  di[0L] = 2L
  gap = where(di gt 1L, norb)

  if (norb gt 3) then begin
    torb = dblarr(norb-3L)
    twind = torb
    tsheath = torb
    tpileup = torb
    twake = torb
    period = torb
    palt = torb
    sma = dblarr(norb-3L,3)

    hwind = twind
    hsheath = tsheath
    hpileup = tpileup
    hwake = twake

    for i=1L,(norb-3L) do begin

      p1 = min(alt[gndx[gap[i]:(gap[i+1L]-1L)]],j)
      j1 = gndx[j+gap[i]]

      p2 = min(alt[gndx[gap[i+1L]:(gap[i+2L]-1L)]],j)
      j2 = gndx[j+gap[i+1L]]
    
      dj = double(j2 - j1 + 1L)

      k = i - 1L
    
      torb[k] = time[(j1+j2)/2L]
      period[k] = (time[j2] - time[j1])/3600D
      palt[k] = (p1 + p2)/2.

      indx = where(finite(wind[j1:j2,0]), count)
      twind[k] = double(count)/dj
      hwind[k] = double(count)*(dt/3600D)

      indx = where(finite(sheath[j1:j2,0]), count)
      tsheath[k] = double(count)/dj
      hsheath[k] = double(count)*(dt/3600D)

      indx = where(finite(pileup[j1:j2,0]), count)
      tpileup[k] = double(count)/dj
      hpileup[k] = double(count)*(dt/3600D)

      indx = where(finite(wake[j1:j2,0]), count)
      twake[k] = double(count)/dj
      hwake[k] = double(count)*(dt/3600D)

;   Determine semi-minor axis direction for each orbit -- start at periapsis
;   and look for the point in the orbit outbound where [S(periapsis) dot S] 
;   changes sign.  This will be a line perpendicular to the semi-major axis 
;   and therefore parallel to the semi-minor axis.  Note: this is all done
;   in MSO coordinates.

      s1 = ss[j1:j2,0:2]
      pdots = (s1[*,0]*s1[0,0]) + (s1[*,1]*s1[0,1]) + (s1[*,2]*s1[0,2])
      indx = where((pdots*shift(pdots,1)) lt 0.)
      sma[k,0:2] = ss[indx[0]+j1,0:2]/ss[indx[0]+j1,3]

    endfor
  endif

  if keyword_set(swia) then begin
    if (norb gt 15) then sma = smooth(sma,[11,1],/edge_truncate) ; unit vector --> semi-minor axis
    fov = sma                      ; unit vector --> perpendicular to SWIA FOV center plane
    fov[*,0] = 0D                  ; cross product --> X x SMA
    fov[*,1] = -sma[*,2]
    fov[*,2] = sma[*,1]
    for i=0L,n_elements(fov[*,0])-1L do begin
       amp = sqrt(fov[i,1]*fov[i,1] + fov[i,2]*fov[i,2])
       fov[i,*] = fov[i,*]/amp
    endfor

; The vector fov changes smoothly over the mission lifetime.  I want to calulate the 
; angle between fov and nadir throughout all the orbits.

    nx = -x/r   ; unit vector --> nadir
    ny = -y/r
    nz = -z/r

    fx = replicate(0D, n_elements(time))
    fy = spline(torb, fov[*,1], time)
    fz = spline(torb, fov[*,2], time)
    
    sdotf = dblarr(n_elements(time))
    for i=0L, n_elements(time)-1L do sdotf[i] = (ny[i]*fy[i]) + (nz[i]*fz[i])
  
    phi = 90D - (!radeg*acos(sdotf))

; phi is the elevation angle of nadir in SWIA's FOV.  The optimal FOV has phi = 0, 
; that is, nadir is in the center plane of the FOV.
; SWIA's blind spots are at |phi| > 45 degrees.

; Clip off the periapsis and apoapsis parts of the orbit -- focus on the sides only.
  
    alt = (ss[*,3] - 1D)*R_m
    indx = where((alt lt 500D) or (alt gt 5665D))
    phi[indx] = !values.f_nan
  
    swia = {time    : time    , $   ; time (UTC)
            fx      : fx      , $   ; FOV unit vector (x component)
            fy      : fy      , $   ; FOV unit vector (y component)
            fz      : fz      , $   ; FOV unit vector (z component)
            phi     : phi        }  ; elev of nadir in SWIA FOV

  endif

; Package the results - statistics are on an orbit-by-orbit basis

  stat = {time    : torb    , $   ; time (UTC)
          wind    : twind   , $   ; fraction of time in solar wind
          sheath  : tsheath , $   ; fraction of time in sheath
          pileup  : tpileup , $   ; fraction of time in MPR
          wake    : twake   , $   ; fraction of time in wake
          hwind   : hwind   , $   ; hours in solar wind
          hsheath : hsheath , $   ; hours in sheath
          hpileup : hpileup , $   ; hours in MPR
          hwake   : hwake   , $   ; hours in wake
          period  : period  , $   ; orbit period
          palt    : palt       }  ; periapsis altitude

; Stack up times for plotting in one panel

  tpileup = tpileup + twake
  tsheath = tsheath + tpileup
  twind = twind + tsheath

; Store the data in TPLOT

  store_data, 'twind'  , data = {x:torb, y:twind}
  store_data, 'tsheath', data = {x:torb, y:tsheath}
  store_data, 'tpileup', data = {x:torb, y:tpileup}
  store_data, 'twake'  , data = {x:torb, y:twake}

  options, 'tsheath', 'color', rcols[0]
  options, 'tpileup', 'color', rcols[1]
  options, 'twake', 'color', rcols[2]

  store_data, 'stat', data = ['twind','tsheath','tpileup','twake']
  ylim, 'stat', 0, 1
  options, 'stat', 'panel_size', 0.75
  options, 'stat', 'ytitle', 'Orbit Fraction'
  
  store_data, 'period', data = {x:torb, y:period}
  options,'period','ytitle','Period'
  options,'period','panel_size',0.5
  options,'period','ynozero',1
  
  store_data, 'palt', data = {x:torb, y:palt}
  options,'palt','ytitle','Periapsis'
  
  store_data, 'lon', data = {x:time, y:lon}
  ylim,'lon',-180,180,0
  options,'lon','yticks',4
  options,'lon','yminor',3
  
  store_data, 'lat', data = {x:time, y:lat}
  ylim,'lat',-90,90,0
  options,'lat','yticks',2
  options,'lat','yminor',3
  options,'lat','panel_size',0.5

; Determine orbit numbers

  orbnum = mvn_orbit_num(time=time, verbose=-1)

; Put up the plot

  vars = ['alt2','stat','sza','period','palt','lon','lat']

  if not keyword_set(loadonly) then begin
    avars = vars[0:2]
    nvars = n_elements(avars)

    str_element, topt, 'varnames', tvars, success=ok
    if (not ok) then tvars = avars
    for i=(nvars-1),0,-1 do if (~max(strcmp(avars[i],tvars))) then tvars = [avars[i],tvars]

    if (treset) then timespan,[tmin,tmax],/sec
    tplot,tvars
    if (donow) then timebar,systime(/utc,/sec),line=1
  endif

  return

end
