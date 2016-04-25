;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS HPCA data using spd_slice2d.
;
;Notes:
;  -Example containing for/while loops cannot be copied directly to the console.
;
;  *** This is a work in progress ***
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:18:43 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19587 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_slice2d_hpca_crib.pro $
;-



;===========================================================================
; Basic Example
;  -Demonstrates the basics of creating a single plot
;===========================================================================


;setup
;---------------------------------------------
probe = '1'
data_rate = 'brst'
;data_rate = 'srvy'

timespan, '2015-10-20/05:56:30', 5, /min  ;brst
;timespan, '2015-11-16/06:32:00', 20, /min  ;brst/srvy
trange = timerange()


;load data into tplot
;---------------------------------------------

;particle data 
mms_load_hpca, probes=probe, trange=trange, $
               data_rate=data_rate, level='l1b', datatype='vel_dist'

;azimuth data
mms_load_hpca, probe=probe, trange=trange, $
               data_rate=data_rate, level='l1a', datatype='spinangles', $
               varformat='*_angles_per_ev_degrees'

;B field (only necessary for field-aligned slices)
;mms_load_dfg, probe=probe, trange=trange, level='ql'

;use h+ dist function var for example
tname = 'mms'+probe[0]+'_hpca_hplus_vel_dist_fn'


;reformat data from tplot variables into compatible 3D structures
;  -this will return a pointer to the structure array in order to save memory 
;---------------------------------------------
dist = mms_get_hpca_dist(tname)


;generate and plot 2D slice
;---------------------------------------------

;time at which to retrieve the slice
time = mean(trange)

;get slice
slice = spd_slice2d(dist, time=time, /geo)  ;use distribution closest to specified time
;slice = spd_slice2d(dist, time=time, /geo, samples=2)  ;average 2 closest distributions

;average all data in specified time window
;slice = spd_slice2d(dist, time=time, /geo, window=20)  ; window (sec) starts at TIME  
;slice = spd_slice2d(dist, time=time, /geo, window=20, /center_time)  ; window centered on TIME
          
        
;plot
spd_slice2d_plot, slice


stop


;===========================================================================
; Multiple plots
;  -This example demonstrates how to create a series of single-distribution plots
;===========================================================================

;setup
probe = '1'
data_rate = 'brst'
timespan, '2015-10-22/06:05:00', 2, /min
trange = timerange()

;particle data 
mms_load_hpca, probes=probe, trange=trange, $
               data_rate=data_rate, level='l1b', datatype='vel_dist'

;azimuth data
mms_load_hpca, probe=probe, trange=trange, $
               data_rate=data_rate, level='l1a', datatype='spinangles', $
               varformat='*_angles_per_ev_degrees'

;reformat data
dist = mms_get_hpca_dist('mms'+probe[0]+'_hpca_hplus_vel_dist_fn')

;get center time for each full distribution
times = ( (*dist).time + (*dist).end_time ) / 2.

;create and export a single-disribution plot at each time
for i=0, n_elements(times)-1 do begin

  ;get slice from nearest distribution
  slice = spd_slice2d(dist, time=times[i], /geo)

  ;plot and write .png image to current directory
  ;  -use /eps keyword to write .eps file instead of png
  spd_slice2d_plot, slice, export='mms'+probe+'_hplus_'+time_string(times[i],format=2)

endfor


end


