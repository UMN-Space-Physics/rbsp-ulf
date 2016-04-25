;+
;Purpose:
;  Crib sheet demonstrating how to obtain particle distribution slices 
;  from MMS FPI data using spd_slice2d.
;
;  Run as script or copy-paste to command line.
;    (examples containing loops cannot be copy-pasted to command line)
;
;
;Notes:
;
;  *** This is a work in progress ***
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-10 14:23:41 -0800 (Wed, 10 Feb 2016) $
;$LastChangedRevision: 19935 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/mms_slice2d_fpi_crib.pro $
;-



;======================================================================
; FPI
;--------
;  -FPI data is large and can be very memory intensive!  It is recommended 
;   that no more than a few minutes of data is loaded at a time for ions
;   and less for electrons.
;======================================================================



;=============================
; Setup and basic usage
;=============================

;setup
;---------------------------------------------
probe='1'
species='i'
data_rate='brst'
trange=['2015-8-15/12:50','2015-8-15/12:51']


;load particle data into tplot
;---------------------------------------------
mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-dist', $
              probe=probe, trange=trange

name =  'mms'+probe+'_d'+species+'s_brstSkyMap_dist'


;reformat data from tplot variable into compatible 3D structures
;  -this will return a pointer to the structure array in order to save memory 
;---------------------------------------------
dist = mms_get_fpi_dist(name, trange=trange, probe=probe, species=species, data_rate=data_rate)

;basic slice
;  -some plot annotations will need to be set manually for now
;---------------------------------------------

time = '2015-8-15/12:50' ;start time of slice
window = 1 ;window (sec) over which to average

;get slice
;  -3d/2d interpolation show smooth contours
;  -geometric interpolation is slow but shows bin boundaries
slice = spd_slice2d(dist, time=time, window=window) ;3D interpolation
;slice = spd_slice2d(dist, time=time, window=window, /two) ;2D interpolation
;slice = spd_slice2d(dist, time=time, window=window, /geo) ;geometric interpolation

;set annotations (temporary)
slice.coord = 'GSE'

;plot
spd_slice2d_plot, slice


stop


;=============================
; Field-aligned slices
;=============================

;load B field data
mms_load_dfg, probe=probe, trange=trange, level='ql'

;load velocity moment
mms_load_fpi, data_rate='brst', level='l1b', datatype='d'+species+'s-moms', $
              probe=probe, trange=trange

bname = 'mms'+probe+'_dfg_srvy_gse_bvec'
vname = 'mms'+probe+'_d'+species+'s_bulk'

;combine separate velocity components
join_vec, vname + ['X','Y','Z'], vname

;field/velocity aligned slice
;  -the plot's x axis is parallel to the B field
;  -the plot's y axis is defined by the bulk velocity
;---------------------------------------------
slice = spd_slice2d(dist, time=time, window=window, $
                    rotation='bv', mag_data=bname, vel_data=vname)

;plot
spd_slice2d_plot, slice


stop


;=============================
; Time series
;=============================

;produce a plot of 2 seconds of data every 10 seconds for 1 minute
time = time_double('2015-8-15/12:50')
times = time + findgen(6) * 10.
window = 1

for i=0, n_elements(times)-1 do begin

  slice = spd_slice2d(dist, time=times[i], window=window)

  ;verify success
  if ~is_struct(slice) then continue

  ;add slice structure to array for plotting later
  slices = array_concat(slice,slices)

endfor

;set annotations (temporary)
slices.coord = 'GSE'

;create plots as needed
spd_slice2d_plot, slices[0], window=0
spd_slice2d_plot, slices[4], window=1


stop


;=============================
; Export plots to png/eps
;  -see makepng, popen/pclose for manual usage
;=============================

; export .png or .eps to current directory
for i=0, n_elements(slices)-1 do begin

  filename = 'fpi_'+species+'_'+time_string(slices[i].trange[0],format=2)

  spd_slice2d_plot, slices[i], export=filename ;,/eps

endfor


stop


;=============================
; Fast survey data
;=============================


;load fast survey data
mms_load_fpi, data_rate='fast', level='l1b', datatype='d'+species+'s-dist', $
              probe=probe, trange=trange

;reformat data
name = 'mms'+probe+'_d'+species+'s_fastSkyMap_dist'
dist_fast = mms_get_fpi_dist(name, trange=trange, probe=probe, species=species, data_rate=data_rate)

time = '2015-8-15/12:50' ;start time of slice

;get slice from distribution closest to specified time
slice = spd_slice2d(dist_fast, time=time)

;set annotations (temporary)
slice.coord = 'GSE'

;plot
spd_slice2d_plot, slice


end