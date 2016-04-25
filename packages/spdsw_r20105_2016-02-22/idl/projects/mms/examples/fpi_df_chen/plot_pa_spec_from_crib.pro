;+
;PROCEDURE: plot_pa_spec_from_crib
;PURPOSE: 
;  It is a crib sheet for plotting fpi energy spectra using
;  the TPLOT package
;
;INPUT
;PARAMETERS:   sat:        Satellite number
;              specie:  'i' or 'e'
;              units_name: Units for energy spectra
;                          'Counts', 'DF',
;                           'DIFF FLUX', 'EFLUX'
;              energy: energy range for pa spectra
;              eff_table: 0: ground, 1: onboard --meaningless right
;now
;              pabin: pa bins size, default: 6 degrees
;              all_energy_bins: if set, calculate pa distributions for
;all energies
;              reload3d: if set, call fpi_3dflux_2dbin to store [time,
;angular bin, energy] structures for the requested time
;              resolution: data resolution, default: brst
;
;CREATED BY: Shan Wang, based on the same code for cis in CCAT
;
;LAST MODIFIED: 07/09/2015
;
;MODIFICATION HISTORY:
;-

PRO plot_pa_spec_from_crib, sat, specie,  units_name, $
                            energy, eff_table, $
                            PABIN=PABIN, $
                            datab=datab,$
                            ALL_ENERGY_BINS=ALL_ENERGY_BINS,$
                            reload3d = reload3d,$
                            resolution=resolution
  
  COMMON get_error, get_err_no, get_err_msg, default_verbose
  
  ; Check if sat and specie arrays have the same number of elements
  IF n_elements(sat) NE n_elements(specie) THEN BEGIN
    print, 'The sat array and the specie array MUST have'
    print, 'the same number of elements.'
    stop
  ENDIF
  
  ; Loop over all sat/specie combinations
  FOR ii=0,n_elements(specie)-1 DO BEGIN
    
    get_err_no = 0 ; reset error indicator
   
      
      name = 'PASPEC' + $
        '_EN' + STRCOMPRESS(STRING(energy(0), format='(i5.5)'),/REMOVE_ALL) + $
        '_'   + STRCOMPRESS(STRING(energy(1), format='(i5.5)'),/REMOVE_ALL) + $
        '_mms' + STRCOMPRESS(sat(ii),/REMOVE_ALL) + $
        '_UN' + STRUPCASE(strcompress(units_name,/REMOVE_ALL)) + $
        '_FPI' + STRCOMPRESS(specie(ii),/REMOVE_ALL) 
      
      if keyword_set(reload3d) then begin
         fpi_3dflux_2dbin,sat,specie[ii],resolution=resolution,units_name='df',$
                          thebdata=datab
      endif
      dat = call_function('get_fpi_3dflux_2dbin',sat,specie[ii],resolution=resolution,units_name='df')
      
      IF get_err_no EQ 0 THEN BEGIN ;check if data were found for time interval
        found = 1
        
         get_err_no = 0
        get_theta_phi, sat, dat, mag_theta, mag_phi, $
          datab = datab, /ave           ; get magnetic field data

        IF get_err_no NE 0 THEN GOTO, next

        ;all_energy_bins = 1
        get_fpi_pa_spec,   $
          sat(ii),           $
          mag_theta,         $
          mag_phi,           $
          specie=specie(ii), $
          eff_table,         $
           dat = dat,        $
          angle=angle,       $
          energy=energy,     $
          units=units_name,  $
          name=name,         $
          pabin=pabin,       $
          all_energy_bins=all_energy_bins

      ENDIF

      read:

      IF get_err_no GT 0 THEN GOTO, next

      IF NOT KEYWORD_SET(ALL_ENERGY_BINS) THEN BEGIN
        ; Combine the different product of the same specie
        enrange=STRCOMPRESS(STRING(energy(0), format='(i5.5)'),/REMOVE_ALL) + $
          '_'   + STRCOMPRESS(STRING(energy(1), format='(i5.5)'),/REMOVE_ALL)
         
        ; Set plot attributes
        CASE STRUPCASE(units_name) OF
          'COUNTS': uname = 'COUNTS'
          'NCOUNTS': uname = '1/bin'
          'RATE': uname = '1/s'
          'NRATE': uname = '1/s-bin'
          'EFLUX': uname = 'eV/cm!E2!N-s-sr-eV'
          'DIFF FLUX': uname = '1/cm!E2!N-s-sr-(eV/e)'
          'DF': uname = 's!E3!N/cm!E6!N'
        ENDCASE
        
        options, name, 'spec',1
        options, name, 'x_no_interp',1
        options, name, 'y_no_interp',1
        options, name, 'ytitle', $
          'mms' + string(sat(ii), format='(i1.1)') + '!C' + $
          specie(ii) + ' ' + $
          STRCOMPRESS(STRING(energy(0), format='(i5)'),/REMOVE_ALL) + '-' + $
          STRCOMPRESS(STRING(energy(1), format='(i5)'),/REMOVE_ALL) + ' (eV)'
        options, name, 'ztitle', uname

          ylim,    name,  0., 180., 0
          zlim,name,0,0,1
        
      ENDIF
      next:
  ENDFOR


END

