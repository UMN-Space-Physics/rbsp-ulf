;+
;PROCEDURE: 
;	mvn_swe_sc_pot
;
;PURPOSE:
;	Estimates the spacecraft potential from SWEA energy spectra.  The basic
;   idea is to look for a break in the energy spectrum (sharp change in flux
;   level and slope).  No attempt is made to estimate the potential when the
;   spacecraft is in darkness (expect negative potential) or below 250 km
;   altitude (expect small or negative potential).
;
;AUTHOR: 
;	David L. Mitchell
;
;CALLING SEQUENCE: 
;	mvn_swe_sc_pot, potential=dat
;
;INPUTS: 
;   none - energy spectra are obtained from SWEA common block.
;
;KEYWORDS:
;	POTENTIAL: Returns a time-ordered array of spacecraft potentials
;
;   ERANGE:    Energy range over which to search for the potential.
;              Default = [3.,20.]
;
;   THRESH:    Threshold for the minimum slope: d(logF)/d(logE). 
;              Default = 0.05
;
;              A smaller value includes more data and extends the range 
;              over which you can estimate the potential, but at the 
;              expense of making more errors.
;
;   DEMAX:     The largest allowable energy width of the spacecraft 
;              potential feature.  This excludes features not related
;              to the spacecraft potential at higher energies (often 
;              observed downstream of the shock).  Default = 6 eV.
;
;   FUDGE:     Multiply the derived potential by this fudge factor.
;              (for calibration against LPW).  Default = 1.
;
;   DDD:       Use 3D data to calculate potential.  Allows bin masking,
;              but lower cadence and typically lower energy resolution.
;
;   ABINS:     When using 3D spectra, specify which anode bins to 
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,16)
;
;   DBINS:     When using 3D spectra, specify which deflection bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,6)
;
;   OBINS:     When using 3D spectra, specify which solid angle bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = reform(ABINS#DBINS,96).  Takes precedence over
;              ABINS and OBINS.
;
;   MASK_SC:   Mask the spacecraft blockage.  This is in addition to any
;              masking specified by the above three keywords.
;              Default = 1 (yes).
;
;   PANS:      Named varible to hold the tplot panels created.
;
;   OVERLAY:   Overlay the result on the energy spectrogram.
;
;   SETVAL:    Make no attempt to estimate the potential, just set it to
;              this value.  Units = volts.  No default.
;
;   BADVAL:    If the algorithm cannot estimate the potential, then set it
;              to this value.  Units = volts.  Default = NaN.
;
;   ANGCORR:   Angular distribution correction based on interpolated 3d data
;              to emphasize the returning photoelectrons and improve 
;              the edge detection (added by Yuki Harada).
;
;OUTPUTS:
;   None - Result is stored in SPEC data structure, returned via POTENTIAL
;          keyword, and stored as a TPLOT variable.
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-02-04 09:54:57 -0800 (Thu, 04 Feb 2016) $
; $LastChangedRevision: 19900 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sc_pot.pro $
;
;-

pro mvn_swe_sc_pot, potential=potential, erange=erange, fudge=fudge, thresh=thresh, dEmax=dEmax, $
                    pans=pans, overlay=overlay, ddd=ddd, abins=abins, dbins=dbins, obins=obins, $
                    mask_sc=mask_sc, setval=setval, badval=badval, angcorr=angcorr

  compile_opt idl2
  
  @mvn_swe_com

  if (size(mvn_swe_engy,/type) ne 8) then begin
    print,"No energy data loaded.  Use mvn_swe_load_l0 first."
    phi = 0
    return
  endif
  
  if (size(setval,/type) ne 0) then begin
    print,"Setting the s/c potential to: ",setval
    mvn_swe_engy.sc_pot = setval
    return
  endif
  
  if (size(badval,/type) eq 0) then badval = !values.f_nan else badval = float(badval)

; Clear any previous potential calculations

  mvn_swe_engy.sc_pot = badval
  
  if not keyword_set(erange) then erange = [3.,20.]
  erange = minmax(float(erange))
  if not keyword_set(fudge) then fudge = 1.
  if keyword_set(ddd) then dflg = 1 else dflg = 0

  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then begin
    obins = replicate(1B, 96, 2)
    obins[*,0] = reform(abins # dbins, 96)
    obins[*,1] = obins[*,0]
  endif else obins = byte(obins # [1B,1B])
  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then obins = swe_sc_mask * obins

  if (size(thresh,/type) eq 0) then thresh = 0.05
  if (size(dEmax,/type) eq 0) then dEmax = 6.
  
  if (dflg) then begin
    ok = 0
    if (size(mvn_swe_3d,/type) eq 8) then begin
      t = mvn_swe_3d.time
      npts = n_elements(t)
      e = fltarr(64,npts)
      f = e
      ok = 1
    endif

    if ((not ok) and size(swe_3d,/type) eq 8) then begin
      t = swe_3d.time
      npts = n_elements(t)
      e = fltarr(64,npts)
      f = e
      ok = 1
    endif
    
    if (not ok) then begin
      print, "No valid 3D data."
      return
    endif
    
    for i=0L,(npts-1L) do begin
      ddd = mvn_swe_get3d(t[i], units='eflux')

      if (ddd.time gt t_mtx[2]) then boom = 1 else boom = 0
      ondx = where(obins[*,boom] eq 1B, ocnt)
      onorm = float(ocnt)
      obins_b = replicate(1B, 64) # obins[*,boom]

      e[*,i] = ddd.energy[*,0]
      f[*,i] = total(ddd.data * obins_b, 2, /nan)/onorm
    endfor

  endif else begin
    
    old_units = mvn_swe_engy[0].units_name
    mvn_swe_convert_units, mvn_swe_engy, 'eflux'

    t = mvn_swe_engy.time
    npts = n_elements(t)
    e = mvn_swe_engy.energy
    f = mvn_swe_engy.data

  endelse
  
;  Angular distribution correction based on interpolated 3d data
;  to emphasize the returning photoelectrons.
;  This section was added by Yuki Harada.
  if keyword_set(angcorr) and (size(mvn_swe_3d,/type) eq 8) then begin
     ww = finite(mvn_swe_3d.data) * 1.
     wsky = where( mvn_swe_3d.phi gt 112.5 and mvn_swe_3d.phi lt 292.5 $
                   and mvn_swe_3d.theta gt -45 and mvn_swe_3d.theta lt 45 , comp=cwsky )
     ww[cwsky] = 0.
     skyflux = total(mvn_swe_3d.data*mvn_swe_3d.domega*ww,2,/nan) $
               /total(mvn_swe_3d.domega*ww,2,/nan)

     ww = finite(mvn_swe_3d.data) * 1.
     aveflux = total(mvn_swe_3d.data*mvn_swe_3d.domega*ww,2,/nan) $
               /total(mvn_swe_3d.domega*ww,2,/nan)

     fr = f * !values.f_nan
     for j=0,63 do fr[j,*] = interp(reform(skyflux[j,*]/aveflux[j,*]),mvn_swe_3d.time,t) < 1.2
;  A maximum factor of 1.2 is set to avoid too much emphasis on lowest
;  energy photoelectrons
     f = f * fr
  endif


  indx = where(e[*,0] lt 60., n_e)
  e = e[indx,*]
  f = alog10(f[indx,*])
  
  potstr = {time : 0D            , $
            pot  : !values.f_nan , $
            dE   : !values.f_nan , $
            amp  : !values.f_nan , $
            flg  : 0                }
  potential = replicate(potstr, npts)
  potential.time = t

; Filter out bad spectra

  gndx = round(total(finite(f),1))
  gndx = where(gndx eq n_e, npts)
  if (npts gt 0L) then begin
    t = t[gndx]
    e = e[*,gndx]
    f = f[*,gndx]
    potential[gndx].flg = 1
  endif else begin
    print,"No good spectra!"
    return
  endelse

; Take first and second derivatives of log(eflux) w.r.t. log(E)

  df = f
  d2f = f

  for i=0L,(npts-1L) do df[*,i] = deriv(f[*,i])
  for i=0L,(npts-1L) do d2f[*,i] = deriv(df[*,i])

; Oversample and smooth

  n_es = 4*n_e
  emax = max(e, dim=1, min=emin)
  dloge = (alog10(emax) - alog10(emin))/float(n_es - 1)
  ee = 10.^((replicate(1.,n_es) # alog10(emax)) - (findgen(n_es) # dloge))
  
  dfs = fltarr(n_es,npts)
  for i=0L,(npts-1L) do dfs[*,i] = interpol(df[*,i],n_es)

  d2fs = fltarr(n_es,npts)
  for i=0L,(npts-1L) do d2fs[*,i] = interpol(d2f[*,i],n_es)

; Trim to the desired search range

  indx = where((ee[*,0] gt erange[0]) and (ee[*,0] lt erange[1]), n_e)
  ee = ee[indx,*]
  dfs = dfs[indx,*]
  d2fs = d2fs[indx,*]

; The spacecraft potential is taken to be the maximum slope (dlogF/dlogE)
; within the search window.  A fudge factor is included to adjust the estimate 
; for cross calibration with LPW.
;
; Use diagnostics keywords in swe_engy_snap to plot these functions, together
; with the retrieved potential.
  
  zcross = d2fs*shift(d2fs,1,0)
  zcross[0,*] = 1.

  phi = replicate(badval, npts)
  for i=0L,(npts-1L) do begin
    indx = where((dfs[*,i] gt thresh) and (zcross[*,i] lt 0.), ncross) ; local maxima in slope

    if (ncross gt 0) then begin
      k = max(indx)               ; lowest energy feature above threshold
      dfsmax = dfs[k,i]
      dfsmin = dfsmax/3.

      while ((dfs[k,i] gt dfsmin) and (k lt n_e-1)) do k++
      kmax = k
      k = max(indx)
      while ((dfs[k,i] gt dfsmin) and (k gt 0)) do k--
      kmin = k
      
      dE = ee[kmin,i] - ee[kmax,i]
      if ((kmax eq (n_e-1)) or (kmin eq 0)) then dE = 2.*dEmax
      
      if (dE lt dEmax) then phi[i] = ee[max(indx),i]  ; only accept narrow features
      
      potential[gndx[i]].dE = dE
      potential[gndx[i]].amp = dfsmax
    endif
  endfor

; Filter for low flux

  fmax = max(mvn_swe_engy[gndx].data, dim=1)
  indx = where(fmax lt 1.e7, count)
  if (count gt 0L) then begin
    phi[indx] = badval
    potential[gndx[indx]].flg = -1
  endif

; Filter out shadow regions

  get_data, 'wake', data=wake, index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /current, /loadonly
    get_data, 'wake', data=wake, index=i
  endif
  if (i gt 0) then begin
    shadow = interpol(float(finite(wake.y)), wake.x, mvn_swe_engy[gndx].time)
    indx = where(shadow gt 0., count)
    if (count gt 0L) then begin
      phi[indx] = badval
      potential[gndx[indx]].flg = -2
    endif
  endif

; Filter out altitudes below 250 km

  get_data, 'alt', data=alt, index=i
  if (i eq 0) then begin
    maven_orbit_tplot, /current, /loadonly
    get_data, 'alt', data=alt, index=i
  endif
  if (i gt 0) then begin
    altitude = interpol(alt.y, alt.x, mvn_swe_engy[gndx].time)
    indx = where(altitude lt 250., count)
    if (count gt 0L) then begin
      phi[indx] = badval
      potential[gndx[indx]].flg = -3
    endif
  endif

; Apply fudge factor, and store the result

  phi = phi*fudge
  potential[gndx].pot = phi

  if (not dflg) then begin
    mvn_swe_engy[gndx].sc_pot = phi
    mvn_swe_convert_units, mvn_swe_engy, old_units
  endif else begin
    mvn_swe_engy[gndx].sc_pot = interpol(phi,t,mvn_swe_engy[gndx].time)
  endelse
  
  swe_sc_pot = replicate(swe_pot_struct, npts)
  swe_sc_pot.time = t
  swe_sc_pot.potential = phi
  swe_sc_pot.valid = 1

; Make tplot variables
  
  store_data,'df',data={x:t, y:transpose(dfs), v:transpose(ee)}
  options,'df','spec',1
  ylim,'df',0,30,0
  zlim,'df',0,0,0
  
  store_data,'d2f',data={x:t, y:transpose(d2fs), v:transpose(ee)}
  options,'d2f','spec',1
  ylim,'d2f',0,30,0
  zlim,'d2f',0,0,0

  pot = {x:t, y:phi}  
  store_data,'mvn_swe_sc_pot',data=pot
  pans = 'mvn_swe_sc_pot'

  store_data,'Potential',data=['d2f','mvn_swe_sc_pot']
  ylim,'Potential',0,30,0

  if keyword_set(overlay) then begin
    str_element,pot,'thick',2,/add
    str_element,pot,'color',0,/add
    str_element,pot,'psym',3,/add
    store_data,'swe_pot_overlay',data=pot
    store_data,'swe_a4_pot',data=['swe_a4','swe_pot_overlay']
    ylim,'swe_a4_pot',3,5000,1

    tplot_options, get=opt
    str_element, opt, 'varnames', varnames, success=ok
    if (ok) then begin
      i = (where(varnames eq 'swe_a4'))[0]
      if (i ne -1) then begin
        varnames[i] = 'swe_a4_pot'
        tplot, varnames
      endif
    endif
  endif

  return

end
