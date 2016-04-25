;+
; NAME: rbsp_efw_density_fit_from_uh_line
; SYNTAX: 
; PURPOSE: Return a tplot variable of density based on sc
; potential. Calibrations from the UH line are updated every few weeks
; INPUT: sc_potential - name of tplot variable (string) that contains the quantity (V1+V2)/2
; OUTPUT: tplot variable of density
; KEYWORDS: sc -> 'a' or 'b'
;           newname -> name of output density tplot variable. Defaults
;                 to 'density'
;         dmin, dmax -> min and max allowable density values. Values
;            outside of these limits are set to NaN or setval if set
;         setval -> value to set density to if it is outside dmin,
;         dmax range
;
; HISTORY: Written by Aaron W Breneman (UMN), based on Scott
; Thaller's density calibrations to EMFISIS upper hybrid line
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-10-28 11:47:06 -0700 (Tue, 28 Oct 2014) $
;   $LastChangedRevision: 16059 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/calibration_files/rbsp_efw_density_fit_from_uh_line.pro $
;-


; RBSP B desnity fits for Oct 2013, Feb and Mar 2014




pro rbsp_efw_density_fit_from_uh_line,sc_potential,sc,newname=newname,dmin=dmin,dmax=dmax,setval=setval

  get_data,sc_potential,data=pot

  if is_struct(pot) then begin

     times = time_double(pot.x)
     v = pot.y
     den = fltarr(n_elements(pot.x))
     timesf = dblarr(n_elements(pot.x))

