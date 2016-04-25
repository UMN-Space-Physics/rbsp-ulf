;+
;Procedure:
;  spd_pgs_do_fac
;
;Purpose:
;  Applies field aligned coordinate transformation to input data
;
;Input:
;  data: The struct to be rotated
;  mat: The fac rotation matrix
;    
;Output:
;  output=output:  The struct of rotated data
;  error=error: 1 indicates error occured, 0 indicates no error occured
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 15:09:48 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19671 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_do_fac.pro $
;-


pro spd_pgs_do_fac,data,mat,output=output,error=error

  compile_opt idl2,hidden

  error = 1

  output_t=data
  ;identity matrix for testing
  ;mat = [[1,0,0],[0,1,0],[0,0,1]]

  ;if nans are in the transform matrix, replace data with NANs instead.
  ;Downstream code is not really equiped to properly handle NaNs in angles
  if total(finite(mat)) lt n_elements(mat) then begin
    output_t.data = !values.d_nan
  endif else begin

    r = replicate(1.,n_elements(data.data)) 
    sphere_to_cart,r,reform(data.theta,n_elements(data.theta)),reform(data.phi,n_elements(data.phi)),vec=cart_data
  
    x = mat[0,0]*cart_data[*,0] + mat[0,1]*cart_data[*,1] + mat[0,2]*cart_data[*,2]
    y = mat[1,0]*cart_data[*,0] + mat[1,1]*cart_data[*,1] + mat[1,2]*cart_data[*,2]
    z = mat[2,0]*cart_data[*,0] + mat[2,1]*cart_data[*,1] + mat[2,2]*cart_data[*,2]
  
    cart_to_sphere,x,y,z,r,theta,phi,/ph_0_360
  
    output_t.theta=theta
    output_t.phi=phi
     
    error = 0
  
  endelse
  
  output=output_t
  
end