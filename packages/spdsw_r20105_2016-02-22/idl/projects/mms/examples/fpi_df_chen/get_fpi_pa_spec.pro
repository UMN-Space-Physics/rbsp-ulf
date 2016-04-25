;+
; PROCEDURE:	get_fpi_pa_spec
;
; PURPOSE:	
;	Generates pitch angle-time spectrogram data structures for
;	tplot
; Created according to get_codif_pa_spec from CCAT-- Shan Wang 07/09/2015
;
; INPUT:		
;
; KEYWORDS: 
;      
;
; Last Modification: 06/05/12
;
; Modification History:
;     07/14/99 - removed while loop that computed time averaged 
;                pitch angles 
;     07/22/99 - add keyword 'gap_time' for DATA GAP time check
;     08/19/99 - add keyword 'EFF_FILE'
;     09/23/99 - changed check for keyword FILTER => 0=Yes, 1=No
;     09/30/99 - added keyword 'PaBin'
;     10/01/99 - mulitply data by aweight just after theta's and phi's
;                are selected out.  only these are used in computing
;                aweight.
;     10/07/99 - fixed miscalculation of flux*aweight
;     11/09/99 - added option for backgroud subtraction for all non
;                proton species.
;     04/09/01 - Modified for the needs of CLUSTER/CODIF data
;     05/22/01 - C.M. the keyword PABIN is utilised
;     02/05/02 - C.M. The keyword ALL_ENERGY_BINS is introduced
;     03/13/02 - C.M. OLD_EFF keyword added -- obsolete
;     08/08/02 - C.M. BKG keyword added -- not now
;     06/05/12 - C.M. Keywords HE1_CLEAN and RAPID added -- obsolete
;     
;     9/18/2015 - keyword tstamp_center, if set, use the center time of 
;                 each bin as the stamp, otherwise use the start time
;-

PRO get_fpi_pa_spec, sat,           $
                       mag_theta, mag_phi,        $
                       specie=specie,             $
                       eff_table,                 $
                       dat = dat,  	          $
                       ENERGY=energy, 	          $
                       ANGLE=an, 		  $
                       ARANGE=ar, 	          $
                       BINS=bins, 	          $
                       units = units,  	          $
                       name  = name, 	          $
                       missing = missing,         $
                       s_t=s_t,		          $
                       e_t=e_t,		          $
                       PRODUCT = product,	  $
                       EFF_ROUTINE = eff_routine, $
                       FILTER = FILTER,           $
                       DELTAT = deltat,           $
                       EFF_FILE = eff_file,       $
                       PABIN = PaBin,             $
                       BACKGROUND = background,   $
                       ALL_ENERGY_BINS=ALL_ENERGY_BINS
                       tstamp_center = tstamp_center

  
  COMMON get_error, get_err_no, get_err_msg, default_verbose
  
  ex_start = systime(1)         ; strat timing execution time
  
  get_err_no = 0

  if ~keyword_set(dat) then begin
     routine = 'get_fpi_3dflux_2dbin'
     dat = call_function(routine,sat,specie) 
                                ; parameters: PROD, SPECIE, SAT
  endif
  
  IF get_err_no GT 0 THEN RETURN
  

  packets=n_elements(dat.time) ; number of packets
  nenergy = dat.nenergy ; number of energy bins
  nbins = dat.nbins ; number of angle bins
  
;----------------------------------------------------------------------------
; Convert units. Keyword UNITS (for future)
;----------------------------------------------------------------------------  
  IF NOT KEYWORD_SET(units) THEN units = 'counts'


if strupcase(units) ne 'DF' then begin
  y0 = dat.data*1.0e30 ;s^3/cm^6 to s^3/km^6
  ynew = y0
  for i=0,n_elements(dat.time)-1 do begin
    convert_flux_unit,specie=specie,energy=dat.energy,flux=y0[*,*,i],$
      from_unit='df',to_unit=units,new_flux=y1
      ynew[*,*,i] = y1
   endfor
  dat.data = ynew
  dat.units_name = units
  
endif

;-----------------------------------------------------------------------
; Set domega
;-----------------------------------------------------------------------
  theta = dat.theta/!radeg
  phi = dat.phi/!radeg
  dtheta = dat.dtheta/!radeg
  dphi = dat.dphi/!radeg
  
  str_element,dat,"domega",value=domega,index=ind
  IF ind GE 0 THEN BEGIN
    IF ndimen(domega) EQ 1 THEN domega=replicate(1.,na)#domega
  ENDIF ELSE BEGIN
    IF ndimen(dtheta) EQ 1 THEN dtheta=replicate(1.,na)#dtheta
    IF ndimen(dphi) EQ 1 THEN dphi=replicate(1.,na)#dphi
    domega=2.*dphi*cos(theta)*sin(.5*dtheta)
  ENDELSE
