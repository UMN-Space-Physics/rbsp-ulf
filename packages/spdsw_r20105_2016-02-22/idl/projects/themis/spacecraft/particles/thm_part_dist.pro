;+
;NAME:
; thm_part_dist
;PURPOSE:
; wrapper function around the different routines called 'get_p???'
; used for ESA particle data and 'thm_sst_p???' routines that extract
; SST data.
;INPUT:
; format = a string denoting the data that is desired: options are:
;          'tha_peif': Full Esa mode data, ions, probe A
;          'tha_peef': Full Esa mode data, electrons, probe A
;          'tha_peir': Reduced Esa mode data, ions, probe A
;          'tha_peer': Reduced Esa mode data, electrons, probe A
;          'tha_peir': Burst Esa mode data, ions, probe A
;          'tha_peer': Reduced Esa mode data, electrons, probe A
;          'tha_psif': Full Sst mode data, ions, probe A
;          'tha_psef': Full Sst mode data, electrons, probe A
;          'tha_psir': Reduced Sst mode data, ions, probe A
;          'tha_pser': Reduced Sst mode data, electrons, probe A
;         For other probes, just replace 'tha' with the appropriate
;         string, 'thb', 'thc', 'thd', 'the'
;          If this is not set, then the string is constructed from the
;          type and probe keywords
; time = an input time, if not passed in, then this routine will
;        attempt to get the time from plotted data, via ctime, unless
;        the index keyword is passed in (for SST) or
;        when start, en, advance, retreat, or index are passed in.
;KEYWORDS:
; type = 4 character string denoting the type of data that you need,
;        e.g., 'peif' for full mode esa data
; probe = the THEMIS probe, 'a','b','c','d','e'
; cursor = if set, then choose a time from the plot, using
;          ctime.pro. This overrides any input -- that is, the
;          variable that was used becomes the input variable and the
;          time obtained becomes the time of the data.
; index = an index for the data point that is to be returned
; start (ESA only) = if set, then get the first saved data point
; en (ESA only) = if set, get the last saved data point
; advance (ESA only) = if set, get the data point after the one that
;                      was gotten last
; retreat (ESA only) = if set, get the data point before the one that
;                      was gotten last
; times = if set, returns the time array for all the saved data points
;OUTPUT:
; dat = the '3d data structure' for the given data type: In general
;       this will be different for different data types, but there are
;       elements that are common to all, Here is a sample for tha_psif
;       data:
;   PROJECT_NAME    STRING    'THEMIS'
;   DATA_NAME       STRING    'SST Ion Full distribution'
;   UNITS_NAME      STRING    'Counts'
;   UNITS_PROCEDURE STRING    'thm_sst_convert_units'
;   TPLOTNAME       STRING    ''
;   TIME            DOUBLE       1.1837675e+09
;   END_TIME        DOUBLE       1.1837676e+09
;   TRANGE          DOUBLE    Array[2] ;;not always present
;   INDEX           LONG                 4
;   NBINS           LONG                64
;   NENERGY         LONG                16
;   MAGF            FLOAT     Array[3]
;   SC_POT          FLOAT           0.00000
;   MASS            FLOAT         0.0104390
;   CHARGE          FLOAT           0.00000
;   VALID           INT              1
;   MODE            INT              0
;   CNFG            INT            577
;   NSPINS          INT             64
;   DATA            FLOAT     Array[16, 64]
;   ENERGY          FLOAT     Array[16, 64]
;   THETA           FLOAT     Array[16, 64]
;   PHI             FLOAT     Array[16, 64]
;   DENERGY         FLOAT     Array[16, 64]
;   DTHETA          FLOAT     Array[16, 64]
;   DPHI            FLOAT     Array[16, 64]
;   BINS            INT       Array[16, 64]
;   GF              FLOAT     Array[16, 64]
;   INTEG_T         FLOAT     Array[16, 64]
;   DEADTIME        FLOAT     Array[16, 64]
;   GEOM_FACTOR     FLOAT          0.100000
;   ATTEN           INT             10
;
; NOTE: 1.  that the .time tag refers to the interval start time. The
; .trange tag gives the time range, and is not always present.
;       2.  For documentation on sun contamination correction keywords that
;       may be passed in through the _extra keyword please see:
;       thm_remove_sunpulse.pro or thm_crib_sst_contamination.pro
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-05-09 14:11:06 -0700 (Fri, 09 May 2014) $
;$LastChangedRevision: 15085 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_dist.pro $
;-
function thm_part_dist, format, time, type = type, probe = probe, $
                        cursor = cursor, sst_cal = sst_cal, pattern = pattern, $
                        bgnd_remove = bgnd_remove, err_msg=err_msg, _extra = ex

