;+
;Procedure:
;     mms_feeps_spin_avg
;
;Purpose:
;     spin-averages FEEPS spectra using the '_spinsectnum' 
;       variable (variable containing spin sector #s associated 
;       with each measurement)
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-17 14:31:07 -0800 (Wed, 17 Feb 2016) $
;$LastChangedRevision: 20053 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_spin_avg.pro $
;-
pro mms_feeps_spin_avg, probe=probe, data_units = data_units, datatype = datatype, $
  suffix = suffix
  if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
  if undefined(datatype) then datatype = 'electron'
  if undefined(data_units) then data_units = 'flux'
  if undefined(suffix) then suffix=''

  prefix = 'mms'+probe+'_epd_feeps_'

  ; get the spin sectors
  get_data, prefix + 'spinsectnum'+suffix, data=spin_sectors
  
  if ~is_struct(spin_sectors) then begin
      dprint, dlevel = 0, 'Error, couldn''t find the tplot variable containing the spin sectors for calculating the spin averages.'
  endif

  spin_starts = where(spin_sectors.Y[0:n_elements(spin_sectors.Y)-2] ge spin_sectors.Y[1:n_elements(spin_sectors.Y)-1])+1
 
  prefix = 'mms'+probe+'_epd_feeps_'
  var_name = prefix+datatype+'_'+data_units+'_omni'+suffix
  get_data, var_name, data=flux_data, dlimits=flux_dl

  if ~is_struct(flux_data) || ~is_struct(flux_dl) then begin
    dprint, dlevel = 0, 'Error, no data or metadata for the variable: ' + prefix+suffix
    return
  endif

  spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(flux_data.Y[0, *]))

  current_start = spin_starts[0]
  ; loop through the spins for this telescope
  for spin_idx = 1, n_elements(spin_starts)-1 do begin
    spin_sum_flux[spin_idx-1, *] = average(flux_data.Y[current_start:spin_starts[spin_idx], *], 1)

    current_start = spin_starts[spin_idx]+1
  endfor

  store_data,var_name+'_spin'+suffix, data={x: flux_data.X[spin_starts], y: spin_sum_flux, v: flux_data.V}, dlimits=flux_dl
  options, var_name+'_spin'+suffix, spec=1
  
  ylim, var_name+'_spin'+suffix, 50., 600., 1
  zlim, var_name+'_spin'+suffix, 0, 0, 1

end