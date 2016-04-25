;+
;PROCEDURE: mms_part_products
;PURPOSE:
;  Generate spectra from particle data 
;  Provides different angular view and angle restriction options in spacecraft and fac coords
;
;Inputs:
; Argument descriptions inline below.
;
;Outputs:
; Argument descriptions inline below
;
;Keywords:
; Argument description inline below
;
;Notes: 
;
;  TODO: Accept multiple arguments, loop
;
;$LastChangedDate: 2016-02-10 19:04:54 -0800 (Wed, 10 Feb 2016) $
;$LastChangedRevision: 19950 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/spedas/beta/mms_part_products/mms_part_products.pro $
;-

pro mms_part_products, $
                     in_tvarname, $ ;the tplot variable name for the MMS being processed
                     energy=energy,$ ;energy range
                     trange=trange,$
                     probe=probe,$ ;needed for some field aligned transforms
                                          
                     phi=phi_in,$ ;angle limist 2-element array [min,max], in degrees, spacecraft spin plane
                     theta=theta,$ ;angle limits 2-element array [min,max], in degrees, normal to spacecraft spin plane
                     pitch=pitch,$ ;angle limits 2-element array [min,max], in degrees, magnetic field pitch angle
                     gyro=gyro_in,$ ;angle limits 2-element array [min,max], in degrees, gyrophase  
   
                     outputs=outputs,$ ;list of requested output types (simpler than the angle=angle & /energy setup from before
                     
                     units=units,$ ;scalar unit conversion for data 
                     
                     regrid=regrid, $ ;When performing FAC transforms, loss of resolution in sample bins occurs.(because the transformed bins are not aligned with the sample bins)  
                                      ;To resolve this, the FAC distribution is resampled at higher resolution.  This 2 element array specifies that resolution.[nphi,ntheta]
                     
                     suffix=suffix, $ ;tplot suffix to apply when generating outputs
                     
                     datagap=datagap, $ ;setting for tplot variables, controls how long a gap must be before it is drawn.(can also manually degap)
                            
                     fac_type=fac_type,$ ;select the field aligned coordinate system variant. Existing options: "phigeo,mphigeo, xgse"
                     
                     mag_name=mag_name, $ ;tplot variable containing magnetic field data for moments and FAC transformations 
                     sc_pot_name=sc_pot_name, $ ;tplot variable containing spacecraft potential data for moments
                     pos_name=pos_name, $ ;tplot variable containing spacecraft position for FAC transformations
                  
                     error=error,$ ;indicate error to calling routine 1=error,0=success
                     
                     start_angle=start_angle, $ ;select a different start angle
                      
                     tplotnames=tplotnames, $ ;set of tplot variable names that were created
                   
                     display_object=display_object, $ ;object allowing dprint to export output messages

                     _extra=ex ;TBD: consider implementing as _strict_extra 


  compile_opt idl2
  
  twin = systime(/sec)
  error = 1
  
  
  if ~undefined(erange) then begin
    dprint,'ERROR: erange= keyword deprecated.  Using "energy=" instead.',dlevel=1
    return
  endif

  ;enable "best practices" keywords by default
  
  if undefined(outputs) then begin
    ;outputs = ['energy','phi','theta'] ;default to energy phi theta
    outputs = ['energy'] ;default changed at vassilis's request
  endif
  
  outputs_lc = strlowcase(outputs)
  if n_elements(outputs_lc) eq 1 then begin 
    outputs_lc = strsplit(outputs_lc,' ',/extract)
  endif


  if undefined(suffix) then begin
    suffix = ''
  endif
  
  
  ;units_lc = 'f (s!U3!N/cm!U6!N)'
  
  if undefined(units) then begin
    units_lc = 'eflux'
  endif else begin
    units_lc = strlowcase(units)
  endelse
  
  if undefined(datagap) then begin
     datagap = 600.
  endif

  if undefined(regrid) then begin
    regrid = [32,16] ;default 16 phi x 8 theta regrid
  endif

  if undefined(pitch) then begin
    pitch = [0,180.]
  endif 
  
  if undefined(theta) then begin
    theta = [-90,90.]
  endif 
  
  if undefined(phi_in) then begin
    phi = [0,360.]
  endif else begin
    if abs(phi_in[1]-phi_in[0]) gt 360 then begin
      dprint, 'ERROR: Phi restrictons must have range no larger than 360 degrees'
      return
    endif
    phi = spd_pgs_map_azimuth(phi_in)
    ;catch offset full ranges
    if phi[0] eq phi[1] then phi = [0,360.]
  endelse
  
  if undefined(gyro_in) then begin
    gyro = [0,360.]
  endif else begin
    if abs(gyro_in[1]-gyro_in[0]) gt 360 then begin
      dprint, 'ERROR: Gyrophase restrictons must have range no larger than 360 degrees'
      return
    endif
    gyro = spd_pgs_map_azimuth(gyro_in)
    ;catch offset full ranges
    if gyro[0] eq gyro[1] then gyro = [0,360.]
  endelse
  
  ;Create energy spectrogram after FAC transformation if limits are not 
  ;identical to the default.
  if ~array_equal(gyro,[0,360.]) or ~array_equal(pitch,[0,180.]) then begin
    idx = where(outputs_lc eq 'energy', nidx)
    if nidx gt 0 then begin
      outputs_lc[idx] = 'fac_energy'
    endif
  endif
  
;  if undefined(mag_name) then begin
;    mag_name = 'th'+probe_lc+'_fgs'
;  endif
;  
;  if undefined(pos_name) then begin
;    pos_name = 'th'+probe_lc+'_state_pos'
;  endif
  
  if is_struct(ex) then begin
    if in_set(strlowcase(tag_names(ex)),'scpot') then begin
      dprint,'ERROR: scpot keyword is deprecated.  Please use sc_pot_name'
      return
    endif else if in_set(strlowcase(tag_names(ex)),'scpot_suffix') then begin
      dprint,'ERROR: scpot_suffix keyword is deprecated.  Please use sc_pot_name'
      return
    endif
  endif
  
;  if undefined(sc_pot_name) then begin
;    sc_pot_name = 'th'+probe_lc+'_pxxm_pot' 
;  endif
  
  if undefined(fac_type) then begin
    fac_type = 'mphigeo'
  endif
  
  fac_type_lc = strlowcase(fac_type)
  
  ;If set, this prevents concatenation from previous calls
  undefine,tplotnames
  
  
  ;--------------------------------------------------------
  ;Get array of sample times and initialize indices for loop
  ;--------------------------------------------------------
  
  times = mms_get_dist(in_tvarname, /times)

  if size(times,/type) ne 5 then begin
    dprint,dlevel=1, 'No ',in_tvarname,' data has been loaded.
    return
  endif

  if ~undefined(trange) then begin

    trd = time_double(trange)
    time_idx = where(times ge trd[0] and times le trd[1], nt)

    if nt lt 1 then begin
      dprint,dlevel=1, 'No ',in_tvarname,' data for time range ',time_string(trd)
      return
    endif
    
  endif else begin
    time_idx = lindgen(n_elements(times))
  endelse
  
  times = times[time_idx]


  ;--------------------------------------------------------
  ;Prepare support data
  ;--------------------------------------------------------
  
  ;create rotation matrix to field aligned coordinates if needed
  if in_set(outputs_lc,'pa') || in_set(outputs_lc,'gyro') || in_set(outputs_lc,'fac_energy') then begin
    mms_pgs_make_fac,times,mag_name,pos_name,fac_output=fac_matrix,fac_type=fac_type_lc,display_object=display_object,probe=probe
    ;remove FAC outputs if there was an error, return if no outputs remain
    if undefined(fac_matrix) then begin
      outputs_lc = ssl_set_complement(['pa','gyro','fac_energy'],outputs_lc)
      if array_equal(outputs_lc,-1) then begin
        return
      endif
    endif
  endif
;  
;  ;get support data for moments calculation
;  if in_set(outputs_lc,'moments') then begin
;    if units_lc ne 'eflux' then begin
;      dprint,dlevel=1,'Warning: Moments can only be calculated if data is in eflux.  Skipping product.'
;      outputs_lc[where(outputs_lc eq 'moments')] = ''
;    endif else begin
;      mms_pgs_clean_support, times, probe_lc, mag_name, sc_pot_name, mag_out=mag_data, sc_pot_out=sc_pot_data
;    endelse
;  endif


  ;--------------------------------------------------------
  ;Loop over time to build the spectrograms/moments
  ;--------------------------------------------------------
  
  for i = 0,n_elements(time_idx)-1 do begin
  
    spd_pgs_progress_update,last_tm,i,n_elements(time_idx)-1,display_object=display_object,type_string=in_tvarname
  
    ;Get the data structure for this samgple
    ;only FPI, atm

    dist = mms_get_dist(in_tvarname,time_idx[i],/structure)

    ;Sanitize Data.
    ;#1 removes uneeded fields from struct to increase efficiency
    ;#2 Reforms into angle by energy data 
  
    mms_pgs_clean_data,dist,output=clean_data,units=units_lc
    
    ;Copy bin status prior to application of angle/energy limits.
    ;Phi limits will need to be re-applied later after phi bins
    ;have been aligned across energy (only necessary for ESA). 
    if (in_set(outputs_lc,'pa') || in_set(outputs_lc,'gyro') || in_set(outputs_lc,'fac_energy')) then begin
      pre_limit_bins = clean_data.bins 
    endif
    
    ;Apply phi, theta, & energy limits
    spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 
    
    ;Calculate moments
    ;  -data must be in 'eflux' units 
;    if in_set(outputs_lc, 'moments') then begin
;      thm_pgs_moments, clean_data, moments=moments, sigma=mom_sigma,delta_times=delta_times, get_error=get_error, mag_data=mag_data, sc_pot_data=sc_pot_data, index=i , _extra = ex
;    endif 
   
    ;Build theta spectrogram
    if in_set(outputs_lc, 'theta') then begin
      spd_pgs_make_theta_spec, clean_data, spec=theta_spec, yaxis=theta_y
    endif
    
    ;Build phi spectrogram
    if in_set(outputs_lc, 'phi') then begin
      spd_pgs_make_phi_spec, clean_data, spec=phi_spec, yaxis=phi_y
    endif
    
    ;Build energy spectrogram
    if in_set(outputs_lc, 'energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=en_spec, yaxis=en_y
    endif
    
    ;Perform transformation to FAC, regrid data, and apply limits in new coords
    if (in_set(outputs_lc,'pa') || in_set(outputs_lc,'gyro') || in_set(outputs_lc,'fac_energy')) then begin
      
      ;limits will be applied to energy-aligned bins
      clean_data.bins = temporary(pre_limit_bins)
      
      ;align bins across energies 
      ; -ensures smoother statistics and less jagged edges
      ; -better matches plots from tpm2
      spd_pgs_align_phi, clean_data
      spd_pgs_limit_range,clean_data,phi=phi,theta=theta,energy=energy 
      
      ;perform FAC transformation and interpolate onto a new, regular grid 
      spd_pgs_do_fac,clean_data,reform(fac_matrix[i,*,*],3,3),output=clean_data,error=error
      spd_pgs_regrid,clean_data,regrid,output=clean_data
      
      clean_data.theta = 90-clean_data.theta ;pitch angle is specified in co-latitude
      
      ;apply gyro & pitch angle limits(identical to phi & theta, just in new coords)
      spd_pgs_limit_range,clean_data,phi=gyro,theta=pitch
      
    endif
    
    ;Build pitch angle spectrogram
    if in_set(outputs_lc,'pa') then begin
      ;convert from latitude to co-latitude
      spd_pgs_make_theta_spec, clean_data, spec=pa_spec, yaxis=pa_y
    endif
    
    ;Build gyrophase spectrogram
    if in_set(outputs_lc, 'gyro') then begin
      spd_pgs_make_phi_spec, clean_data, spec=gyro_spec, yaxis=gyro_y
    endif
    
    ;Build energy spectrogram from field aligned distribution
    if in_set(outputs_lc, 'fac_energy') then begin
      spd_pgs_make_e_spec, clean_data, spec=fac_en_spec,  yaxis=fac_en_y
    endif
    
  endfor
 
 
  ;Place nans in regions outside the requested range
  ; -This is mainly to remove "bleeding" seen when limiting the range
  ;  along a coordinate where the data is not regularly gridded.
  ;  To obtain a complete spectrogram for the limited range all intersecting
  ;  bins must be used.  This means that many bins that intersect the 
  ;  limited range but may extend far past it are left active.
  ; -Currently, phi for ESA is the only non-regular case.
  spd_pgs_clip_spec, y=phi_y, z=phi_spec, range=phi
 
 
  ;--------------------------------------------------------
  ;Create tplot variables for requested data types
  ;--------------------------------------------------------

  tplot_prefix = in_tvarname+'_'
 

  ;NOTE: these test for generating spectra will not work if we decide to loop over probe/datatype
  
  ;Energy Spectrograms
  if ~undefined(en_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=en_y, z=en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
 
  ;Theta Spectrograms
  if ~undefined(theta_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'theta'+suffix, x=times, y=theta_y, z=theta_spec, yrange=theta,units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
  
  ;Phi Spectrograms
  if ~undefined(phi_spec) then begin
    ;phi range may be wrapped about phi=0, this keeps an invalid range from being passed to tplot
    phi_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    spd_pgs_make_tplot, tplot_prefix+'phi'+suffix, x=times, y=phi_y, z=phi_spec, yrange=phi_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    spd_pgs_shift_phi_spec, names=tplot_prefix+'phi'+suffix, start_angle=start_angle
  endif
  
  ;Pitch Angle Spectrograms
  if ~undefined(pa_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'pa'+suffix, x=times, y=pa_y, z=pa_spec, yrange=pitch,units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
  
  ;Gyrophase Spectrograms
  if ~undefined(gyro_spec) then begin
    ;gyro range may be wrapped about gyro=0, this keeps an invalid range from being passed to tplot
    gyro_y_range = (undefined(start_angle) ? 0:start_angle) + [0,360]
    spd_pgs_make_tplot, tplot_prefix+'gyro'+suffix, x=times, y=gyro_y, z=gyro_spec, yrange=gyro_y_range,units=units_lc,datagap=datagap,tplotnames=tplotnames
    spd_pgs_shift_phi_spec, names=tplot_prefix+'gyro'+suffix, start_angle=start_angle
  endif
  
  ;Field-Aligned Energy Spectrograms
  if ~undefined(fac_en_spec) then begin
    spd_pgs_make_tplot, tplot_prefix+'energy'+suffix, x=times, y=fac_en_y, z=fac_en_spec, ylog=1, units=units_lc,datagap=datagap,tplotnames=tplotnames
  endif
  
  ;Moments Variables
;  if ~undefined(moments) then begin
;    moments.time = times
;    thm_pgs_moments_tplot, moments, prefix=tplot_mom_prefix, suffix=suffix, tplotnames=tplotnames
;  endif
;  
;  ;Moments Error Esitmates
;  if ~undefined(mom_sigma) then begin
;    mom_sigma.time = times
;    thm_pgs_moments_tplot, mom_sigma, /get_error, prefix=tplot_mom_prefix, suffix=suffix, tplotnames=tplotnames
;  endif
;  
;  if ~undefined(delta_times) then begin
;    store_data,tplot_mom_prefix+'delta_time',data={x:times,y:delta_times},verbose=0
;    tplotnames = array_concat(tplot_mom_prefix+'delta_time',tplotnames)
;  endif
 
 
  error = 0
  
  dprint,'Complete. Runtime: ',systime(/sec) - twin,' secs' 
end
