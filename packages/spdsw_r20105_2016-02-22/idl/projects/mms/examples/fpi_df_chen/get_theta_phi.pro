;+ 
; PROCEDURE:  get_theta_phi
;
; PURPOSE: get the average or all magnetic theta and phi data in 
;          codif coordinates
;
; INPUT:
;        sat -> spacesraft number
;        dat -> instrument data structure
;        datab -> magnetic field tplot variable
;        
; OUTPUT: 
;         mag_theta -> magnetic field theta in gse
;         mag_phi   -> magnetic field phi in gse

; CREATED BY: Shan Wang, based on get_theta_phi.pro in CCAT created by
;C. Mouikis
;
; LAST MODIFICATION: 07/09/2015
;
; MODIFICATION HISTORY:
;-
PRO get_theta_phi, sat, dat, mag_theta, mag_phi, $
                   datab = datab,$
                   ave=ave,$
                   interp=interp
  
  COMMON get_error, get_err_no, get_err_msg, default_verbose

  get_data,datab,data=db
  Btime = db.x
  Bxyz = db.y[*,0:2]
  
  IF keyword_set(ave) THEN BEGIN
    IF Btime(0) NE -9999.9 THEN BEGIN
      ; calculate average value
       ;get_timespan,trange
       n_t = n_elements(dat.time)
       Bxavg = fltarr(n_t)
       Byavg = fltarr(n_t)
       Bzavg = fltarr(n_t)
       for it=0, n_t-1 do begin
        ind = where(Btime ge dat.time[it] and $
                   Btime le dat.end_time[it],cc)
        if cc eq 0 then begin
           ;print,'B data not available at time '+time_string(dat.time[it],precision=3)
           ;print,'interpolating..'
           Bxavg[it]=interpol(Bxyz[*,0], Btime, (dat.time[it] + dat.end_time[it])/2.)
           Byavg[it]=interpol(Bxyz[*,1], Btime, (dat.time[it] + dat.end_time[it])/2.)
           Bzavg[it]=interpol(Bxyz[*,2], Btime, (dat.time[it] + dat.end_time[it])/2.)
           continue
        endif
        Bxavg[it] = mean(Bxyz(ind,0), /NaN)
        Byavg[it] = mean(Bxyz(ind,1), /NaN)
        Bzavg[it] = mean(Bxyz(ind,2), /NaN)
       endfor
      

      ravg = sqrt(Bxavg^2+Byavg^2)
      mag_theta = (ATAN(Bzavg/ravg))*!RADEG
      mag_phi = (ATAN(Byavg,Bxavg))*!RADEG
      mag_phi = mag_phi - 360*FLOOR(mag_phi/360.)

    ENDIF
  
    IF Btime(0) EQ -9999.9 THEN BEGIN
      print, 'NO CORRESPONDING MAGNETIC FIELD FILES FOUND.'
      print, 'MAGNETIC FIELD PHI & THETA VALUES CAN BE PROVIDED '
      print, 'MANUALLY USING THE CORRESPONDING KEYWORDS'
    ENDIF
    
  ENDIF 

  IF keyword_set(interp) THEN BEGIN

    ; interpolate B values on fpi data times

    IF Btime(0) EQ -9999.9 THEN BEGIN
      print, 'NO CORRESPONDING MAGNETIC FIELD FILES FOUND.'
      print, 'MAGNETIC FIELD PHI & THETA VALUES CAN BE PROVIDED '
      print, 'MANUALLY USING THE CORRESPONDING KEYWORDS'
      
      get_err_no = 1
      GOTO, next

    ENDIF

    Bx = INTERPOL(Bxyz(*,0), Btime, (dat.time + dat.end_time)/2.)
    By = INTERPOL(Bxyz(*,1), Btime, (dat.time + dat.end_time)/2.)
    Bz = INTERPOL(Bxyz(*,2), Btime, (dat.time + dat.end_time)/2.)
    ;Bx = INTERPOL(Bxyz(*,0), Btime, dat.time)
    ;By = INTERPOL(Bxyz(*,1), Btime, dat.time)
    ;Bz = INTERPOL(Bxyz(*,2), Btime, dat.time)


    ravg = sqrt(Bx^2+By^2)
    mag_theta = (ATAN(Bz/ravg))*!RADEG
    mag_phi = (ATAN(By, Bx))*!RADEG
    mag_phi = mag_phi - 360*floor(mag_phi/360.)
    
;    store_data, 'B_xyz_gse', /DELETE
;    store_data, 'B_xyz_codif', /DELETE
  ENDIF
   
  next:
 
END
