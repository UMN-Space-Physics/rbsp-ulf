;+
;Procedure:
;  thm_crib_part_slice2d_multi
;
;Purpose:
;  Demonstrate how to create a time series of distribution  
;  slices using a while loop.
;
;See also:
;  thm_crib_part_slice2d
;  thm_crib_part_slice2d_adv
;  thm_crib_part_slice2d_plot
;  thm_crib_part_slice1d
;
;Notes:
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-05-14 14:38:31 -0700 (Thu, 14 May 2015) $
;$LastChangedRevision: 17616 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_part_slice2d_multi.pro $
;-



;===========================================================
; Load Data
;===========================================================

; Set time range
day = '2008-02-26/'
start_time = time_double(day + '04:50:00')
end_time = time_double(day + '04:55:00')

; pad time range to ensure enough data is loaded
trange=[start_time - 90, end_time + 90]

; set data types
probe = 'b'
datatype = 'pseb'


; This example will use basic allignment that doesn't require mag & velocity data
;thm_load_fgm, probe=probe, datatype = 'fgh', level=2, coord='dsl', trange=trange
;thm_load_esa, probe=probe, datatype = 'peeb_velocity_dsl', trange=trange


; Create array of SST particle distributions
dist_arr = thm_part_dist_array(probe=probe, datatype=datatype, trange=trange)



;===========================================================
;Set options for slice plots
;===========================================================

timewin = 60.   ; set the time window for each slice
incriment = 30. ; time incriment for next slice's start

coord = 'gsm'   ; GSM coordinates

erange = [0,5e5]; limit energy range

zrange = [2.2e-27, 2.2e-20] ; plot using fixed range



;===========================================================
; Use loop to create multiple slices and export plots
;===========================================================

;initialize the time variable we will be looping over
slice_time = start_time

;keep producing plots until end_time is reached
while slice_time lt end_time do begin
  
  ;Create slice
  thm_part_slice2d, dist_arr, slice_time=slice_time, timewin=timewin, $
                    coord=coord, rotation=rotation, erange=erange, $
                    part_slice=part_slice, $
                    fail=fail

  ;Check for errors,
  ;the FAIL variable will contain a string message if something goes wrong
  if keyword_set(fail) then begin
    print, 'An error occured while creating the slice at '+time_string(slice_time)+':'
    print, fail
  endif else begin

    ;create filename for image
    file_name = time_string(format=2,slice_time) + '_th'+probe+'_'+datatype
  
    ;Call plotting procedure
    thm_part_slice2d_plot, part_slice, $
                     zrange=zrange, $    ;use constant zrange
                     export=file_name    ;create .png with specified name in current directory

  endelse
 
  ;increment the time
  slice_time += incriment
  
endwhile


END
