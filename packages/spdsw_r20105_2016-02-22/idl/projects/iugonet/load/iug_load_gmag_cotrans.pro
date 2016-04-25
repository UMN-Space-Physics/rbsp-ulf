; +
; NAME:
;     iug_load_gmag_cotrans
; 
; Purpose: Coordinate transformation between HDZ coordinates & GEO coordinates
;
;     HDZ is defined as:
;
;       H = horizontal field strength, in the plane formed by Z and GEO graphic north
;       D = field strength in the Z x X direction in nT
;       Z = downward field strength  
;       
;     H should be a projection onto a basis vector pointing north from station in nT
;     D should be a projection onto a basis vector perpendicular to H in the horizontal plane.
;         
;     Total field strength should be sqrt(H^2+D^2+Z^2) not sqrt(H^2+Z^2)
;     D must be in nT not degrees
;    
;     GEO is defined as:
;         X = Vector parallel to vector pointing outward at the intersection of the equatorial plane and the 0 degree longitudinal meridean(Greenwich Meridean)
;         Y = Z x X
;         Z = Vector parallel to orbital Axis of Earth Pointing northward.
;        
; Written by: Atsuki Shinbori
; -

pro iug_load_gmag_cotrans

; Set the time span of interest
  timespan,'8-3-8',2,/days
  
; thm_load_gmag 
  thm_load_gmag,site = 'thl', trange=trange

; Display all variable names
  tplot_names
  
; Plot the thg_mag_bmls data 
  tplot,'thg_mag_thl'
  
; Now get the data out of tplot:  
  get_data,'thg_mag_thl', data=data_hdz
  time=data_hdz.x
  
; Geophysical coordinate transformation from hdz to geo 
  hdz2geo,data_hdz.y,data_xyz,latitude=77.48,longitude=290.83
  
; Return data to "TPLOT limbo" with new name
  store_data, 'thg_mag_thl_geo', data={x:time, y:data_xyz},dlimit={constant:0.}
  
; Plot the thg_mag_bmls and thg_mag_bmls_geo data 
  tlimit,'8-3-8','8-3-9' ; Limitation of one-day plot
  
  options, 'thg_mag_thl', labels=['H','D','Z'] , $
                         ytitle = 'THL-B (Local GEM)', $
                         ysubtitle = '[nT]' 
  options, 'thg_mag_thl_geo', labels=['X','Y','Z'] , $
                         ytitle = 'THL-B (Local GEO)', $
                         ysubtitle = '[nT]'
  
  tplot,['thg_mag_thl','thg_mag_thl_geo']


  print,'You success the coordinate transformation from HDZ to geo.'

end
