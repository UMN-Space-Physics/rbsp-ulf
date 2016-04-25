;+
;PROCEDURE:   mvn_swe_calib
;PURPOSE:
;  Maintains SWEA calibration factors in a common block (mvn_swe_com).
;
;USAGE:
;  mvn_swe_calib
;
;INPUTS:
;
;KEYWORDS:
;       TABNUM:       Table number (1-6) corresponding to predefined settings:
;
;                       1 : Xmax = 6., Vrange = [0.75, 750.], V0scale = 1., /old_def
;                           primary table for ATLO and Inner Cruise (first turnon)
;                             -64 < Elev < +66 ; 7 < E < 4650
;                              Chksum = 'CC'X
;
;                       2 : Xmax = 6., Vrange = [0.75, 375.], V0scale = 1., /old_def
;                           alternate table for ATLO and Inner Cruise (never used)
;                             -64 < Elev < +66 ; 7 < E < 2340
;                              Chksum = '1E'X
;
;                       3 : Xmax = 5.5, Vrange = [3./Ka, 750.], V0scale = 0., /old_def
;                           primary table for Outer Cruise
;                             -59 < Elev < +61 ; 3 < E < 4630
;                              Chksum = 'C0'X
;                              GSEOS svn rev 8360
;
;                       4 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1., /old_def
;                           alternate table for Outer Cruise
;                             -59 < Elev < +61 ; 3 < E < 4650
;                              Chksum = 'DE'X
;                              GSEOS svn rev 8361
;
;                       5 : Xmax = 5.5, Vrange = [3./Ka, 750.], V0scale = 0.
;                           primary table for Transition and Science
;                             -59 < Elev < +61 ; 3 < E < 4630
;                              Chksum = 'CC'X
;                              GSEOS svn rev 8481
;
;                       6 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1.
;                           alternate table for Transition and Science
;                             -59 < Elev < +61 ; 3 < E < 4650
;                              Chksum = '82'X
;                              GSEOS svn rev 8482
;
;                     Default = 3 (outer cruise, VO disabled).
;                     Passed to mvn_swe_sweep.pro.
;
;       CHKSUM:       Specify the sweep table by its checksum.  See above.
;                     This only works for table numbers > 3.
;
;       DFGON:        Turn on the elevation-dependent sensitivity.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-04 17:42:27 -0800 (Wed, 04 Nov 2015) $
; $LastChangedRevision: 19249 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_calib.pro $
;
;CREATED BY:    David L. Mitchell  03-29-13
;FILE: mvn_swe_calib.pro
;-
pro mvn_swe_calib, tabnum=tabnum, chksum=chksum, dgfon=dgfon

  @mvn_swe_com

; Set the SWEA Ground Software Version

    mvn_swe_version = 3

; Initialize

  if (size(swe_hsk_str,/type) ne 8) then mvn_swe_init

; Find the first valid LUT
;   chksum =   0B means SWEA has just powered on
;   chksum = 255B means SWEA is loading tables

  ok = 0

  if (not ok) then begin
    if keyword_set(tabnum) then begin
      swe_active_chksum = mvn_swe_tabnum(tabnum,/inverse)
      if (size(swe_hsk,/type) ne 8) then begin
        tplot_options, get=topt
        swe_hsk = replicate(swe_hsk_str,2)
        swe_hsk.time = topt.trange_full
        swe_hsk.chksum = swe_active_chksum
        swe_chksum = swe_hsk.chksum
      endif
      if (swe_active_chksum ne 0B) then ok = 1
    endif
  endif

  if (not ok) then begin
    if keyword_set(chksum) then begin
      swe_active_chksum = chksum
      tabnum = mvn_swe_tabnum(swe_active_chksum)
      if (size(swe_hsk,/type) ne 8) then begin
        tplot_options, get=topt
        swe_hsk = replicate(swe_hsk_str,2)
        swe_hsk.time = topt.trange_full
        swe_hsk.chksum = swe_active_chksum
        swe_chksum = swe_hsk.chksum
      endif
      if (tabnum ne 0) then ok = 1
    endif
  endif

  if (not ok) then begin
    if (size(swe_hsk,/type) eq 8) then begin
      nhsk = n_elements(swe_hsk)
      lutnum = swe_hsk.ssctl      ; active LUT number
      swe_chksum = bytarr(nhsk)   ; checksum of active LUT
    
      for i=0L,(nhsk-1L) do swe_chksum[i] = swe_hsk[i].chksum[lutnum[i] < 3]
      indx = where(lutnum gt 3, count)
      if (count gt 0L) then swe_chksum[indx] = 'FF'XB  ; table load during turn-on
    
      indx = where((swe_chksum gt 0B) and (swe_chksum lt 255B), count)
      if (count gt 0L) then begin
        swe_active_chksum = swe_chksum[indx[0]]
        tabnum = mvn_swe_tabnum(swe_active_chksum)
        if (tabnum ne 0) then ok = 1
      endif
    endif else print,"No SWEA housekeeping."
  endif

  if (not ok) then begin
    print,"No valid table number or checksum."
    print,"Cannot determine calibration factors."
    return
  endif

  print, tabnum, swe_active_chksum, format='("LUT: ",i2.2,3x,"Checksum: ",Z2.2)'