err_msg = ''

if keyword_set(cursor) then begin
   ctime,time,vname=vname
   ts=time_string(time)
   dprint,vname,/phelp
   dprint,ts,/phelp
   format = strmid(vname,0,8)
   format = format[0]
   dprint,format,/phelp
endif

if keyword_set(format) then begin
   probe = strmid(format,2,1)
   type  = strmid(format,4,4)
endif else format = 'th'+probe+'_'+type


;calibrated SST data loaded by default (thm_part_load)
;TODO: It might be better to check for the presence of
;      normal & callibrated data with thm_part_trange and 
;      preferentially load calibrated when both exist. 
if strmid(format,5,1) eq 's' then begin
  if strmid(format,7,1) ne 'r' && undefined(sst_cal) then begin
    sst_cal = 1
  endif
  ;SST calibrations only apply to full/burst data
  if keyword_set(sst_cal) && (strmid(format,7,1) eq 'f' || strmid(format,7,1) eq 'b') then begin
    return,thm_part_dist2(format,time,_extra=ex)
  endif
endif


;type=type[0]
if n_elements(time) gt 1 then begin
  case strmid(type,0,3) of
     'pei'  :      times = call_function('get_'+format  ,/time,_extra=ex )
     'pee'  :      times = call_function('get_'+format  ,/time,_extra=ex )
     'psi'  :      times = call_function('thm_sst_'+type,/time,probe=probe, err_msg=err_msg, _extra=ex)   ; thm_sst_sif thm_sst_sir
     'pse'  :      times = call_function('thm_sst_'+type,/time,probe=probe, err_msg=err_msg, _extra=ex)
  endcase
  irange=round( interp(dindgen(n_elements(times)),times,minmax(time)) )
  indexs = l64indgen(irange[1]-irange[0]+1) + irange[0]
;  dprint,times
  for i=0ll,n_elements(indexs)-1ull do begin
    case strmid(type,0,3) of
       'pei'  :      dat0 = call_function('get_'+format  ,index=indexs[i],_extra=ex )
       'pee'  :      dat0 = call_function('get_'+format  ,index=indexs[i],_extra=ex )
       'psi'  :      dat0 = call_function('thm_sst_'+type,index=indexs[i],probe=probe, err_msg=err_msg, _extra=ex)   ; thm_sst_sif thm_sst_sir
       'pse'  :      dat0 = call_function('thm_sst_'+type,index=indexs[i],probe=probe, err_msg=err_msg, _extra=ex)
    endcase
    If(keyword_set(bgnd_remove) && strmid(type, 0, 2) Eq 'pe') Then Begin
      If(is_struct(dat0) && dat0.valid Gt 0) Then Begin
        dat0_b = dat0.data       ;this is overwritten in the bgnd_remove process
        thm_esa_bgnd_remove, dat0_b, dat0.gf, dat0.eff, dat0.nenergy, dat0.nbins, dat0.theta, _extra = ex
        dat0.data = temporary(dat0_b)
      Endif
    Endif
    dat = sum3d(dat,dat0)
    ;if strmid(type,0,2) eq 'pe' then dat.energy[31,*] = !values.f_nan
  endfor

endif else begin
  case strmid(type,0,3) of
     'pei'  :      dat = call_function('get_'+format  ,time,_extra=ex )
     'pee'  :      dat = call_function('get_'+format  ,time,_extra=ex )
     'psi'  :      dat = call_function('thm_sst_'+type,time,probe=probe, err_msg=err_msg, _extra=ex)   ; thm_sst_sif thm_sst_sir
     'pse'  :      dat = call_function('thm_sst_'+type,time,probe=probe, err_msg=err_msg, _extra=ex)
  endcase
  If(keyword_set(bgnd_remove) && strmid(type, 0, 2) Eq 'pe') Then Begin
    If(is_struct(dat) && dat.valid Gt 0) Then Begin
      dat_b = dat.data  ;this is overwritten in the bgnd_remove process
      thm_esa_bgnd_remove, dat_b, dat.gf, dat.eff, dat.nenergy, dat.nbins, dat.theta, _extra = ex
      dat.data = temporary(dat_b)
    Endif
  Endif
endelse

return,dat

end
