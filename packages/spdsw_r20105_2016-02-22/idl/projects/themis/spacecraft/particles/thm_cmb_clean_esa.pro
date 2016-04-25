;+
;Procedure:
;  thm_cmb_clean_sst
;
;
;Purpose:
;  Runs standard ESA sanitation routine on data array.
;    -removes excess fields in data structures
;    -performs unit conversion (if UNITS specified)
;    -removes retrace bin (top energy)
;    -reverses energies to be in ascending order
;
;
;Calling Sequence:
;  thm_cmb_clean_esa, dist_array, [,units=units]
;
;Input:
;  dist_array:  ESA particle data array from thm_part_dist_array
;  units: String specifying output units
;
;
;Output:
;  none, modifies input
;
;
;Notes:
;  Further unit conversions will not be possible after sanitation
;  due to the loss of some support quantities.
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-07-08 12:57:33 -0700 (Wed, 08 Jul 2015) $
;$LastChangedRevision: 18038 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_cmb_clean_esa.pro $
;
;-
    
pro thm_cmb_clean_esa, data, units=units, _extra=ex

  compile_opt idl2,hidden

  ;ensure units is defined    
  if undefined(units) then units = (*data[0])[0].units_name
  
  ;loop over pointers
  for i=0, n_elements(data)-1 do begin

    ;loop over structures
    for j=0, n_elements(*data[i])-1 do begin
      
      ;sanitization
      thm_pgs_clean_esa, (*data[i])[j], units, output=temp, _extra=ex
      
      ;FIXME:
      ;This *should* be a temporary fix to maintain gaps in cases where 
      ;pe?r data is present but all zeroes.  This may be a processing problem,
      ;and the data recoverable, or gaps/nans may be added at a lower level.
      if total( temp.data ne 0 ) eq 0 then temp.data = !values.F_NAN
      
      ;new struct array must be built
      if j eq 0 then begin
        temp_arr = replicate(temp, n_elements(*data[i]))
      endif else begin
        temp_arr[j] = temp
      endelse
      
    endfor
    
    ;replace data
    ptr_free, data[i]
    data[i] = ptr_new(temp_arr, /no_copy)
  
  endfor
    
end