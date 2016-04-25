;+
;Procedure:
;  thm_part_process
;
;Purpose:
;  Apply standard processing to particle distribution array 
;  and pass out the processed copy.  This routine will apply
;  eclipse corrections, perform a unit conversion, and 
;  call the standard processing routines.
;
;Calling Sequence:
;  thm_part_process, in, out [,units=units] [,sst_sun_bins=sst_sun_bins]
;
;Input:
;  in:  Pointer array from thm_part_dist_array
;  units:  String specifying new units
;  _extra: Passed to sanitization routines
;
;Output:
;  out:  Pointer array to processed copy of the data
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-11 16:06:10 -0700 (Fri, 11 Sep 2015) $
;$LastChangedRevision: 18774 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_process.pro $
;-
pro thm_part_process, in, out, units=units, _extra=_extra

    compile_opt idl2, hidden


if in_set(ptr_valid(in),0) then return

units_lc = strlowcase(units)

out = ptrarr(n_elements(in))

for i=0, n_elements(in)-1 do begin
  
  thm_pgs_get_datatype, in[i], instrument=instrument

  for j=0, n_elements(*in[i])-1 do begin

    dist = (*in[i])[j]

    ;apply eclipse corrections to azimuths
    thm_part_apply_eclipse, dist, eclipse=eclipse

    ;general processing including unit conv & sst contamination removal
    case instrument of
      'esa': thm_pgs_clean_esa, dist, units_lc, output=clean_dist, _extra=_extra
      'sst': thm_pgs_clean_sst, dist, units_lc, output=clean_dist, _extra=_extra
      'combined': thm_pgs_clean_cmb, dist, units_lc, output=clean_dist
      else: begin
        dprint,dlevel=0,'WARNING: Instrument type unrecognized'
        ptr_free, out
        return
      endelse
    endcase

    ;ESA/SST sanitization routines remove descriptor fields, 
    ;add them back here for compatibility with general particle routines
    if instrument ne 'combined' then begin
      clean_dist = create_struct('project_name', dist.project_name, $
                                 'spacecraft', dist.spacecraft, $
                                 'data_name', dist.data_name, $
                                 'units_name', units_lc, $
                                 clean_dist[0])
    endif
    
    ;build new array
    array = array_concat(clean_dist, array, /no_copy) 

  endfor

  out[i] = ptr_new(array, /no_copy)

endfor


end