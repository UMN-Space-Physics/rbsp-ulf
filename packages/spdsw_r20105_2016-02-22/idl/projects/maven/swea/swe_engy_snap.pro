;+
;PROCEDURE:   swe_engy_snap
;PURPOSE:
;  Plots energy spectrum snapshots in a separate window for times selected with the 
;  cursor in a tplot window.  Hold down the left mouse button and slide for a movie 
;  effect.  This procedure depends on running swe_plot_dpu first, which unpacks the
;  A4 packets, creating 16 energy spectra per packet.
;
;  If housekeeping data exist (almost always the case), then they are displayed 
;  as text in a small separate window.
;
;USAGE:
;  swe_engy_snap
;
;INPUTS:
;
;KEYWORDS:
;       UNITS:         Plot the data in these units.  See mvn_swe_convert_units.
;                      Default = 'eflux'.
;
;       TIMES:         Make a plot for these times.
;
;       TPLOT:         Get energy spectra from tplot variable instead of SWEA
;                      common block.
;
;       FIXY:          Use a fixed y-axis range.  Default = 1 (yes).
;
;       KEEPWINS:      If set, then don't close the snapshot window(s) on exit.
;
;       ARCHIVE:       If set, show shapshots of archive data (A5).
;
;       BURST:         Synonym for ARCHIVE.
;
;       SPEC:          Named variable to hold the energy spectrum at the last time
;                      selected.
;
;       SUM:           If set, use cursor to specify time ranges for averaging.
;
;       POT:           Overplot an estimate of the spacecraft potential.  Must run
;                      mvn_swe_sc_pot first.
;
;       SCP:           Override any other estimates of the spacecraft potential and
;                      force it to be this value.
;
;       DEMAX:         Maximum width of spacecraft potential signature.
;
;       PEPEAKS:       Overplot the nominal energies of the photoelectron energy peaks
;                      at 23 and 27 eV.
;
;       BCK:           Plot background level (Potassium-40 decay and penetrating
;                      particles only).
;
;       MAGDIR:        Print magnetic field geometry (azim, elev, clock) on the plot.
;
;       PDIAG:         Plot potential estimator in a separate window.
;
;       PXLIM:         X limits (Volts) for diagnostic plot.
;
;       MB:            Perform a Maxwell-Boltzmann fit to determine density and 
;                      temperature.  Uses a moment calculation to determine the
;                      halo density, which is defined as the high energy residual
;                      after subtracting the best-fit Maxwell-Boltzmann.
;
;       KAP:           Instead of the halo moment calculation, fit the halo with
;                      a kappa function to estimate halo density.
;
;       MOM:           Instead of fitting the core with a Maxwell-Boltzmann, use
;                      a moment calculation for all energies above the spacecraft
;                      potential.
;
;       ERANGE:        Energy range for computing the moment.  Only effective when
;                      keyword MOM is set.
;
;       SCAT:          Plot the scattered photoelectron population, which is defined
;                      as the low-energy residual after subtracting the best-fit
;                      Maxwell-Boltzmann.
;
;       SEC:           Calculate secondary electron spectrum using McFadden's
;                      semi-empirical approach.
;
;       DDD:           Create an energy spectrum from the nearest 3D spectrum and
;                      plot for comparison.
;
;       ABINS:         Anode bin mask (16 elements: 0=off, 1=on).  Default = all on.
;
;       DBINS:         Deflector bin mask (6 elements: 0=off, 1=on).  Default = all on.
;
;       OBINS:         3D solid angle bin mask (96 elements: 0=off, 1=on).
;                      Default = reform(ABINS # DBINS).
;
;       MASK_SC:       Mask solid angle bins that view the spacecraft.  Default = yes.
;                      This masking is in addition to OBINS.
;
;       NOERASE:       Overplot all spectra after the first.
;
;       RAINBOW:       With NOERASE, overplot spectra using up to 6 different colors.
;
;       POPEN:         Set this to the name of a postscript file for output.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-12-09 21:30:59 -0800 (Wed, 09 Dec 2015) $
; $LastChangedRevision: 19564 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_engy_snap.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro swe_engy_snap, units=units, keepwins=keepwins, archive=archive, spec=spec, ddd=ddd, $
                   abins=abins, dbins=dbins, obins=obins, sum=sum, pot=pot, pdiag=pdiag, $
                   pxlim=pxlim, mb=mb, kap=kap, mom=mom, scat=scat, erange=erange, $
                   noerase=noerase, thresh=thresh, scp=scp, fixy=fixy, pepeaks=pepeaks, $
                   dEmax=dEmax, burst=burst, rainbow=rainbow, mask_sc=mask_sc, sec=sec, $
                   bkg=bkg, tplot=tplot, magdir=magdir, bck=bck, shiftpot=shiftpot, $
                   xrange=xrange,sscale=sscale, popen=popen, times=times

  @mvn_swe_com
  common snap_layout, snap_index, Dopt, Sopt, Popt, Nopt, Copt, Fopt, Eopt, Hopt

  mass = 5.6856297d-06             ; electron rest mass [eV/(km/s)^2]
  c1 = (mass/(2D*!dpi))^1.5
  c2 = (2d5/(mass*mass))
  c3 = 4D*!dpi*1d-5*sqrt(mass/2D)  ; assume isotropic electron distribution

  if not keyword_set(archive) then aflg = 0 else aflg = 1
  if keyword_set(burst) then aflg = 1
  if not keyword_set(units) then units = 'eflux'
  if keyword_set(sum) then npts = 2 else npts = 1
  if keyword_set(ddd) then dflg = 1 else dflg = 0
  if keyword_set(noerase) then oflg = 0 else oflg = 1
  if (size(scp,/type) eq 0) then scp = !values.f_nan else scp = float(scp[0])
  if (size(thresh,/type) eq 0) then thresh = 0.05
  if (size(dEmax,/type) eq 0) then dEmax = 4.
  if (size(fixy,/type) eq 0) then fixy = 1
  if keyword_set(fixy) then fflg = 1 else fflg = 0
  if keyword_set(rainbow) then rflg = 1 else rflg = 0
  if keyword_set(sec) then dosec = 1 else dosec = 0
  if not keyword_set(sscale) then sscale = 5D
  if keyword_set(bkg) then dobkg = 1 else dobkg = 0
  if keyword_set(shiftpot) then spflg = 1 else spflg = 0
  if (n_elements(xrange) ne 2) then xrange = [1.,1.e4]
  if (size(popen,/type) eq 7) then begin
    psflg = 1
    psname = popen[0]
    csize1 = 1.2
    csize2 = 1.0
  endif else begin
    psflg = 0
    csize1 = 1.2
    csize2 = 1.4
  endelse

  tflg = 0
  if keyword_set(tplot) then begin
    get_data,'swe_a4',data=dat,limits=lim,index=i
    if (i gt 0) then begin
      str_element,lim,'ztitle',units,success=ok
      if (ok) then units = strlowcase(units) else units = 'unknown'
      tspec = {time:dat.x, data:dat.y, energy:dat.v, units_name:units}
      tflg = 1
    endif else print,'No SPEC data found in tplot.'
  endif

  get_data,'alt',data=alt
  if (size(alt,/type) eq 8) then begin
    doalt = 1
    get_data,'sza',data=sza
    get_data,'lon',data=lon
    get_data,'lat',data=lat
  endif else doalt = 0

  domag = 0
  if keyword_set(magdir) then begin
    get_data,'mvn_B_1sec_iau_mars',data=mag
    if (size(mag,/type) eq 8) then domag = 1 else domag = 0
  endif

  if (n_elements(abins) ne 16) then abins = replicate(1B, 16)
  if (n_elements(dbins) ne  6) then dbins = replicate(1B, 6)
  if (n_elements(obins) ne 96) then begin
    obins = replicate(1B, 96, 2)
    obins[*,0] = reform(abins # dbins, 96)
    obins[*,1] = obins[*,0]
  endif else obins = reform(byte(obins)) # [1B,1B]
  if (size(mask_sc,/type) eq 0) then mask_sc = 1
  if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  
  if keyword_set(pot) then dopot = 1 else dopot = 0
  if keyword_set(pepeaks) then dopep = 1 else dopep = 0
  if keyword_set(scat) then scat = 1 else scat = 0

  if keyword_set(mb) then begin
    mb = 1
    dopot = 1
  endif else mb = 0
  if keyword_set(kap) then kap = 1 else kap = 0

  if keyword_set(mom) then begin
    mom = 1
    dopot = 1
    mb = 0
    kap = 0
  endif else mom = 0

  if keyword_set(pdiag) then begin
    get_data,'df',data=df
    get_data,'d2f',data=d2f,index=i
    if (i gt 0) then pflg = 1 else pflg = 0
  endif else pflg = 0

  if (not tflg) then begin
    if (size(mvn_swe_engy,/type) ne 8) then mvn_swe_makespec
  
    if (aflg) then begin
      if (size(mvn_swe_engy_arc,/type) ne 8) then begin
        print,"No SPEC archive data."
        return
      endif
      mvn_swe_convert_units, mvn_swe_engy_arc, units
    endif else begin
      if (size(mvn_swe_engy,/type) ne 8) then begin
        print,"No SPEC survey data."
        return
      endif
    endelse
  endif
  
  if (fflg) then begin
    case strupcase(units) of
      'COUNTS' : drange = [1e0, 1e5]
      'RATE'   : drange = [1e1, 1e6]
      'CRATE'  : drange = [1e1, 1e6]
      'FLUX'   : drange = [1e1, 3e8]
      'EFLUX'  : drange = [1e4, 3e9]
      'E2FLUX' : drange = [1e6, 1e11]
      'DF'     : drange = [1e-18, 1e-8]
      else     : drange = [0,0]
    endcase
  endif

  if (size(swe_hsk,/type) eq 8) then begin
    if (n_elements(swe_hsk) gt 2L) then hflg = 1 else hflg = 0
  endif else hflg = 0
  if keyword_set(keepwins) then kflg = 0 else kflg = 1
  if keyword_set(archive) then aflg = 1 else aflg = 0

; Put up snapshot window(s)

  Twin = !d.window

  if (size(Dopt,/type) ne 8) then swe_snap_layout, 0

  window, /free, xsize=Eopt.xsize, ysize=Eopt.ysize, xpos=Eopt.xpos, ypos=Eopt.ypos
  Ewin = !d.window

  if (hflg) then begin
    window, /free, xsize=Hopt.xsize, ysize=Hopt.ysize, xpos=Hopt.xpos, ypos=Hopt.ypos
    Hwin = !d.window
  endif
  
  if (pflg) then begin
    window, /free, xsize=Sopt.xsize, ysize=Sopt.ysize, xpos=Sopt.xpos, ypos=Sopt.ypos
    Pwin = !d.window
  endif

; Get the spectrum closest the selected time
  
  ok = 1

  print,'Use button 1 to select time; button 3 to quit.'

  wset,Twin
  trange = 0
  ctime,trange,npoints=npts,/silent
  if (npts gt 1) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released

  if (size(trange,/type) ne 5) then begin
    wdelete,Ewin
    if (hflg) then wdelete,Hwin
    if (pflg) then wdelete,Pwin
    wset,Twin
    return
  endif

  if (tflg) then begin
    if (npts eq 1) then begin
      dt = min(abs(trange[0] - tspec.time), i)
      spec = {time:tspec.time[i], data:reform(tspec.data[i,*]), $
              energy:tspec.energy, units_name:tspec.units_name, $
              sc_pot:0.}
    endif else begin
      tmin = min(trange, max=tmax)
      i = where((tspec.time ge tmin) and (tspec.time le tmax), count)
      if (count gt 0L) then begin
        spec = {time:mean(tspec.time[i]), data:average(tspec.data[i,*],1,/nan), $
                energy:tspec.energy, units_name:tspec.units_name, sc_pot:0.}
      endif
    endelse
  endif else begin
    spec = mvn_swe_getspec(trange, /sum, archive=aflg, units=units, yrange=yrange)
  endelse
  if (fflg) then yrange = drange
  
  if (spflg) then begin
    if (finite(scp)) then pot = scp $
                     else if (finite(spec.sc_pot)) then pot = spec.sc_pot else pot = 0.
    spec = conv_units(spec,'df')
    spec.energy -= pot
    spec = conv_units(spec,units)
  endif
  
  case strupcase(spec.units_name) of
    'COUNTS' : ytitle = 'Raw Counts'
    'RATE'   : ytitle = 'Raw Count Rate'
    'CRATE'  : ytitle = 'Count Rate'
    'EFLUX'  : ytitle = 'Energy Flux (eV/cm2-s-ster-eV)'
    'E2FLUX' : ytitle = 'Energy Flux (eV/cm2-s-ster)'
    'FLUX'   : ytitle = 'Flux (1/cm2-s-ster-eV)'
    'DF'     : ytitle = 'Dist. Function (1/cm3-(km/s)3)'
    else     : ytitle = 'Unknown Units'
  endcase

  if (hflg) then dt = min(abs(swe_hsk.time - spec.time), jref)  ; closest HSK
  
  nplot = 0
  xs = 0.71
  dys = 0.03
  
  while (ok) do begin

    x = spec.energy
    y = spec.data
    phi = spec.sc_pot
    ys = 0.90

    if (psflg) then popen, psname + string(nplot,format='("_",i2.2)') $
               else wset, Ewin

; Put up an Energy Spectrum with (optionally) model fit, background, scattering, etc.

    psym = 10

    if ((nplot eq 0) or oflg) then plot_oo,x,y,yrange=yrange,/ysty,xrange=xrange, $
            xtitle='Energy (eV)', ytitle=ytitle,charsize=csize2,psym=psym,title=time_string(spec.time) $
                              else oplot,x,y,psym=psym
    
    if (rflg) then oplot,x,y,psym=psym,color=(nplot mod 6)+1

    if (dflg) then begin
      if (npts gt 1) then ddd = mvn_swe_get3d(trange,/all,/sum) $
                     else ddd = mvn_swe_get3d(spec.time)
      mvn_swe_convert_units, ddd, spec.units_name
      dt = min(abs(swe_hsk.time - ddd.time), kref)

      if (ddd.time gt t_mtx[2]) then boom = 1 else boom = 0
      indx = where(obins[*,boom] eq 1B, onorm)
      omask = replicate(1.,64) # obins[*,boom]
      onorm = float(onorm)

      spec3d = total(ddd.data*omask,2,/nan)/onorm
      oplot,ddd.energy[*,0],spec3d,psym=psym,color=4
    endif

; Secondary electrons produced by primary electron impact inside the instrument.
; Method from McFadden, adapted from Dave Evans.

    if (dosec) then begin
      units = spec.units_name
      odat = conv_units(spec,'crate')

      energy = odat.energy
      nenergy = odat.nenergy
      sec_spec = dblarr(nenergy)

      if (finite(scp)) then pot = scp $
                       else if (finite(phi)) then pot = phi else pot = 0.
      kndx = where(energy gt pot)
      kmax = max(kndx)

      alpha = 1.35
      Tmax = 2.283
      Emax = 325.
      k = 2.2
      scale = sscale

      Vbias = 0.                     ; primaries not passing through exit grid
      Erat = (energy + Vbias)/Emax   ; effect of V0 cancels when using swe_swp
      arg = Tmax*(Erat^alpha) < 80.  ; avoid underflow

      delta = (Erat^(1. - alpha))*(1. - exp(-arg))/(1. - exp(-Tmax))
      eff = scale*(1. - exp(-k*delta))/(1. - exp(-k))

      for k=1,kmax-1 do sec_spec[k:kmax] += eff[k]*odat.data[k]/energy[k:kmax]^2.0

      odat.data = sec_spec
      sec_dat = conv_units(odat, units)
      dif_dat = spec
      dif_dat.data = (spec.data - sec_dat.data) > 1.
      oplot,sec_dat.energy[kndx],sec_dat.data[kndx],color=5,line=2
      oplot,dif_dat.energy,dif_dat.data,color=5,psym=10
    endif

; Background counts resulting from the wings of the energy response function.
; Empirical: based on fits to solar wind core
; Experimental.

    if (dobkg) then begin
      units = spec.units_name
      odat = conv_units(spec,'crate')

      energy = odat.energy
      nenergy = odat.nenergy

      if (finite(scp)) then pot = scp $
                       else if (finite(phi)) then pot = phi else pot = 0.
      kndx = where(energy le pot, kcnt)

      if (kcnt gt 0L) then begin
        bkg_spec = dblarr(nenergy)
        kmax = nenergy - 1

        scale = 1.5d-1

        for k=1,(nenergy-2) do begin
          denergy = energy - energy[k]
          bkg_spec[0:k-1] += scale*odat.data[k]/denergy[0:k-1]^2.0
          bkg_spec[k+1:kmax] += scale*odat.data[k]/denergy[k+1:kmax]^2.0
        endfor
        bkg_spec[kndx] = !values.f_nan

        odat.data = bkg_spec
        bkg_dat = conv_units(odat, units)
        dif_dat = spec
        dif_dat.data = (spec.data - bkg_dat.data) > 1.
        oplot,bkg_dat.energy,bkg_dat.data,color=5,line=2
        oplot,dif_dat.energy,dif_dat.data,color=5,psym=10
      endif
    endif
    
    if keyword_set(bck) then begin
      bck = spec
      bck.data[*] = 5.6/16.  ; background crate per anode at periapsis
      bck.units_name = 'crate'
      mvn_swe_convert_units, bck, spec.units_name
      oplot, bck.energy, bck.data, line=2, color=4              ; periapsis
      oplot, bck.energy, bck.data*(0.97/0.63), line=2, color=4  ; apoapsis
      
      bck.data[*] = 1.071e6  ; saturation crate per anode
      bck.units_name = 'crate'
      mvn_swe_convert_units, bck, spec.units_name
      oplot, bck.energy, bck.data, line=2, color=4
    endif

    if (dopot) then begin
      if (finite(scp)) then pot = scp $
                       else if (finite(phi)) then pot = phi else pot = 0.
     
      oplot,[pot,pot],yrange,line=2,color=6
    endif
    
    if (dopep) then begin
      oplot,[23.,23.],yrange,line=2,color=1
      oplot,[27.,27.],yrange,line=2,color=1
    endif
    
    if (doalt) then begin
      dt = min(abs(alt.x - spec.time), aref)
      xyouts,xs,ys,string(round(alt.y[aref]), format='("ALT = ",i5)'),charsize=csize1,/norm
      ys -= dys
      if (~mb and ~mom) then begin
        xyouts,xs,ys,string(round(sza.y[aref]), format='("SZA = ",i5)'),charsize=csize1,/norm
        ys -= dys
      endif
    endif
    
    if (domag) then begin
      dt = min(abs(mag.x - spec.time), mref)
      str_element, mag, 'azim', success=ok
      if (ok) then begin
        xyouts,xs,ys,string(round(mag.azim[mref]), format='("Baz = ",i5)'),charsize=csize1,/norm
        ys -= dys
      endif
      str_element, mag, 'elev', success=ok
      if (ok) then begin
        xyouts,xs,ys,string(round(mag.elev[mref]), format='("Bel = ",i5)'),charsize=csize1,/norm
        ys -= dys
      endif
      str_element, mag, 'clock', success=ok
      if (ok) then begin
        xyouts,xs,ys,string(round(mag.clock[mref]), format='("Bclk = ",i5)'),charsize=csize1,/norm
        ys -= dys
      endif
    endif
    
    if (mb) then begin
      E1 = spec.energy
      F1 = spec.data - spec.bkg
      
      counts = conv_units(spec,'counts')
      cnts = counts.data
      sig2 = counts.var  ; variance w/ digitization noise
      sdev = F1 * (sqrt(sig2)/(cnts > 1.))

      p = swe_maxbol()
      if (finite(scp)) then p.pot = scp $
                       else if (finite(phi)) then p.pot = phi else p.pot = 0.

      psep = 2.0
      indx = where(E1 gt psep*p.pot)
      Fpeak = max(F1[indx],k,/nan)
      Epeak = E1[indx[k]]
      p.t = Epeak/2.
      p.n = Fpeak/(4.*c1*c2*sqrt(p.t)*exp((p.pot/p.t) - 2.))
      Elo = Epeak*0.7 < ((Epeak/2.) > (psep*phi))
      imb = where((E1 gt Elo) and (E1 lt Epeak*2.))

      if (n_elements(erange) gt 1) then begin
        Emin = min(erange, max=Emax)
        imb = where((E1 ge Emin) and (E1 le Emax))
      endif

      fit,E1[imb],F1[imb],dy=sdev[imb],func='swe_maxbol',par=p,names='N T',/silent
      
      N_core = p.n

      if (kap) then begin
        Fh = F1 - swe_maxbol(E1,par=p)
        ikap = where(E1 gt Epeak*3.)
        Fhmax = max(Fh[ikap],k,/nan)
        Ehmax = E1[ikap[k]]
        Th = Ehmax/2.

        p.k_n = Fhmax/(4.*c1*c2*sqrt(Th)*exp((p.pot/Th) - 2.))
        p.k_vh = sqrt(Ehmax/mass)
        
        ikap = where((E1 gt Epeak*0.8) and (E1 lt Epeak*25.))

        fit,E1[ikap],F1[ikap],func='swe_maxbol',par=p,names='N T K_N',/silent
        fit,E1[ikap],F1[ikap],func='swe_maxbol',par=p,names='N T K_N K_VH',/silent
;        fit,E1[indx],F1[indx],func='swe_maxbol',par=p,names='N T K_N K_VH K_K',/silent

        N_tot = p.n + p.k_n
        pk = p
        pk.n = 0.
        oplot,E1[ikap],swe_maxbol(E1[ikap],par=pk),color=3
      endif else begin
        dE = E1
        dE[0] = abs(E1[1] - E1[0])
        for i=1,62 do dE[i] = abs(E1[i+1] - E1[i-1])/2.
        dE[63] = abs(E1[63] - E1[62])

        j = where(E1 gt Epeak*2., n_e)
        E_halo = E1[j]
        F_halo = F1[j] - swe_maxbol(E_halo, par=p)
        oplot,E_halo,F_halo,color=1,psym=10
        prat = (p.pot/E_halo) < 1.

        N_halo = c3*total(dE[j]*sqrt(1. - prat)*(E_halo^(-1.5))*F_halo)
        N_tot = N_core + N_halo
      endelse

      jndx = where(E1 gt p.pot)
      col = 4
      oplot,E1[jndx],swe_maxbol(E1[jndx],par=p),thick=2,color=col,line=1
      oplot,E1[imb],swe_maxbol(E1[imb],par=p),color=col,thick=2
      xyouts,xs,ys,string(N_tot,format='("N = ",f5.2)'),color=col,charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(p.T,format='("T = ",f5.2)'),color=col,charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(p.pot,format='("V = ",f5.2)'),color=6,charsize=csize1,/norm
      ys -= dys
      if (kap) then begin
        xyouts,xs,ys,string(p.k_n,format='("Nh = ",f5.2)'),color=3,charsize=csize1,/norm
        ys -= dys
        xyouts,xs,ys,string(p.k_vh,format='("Vh = ",f6.0)'),color=3,charsize=csize1,/norm
        ys -= dys
        xyouts,xs,ys,string(p.k_k,format='("k = ",f5.2)'),color=3,charsize=csize1,/norm        
        ys -= dys
      endif else begin
        xyouts,xs,ys,string(N_halo,format='("Nh = ",f5.2)'),color=1,charsize=csize1,/norm
        ys -= dys
      endelse

      if (scat) then begin
        kndx = where((E1 gt phi) and (E1 lt Epeak), count)
        if (count gt 0L) then begin
          x_scat = E1[kndx]
          y_scat = F1[kndx] - swe_maxbol(E1[kndx], par=p)
          kndx = where(E1 le phi, count)
          if (count gt 0L) then begin
            x_scat = [x_scat, E1[kndx]]
            y_scat = [y_scat, F1[kndx]]
          endif
          oplot,x_scat,y_scat,color=3,psym=10
        endif
      endif
    endif

    if (mom) then begin
      eflux = conv_units(spec,'eflux')
      E1 = eflux.energy
      F1 = eflux.data - eflux.bkg

      dE = E1
      dE[0] = abs(E1[1] - E1[0])
      for i=1,62 do dE[i] = abs(E1[i+1] - E1[i-1])/2.
      dE[63] = abs(E1[63] - E1[62])

      if (n_elements(erange) gt 1) then begin
        Emin = min(erange, max=Emax)
        j = where((E1 ge Emin) and (E1 le Emax), n_e)
      endif else begin
        if (finite(scp)) then pot = scp $
                         else if (finite(phi)) then pot = phi else pot = 0.
        j = where(E1 gt pot, n_e)
        j = j[0:(n_e-2)]  ; one channel cushion from s/c potential
        n_e--
      endelse

      oplot,spec.energy[j],spec.data[j],color=1,psym=10

      prat = (pot/E1[j]) < 1.
      N_tot = c3*total(dE[j]*sqrt(1. - prat)*(E1[j]^(-1.5))*F1[j])      
      P_tot = (2./3.)*c3*total(dE[j]*((1. - prat)^1.5)*(E1[j]^(-0.5))*F1[j])
      temp = P_tot/N_tot  ; temperature corresponding to kinetic energy density

      xyouts,xs,ys,string(N_tot,format='("N = ",f6.3)'),color=1,charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(temp,format='("T = ",f6.2)'),color=1,charsize=csize1,/norm
      ys -= dys
      xyouts,xs,ys,string(pot,format='("V = ",f6.2)'),color=6,charsize=csize1,/norm
      ys -= dys
    endif
     
    if (dflg) then begin
      xyouts,xs,ys,'3D',charsize=csize1,/norm,color=4
      ys -= dys
    endif
    
    if (psflg) then pclose

    if (pflg) then begin
      wset, Pwin

      xs = 0.71
      ys = 0.90
      dys = 0.03

      if not keyword_set(pxlim) then xlim = [0.,30.] else xlim = minmax(pxlim)

      indx = where((df.v ge xlim[0]) and (df.v le xlim[1]))
      ymin = min(df.y[indx],/nan) < min(d2f.y[indx],/nan)
      ymax = max(df.y[indx],/nan) > max(d2f.y[indx],/nan)
      ylim = [floor(100.*ymin), ceil(100.*ymax)]/100.

      dt = min(abs(d2f.x - trange[0]), kref)
      px = reform(d2f.v[kref,*])
      py = reform(df.y[kref,*])
      py2 = reform(d2f.y[kref,*])    
      n_e = n_elements(py)

      zcross = py2 * shift(py2,1)
      zcross[0] = 1.
      indx = where((zcross lt 0.) and (py gt thresh[0]), ncross)
      
      title = string(spec.sc_pot,format='("Potential = ",f5.1," V")')
      plot,px,py,xtitle='Potential (V)',ytitle='dF and d2F',$
                  xrange=xlim,/xsty,yrange=ylim,/ysty,title=title,charsize=csize2
      oplot,[spec.sc_pot,spec.sc_pot],ylim,line=2,color=6
      oplot,px,py2,color=4
      oplot,xlim,[0,0],line=2
      oplot,xlim,[thresh,thresh],line=2,color=5      

      if (ncross gt 0L) then begin
        k = max(indx)  ; lowest energy feature above threshold
        pymax = py[k]
        pymin = pymax/3.

        while ((py[k] gt pymin) and (k lt n_e-1)) do k++
        kmax = k
        k = max(indx)
        while ((py[k] gt pymin) and (k gt 0)) do k--
        kmin = k
      
        dE = px[kmin] - px[kmax]
        if ((kmax eq (n_e-1)) or (kmin eq 0)) then dE = 2.*dEmax
      
        if (dE lt dEmax) then k = max(indx) else k = -1  ; only accept narrow features

        for j=0,(ncross-1) do oplot,[px[indx[j]],px[indx[j]]],ylim,color=2

        if (k gt 0) then begin
          xyouts,xs,ys,string(px[k],format='("V = ",f6.2)'),color=6,charsize=csize1,/norm
          oplot,[px[k],px[k]],ylim,color=6,line=2
        endif

        ys = ys - dys
        xyouts,xs,ys,string(dE,format='("dE = ",f6.2)'),charsize=csize1,/norm

      endif
    endif

; Print out housekeeping in another window

    if (hflg) then begin
      wset, Hwin
      
      csize = 1.4
      x1 = 0.05
      x2 = 0.75
      x3 = x2 - 0.12
      y1 = 0.95 - 0.035*findgen(28)
  
      fmt1 = '(f7.2," V")'
      fmt2 = '(f7.2," C")'
      fmt3 = '(i2)'
      
      j = jref

      k = swe_hsk[j].ssctl
      if (k lt 4) then tabnum = mvn_swe_tabnum(swe_hsk[j].chksum[k]) else tabnum = -1

      erase
      xyouts,x1,y1[0],/normal,"SWEA Housekeeping",charsize=csize
      xyouts,x1,y1[1],/normal,time_string(swe_hsk[j].time),charsize=csize
      xyouts,x1,y1[3],/normal,"P28V",charsize=csize
      xyouts,x2,y1[3],/normal,string(swe_hsk[j].P28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[4],/normal,"MCP28V",charsize=csize
      xyouts,x2,y1[4],/normal,string(swe_hsk[j].MCP28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[5],/normal,"NR28V",charsize=csize
      xyouts,x2,y1[5],/normal,string(swe_hsk[j].NR28V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[6],/normal,"MCPHV",charsize=csize
      xyouts,x2,y1[6],/normal,string(sigfig(swe_hsk[j].MCPHV,3),format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[7],/normal,"NRV",charsize=csize
      xyouts,x2,y1[7],/normal,string(swe_hsk[j].NRV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[9],/normal,"P12V",charsize=csize
      xyouts,x2,y1[9],/normal,string(swe_hsk[j].P12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[10],/normal,"N12V",charsize=csize
      xyouts,x2,y1[10],/normal,string(swe_hsk[j].N12V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[11],/normal,"P5AV",charsize=csize
      xyouts,x2,y1[11],/normal,string(swe_hsk[j].P5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[12],/normal,"N5AV",charsize=csize
      xyouts,x2,y1[12],/normal,string(swe_hsk[j].N5AV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[13],/normal,"P5DV",charsize=csize
      xyouts,x2,y1[13],/normal,string(swe_hsk[j].P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[14],/normal,"P3P3DV",charsize=csize
      xyouts,x2,y1[14],/normal,string(swe_hsk[j].P3P3DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[15],/normal,"P2P5DV",charsize=csize
      xyouts,x2,y1[15],/normal,string(swe_hsk[j].P2P5DV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[17],/normal,"ANALV",charsize=csize
      xyouts,x2,y1[17],/normal,string(swe_hsk[j].ANALV,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[18],/normal,"DEF1V",charsize=csize
      xyouts,x2,y1[18],/normal,string(swe_hsk[j].DEF1V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[19],/normal,"DEF2V",charsize=csize
      xyouts,x2,y1[19],/normal,string(swe_hsk[j].DEF2V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[20],/normal,"V0V",charsize=csize
      xyouts,x2,y1[20],/normal,string(swe_hsk[j].V0V,format=fmt1),charsize=csize,align=1.0
      xyouts,x1,y1[22],/normal,"ANALT",charsize=csize
      xyouts,x2,y1[22],/normal,string(swe_hsk[j].ANALT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[23],/normal,"LVPST",charsize=csize
      xyouts,x2,y1[23],/normal,string(swe_hsk[j].LVPST,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[24],/normal,"DIGT",charsize=csize
      xyouts,x2,y1[24],/normal,string(swe_hsk[j].DIGT,format=fmt2),charsize=csize,align=1.0
      xyouts,x1,y1[26],/normal,"SWEEP TABLE",charsize=csize
      xyouts,x2,y1[26],/normal,string(tabnum,format=fmt3),charsize=csize,align=1.0
    endif

; Get the next button press

    nplot++

    wset,Twin
    trange = 0
    ctime,trange,npoints=npts,/silent
    if (npts gt 1) then cursor,cx,cy,/norm,/up  ; make sure mouse button is released

    if (size(trange,/type) eq 5) then begin
      if (tflg) then begin
        if (npts eq 1) then begin
          dt = min(abs(trange[0] - tspec.time), i)
          spec = {time:tspec.time[i], data:reform(tspec.data[i,*]), $
                  energy:tspec.energy, units_name:tspec.units_name, $
                  sc_pot:0.}
        endif else begin
          tmin = min(trange, max=tmax)
          i = where((tspec.time ge tmin) and (tspec.time le tmax), count)
          if (count gt 0L) then begin
            spec = {time:mean(tspec.time[i]), data:average(tspec.data[i,*],1,/nan), $
                    energy:tspec.energy, units_name:tspec.units_name, sc_pot:0.}
          endif
        endelse
      endif else begin
        spec = mvn_swe_getspec(trange, /sum, archive=aflg, units=units, yrange=yrange)
  
        if (spflg) then begin
          if (finite(scp)) then pot = scp $
                           else if (finite(spec.sc_pot)) then pot = spec.sc_pot else pot = 0.
          spec = conv_units(spec,'df')
          spec.energy -= pot
          spec = conv_units(spec,units)
        endif
      endelse
      if (fflg) then yrange = drange
      if (hflg) then dt = min(abs(swe_hsk.time - trange[0]), jref)
    endif else ok = 0

  endwhile

  if (kflg) then begin
    wdelete, Ewin
    if (hflg) then wdelete, Hwin
    if (pflg) then wdelete, Pwin
  endif

  wset, Twin

  return

end
