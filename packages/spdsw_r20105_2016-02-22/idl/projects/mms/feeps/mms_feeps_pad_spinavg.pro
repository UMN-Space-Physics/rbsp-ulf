;+
; PROCEDURE:
;         mms_feeps_pad_spinavg
;
; PURPOSE:
;         Spin-averages FEEPS pitch angle distributions
;
; KEYWORDS:
;         probe: value for MMS SC #
;         datatype: 'electron' or 'ion'
;         energy: energy range to include in the calculation
;         bin_size: size of the pitch angle bins
;
; EXAMPLES:
;
;
; OUTPUT:
;
;
; NOTES:
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-17 14:29:26 -0800 (Wed, 17 Feb 2016) $
;$LastChangedRevision: 20051 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_pad_spinavg.pro $
;-
pro mms_feeps_pad_spinavg, probe=probe, species = species, data_units = data_units, $
  datatype = datatype, energy = energy, bin_size = bin_size, suffix = suffix
  if undefined(probe) then probe='1' else probe = strcompress(string(probe), /rem)
  if undefined(datatype) then datatype = 'electron'
  if undefined(data_units) then data_units = 'cps'
  if undefined(suffix) then suffix = ''
  if undefined(energy) then energy = [0, 1000]
  if undefined(bin_size) then bin_size = 15

  en_range_string = strcompress(string(energy[0]), /rem) + '-' + strcompress(string(energy[1]), /rem) + 'keV'
 ; units_label = data_units eq 'Counts' ? 'Counts': '[(cm!E2!N s sr KeV)!E-1!N]'

  prefix = 'mms'+probe+'_epd_feeps_'
  ; get the spin sectors
  get_data, prefix + 'spinsectnum'+suffix, data=spin_sectors
  
  if ~is_struct(spin_sectors) then begin
    dprint, dlevel = 0, 'Error, couldn''t find the tplot variable containing the spin sectors for calculating the spin averages.'
  endif
  
  spin_starts = where(spin_sectors.Y[0:n_elements(spin_sectors.Y)-2] ge spin_sectors.Y[1:n_elements(spin_sectors.Y)-1])+1

  pad_name = 'mms'+probe+'_epd_feeps_' + datatype + '_' + en_range_string + '_pad'

  get_data, pad_name, data=pad_data, dlimits=pad_dl

  if ~is_struct(pad_data) then begin
    stop
    dprint, dlevel = 0, 'Error, variable containing valid PAD data missing.'
    return
  endif

  spin_sum_flux = dblarr(n_elements(spin_starts), n_elements(pad_data.Y[0, *]))
  spin_times = dblarr(n_elements(spin_starts))

  current_start = 0
  ; loop through the spins for this telescope
  for spin_idx = 0, n_elements(spin_starts)-1 do begin
    ; loop over energies
    ;spin_sum_flux[spin_idx, *] = total(pad_data.Y[current_start:spin_starts[spin_idx], *], 1)
    spin_sum_flux[spin_idx, *] = average(pad_data.Y[current_start:spin_starts[spin_idx], *], 1)
    spin_times[spin_idx] = pad_data.X[current_start]
    current_start = spin_starts[spin_idx]+1
  endfor

  suffix = suffix + '_spin'
  newname = prefix+en_range_string+'_pad'+suffix

  ; rebin the data before storing it
  ; the idea here is, for bin_size = 15 deg, rebin the data from center points to:
  ;    new_bins = [0, 15, 30, 45, 60, 75, 90, 105, 120, 135 , 150, 165, 180]

  n_pabins = 180./bin_size
  new_bins = 180.*indgen(n_pabins+1)/n_pabins

  rebinned_data = congrid(spin_sum_flux, n_elements(spin_starts), n_elements(new_bins), /center, /interp)

  store_data, newname, data={x: spin_times, y: rebinned_data, v: new_bins}, dlimits=flux_dl
  options, newname, spec=1, ystyle=1, ztitle=units_label, ytitle='MMS'+probe+' FEEPS '+datatype, ysubtitle=en_range_string+'!CPAD (deg)'
  ylim, newname, 1., 180.
  zlim, newname, 0, 0, 1
end