;**************************************************
;GENERIC CALIBRATION FOR MOST RECENT TIMES (BE SURE TO UPDATE THIS....)
     tst = where(times ge time_double('2014-07-01/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 8725.1578*exp(v*4.0412565)+205.79788*exp(v*0.82851517) ; June 1, 2014    
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif
;**************************************************

     tst = where(times ge time_double('2014-04-10/00:00:00') AND times lt time_double('2014-07-01/00:00:00')) 
     if tst[0] ne -1 then begin
        denstmp = 8725.1578*exp(v*4.0412565)+205.79788*exp(v*0.82851517) ; June 1, 2014    
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2014-03-02/00:00:00') AND times lt time_double('2014-04-10/00:00:00'))
     if tst[0] ne -1 then begin
        if sc eq 'a' then denstmp = 9487.0458*exp(v*3.1599373)+164.07663*exp(v*0.51572132) ;Mar 12,13,14, 2014    
        if sc eq 'b' then denstmp = 5059.1326*exp(v*3.1960440)+97.932549*exp(v*0.49372449) ; Mar 2014 12-14 RBSPb
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2014-02-02/00:00:00') AND times lt time_double('2014-03-02/00:00:00'))
     if tst[0] ne -1 then begin
        if sc eq 'a' then denstmp = 11838.774*exp(v*3.2366900)+146.10501*exp(v*0.52979420) ;Feb 12,13,14, 2014
        if sc eq 'b' then denstmp = 8628.6284*exp(v*3.4245489)+117.83428*exp(v*0.54272236) ; feb 12, 13 RBSP b
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-11-15/00:00:00') AND times lt time_double('2014-02-02/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 7354.3897*exp(v*2.8454878)+96.123628*exp(v*0.43020781) ;Jan 3 , 2014
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-10-01/00:00:00') AND times lt time_double('2013-11-01/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 4300.7185*exp(v*2.9569220)+85.003322*exp(v*0.50856921) ;Oct 11-12 2013 RBSP B
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-08-15/00:00:00') AND times lt time_double('2013-10-01/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 8860.1926*exp(v*4.0369044)+481.88790*exp(v*0.98777916) ;Oct 8, 2013 
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-06-15/00:00:00') AND times lt time_double('2013-08-15/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 6568.9865*exp(v*2.7532200)+146.55187*exp(v*0.54184738) ;for Jul 3,4,5
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-05-30/00:00:00') AND times lt time_double('2013-06-15/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 7241.1022*exp(v*2.8091658)+114.65080*exp(v*0.48230506) ;for Jun 3,4,5
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-04-15/00:00:00') AND times lt time_double('2013-05-30/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 7583.2633*exp(v*2.6189202)+94.628415*exp(v*0.42716477) ;for may 10,11,12
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-03-15/00:00:00') AND times lt time_double('2013-04-15/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 7678.1259*exp(v*3.1731390)+127.84690*exp(v*0.62929729) ;for Apr 4,5,6
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-02-19/10:00:00') AND times lt time_double('2013-03-15/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 3364.6009*exp(v*2.9939313)+61.521928*exp(v*0.57541034) ;for Mar 4,5,6
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-02-01/03:00:00') AND times lt time_double('2013-02-19/10:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 2770.3406*exp(v*2.4858)+56.853*exp(v*0.45430762) ;for feb 17,18,19
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2013-01-08/01:00:00') AND times lt time_double('2013-02-01/03:00:00'))
     if tst[0] ne -1 then begin
        denstmp= 3378*exp(v/0.319)+39.3*exp(v/2.13) ;jan 21,22,23
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2012-12-19/07:30:00') AND times lt time_double('2013-01-08/01:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 3777.9946*exp(v*3.1242541)+68.306728*exp(v*0.60038500) ;for Jan 3,4,5
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2012-12-05/07:44:00') AND times lt time_double('2012-12-19/07:30:00'))
     if tst[0] ne -1 then begin
        denstmp= 3096.0876*exp(v*2.9306241)+31.480371*exp(v*0.34482206) ;for Dec 6,7,8
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2012-11-27/11:11:00') AND times lt time_double('2012-12-05/07:44:00'))
     if tst[0] ne -1 then begin
        denstmp = 3245.8930*exp(v*3.1010859)+71.804666*exp(v*0.63419612) ;for Dec 3,4,5
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2012-10-10/02:20:00') AND times lt time_double('2012-11-27/11:11:00'))
     if tst[0] ne -1 then begin
        denstmp = 3448.12*exp(v*2.75) +64.372*exp(v*0.474) ;             ;for  Nov 3,4,5
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2012-10-03/00:00:00') AND times lt time_double('2012-10-10/02:20:00'))
     if tst[0] ne -1 then begin
        denstmp = 3506.7880*exp(v*1.9765367)+62.761338*exp(v*0.3505696) ;for  Oct 3,4,5
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2012-09-28/00:00:00') AND times lt time_double('2012-10-03/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 6252.0946*exp(v*2.8359046)+586.56744*exp(v*1.0883319) ;for sep 30 2012        
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif

     tst = where(times ge time_double('2012-09-26/00:00:00') AND times lt time_double('2012-09-28/00:00:00'))
     if tst[0] ne -1 then begin
        denstmp = 5752.4565*exp(v[tst]*2.8941695)+143.44592*exp(v[tst]*0.58234518) ; for sep 26, 2012
        den[tst] = denstmp[tst]
        timesf[tst] = times[tst]
     endif




;--------------------------------------------------
;If set, remove density values below and above dmin and dmax
;--------------------------------------------------

     if keyword_set(dmin) then begin
        goo = where(den lt dmin)
        if goo[0] ne -1 then begin
           if ~keyword_set(setval) then den[goo] = !values.f_nan else den[goo] = setval
        endif
     endif
     if keyword_set(dmax) then begin
        goo = where(den gt dmax)
        if goo[0] ne -1 then begin
           if ~keyword_set(setval) then den[goo] = !values.f_nan else den[goo] = setval
        endif
     endif


     if keyword_set(newname) then store_data,newname,data={x:timesf,y:den} else store_data,'density',data={x:timesf,y:den}


  endif else print,'NO VALID TPLOT VARIABLE INPUTTED.....SKIPPING'

end
