;+
;PROCEDURE: thm_pgs_clean_esa
;PURPOSE:
;  Helper routine for thm_part_products
;  Maps ESA data into simplified format for high-level processing.
;  Creates consistency for downstream routines and throws out extra fields to save memory 
;  
;Inputs(required):
;  data: ESA particle data structure from thm_part_dist, get_th?_pe??, thm_part_dist_array, etc...
;  units: string specifying the units (e.g. 'eflux')
;
;Outputs:
;   output structure elements:
;         data - particle data 2-d array, energy by angle. (Float or double)
;      scaling - scaling coefficient corresponding to 1 count/bin, used for error calculation (float or double)
;         time - sample start time(1-element double precision scalar)
;     end_time - sample end time(1-element double precision scalar)
;          phi - Measurment angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
;         dphi - Width of measurement angle in plane parallel to spacecraft spin.(2-d array matching data array.) (Float or double)
;        theta - Measurment angle in plane perpendicular to spacecraft spin.(2-d array matching data array.) (Float or double)
;       dtheta - Width of measurement angle in plane perpendicular to spacecraft spin. (2-d array matching data array.) (Float or double)
;       energy - Contains measurment energy for each component of data array. (2-d array matching data array.) (Float or double)
;      denergy - Width of measurment energy for each component of data array. (2-d array matching data array.)
;         bins - 0-1 array, indicating which bins are enabled for subsequent calculations. (2-d array matching data array.)  (Integer type.)
;       charge - expected particle charge (1-element float scalar)
;         mass - expected particle mass (1-element float scalar)
;         magf - placeholder for magnetic field vector (3-element float array)
;        scpot - placeholder for spacecraft potential (1-element float scalar)
;
;
;
;Keywords:
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-03-19 17:18:03 -0700 (Thu, 19 Mar 2015) $
;$LastChangedRevision: 17151 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_products/thm_pgs_clean_esa.pro $
;-

;Note: Keep options for vectorizing open
pro thm_pgs_clean_esa,data,units,output=output,_extra=ex

  compile_opt idl2,hidden
  
  ;convert to requested units
  ;get scaling coefficient used to convert from counts->units
  ;  NOTE: for ESA the value of SCALE does not reflect dead time correction
  udata = conv_units(data,units,scale=scale,_extra=ex)
  scale = float(scale)
  if n_elements(scale) eq 1 then begin
    scale = replicate(scale,size(data.data,/dim))
  endif
  
  ;ensure phi values are in [0,360]
  udata.phi = udata.phi mod 360
  
  
  ;re-arrange energy bins to be in ascending order
  ;this assumes vectorization will be over single mode
  s = sort( udata[0].energy[*,0] )
  
  
  ;modify sorting indices to exclude top ESA energy (first element)
  ;this energy is turned off in the get_th?_pe?? routines for 
  ;all datatypes except 15 energy full electron
  if data.apid ne '457'xu || data.nenergy ne 15 then begin
    idx = where(s ne 0, ni)
    if ni gt 0 then s = s[idx]
  endif
  
    
  ;create standard array for output
  ;**extra dimension in case of later vectorization
  output = { data: udata.data[s,*,*], $
             scaling: scale[s,*,*], $
             time: udata.time, $
             end_time: udata.end_time, $
             phi: udata.phi[s,*,*], $
             dphi: udata.dphi[s,*,*], $
             theta: udata.theta[s,*,*], $
             dtheta: udata.dtheta[s,*,*], $
             energy: udata.energy[s,*,*], $
             denergy: udata.denergy[s,*,*], $
             bins: udata.bins[s,*,*], $
             charge:udata.charge, $
             mass:udata.mass, $
             magf:udata.magf, $
             sc_pot:udata.sc_pot $
            } 


end
