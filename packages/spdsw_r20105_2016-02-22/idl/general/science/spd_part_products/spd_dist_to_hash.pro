;+
;Procedure:
;
;
;Purpose:
;
;
;Calling Sequence:
;
;
;Input:
;
;
;Output:
;
;
;Notes:
;  -Requires IDL 8.0+, 8.2+ recommended
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-17 17:45:39 -0800 (Wed, 17 Feb 2016) $
;$LastChangedRevision: 20057 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_dist_to_hash.pro $
;-

function spd_dist_to_hash, d, counts=counts

    compile_opt idl2, hidden


if !version.release lt 8.0 then begin
  message, 'IDL 8.0 or higher is required to use this function'
endif

if ~ptr_valid(d) || ~is_struct(*d[0]) then begin
  dprint, dlevel=0, 'Invalid input data'
  return, !null
endif

counts_set = ~undefined(counts) 
if counts_set then begin
  if ~ptr_valid(counts) || ~is_struct(*counts[0]) then begin
    dprint, dlevel=0, 'Invalid counts data'
    return, !null
  endif
endif


c = 299792458d ;m/s
erest = (*d[0])[0].mass * c^2 / 1e6 ;convert mass from eV/(km/s)^2 to eV/c^2


out = hash()

for i=0, n_elements(d)-1 do begin

  ;all fields must be reformed to single dimension later
  n = n_elements((*d[i])[0].data)

  for j=0, n_elements(*d[i])-1 do begin

    ;TODO: Include fractional seconds once supported by stel3d
    time = time_string( (*d[i])[j].time )

    ;calculate velocity in km/s
    ;fill counts if not set
    ;use lat instead of co-lat
    out[time] = hash( 'energy', reform( (*d[i])[j].energy ,n), $
                      'v', reform( c * sqrt( 1 - 1/(((*d[i])[j].energy/erest + 1)^2) )  /  1000. ,n), $
                      'azim', reform( (*d[i])[j].phi ,n), $
                      'elev', 90-reform( (*d[i])[j].theta ,n), $
                      'count', reform( counts_set ? (*counts[i])[j].data : (*d[i])[j].data*0. ,n), $
                      'psd', reform( (*d[i])[j].data ,n)  )

  endfor
endfor

if out.isempty() then return, !null

return, out

end