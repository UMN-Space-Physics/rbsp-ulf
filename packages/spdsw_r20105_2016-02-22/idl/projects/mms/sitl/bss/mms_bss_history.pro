;+
; NAME: mms_bss_history
;
; PURPOSE: 
;   To create a time-profile of the number of PENDING segments.
;   'bss' stands for 'burst segment status' which is the official 
;   name of the back-structure.
;
; USAGE:
;   With no keyword, this program diplays the plot in an IDL window.
;   Use the keywords for outputs.
;   
; KEYWORDS:
;   BSS: back-structure created by mms_bss_query
;   TRANGE: narrow the time range. It can be in either string or double.
;   TPLOT: 0 = no plot; 1 = tplot (default)
;   ASCII: 'tplot_ascii' commands will be used to export the results
;   CSV: output into csv files
;   
; CREATED BY: Mitsuo Oka  Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-11-11 08:43:26 -0800 (Wed, 11 Nov 2015) $
; $LastChangedRevision: 19336 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/mms_bss_history.pro $
;-
FUNCTION mms_bss_history_cat, bsh, category, wt
  compile_opt idl2
  wcat = lonarr(n_elements(wt)); output
  s = mms_bss_query(bss=bsh, category=category)
  if n_tags(s) eq 0 then return, wcat
  imax = n_elements(s.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    ndx = where( (s.UNIX_CREATETIME[i] le wt) and (wt le s.UNIX_FINISHTIME[i]), ct); extract pending period
    wcat[ndx] += s.SEGLENGTHS[i]; count segment size
  endfor
  return, wcat
END

FUNCTION mms_bss_history_overwritten, bsh, category, wDt
  compile_opt idl2
  wcat = lonarr(n_elements(wDt)); output
  s = mms_bss_query(bss=bsh, category=category)
  if n_tags(s) eq 0 then return, wcat
  imax = n_elements(s.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    day = time_double(time_string(s.UNIX_FINISHTIME[i],prec=-3))
    result = min(wDt-day, ndx,/abs)
    wcat[ndx] += s.SEGLENGTHS[i]; count segment size
  endfor
  return, wcat
END

FUNCTION mms_bss_history_overwritten2, bsh, category, wt
  compile_opt idl2
  wcat = lonarr(n_elements(wt)); output
  s = mms_bss_query(bss=bsh, category=category)
  if n_tags(s) eq 0 then return, wcat
  imax = n_elements(s.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    result=min(wt-s.UNIX_FINISHTIME[i],ndx, /absolute)
    wcat[ndx] += s.SEGLENGTHS[i]; count segment size
  endfor
  return, (-1L)*wcat
END

FUNCTION mms_bss_history_threshold, wt
  compile_opt idl2
  hard_limit = 24576L
  nmax=n_elements(wt)
  wthres = lonarr(nmax)
  
  ; DEFAULT VALUE
  wthres[0:nmax-1] = hard_limit-18000L
  
  ; TEMPRARY THRESHOLD INCREASE IN AUGUST
  stime = time_double('2015-08-04')
  etime = systime(/utc,/seconds)
  idx=where(stime le wt and wt lt etime, ct)
  if ct gt 0 then begin
    wthres[idx] = hard_limit - 15000L
  endif
  
  return, wthres
END

PRO mms_bss_history, bss=bss, trange=trange, tplot=tplot, csv=csv, dir=dir
  compile_opt idl2
  mms_init
  
  if undefined(tplot) then tplot=1
  if undefined(dir) then dir = '' else dir = thm_addslash(dir)

  ;----------------
  ; CATCH
  ;----------------
  catch, error_status
  if error_status ne 0 then begin
    catch, /cancel
    eva_error_message, error_status
    message, /reset
    return
  endif
  
  ;----------------
  ; TIME
  ;----------------
  tnow = systime(/utc,/seconds)
  tlaunch = time_double('2015-03-12/22:44')
  t3m = tnow - 120.d0*86400.d0; 120 days
  if n_elements(trange) eq 2 then begin
    tr = timerange(trange)
  endif else begin
    tr = [t3m,tnow]
    ;tr = [tlaunch,tnow]
    trange = time_string(tr)
  endelse
  
  ; time grid to be used for Pending buffer history
  ;mmax = 4320L ; extra data point for displaying grey-shaded region
  dt = 600.d0;10min
  nmax = (tr[1]-tr[0])/dt; + mmax
  wt = tr[0]+ dindgen(nmax)*dt
  
  ; time grid to be used for daily values of Increase and Decrease
  wDs = time_double(time_string(tr[0],prec=-3))
  wDe = time_double(time_string(tr[1],prec=-3))+86400.d0
  qmax = floor((wDe-wDs)/86400.d0); number of days
  wDt = wDs + 86400.d0*dindgen(qmax)
  wDi = lonarr(qmax) & wDi0= lonarr(qmax) & wDi1= lonarr(qmax) & wDi2= lonarr(qmax)
  wDi3= lonarr(qmax) & wDi4= lonarr(qmax) & wDd = lonarr(qmax) & wDd0= lonarr(qmax)
  wDd1= lonarr(qmax) & wDd2= lonarr(qmax) & wDd3= lonarr(qmax) & wDd4= lonarr(qmax)

  ;----------------
  ; LOAD DATA
  ;----------------
  if n_elements(bss) eq 0 then bss = mms_bss_query(trange=trange)

  ;------------------
  ; ANALYSIS (TOTAL)
  ;------------------
  wthres= mms_bss_history_threshold(wt); Threshold
  wcatT = lonarr(nmax); All segmentes
  wcatT2= lonarr(nmax); Segments being HELD for more than 3 days
  imax = n_elements(bss.FOM); number of filtered-out segments
  for i=0,imax-1 do begin; For each segment
    ndx = where( (bss.UNIX_CREATETIME[i] le wt) and (wt le bss.UNIX_FINISHTIME[i]), ct); extract pending period
    wcatT[ndx] += bss.SEGLENGTHS[i]; count segment size
    ndx = where( (bss.START[i]+3.d0*86400.d0 le wt) and (wt le bss.UNIX_FINISHTIME[i]) and $
      (strmatch(strlowcase(bss.STATUS[i]),'*complete*') or $; also contains INCOMPLETE
       strmatch(strlowcase(bss.STATUS[i]),'*demoted*') or $
       strmatch(strlowcase(bss.STATUS[i]),'*realloc*') or $
       strmatch(strlowcase(bss.STATUS[i]),'*held*')), ct)
       ; Here, we want segments that were 'HELD' or 'REALLOC' when they were isPending=1.
       ; The problem is HELD and REALLOC are transitory and such segments can turn into
       ; either COMPLETE, INCOMPLETE or DEMOTED.
    wcatT2[ndx] += bss.SEGLENGTHS[i]
  endfor
  ;wcatT2[nmax-mmax:nmax-1] = !VALUES.F_NAN
  wcatT2[nmax-1] = wcatT2[nmax-2]

  ; All segments (except bad segments and DELETED segments)
  wcat0  = mms_bss_history_cat(bss, 0, wt)
  wcat1  = mms_bss_history_cat(bss, 1, wt)
  wcat2  = mms_bss_history_cat(bss, 2, wt)
  wcat3  = mms_bss_history_cat(bss, 3, wt)
  wcat4  = mms_bss_history_cat(bss, 4, wt)
  
  ;///////// Do we really need this? ////////////////// 
  ; This is a temporary fix 2015-09-25
  wcatT  = mms_bss_history_cat(bss, 5, wt)
  ;////////////////////////////////////////////////////
  ;
  ; Newly held buffers and newly transmitted buffers
  wInc = lonarr(nmax); increase --> mostly selected buffers by SITL
  wDec = lonarr(nmax); decrease --> mostly transmitted buffers by SDC
  for n=1,nmax-1 do begin; for each time step of the time-grid
    this_wDt = time_double(time_string(wt[n],prec=-3))
    result = min(wDt-this_wDt,q,/abs); determine the date (q)
    a = wcatT[n]-wcatT[n-1]
    if a ge 0 then begin; if increased
      wInc[n] = a
      wDi[q] += wInc[n]
    endif else begin
      wDec[n] = (-a)
      wDd[q] += wDec[n]
    endelse
    a = wcat0[n]-wcat0[n-1] & if a ge 0 then wDi0[q] += a else wDd0[q] -= a
    a = wcat1[n]-wcat1[n-1] & if a ge 0 then wDi1[q] += a else wDd1[q] -= a
    a = wcat2[n]-wcat2[n-1] & if a ge 0 then wDi2[q] += a else wDd2[q] -= a
    a = wcat3[n]-wcat3[n-1] & if a ge 0 then wDi3[q] += a else wDd3[q] -= a
    a = wcat4[n]-wcat4[n-1] & if a ge 0 then wDi4[q] += a else wDd4[q] -= a
  endfor
  
  
  
  ; Overwritten segments
  bsA = mms_bss_query(bss=bss,exclude='INCOMPLETE'); exclude INCOMPLETE segments
  bsB = mms_bss_query(bss=bsA,status='DERELICT DEMOTED'); include DERELICT or DEMOTED segments
  wcat0o = mms_bss_history_overwritten(bsB, 0, wDt)
  wcat1o = mms_bss_history_overwritten(bsB, 1, wDt)
  wcat2o = mms_bss_history_overwritten(bsB, 2, wDt)
  wcat3o = mms_bss_history_overwritten(bsB, 3, wDt)
  wcat4o = mms_bss_history_overwritten(bsB, 4, wDt)
  
  wDi = wDi0+wDi1+wDi2+wDi3+wDi4
  wDd = wDd0+wDd1+wDd2+wDd3+wDd4
  
  ;------------------
  ; CSV
  ;------------------
  if keyword_set(csv) then begin
    
    ; PENDING SEGMENTS
    write_csv, dir+'mms_bss_history.txt', time_string(wt),wthres,wcatT2,wcat0,wcat1,wcat2,$
      wcat3,wcat4, HEADER=['time','Threshold','HELD >3days','Category 0','Category 1',$
      'Category 2','Category 3','Category 4']
    
    ; OVERWRITTEN SEGMENTS
    write_csv, dir+'mms_bss_overwritten.txt', time_string(wDt),wcat0o,wcat1o,wcat2o,wcat3o,wcat4o,$
      HEADER=['time','Category 0','Category 1','Category 2','Category 3','Category 4']
    
    ; INCREASE/DECREASE
    write_csv, dir+'mms_bss_diff.txt', time_string(wt),wInc,wDec,$
      HEADER=['time','Increase','Decrease']
    write_csv, dir+'mms_bss_diff_per_day.txt', time_string(wDt),wDi,wDd,$
      HEADER=['time','Increase/day','Decrease/day']  
    
    ; BREAKDOWN
    write_csv, dir+'mms_bss_inc_per_day.txt', time_string(wDt),wDi,wDi0,wDi1,wDi2,wDi3,wDi4,$
      HEADER=['time','Total','Category 0','Category 1','Category 2','Category 3','Category 4']
    write_csv, dir+'mms_bss_dec_per_day.txt', time_string(wDt),wDd,wDd0,wDd1,wDd2,wDd3,wDd4,$
      HEADER=['time','Total','Category 0','Category 1','Category 2','Category 3','Category 4']
  endif
  
  ;------------------
  ; TPLOT
  ;------------------
  if keyword_set(tplot) then begin
    
    ; PENDING SEGMENTS
    wcat  = lonarr(nmax,7)
    wcat[*,6] = wcatT2; HELD > 3 days
    wcat[*,5] = wcat4; Category 4
    wcat[*,4] = wcat[*,5] + wcat3; Category 4 + 3
    wcat[*,3] = wcat[*,4] + wcat2; Category 4 + 3 + 2
    wcat[*,2] = wcat[*,3] + wcat1; Category 4 + 3 + 2 + 1
    wcat[*,1] = wcat[*,2] + wcat0; Category 4 + 3 + 2 + 1 + 0
    wcat[*,0] = wthres
    store_data,'mms_bss_history',data={x:wt, y:wcat, v:[0,1,2,3,4,5,6]}
    options,'mms_bss_history',colors=[3,1,6,5,4,2,0],ytitle='PENDING Buffers',$
      title='MMS Burst Memory Management',labels=['Threshold','Category 0','Category 1',$
      'Category 2','Category 3','Category 4','HELD >3days'],labflag=-1
  
    ; OVERWRITTEN SEGMENTS
    wDt += 43200.d0; Psym=10 makes a bar centered around wDt. Here, we shift by 12 hours to correct this.
    wovr = lonarr(qmax,5)
    wovr[*,4] = wcat4o
    wovr[*,3] = wovr[*,4] + wcat3o
    wovr[*,2] = wovr[*,3] + wcat2o
    wovr[*,1] = wovr[*,2] + wcat1o
    wovr[*,0] = wovr[*,1] + wcat0o
    store_data,'mms_bss_overwritten',data={x:wDt, y:wovr, v:[0,1,2,3,4]}
    options,'mms_bss_overwritten',colors=[0,6,5,4,2],ytitle='Overwritten Buffers',$
      labels=['Category 0','Category 1','Category 2','Category 3','Category 4'],labflag=-1,$
      psym=10
    
    ; INCREASE/DECREASE
    store_data,'mms_bss_inc',data={x:wt,y:wInc}
    store_data,'mms_bss_dec',data={x:wt,y:wDec}
    store_data,'mms_bss_inc_per_day',data={x:wDt,y:wDi}
    store_data,'mms_bss_dec_per_day',data={x:wDt,y:wDd}
    options,'mms_bss_inc_per_day',psym=10,colors=0,labels=['increase']
    options,'mms_bss_dec_per_day',psym=10,colors=1,labels=['decrease']
    store_data,'mms_bss_diff_per_day',data=['mms_bss_inc_per_day','mms_bss_dec_per_day']
    options,'mms_bss_diff_per_day',ytitle='PENDING Buffers',labflag=-1
  
    ; PLOT  
    timespan,time_string(tr[0]),tr[1]-tr[0]+3.d0*86400.d0,/seconds
    tplot,['mms_bss_history','mms_bss_diff_per_day','mms_bss_overwritten']
  endif
END
