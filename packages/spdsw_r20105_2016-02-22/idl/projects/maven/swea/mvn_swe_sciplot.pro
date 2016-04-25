;+
;PROCEDURE: 
;	mvn_swe_sciplot
;PURPOSE:
;	Creates a science-oriented summary plot for SWEA and MAG and optionally other 
;   instruments.
;
;   Warning: This routine can consume a large amount of memory:
;
;     SWEA + MAG : 0.6 GB/day
;     SEP        : 0.2 GB/day
;     SWIA       : 0.2 GB/day
;     STATIC     : 3.5 GB/day
;     LPW        : TBD
;     EUV        : TBD
;     -------------------------
;      total     : 4.5 GB/day
;
;   You'll also need memory for performing calculations on large arrays, so you
;   can create a plot with all data types spanning ~1 day per 8 GB of memory.
;
;AUTHOR: 
;	David L. Mitchell
;CALLING SEQUENCE: 
;	mvn_swe_sciplot
;INPUTS:
;   None:      Uses data currently loaded into the SWEA common block.
;
;KEYWORDS:
;   SUN:       Create a panel for the Sun direction in spacecraft coordinates.
;
;   RAM:       Create a panel for the RAM direction in spacecraft coordinates.
;
;   SEP:       Include two panels for SEP data: one for ions, one for electrons.
;
;   SWIA:      Include panels for SWIA ion density and bulk velocity (coarse
;              survey ground moments).
;
;   STATIC:    Include two panels for STATIC data: one mass spectrum, one energy
;              spectrum.
;
;   LPW:       Include panels for LPW data.
;
;   EUV:       Include a panel for EUV data.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-23 11:12:23 -0800 (Mon, 23 Nov 2015) $
; $LastChangedRevision: 19453 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sciplot.pro $
;
;-

pro mvn_swe_sciplot, sun=sun, ram=ram, sep=sep, swia=swia, static=static, lpw=lpw, euv=euv

  compile_opt idl2

  @mvn_swe_com

  mvn_swe_sumplot,/loadonly
  mvn_swe_sc_pot,/over
  engy_pan = 'swe_a4_pot'
  options,engy_pan,'ytitle','SWEA elec!ceV'

; Try to load resampled PAD data

  mvn_swe_pad_restore
  tname = 'mvn_swe_pad_resample'
  get_data,tname,index=i
  if (i gt 0) then begin
    pad_pan = tname
    options,tname,'ytitle','SWEA PAD!c(111-140 eV)'
  endif else pad_pan = 'swe_a2_280'

; Spacecraft orientation

  alt_pan = 'alt2'

  if keyword_set(sun) then begin
    mvn_swe_sundir
    sun_pan = 'Sun_MAVEN_SPACECRAFT'
    get_data,sun_pan,index=i
    if (i gt 0) then begin
      options,sun_pan,'ytitle','Sun (PL)'
    endif else sun_pan = ''
  endif else sun_pan = ''

  if keyword_set(ram) then begin
    mvn_sc_ramdir
    ram_pan = 'V_sc_MAVEN_SPACECRAFT'
    get_data,ram_pan,index=i
    if (i gt 0) then begin
      options,ram_pan,'ytitle','RAM (PL)!ckm/s'
    endif else ram_pan = ''
  endif else ram_pan = ''

; MAG data

  mvn_swe_addmag
  mvn_mag_geom
  mvn_mag_tplot, /model
  
  mag_pan = 'mvn_mag_bamp mvn_mag_bang'

; SEP electron and ion data - sum all look directions for both units

  sep_pan = ''
  if keyword_set(sep) then mvn_swe_addsep, pans=sep_pan

; SWIA survey data

  swi_pan = ''
  if keyword_set(swia) then mvn_swe_addswi, pans=swi_pan

; STATIC data

  sta_pan = ''
  if keyword_set(static) then mvn_swe_addsta, pans=sta_pan

; LPW data

  lpw_pan = ''
  if keyword_set(lpw) then mvn_swe_addlpw, pans=lpw_pan

; EUV data

  euv_pan = ''
  if keyword_set(euv) then mvn_swe_addeuv, pans=euv_pan

; Assemble the panels and plot

  pans = ram_pan + ' ' + sun_pan + ' ' + alt_pan + ' ' + euv_pan + ' ' + $
         swi_pan + ' ' + sta_pan + ' ' + mag_pan + ' ' + sep_pan + ' ' + $
         lpw_pan + ' ' + pad_pan + ' ' + engy_pan

  tplot, pans

  return

end
