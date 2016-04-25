;+
;PROCEDURE: mav_get_altitude
;PURPOSE:
;  Calculates the altitude of the MAVEN spacecraft above the Martian
;  surface (either the solid planet or the constant-pressure surface
;  known as the 'areoid')
;
;USAGE:
;  mav_get_altitude, elon_sc, lat_sc,r_sc, alt_sc

;INPUTS:
;       xpc: a 1-dimensional array of values of the east longitude
;                of the spacecraft. UNITS: km
;
;       ypc:  a 1-dimensional array of values of the latitude
;                of the spacecraft. UNITS: km
;
;       zpc:    a 1-dimensional array of values of the radial
;                distance of the spacecraft from the planet's center
;                of mass. UNITS: kilometers
;OUTPUT:                
;       The output array of spacecraft altitudes. 
;                UNITS: kilometers
        
;KEYWORDS:
;       TOPOGRAPHIC: Set this keyword to anything nonzero if the spacecraft
;                    altitude above the planet's topography is
;                    desired.  If this keyword is not specified, the
;                    altitude will be above the constant-pressure
;                    surface known as the areoid (the equivalent of
;                    sea level) and the relevant altitude for most
;                    MAVEN studies.
;  
;CREATED BY:	Robert J. Lillis 2013-01-22
;FILE:  mav_get_altitude
;VERSION:  1.1

; NOTE

function mvn_get_altitude, xpc, ypc, zpc, mola_struc = mola_struc, $
                           topographic = topographic

; if the MOLA  file has been preloaded, then there's no need to
; restore the file.
  If not keyword_set (mola_struc) then begin
      rootdir = 'maven/anc/spice/sav/'
      
      pathname = rootdir + 'mola_save_file_0.25deg.idl'
      file = mvn_pfp_file_retrieve(pathname)
      if (findfile(file[0]) eq '') then begin
          print,"File not found: ",pathname
          return, sqrt(-5.5)
      endif

      restore, file[0]
  endif

  cart2latlong, xpc,ypc,zpc, r_sc, lat_sc,elon_sc

  nelon = n_elements (mola_struc.elon)
  nlat = n_elements (mola_struc.lat)
  elon_fractional_indices = elon_sc*(nelon/360.0) - 1.0
  lat_fractional_indices = (90.0+lat_sc)*(nlat/180.0) -1.0

  if keyword_set (topographic) then r = mola_struc.r_pl else r = $
    mola_struc.r_areoid

  r_surface_km = 0.001*interpolate (r,elon_fractional_indices, $
                                    lat_fractional_indices)
  alt_sc = r_sc - r_surface_km
  return, alt_sc
end
  
  