; Integration time per energy/angle bin prior to summing bins.
; There are 7 deflection bins for each of 64 energy bins spanning
; 1.95 sec.  The first deflection bin is for settling and is
; discarded.

  swe_duty = (1.95D/2D)*(6D/7D)  ; duty cycle (fraction of time counts are accumulated)
  swe_integ_t = 1.95D/(7D*64D)   ; integration time per energy/deflector bin

; Analyzer constant (calibrations show 1.4% variation in azimuth caused
; by slight misalignment of the hemispheres)

  swe_Ka = 6.17
  
; Energy Sweep

; Generate initial sweep table

  mvn_swe_sweep, tabnum=tabnum, result=swp

; Energy Sweep
 
  swe_swp = fltarr(64,3)         ; energy for group=0,1,2

  swe_swp[*,0] = swp.e
  for i=0,31 do swe_swp[(2*i):(2*i+1),1] = sqrt(swe_swp[(2*i),0] * swe_swp[(2*i+1),0])
  for i=0,15 do swe_swp[(4*i):(4*i+3),2] = sqrt(swe_swp[(4*i),1] * swe_swp[(4*i+3),1])

  energy = swe_swp[*,0]
  denergy = energy
  denergy[0] = abs(energy[0] - energy[1])
  for i=1,62 do denergy[i] = abs(energy[i-1] - energy[i+1])/2.
  denergy[63] = abs(energy[62] - energy[63])

  swe_energy  = energy
  swe_denergy = denergy

; Energy Resolution (dE/E, FWHM), which can be a function of elevation, 
; so this array has an additional dimension.  Calibrations show that the
; variation with elevation is modest (< 1% from +55 to -30 deg, increasing
; to 4% at -45 deg).
  
  swe_de = fltarr(6,64,3)        ; energy resolution for group=0,1,2
  
  for i=0,5 do swe_de[i,*,0] = swp.de * swp.e

  for i=0,31 do begin
    swe_de[*,(2*i),1] = (swe_swp[(2*i),0]   + swe_de[*,(2*i),0]/2.) - $
                        (swe_swp[(2*i+1),0] - swe_de[*,(2*i+1),0]/2.)
    swe_de[*,(2*i+1),1] = swe_de[*,(2*i),1]
  endfor

  for i=0,15 do begin
    swe_de[*,(4*i),2] = (swe_swp[(4*i),0]   + swe_de[*,(4*i),0]/2.) - $
                        (swe_swp[(4*i+3),0] - swe_de[*,(4*i+3),0]/2.)
    for j=1,3 do swe_de[*,(4*i+j),2] = swe_de[*,(4*i),2]
  endfor

; Deflection Angle

  swe_el = fltarr(6,64,3)        ; 6 el bins per energy step for group=0,1,2
  
  swe_el[*,*,0] = swp.theta
  for i=0,31 do begin
    swe_el[*,(2*i),1] = (swe_el[*,(2*i),0] + swe_el[*,(2*i+1),0])/2.
    swe_el[*,(2*i+1),1] = swe_el[*,(2*i),1]
  endfor

  for i=0,15 do begin
    swe_el[*,(4*i),2] = (swe_el[*,(4*i),1] + swe_el[*,(4*i+3),1])/2.
    for j=1,3 do swe_el[*,(4*i+j),2] = swe_el[*,(4*i),2]
  endfor

; Deflection Angle Range

  swe_del = fltarr(6,64,3)            ; 6 del bins per energy step for group=0,1,2

  for j=0,2 do for i=0,63 do swe_del[*,i,j] = median(swe_el[*,i,j] - shift(swe_el[*,i,j],1))

