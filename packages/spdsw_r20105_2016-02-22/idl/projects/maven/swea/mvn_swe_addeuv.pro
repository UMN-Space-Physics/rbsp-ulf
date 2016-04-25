;+
;PROCEDURE:   mvn_swe_addeuv
;PURPOSE:
;  Loads EUV data and creates tplot variables using EUV code.
;
;USAGE:
;  mvn_swe_addeuv
;
;INPUTS:
;    None:          Data are loaded based on timespan.
;
;KEYWORDS:
;
;    PANS:          Named variable to hold a space delimited string containing
;                   the tplot variable(s) created.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-11-23 17:10:51 -0800 (Mon, 23 Nov 2015) $
; $LastChangedRevision: 19460 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addeuv.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addeuv, pans=pans

  pans = ''
  mvn_lpw_load_l2, ['euv'], tplotvars=euv_pan, /notplot
  
  if (euv_pan[0] ne '') then begin
    for i=0,(n_elements(euv_pan)-1) do pans += euv_pan[i] + ' '
    pans = strtrim(strcompress(pans),2)
  endif
  
  return
  
end
