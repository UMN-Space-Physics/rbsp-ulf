;+
;Procedure:
;  mms_get_hpca_dist
;
;Purpose:
;  Returns pseudo-3D particle data structures containing mms hpca data
;  for use with spd_slice2d.
;
;Calling Sequence:
;  data = mms_get_hpca_dist(tname [,index] [,trange=trange] [,/times] [,/structure])
;
;Input:
;  tname: Tplot variable containing the desired data.
;  index:  Index of time samples to return (supersedes trange)
;  trange:  Two element time range to constrain the requested data
;  times:  Flag to return full array of time samples
;  structure:  Flag to return a structure array instead of a pointer.  
;
;Output:
;  return value: pointer to array of pseudo 3D particle distribution structures
;                or 0 in case of error
;
;Notes:
;  This is a work in progress
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-29 15:22:13 -0800 (Fri, 29 Jan 2016) $
;$LastChangedRevision: 19853 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/hpca/mms_get_hpca_dist.pro $
;-

function mms_get_hpca_dist, tname, index, trange=trange, times=times, structure=structure

    compile_opt idl2


name = (tnames(tname))[0]
if name eq '' then begin
  dprint, dlevel=0, 'Variable: "'+tname+'" not found'
  return, 0
endif

;pull data and metadata
get_data, name, ptr=p

if ~is_struct(p) then begin
  dprint, dlevel=0, 'Variable: "'+tname+'" contains invalid data'
  return, 0
endif

if size(*p.y,/n_dim) ne 3 then begin
  dprint, dlevel=0, 'Variable: "'+tname+'" has wrong number of elements'
  return, 0
endif

;get some basic info from name
var_info = stregex(name, 'mms([1-4])_hpca_([^_]+)_(.+)', /subexpr, /extract)
probe = var_info[1]
species = var_info[2]
datatype = var_info[3]


; Match particle data to azimuth data
;-----------------------------------------------------------------

s = mms_get_hpca_info()

;get azimuth data from ancillary file
;  -contains azimuth & temporal data
get_data, 'mms'+probe+'_hpca_azimuth_angles_per_ev_degrees', ptr=azimuth

if ~is_struct(azimuth) then begin
  dprint, dlevel=0, 'No azimuth data found for the current time range'
  return, 0
endif

;find azimuth times with complete 1/2 spins of particle data
;this is used to determine the number of 3D distributions that will be created
;and where their corresponding data is located in the particle data structure
n_times = n_elements((*azimuth.y)[0,0,*])  ;# data samples for each azimuth array 
data_idx = value_locate(*p.x, *azimuth.x)  ;data index corresponding to each azimuth array
full = where( (data_idx[1:*] - data_idx[0:n_elements(data_idx)-2]) eq n_times, n_full)
if n_full eq 0 then begin
  dprint, dlevel=0, 'Azimuth data does not cover current data''s time range'
  return, 0
endif


; Return matched times if requested
;   -This allows calling code to loop over indices without having to determine
;    which (azimuth) times are associate with complete data sets
;   -These times are not center of distribution but center of first energy sweep
;------------------------------------------------------------------
if keyword_set(times) then begin
  return, (*azimuth.x)[full]
endif


; Allow calling code to request a time range or specify index to specific sample.
;-----------------------------------------------------------------
if ~undefined(index) then begin
  full = full[index]
  n_full = n_elements(full)
endif else if ~undefined(trange) then begin
  tr = minmax(time_double(trange))
  index = where( (*azimuth.x)[full] ge tr[0] and (*azimuth.x)[full] lt tr[1], n_full)
  if n_times eq 0 then begin
    dprint, 'No data in time range: '+strjoin(time_string(tr),' ')
    return, 0
  endif
  full = full[index]
endif
data_idx = data_idx[full]


; Initialize energies, angles, and support data
;-----------------------------------------------------------------

