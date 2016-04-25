;+
;PROCEDURE:   mvn_swe_addsta
;PURPOSE:
;  Loads STATIC data and creates tplot variables using STATIC code.
;
;USAGE:
;  mvn_swe_addswi
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
; $LastChangedDate: 2015-11-23 11:11:45 -0800 (Mon, 23 Nov 2015) $
; $LastChangedRevision: 19452 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_addsta.pro $
;
;CREATED BY:    David L. Mitchell  03/18/14
;-
pro mvn_swe_addsta, pans=pans

  mvn_sta_l2_load
  mvn_sta_l2_tplot,/replace
  
  pans = ''
  
  get_data, 'mvn_sta_c0_E', index=i
  if (i gt 0) then pans = pans + ' ' + 'mvn_sta_c0_E'

  get_data, 'mvn_sta_c6_M', index=i
  if (i gt 0) then pans = pans + ' ' + 'mvn_sta_c6_M'
  
  pans = strtrim(strcompress(pans),2)

  return
  
end
