;+
;PROCEDURE:   mvn_swe_swi_cal
;PURPOSE:
;  Compares ion density from SWIA and electron density from SWEA for the purpose 
;  of cross calibration.  Beware of situations where SWEA and/or SWIA are not
;  measuring important parts of the distribution.  Furthermore, SWEA data must be
;  corrected for spacecraft potential (see mvn_swe_sc_pot), and photoelectron 
;  contamination must be removed for any hope of a decent cross calibration.
;
;USAGE:
;  mvn_swe_swi_cal
;
;INPUTS:
;       None.  Uses the current value of TRANGE_FULL to define the time range
;       for analysis.  Calls timespan, if necessary, to set this value.
;
;KEYWORDS:
;       FINE:      Select SWIA 'fine' data for comparison with SWEA.  Default
;                  is to use 'coarse' data.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-18 14:44:42 -0700 (Mon, 18 May 2015) $
; $LastChangedRevision: 17642 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_swi_cal.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_swe_swi_cal, fine=fine

  tplot_options, get=opt
  if (max(opt.trange_full) eq 0D) then timespan

; Load SWEA data and create summary plot

  mvn_swe_load_l0
  mvn_swe_sumplot,/eph,/orb,/loadonly

; Get illumination of SWEA (to evaluate sunlight contamination)

  mvn_swe_sundir
  pans = ['Sun_The','Sun_Phi','alt2']
  
; Load MAG data

  mvn_swe_addmag
  mvn_mag_load,spice_frame='mso'
  options,'mvn_B_1sec_mso','ytitle','B!dMSO!n [nT]'

; Calculate spacecraft potential from SWEA data

  mvn_swe_sc_pot,/over
  mvn_swe_n1d,/mom
  get_data,'mvn_swe_spec_dens',data=den
  store_data,'mvn_swe_n1d_over',data={x:den.x, y:den.y}
  options,'mvn_swe_n1d_over','color',6
  options,'mvn_swe_n1d_over','psym',-3

; Load SWIA fine spectra

  if keyword_set(fine) then begin
    mvn_swia_load_l2_data, /loadfine, /tplot
    mvn_swia_part_moments, type=['fs','fa']
    options,'mvn_swifs_density','ynozero',1
    get_data,'mvn_swifs_density',data=den
    dt = den.x - shift(den.x,1)
    indx = where(dt gt 600D, count)
    if (count gt 0L) then den.y[indx] = !values.f_nan
    store_data,'mvn_swifs_density',data=den
    store_data,'ie_density',data=['mvn_swifs_density','mvn_swe_n1d_over']
    options,'ie_density','ynozero',1
    options,'ie_density','ytitle','Ion-Electron!CDensity'

    div_data,'mvn_swe_spec_dens','mvn_swifs_density'
    divname = 'mvn_swe_spec_dens/mvn_swifs_density'
    options,divname,'ynozero',1
    options,divname,'ytitle','Ratio!CSWE/SWI'
    options,divname,'yticklen',1
    options,divname,'ygridstyle',1

    pans = [pans,'mvn_swe_spec_dens/mvn_swifs_density', $
            'ie_density','mvn_B_1sec_mso','swe_a4_pot']
  endif else begin
    mvn_swia_load_l2_data, /loadcoarse, /tplot
    mvn_swia_part_moments, type=['cs','ca']
    options,'mvn_swics_density','ynozero',1
    get_data,'mvn_swics_density',data=den
    dt = den.x - shift(den.x,1)
    indx = where(dt gt 600D, count)
    if (count gt 0L) then den.y[indx] = !values.f_nan
    store_data,'mvn_swics_density',data=den
    store_data,'ie_density',data=['mvn_swics_density','mvn_swe_n1d_over']
    options,'ie_density','ynozero',1
    options,'ie_density','ytitle','Ion-Electron!CDensity'

    div_data,'mvn_swe_spec_dens','mvn_swics_density'
    divname = 'mvn_swe_spec_dens/mvn_swics_density'
    options,divname,'ynozero',1
    options,divname,'ytitle','Ratio!CSWE/SWI'
    options,divname,'yticklen',1
    options,divname,'ygridstyle',1

    pans = [pans,'mvn_swe_spec_dens/mvn_swics_density', $
            'ie_density','mvn_B_1sec_mso','swe_a4_pot']
  endelse

  tplot,pans

  return

end
