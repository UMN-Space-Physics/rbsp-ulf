;+
;Procedure:
;  thm_part_slice2d_removezeros
;
;
;Purpose:
;  Helper routine for thm_part_slice2d_plot.
;  Removes trailing zeros and/or decimal from string.
;  
;  This could probably be repurposed into a general routine.
;
;
;Input:
;  sval: (string) Numerical string to be modified
;
;
;Output:
;  return value: (string) copy of input string with trailing 
;                 zeros and/or decimal removed.
;
;
;Notes:
;  -Assumes trailing spaces have already been removed.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2013-10-30 18:39:18 -0700 (Wed, 30 Oct 2013) $
;$LastChangedRevision: 13456 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/slices/thm_part_slice2d_removezeros.pro $
;
;-

; Removes trailing zeros and/or decimal from string,
; Assumes trailing spaces have already been removed.
function thm_part_slice2d_removezeros, sval

    compile_opt idl2, hidden
  
  if ~stregex(sval, '\.', /bool) then return, sval

  f = stregex(sval, '0*$',length=len)

  if stregex(sval, '\.0*$', /bool) then len++

  return, strmid(sval, 0, (strlen(sval)-len) )

end

