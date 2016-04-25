;+
; PROCEDURE:
;         mms_fpi_burst_energies
;
; PURPOSE:
;         Returns the energies for burst mode FPI spectra.  This routine uses 
;            the alternating energy tables set by the parity bit
;
; NOTE:
;         Burst mode FPI data must be loaded prior to calling this function
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-19 15:36:47 -0800 (Fri, 19 Feb 2016) $
;$LastChangedRevision: 20069 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_burst_energies.pro $
;-
function mms_fpi_burst_energies, species, probe, level = level, suffix = suffix
  if undefined(suffix) then suffix = ''
  if undefined(probe) then begin
    dprint, dlevel = 'Error, need probe to find burst mode energies'
    return, 0
  endif else probe = strcompress(string(probe), /rem)
  if undefined(species) then begin
    dprint, dlevel = 'Error, need species to find burst mode energies'
    return, 0
  endif else species = strcompress(string(species), /rem)
  data_rate = 'brst'
  if undefined(level) then level = ''

  en_table = mms_get_fpi_info()

  ; get the step table
  step_var = 'mms'+probe+'_d'+species+'s_stepTable_parity'
  step_var = level eq 'l2' ? strlowcase(step_var+'_'+data_rate)+suffix : step_var+suffix
  
  step_name = (tnames(step_var))[0]
  if step_name eq '' then begin
    dprint, 'Cannot find energy table data: mms'+probe+'_d'+species+'s_stepTable_parity'
    return, 0
  endif
  get_data, step_name, data=step

  if species eq 'i' then energy_table = transpose(en_table.ion_energy) $
  else if species eq 'e' then energy_table = transpose(en_table.electron_energy)

  en_out = transpose(energy_table[*,step.y])
  return, en_out
end