;-----------------------------------------------------------------------
  
  IF NOT(KEYWORD_SET(paBin)) THEN PaBin = 6.0
  missing = !values.f_nan
  packets = n_elements(dat.time)
  if keyword_set(tstamp_center) then begin
  t = (dat.time + dat.end_time)/2.
  endif else begin
    t = dat.time
  endelse
  
  pa = get_pitch_angle(dat, mag_theta, mag_phi)

  fldat = REFORM(dat.data)
  padat = REFORM(pa)
  
  IF KEYWORD_SET(paBin) THEN BEGIN ; set PA bins according to PaBin
    paRange = 180
    BinStartStop = 0.
    FOR i = 1, paRange/paBin DO BinStartStop = [BinStartStop, i*paBin]
    BinCenter = 0.
    FOR i = 1, ((PaRange/paBin)*2)-1,2 DO BinCenter = [BinCenter, i*(PaBin/2.)]
    BinCenter = BinCenter(1:*)
    nmax = paRange / PaBin
  ENDIF
  
  time = dblarr(packets)
  nvar = nmax
  var = fltarr(packets,nvar)
  data = dblarr(packets,nvar)
  
  IF KEYWORD_SET(ALL_ENERGY_BINS) THEN BEGIN

      data = dblarr(dat.nenergy, packets, nvar)

    FOR iebin = 0, dat.nenergy-1 DO BEGIN
      

      
      fldat = REFORM(dat.data)
      padat = REFORM(pa)
      
      fldat = fldat(iebin,*,*)
      fldat = REFORM(fldat)
      padat = padat(iebin,*,*)
      padat = REFORM(padat)

      FOR n = 0, packets-1 DO BEGIN ; Loop over all time steps
        
        datSort0 = padat(*,n)
        domegaSort = domega(0,*)
        fldatSort = fldat(*,n)
        
        var(n,0:nvar-1) = BinCenter(*)
        
        FOR k = 0, nmax-1 DO BEGIN ; Loop over all pa bins
          
          exi = WHERE(datSort0 LT BinStartStop(k+1) AND $
                      datSort0 GE BinStartStop(k), ct)
          IF exi(0) NE -1 THEN BEGIN
            IF STRUPCASE(units) EQ 'COUNTS' THEN $
              aweight = REPLICATE(1,N_ELEMENTS(exi)) $
            ELSE $
              aweight = domegaSort(exi)
            IF ct(0) GT 1 THEN $
              data(iebin,n,k) = TOTAL((fldatSort(exi)*aweight),/NaN) / $
              TOTAL(aweight, /NaN)$
            ELSE $
              data(iebin,n,k) = (fldatSort(exi)*aweight)/aweight
          ENDIF ELSE $
            data(iebin,n,k) = missing
          
        ENDFOR
        
      ENDFOR
      
    ENDFOR
    
    if keyword_set(tstamp_center) then begin
      tstamp = (dat.time + dat.end_time)/2.
    endif else begin
      tstamp = dat.time
    endelse
    
    datastr = {x: tstamp, $
               y: data, v:var, e:dat.energy(*,0)}
    labels =''
    name = STRMID(name,0,STRPOS(name,'EN')-1) + $
      STRMID(name, STRPOS(name, '_mms'), STRLEN(name))
    store_data, name[0], $
      data=datastr,dlim={ylog:1,labels:labels,panel_size:2.}
  ENDIF

  IF NOT KEYWORD_SET(ALL_ENERGY_BINS) THEN BEGIN
    
    IF KEYWORD_SET(ENERGY) THEN BEGIN
      ;----------------------------------------------------------------
      ; min,max energy range for integration. Keyword ENERGY
      ;----------------------------------------------------------------
      er2=[energy_to_ebin(dat,energy)] ; find min & max energy bin
      IF er2(0) GT er2(1) THEN er2=reverse(er2)
      n_en = er2(1)-er2(0)+1
      
      fldat = TOTAL(fldat(er2(0):er2(1),*,*),1)/n_en
      padat = TOTAL(padat(er2(0):er2(1),*,*),1)/n_en
    ENDIF ELSE BEGIN
      fldat = TOTAL(fldat,1)/dat.nenergy
      padat = TOTAL(padat,1)/dat.nenergy
    ENDELSE
    
    IF NOT(KEYWORD_SET(paBin)) THEN PaBin = 6.0
    missing = !values.f_nan
    packets = n_elements(dat.time)
    if keyword_set(tstamp_center) then begin
      t = (dat.time + dat.end_time)/2.
    endif else begin
      t = dat.time
    endelse

    IF KEYWORD_SET(paBin) THEN BEGIN ; set PA bins according to PaBin
      paRange = 180
      BinStartStop = 0.
      FOR i = 1, paRange/paBin DO BinStartStop = [BinStartStop, i*paBin]
      BinCenter = 0.
      FOR i = 1, ((PaRange/paBin)*2)-1,2 DO BinCenter = [BinCenter, i*(PaBin/2.)]
      BinCenter = BinCenter(1:*)
      nmax = paRange / PaBin
    ENDIF

    time = dblarr(packets)
    nvar = nmax
    var = fltarr(packets,nvar)
    data = dblarr(packets,nvar)
    
    
    FOR n = 0, packets-1 DO BEGIN ; Loop over all time steps
      
      datSort0 = padat(*,n)
      domegaSort = domega(0,*)
      fldatSort = fldat(*,n)
      
      var(n,0:nvar-1) = BinCenter(*)
      FOR k = 0, nmax-1 DO BEGIN ; Loop over all pa bins
        
        exi = WHERE(datSort0 LT BinStartStop(k+1) AND $
                    datSort0 GE BinStartStop(k), ct)
        IF exi(0) NE -1 THEN BEGIN
          IF STRUPCASE(units) EQ 'COUNTS' THEN $
            aweight = REPLICATE(1,N_ELEMENTS(exi)) $
          ELSE $
            aweight = domegaSort(exi)
          IF ct(0) GT 1 THEN $
            data(n,k) = TOTAL((fldatSort(exi)*aweight),/NaN) / $
            TOTAL(aweight, /NaN)$
          ELSE $
            data(n,k) = (fldatSort(exi)*aweight)/aweight
        ENDIF ELSE $
          data(n,k) = missing
      ENDFOR
      
    ENDFOR
    
    if keyword_set(tstamp_center) then begin
      tstamp = (dat.time + dat.end_time)/2.
    endif else begin
      tstamp = dat.time
    endelse
    datastr = {x: tstamp, $
               y: data, v:var}
    labels =''
    store_data, name, data=datastr,dlim={ylog:1,labels:labels,panel_size:2.}
    
  ENDIF

END