;final dimensions for a single distribution (energy-azimuth-elevation)
azimuth_dim = dimen(*azimuth.y) ;time-energy-elevation-azimuth
dim = azimuth_dim[ [1,4,3] ]   ;energy-azimuth-elevation
base_arr = fltarr(dim)

;mass & charge of species
;  -slice routines assume mass in eV/(km/s)^2
case species of 
  'hplus':begin
    mass = 1.04535e-2
    charge = 1.
  end
  'heplus':begin
    mass = 4.18138e-2
    charge = 1.
  end
  'heplusplus':begin
    mass = 4.18138e-2
    charge = 2.
  end
  'oplus':begin
    mass = 0.167255
    charge = 1.
  end
  'oplusplus':begin
    mass = 0.167255
    charge = 2.
  end
  else: begin
    dprint, dlevel=0, 'Cannot determine species'
    return, 0
  endelse
endcase

;energy bins are constant
energy = rebin(*p.v2, dim)

;elevations bins are constant
;  -index by anode number in case order is inconsistent
;  -convert to from colat to lat
theta = rebin( reform((90 - s.elevation[*p.v1]),[1,1,dim[2]]), dim)
dtheta = replicate(22.5, dim)

;azimuths are be populated below


; Create standard 3D distributions
;-----------------------------------------------------------------

;basic template structure that is compatible with spd_slice2d
template = {  $
  project_name: 'MMS', $
  spacecraft: probe, $
  data_name: 'HPCA '+species, $
  units_name: 'df_cm', $
  units_procedure: '', $ ;placeholder
  species:species, $
  valid: 1b, $

  charge: charge, $
  mass: mass, $  
  time: 0d, $
  end_time: 0d, $

  data: base_arr, $
  bins: base_arr+1, $ ;must be set or data will be considered invalid

  energy: energy, $
  denergy: base_arr, $
  phi: base_arr, $
  dphi: base_arr, $
  theta: theta, $
  dtheta: dtheta $
}

dist = replicate(template, n_full)


; Populate the structures
;-----------------------------------------------------------------

;get start/end times
;  -this assumes that the times from the particle (and angle) data 
;   are at the center of the corresponding energy sweep
;  -also assumes that there are no gaps in the data
dt = (*azimuth.x)[1:*] - (*azimuth.x)[0:*]  ;delta-time for each 1/2 spin
dt_sweep = (*p.x)[1:*] - (*p.x)[0:*]        ;delta-time for each full energy sweep
dist.time = (*azimuth.x)[full] - dt_sweep[data_idx]
dist.end_time = dist.time + dt[full]  ;index won't exceed elements due to selection criteria

;get azimuth 
;  -shift from from time-energy-elevation-azimuth to energy-azimuth-elevation-time
;   (time must be last to be added to structure array)
dist.phi = transpose( (*azimuth.y)[full,*,*,*], [1,3,2,0])

;get dphi
;  -use median distance between subsequent phi measurments within each distribution
;   (median is used to discard large differences across 0=360)
;  -preserve dimensionality in case differences arise across energy or elevation
dphi = median( (*azimuth.y)[full,*,*,1:*] - (*azimuth.y)[full,*,*,0:*], dim=4 ) ;get medain across phi
dphi = rebin( dphi, [dimen(dphi),dim[1]] ) ;expand back to original dimensions
dist.dphi = transpose( dphi, [1,3,2,0] ) ;shuffle dimensions

;copy particle data
for i=0,  n_elements(dist)-1 do begin

  ;shift from azimuth-energy-elevation to energy-azimuth-elevation
  dist[i].data = transpose( (*p.y)[data_idx[i]:data_idx[i]+(n_times-1),*,*], [1,0,2] )

endfor

;ensure phi values are in [0,360]
;  -this may be unnecessary with new spinangle cdfs
;dist.phi = (dist.phi + 360) mod 360

;spd_slice2d accepts pointers or structures
;pointers are more versatile & efficient, but less user friendly
if keyword_set(structure) then begin
  return, dist 
endif else begin
  return, ptr_new(dist,/no_copy)
endelse


end