; Azimuth Angle and Range

  swe_az = 11.25 + 22.5*findgen(16)   ; azimuth bins in SWEA science coord.
  swe_daz = replicate(22.5,16)        ; nominal widths

; Pitch angle mapping lookup table

  mvn_swe_padlut, lut=lut, dlat=22.5  ; table used in flight software
  swe_padlut = lut

; Geometric Factor
;   Simulations give a geometric factor of 0.03 (ignoring grids, posts, MCP 
;   efficiency, scattering, and fringing fields).
;
;      posts          : 0.8  (7 deg per post * 8 posts)
;      entrance grid  : 0.7  (for both grids combined)
;      exit grid      : 0.9
;      MCP Efficiency : 0.7  (nominal, energy dependent)
;    -------------------------
;      product        : 0.35
;
;   Total estimated geometric factor from simulations: 0.03 * 0.35 = 0.01
;
;   The measured geometric factor is 0.009 (IRAP calibration).  When using V0,
;   deceleration of the incoming electrons effectively reduces the geometric
;   factor in an energy dependent manner (see mvn_swe_sweep for details).
;   This geometric factor includes the absolute MCP efficiency, since it is 
;   based on analyzer measurements in a calibrated beam.  This geometric factor
;   does not take into account cross calibration with SWIA, STATIC, and LPW.

  geom_factor = 0.009/16.            ; geometric factor per anode (cm2-ster-eV/eV)

  swe_gf = replicate(!values.f_nan,64,3)

  swe_gf[*,0] = geom_factor*swp.gfw
  for i=0,31 do swe_gf[(2*i):(2*i+1),1] = (swe_gf[(2*i),0] + swe_gf[(2*i+1),0])/2.
  for i=0,15 do swe_gf[(4*i):(4*i+3),2] = (swe_gf[(4*i),1] + swe_gf[(4*i+3),1])/2.

; Correction factor from cross calibration with SWIA in the solar wind or sheath.
; This factor changes whenever an MCP bias correction is made.  The times of
; these corrections are recorded in mvn_swe_config.  These values are derived by
; comparing electron moments based on the SPEC data product to SWIA ion moments.
; The SPEC product sums over all 96 solid angle bins, weighted by cos(theta).
; However, 10 of the 96 bins are blocked by the spacecraft but are still included
; in the sum.  This produces a ~10% underestimate of the mean differential energy
; flux.  The cross calibration factors below absorb this underestimate.  A future
; update should apply the 10% underestimate only to the SPEC spec data.
;
;     Factor		Calib. Date                    Note
;   ---------------------------------------------------------------------------------
;      2.585        2014-10-14/12:10 to 13:50      S/C in sun point (rare in trans.)
;      2.275        2014-12-21                     Steady solar wind; S/C sun point
;

  swe_crosscal = [2.585, 2.275]

; Add a dimension for relative variation among the 16 anodes.  This variation is
; dominated by the MCP efficiency, but I include the same dimension here for ease
; of calculation later.

  swe_gf = replicate(1.,16) # reform(swe_gf,64*3)
  swe_gf = transpose(reform(swe_gf,16,64,3),[1,0,2])

; Relative MCP efficiency
;   Note that absolute efficiency is incorporated into IRAP geometric factor.
;   The efficiency is energy dependent, peaking at around 300 eV, then falling 
;   gradually with increasing energy.  For SWEA, electrons are accelerated from 
;   the analyzer exit grid (V0) to the top of the MCP stack (+300 V).  If one
;   uses the electron energy before entering the instrument (E), then the effect
;   of V0 cancels, so the energy of an electron when it strikes the top of the 
;   MCP stack is E + 300.
;
;   The following is from Goruganthu & Wilson (Rev. Sci. Instr. 55, 2030, 1984), 
;   which fits experimental data up to 2 keV to within 2%.  (There is a typo in
;   Equation 4 of that paper.)  I extrapolate from 2 to 4.6 keV.

  alpha = 1.35
  Tmax = 2.283
  Emax = 325.
  k = 2.2

  Vbias = 300.                   ; pre-acceleration for SWEA
  Erat = (swe_swp + Vbias)/Emax  ; effect of V0 cancels when using swe_swp
  arg = Tmax*(Erat^alpha) < 80.  ; avoid underflow

  delta = (Erat^(1. - alpha))*(1. - exp(-arg))/(1. - exp(-Tmax))
  swe_mcp_eff = (1. - exp(-k*delta))/(1. - exp(-k))

