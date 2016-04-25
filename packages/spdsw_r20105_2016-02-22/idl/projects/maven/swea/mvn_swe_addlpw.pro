;+
;PROCEDURE:   mvn_swe_addlpw
;PURPOSE:
;  Loads LPW data and creates tplot variables using LPW code.
;
;USAGE:
;  mvn_swe_addlpw
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
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addlpw.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addlpw, pans=pans

  pans = ''
  mvn_lpw_load_l2, ['lpnt'], tplotvars=lpw_pan, /notplot
  
  if (lpw_pan[0] ne '') then begin
    for i=0,(n_elements(lpw_pan)-1) do pans += lpw_pan[i] + ' '
    pans = strtrim(strcompress(pans),2)
  endif
  
  return
  
end
