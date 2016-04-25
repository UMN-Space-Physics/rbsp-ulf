;+
;PROCEDURE:   swe_engy_timing
;PURPOSE:
;  Disassembles A4 packets and sorts data in time sequence.
;
;USAGE:
;  swe_engy_timing
;
;INPUTS:
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2014-10-31 14:15:03 -0700 (Fri, 31 Oct 2014) $
; $LastChangedRevision: 16106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/swe_engy_timing.pro $
;
;CREATED BY:    David L. Mitchell  06-25-13
;FILE: swe_engy_timing.pro
;-
pro swe_engy_timing

  @mvn_swe_com

  if (size(a4,/type) eq 8) then begin

    nspec = 16L*n_elements(a4)
    edat = reform(a4.data,64L*nspec)
    etime = dblarr(64L,nspec)

    tvec = dindgen(448)*(1.95D/448D)
    tsam = dblarr(64)
    for j=0,63 do tsam[j] = total(tvec[(j*7+1):(j*7+6)])/6D

    period = 2D^a4.period
    toff = 2D*dindgen(16)

    for j=0L,(nspec-1L) do begin
      etime[*,j] = tsam + a4[j/16L].time + period[j/16L]*toff[j mod 16L]
;      if (a4[j/16L].smode) then etime[*,j] = etime[*,j] + (period[j/16L] - 1D)
    endfor

    etime = reform(etime,64L*nspec)
      
    store_data,'edat_svy',data={x:etime, y:edat}
    options,'edat_svy','ytitle','Engy Svy Timing'
    options,'edat_svy','psym',1
    ylim,'edat_svy',-10,300,0

  endif else print,"No A4 data to process."

  if (size(a5,/type) eq 8) then begin

    nspec = 16L*n_elements(a5)
    edat = reform(a5.data,64L*nspec)
    etime = dblarr(64L,nspec)

    tvec = dindgen(448)*(1.95D/448D)
    tsam = dblarr(64)
    for j=0,63 do tsam[j] = total(tvec[(j*7+1):(j*7+6)])/6D

    period = 2D^a5.period
    toff = 2D*dindgen(16)

    for j=0L,(nspec-1L) do begin
      etime[*,j] = tsam + a5[j/16L].time + period[j/16L]*toff[j mod 16L]
;      if (a5[j/16L].smode) then etime[*,j] = etime[*,j] + (period[j/16L] - 1D)
    endfor

    etime = reform(etime,64L*nspec)
      
    store_data,'edat_arc',data={x:etime, y:edat}
    options,'edat_arc','ytitle','Engy Arc Timing'
    options,'edat_arc','psym',1
    ylim,'edat_arc',-10,300,0

  endif else print,"No A5 data to process."
 
  return

end
