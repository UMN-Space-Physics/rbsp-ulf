;+
; PROCEDURE aacgmconvcoord 
; 
; :PURPOSE:
; A wrapper procedure to choose AACGM DLM or IDL-native routines 
; to convert (lat,lon) between Geographic coordinates and AACGM.  
; 
; The wrapper procedures/functions check !sdarn.aacgm_dlm_exists 
; (if not defined, then define it by sd_init) to select appropriate 
; AACGM routines (DLM, or IDL native ones attached to TDAS). 
; 
; :Params:
;   glat, glon:   Geographic latitude and longitude. 
;   mlat, mlon:   AACGM latitude and longitude. 
;   alt:          Altitude for conversion.
;   err:          Error status of coordinate transformation. 
;   
; :Keywords:
;   TO_AACGM:   Set to convert from geographic to AACGM coordinates.
;   TO_GEO:     Set to convert from AACGM to geographic coordinates.
; 
; :Examples:
;   aacgmconvcoord, glat,glon,alt, mlat,mlon,err, /TO_AACGM
;   aacgmconvcoord, mlat,mlon,alt, glat,glon,err, /TO_GEO
;   
; :AUTHOR: 
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;   
; :HISTORY:
;   2011/10/04: created and got through the initial bug fixes
;
; $LastChangedBy: lphilpott $
; $LastChangedDate: 2011-10-14 09:20:31 -0700 (Fri, 14 Oct 2011) $
; $LastChangedRevision: 9113 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/sdaacgmlib/aacgmconvcoord.pro $
;-

pro aacgmconvcoord, glat,glon,alt,mlat,mlon,err, TO_AACGM=TO_AACGM, TO_GEO=TO_GEO

;Initialize !sdarn if not defined
help, name='!sdarn',out=out
if out eq '' then sd_init

glon = (glon + 360.) mod 360.

if !sdarn.aacgm_dlm_exists then begin 
  ;print, 'using AACGM_DLM'
  aacgm_conv_coord, glat,glon,alt,mlat,mlon,err,$
    TO_AACGM=TO_AACGM, TO_GEO=TO_GEO
endif else begin
  mlat=glat & mlon=glon
  mlat[*]=0. & mlon[*]=0.
  err = fix(glat) & err[*] = 0
  for i=0L, n_elements(glat)-1 do begin
    cnv_aacgm,glat[i],glon[i],alt[i],tmlat,tmlon,r,terr,geo=TO_GEO
    mlat[i]=tmlat & mlon[i]=tmlon & err[i] = fix(terr)
    ;print, 'cnv_aacgm was executed'
    ;print, glat[i],glon[i],alt[i],'   ',mlat[i],mlon[i],r,err
  endfor
endelse

mlon = (mlon + 360.) mod 360.

return
end


