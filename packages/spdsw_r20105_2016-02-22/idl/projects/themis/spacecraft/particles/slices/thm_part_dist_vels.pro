;+
;Procedure: thm_part_dist_vels
;
;Purpose: Calculate bulk particle velocities from a structure array of particle
;         distrubutions and store in a tplot variable.
;
;Arguments:
;  DIST_ARR: An array of data structures as returned by one of the get_th?_p???
;            routines (or THM_PART_DIST_ARRAY).
;  OUT_NAME: Name of tplot variable in which to store the velocities.
;
;See Also: THM_PART_DIST_ARRAY, V_3D
;
;Created by Bryan Kerr
;-

pro thm_part_dist_vels, dist_arr, out_name

compile_opt idl2

ndist = n_elements(dist_arr)
v_times = dblarr(ndist)
vels = fltarr(ndist,3)
for i=0,ndist-1 do begin
  v_times[i] = dist_arr[i].time
  vels[i,*] = v_3d(dist_arr[i])
endfor

dlimit={labels:[ 'Vx', 'Vy', 'Vz'], $
        colors:[2, 4, 6]}

store_data, out_name, data={x:v_times, y:vels}, dlimit=dlimit

end