
;Procedure:
;  spd_slice2d_get_support
;
;Purpose:
;  Retreive user specified support data for spd_slice2d.
;  This routine abstracts the tast of checking if input is
;  undfined, an array, or a tplot variable. 
;
;Calling Sequence:
;  spd_slice2d_get_support, input, trange, output=output [,/matrix]
;
;Input:
;  input: input variable to be checked
;  trange: two element time range
;  matrix: flag specifying that the data in a 3x3 matrix, otherwise a 3-vector is assumed
;
;Output:
;  output: undefined - if input is undefined
;          3-vector/3x3 matrix - if input is 3-vector/3x3 matrix
;                              - if unput is a valid tplot variable that covers the time range
;          NaN - otherwise 
;
;Notes:
;  -If the specified tplot variables has no points in the time range then 
;   a linear interpolation will be attempted to return a value at the center
;   of the time range.  This will not occur for matrices.
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/core/spd_slice2d_get_support.pro $
;-

pro spd_slice2d_get_support, input, trange, matrix=matrix, output=output

    compile_opt idl2, hidden


if undefined(input) then return

dim = keyword_set(matrix) ? [3,3] : [3]

if is_num(input) && array_equal( size(input,/dim), dim ) then begin
  
  output = double(input)
    
endif else begin

  output = spd_tplot_average(input, trange, interpolate=~keyword_set(matrix))

endelse 


end