; IRAP geometric factor was calibrated at 1.4 keV, so scale the MCP efficiency 
; to unity at that energy.

  Erat = (1400. + Vbias)/Emax
  delta = (Erat^(1. - alpha))*(1. - exp(-Tmax*(Erat^alpha)))/(1. - exp(-Tmax))
  eff0 = (1. - exp(-k*delta))/(1. - exp(-k))
  
  swe_mcp_eff = swe_mcp_eff/eff0

; Now include variation of MCP efficiency with anode.  This is from a rotation
; scan at 1 keV performed on 2013-02-27.  This is expected to change gradually
; in flight, with discrete jumps when the MCP HV is adjusted.
  
  swe_rgf = [0.86321, 1.09728, 1.04393, 0.88254, 0.95927, 1.07825, $
             1.07699, 0.93499, 1.04213, 1.12928, 1.11343, 0.94783, $
             0.87957, 0.96588, 1.00358, 0.98184                     ]

  swe_mcp_eff = swe_rgf # reform(swe_mcp_eff,64*3)
  swe_mcp_eff = transpose(reform(swe_mcp_eff,16,64,3),[1,0,2])

; Analyzer elevation response (from IRAP calibrations, averaged over the six
; elevation bins).  Normalization: mean(swe_dgf) = 1.  Note that rotation
; scans at different yaws in the large SSL vacuum chamber confirm behavior of
; this sort.

  p = { a0 :  5.417775771d-03, $
        a1 :  1.911692997d-05, $
        a2 :  1.067720924d-06, $
        a3 : -2.341636265d-08, $
        a4 : -4.758984454d-10, $
        a5 :  3.831231544e-12   }

  theta = findgen(131) - 65.
  dgf = polycurve(theta,par=p)
  swe_dgf = fltarr(6,64,3)
  
  th_min = swp.th1 < swp.th2
  th_max = swp.th1 > swp.th2
  
  for i=0,5 do begin
    for j=0,63 do begin
      indx = where((theta ge th_min[i,j]) and (theta le th_max[i,j]))
      swe_dgf[i,j,0] = mean(dgf[indx])
    endfor
  endfor

  for i=0,31 do begin
    swe_dgf[*,(2*i),1] = (swe_dgf[*,(2*i),0] + swe_dgf[*,(2*i+1),0])/2.
    swe_dgf[*,(2*i+1),1] = swe_dgf[*,(2*i),1]
  endfor

  for i=0,15 do begin
    swe_dgf[*,(4*i),2] = (swe_dgf[*,(4*i),1] + swe_dgf[*,(4*i+3),1])/2.
    for j=1,3 do swe_dgf[*,(4*i+j),2] = swe_dgf[*,(4*i),2]
  endfor

; Normalize: mean(swe_dgf[*,i,j]) = 1.

  for i=0,63 do begin
    for j=0,2 do begin
      swe_dgf[*,i,j] = swe_dgf[*,i,j]/mean(swe_dgf[*,i,j])
    endfor
  endfor
  
  swe_dgf = transpose(swe_dgf,[1,0,2])

  if not keyword_set(dgfon) then swe_dgf[*] = 1.

; Spacecraft blockage mask (~27% of sky, deployed boom, approximate)
;   Complete blockage: 0, 1, 2, 3, 17, 18
;   Partial blockage: 4, 14 & 15 (summed onboard), 16, 19, 20, 30, 31

  swe_sc_mask = replicate(1B, 96, 2)  ; 96 solid angle bins, 2 boom states
  
  swe_sc_mask[0:31,0] = 0B                                    ; stowed boom
;  swe_sc_mask[[0,1,2,3,4,14,15,16,17,18,19,20,30,31],1] = 0B ; deployed boom
  swe_sc_mask[[0,1,2,3,14,15,16,17,18,31],1] = 0B             ; deployed boom

; Dead time (from IRAP calibration: MCP-Anode-Preamp chain)
; This is for ONE of the 16 chains.  Energy spectra combine all 16 chains, so
; the deadtime correction is different for APID's A4 and A5.

  swe_dead = 2.8e-6              ; IRAP calibration, one MCP-Anode-Preamp chain
  swe_min_dtc = 0.25             ; max 4x deadtime correction

; Electron rest mass

  c = 2.99792458D5               ; velocity of light [km/s]
  mass_e = (5.10998910D5)/(c*c)  ; electron rest mass [eV/(km/s)^2]

  return

end
