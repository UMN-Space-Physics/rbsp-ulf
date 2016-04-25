;+
;PROCEDURE:   mvn_swe_stat
;PURPOSE:
;  Reports the status of SWEA data loaded into the common block.
;
;USAGE:
;  mvn_swe_stat
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-04-19 12:09:05 -0700 (Sun, 19 Apr 2015) $
; $LastChangedRevision: 17367 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_stat.pro $
;
;CREATED BY:    David L. Mitchell  07-24-12
;-
pro mvn_swe_stat, npkt=npkt, silent=silent

  @mvn_swe_com

  npkt = replicate(0,8)

  if (size(swe_hsk,/type) ne 8) then begin
    print,""
    print,"No SWEA data loaded."
    print,""
    return
  endif

  if (n_elements(swe_hsk) eq 2) then begin
    n_hsk = 0L
    n_a6 = 0L
    if (size(mvn_swe_3d,/type) eq 8)       then n_a0 = n_elements(mvn_swe_3d)       else n_a0 = 0L
    if (size(mvn_swe_3d_arc,/type) eq 8)   then n_a1 = n_elements(mvn_swe_3d_arc)   else n_a1 = 0L
    if (size(mvn_swe_pad,/type) eq 8)      then n_a2 = n_elements(mvn_swe_pad)      else n_a2 = 0L
    if (size(mvn_swe_pad_arc,/type) eq 8)  then n_a3 = n_elements(mvn_swe_pad_arc)  else n_a3 = 0L
    if (size(mvn_swe_engy,/type) eq 8)     then n_a4 = n_elements(mvn_swe_engy)     else n_a4 = 0L
    if (size(mvn_swe_engy_arc,/type) eq 8) then n_a5 = n_elements(mvn_swe_engy_arc) else n_a5 = 0L
  endif else begin
    if (size(swe_hsk,/type) eq 8) then n_hsk = n_elements(swe_hsk) else n_hsk = 0L
    if (size(swe_3d,/type) eq 8) then n_a0 = n_elements(swe_3d) else n_a0 = 0L
    if (size(swe_3d_arc,/type) eq 8) then n_a1 = n_elements(swe_3d_arc) else n_a1 = 0L
    if (size(a2,/type) eq 8) then n_a2 = n_elements(a2) else n_a2 = 0L
    if (size(a3,/type) eq 8) then n_a3 = n_elements(a3) else n_a3 = 0L
    if (size(a4,/type) eq 8) then n_a4 = n_elements(a4) else n_a4 = 0L
    if (size(a5,/type) eq 8) then n_a5 = n_elements(a5)*16 else n_a5 = 0L
    if (size(a6,/type) eq 8) then n_a6 = n_elements(a6)*16 else n_a6 = 0L
  endelse
  
  npkt = [n_a0, n_a1, n_a2, n_a3, n_a4, n_a5, n_a6, n_hsk]

  if not keyword_set(silent) then begin
    print,""
    print,"SWEA Common Block:"
    print,n_hsk," Housekeeping packets (normal)"
    print,n_a6," Housekeeping packets (fast)"
    print,n_a0," 3D distributions (survey)"
    print,n_a1," 3D distributions (archive)"
    print,n_a2," PAD distributions (survey)"
    print,n_a3," PAD distributions (archive)"
    print,n_a4," ENGY Spectra (survey)"
    print,n_a5," ENGY Spectra (archive)"
    print,mvn_swe_tabnum(swe_active_chksum),format='("Sweep Table: ",i2)'
    print,""
  endif

  return

end
