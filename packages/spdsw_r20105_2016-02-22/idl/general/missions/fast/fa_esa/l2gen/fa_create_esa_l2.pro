;+
;NAME:
; fa_create_esa_l2
;PURPOSE:
; Creates an L2 data structure from l1 data
;INPUT:
; none explicit, all via keyword
;OUTPUT:
; none explicit, all via keyword
;KEYWORDS:
; input keywords:
;       type = the data type, one of ['ees','ies','eeb','ieb']
;       orbit = orbit range
; output keywords:
;       data_struct = the L2 data structure
;   PROJECT_NAME    STRING    'FAST'
;   DATA_NAME       STRING    'Iesa Burst'
;   DATA_LEVEL      STRING    'Level 1'
;   UNITS_NAME      STRING    'Compressed'
;   UNITS_PROCEDURE STRING    'fa_convert_esa_units'
;   VALID           INT       Array[59832]
;   DATA_QUALITY    BYTE      Array[59832]
;   TIME            DOUBLE    Array[59832]
;   END_TIME        DOUBLE    Array[59832]
;   INTEG_T         DOUBLE    Array[59832]
;   DELTA_T         DOUBLE    Array[59832]
;   NBINS           BYTE      Array[59832]
;   NENERGY         BYTE      Array[59832]
;   GEOM_FACTOR     FLOAT     Array[59832]
;   DATA_IND        LONG      Array[59832]
;   GF_IND          INT       Array[59832]
;   BINS_IND        INT       Array[59832]
;   MODE_IND        BYTE      Array[59832]
;   THETA_SHIFT     FLOAT     Array[59832]
;   THETA_MAX       FLOAT     Array[59832]
;   THETA_MIN       FLOAT     Array[59832]
;   BKG             FLOAT     Array[59832]
;   DATA0           BYTE      Array[48, 32, 59832]
;   DATA1           FLOAT     NaN (48, 64, ntimes1) (here single NaN
;means there is no data for this mode)
;   DATA2           FLOAT     NaN (96, 32, ntimes2)
;   ENERGY          FLOAT     Array[96, 32, 2]
;   BINS            BYTE      Array[96, 32]
;   THETA           FLOAT     Array[96, 32, 2]
;   GF              FLOAT     Array[96, 64]
;   DENERGY         FLOAT     Array[96, 32, 2]
;   DTHETA          FLOAT     Array[96, 32, 2]
;   EFF             FLOAT     Array[96, 32, 2]
;   DEAD            FLOAT       1.10000e-07
;   MASS            FLOAT         0.0104389
;   CHARGE          INT              1
;   SC_POT          FLOAT     Array[59832]
;   BKG_ARR         FLOAT     Array[96, 64]
;   HEADER_BYTES    BYTE      Array[44, 59832]
;data, eflux and orbit are filled here, all else is input
;   DATA            BYTE      Array[96, 64, 59832]
;   EFLUX           FLOAT     Array[96, 64, 59832]
;   ORBIT_START     LONG
;   ORBIT_END       LONG
;;
;HISTORY:
; Dillon, 2009
; added eflux variable, 2015-08-21, jmm
; added orbit stat and end tags, 2015-08-24, jmm
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-08-28 13:51:59 -0700 (Fri, 28 Aug 2015) $
; $LastChangedRevision: 18665 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2gen/fa_create_esa_l2.pro $
;-
pro fa_create_esa_l2,type=type, $
                     orbit=orbit, $
                     data_struct=all_dat

  fa_init

  common fa_information,info_struct

;first input the data

;Add an option for times, jmm, 2015-07-21
  If(~keyword_set(orbit)) Then Begin
     dprint, 'No orbit range set, using timerange()'
     tr = timerange()
     orbit = fa_time_to_orbit(tr)
  Endif

  fa_orbitrange,orbit
  fa_load_l1,datatype=type
  get_fa1_common,type,data=all_dat
  ntimes=n_elements(all_dat.time)

;data0,1, and 2 will be the eflux data for each mode, if there is no
;data for a given mode, then there is a single NaN value
  If(n_elements(all_dat.data0) Eq 1 && ~finite(all_dat.data0[0])) Then Begin
     data0 = all_dat.data0
     data0[*] = 0.0
  Endif Else data0 = float(all_dat.data0) 
  If(n_elements(all_dat.data1) Eq 1 && ~finite(all_dat.data1[0])) Then Begin
     data1 = all_dat.data1
     data1[*] = 0.0
  Endif Else data1 = float(all_dat.data1) 
  If(n_elements(all_dat.data2) Eq 1 && ~finite(all_dat.data2[0])) Then Begin
     data2 = all_dat.data2
     data2[*] = 0.0
  Endif Else data2 = float(all_dat.data2) 

  dead=all_dat.dead
  dt_arr=1.

;ccvt is array for converting COMPRESSED to COUNT
  case type of
     'ees': ccvt=info_struct.byteto16_map
     'eeb': ccvt=info_struct.byteto14_map
     'ies': ccvt=info_struct.byteto16_map
     'ieb': ccvt=info_struct.byteto14_map
     else: begin
        dprint,'Error Converting Between Compressed and Counts: Invalid Type'
        return
     end
  endcase

;define eflux, data here
  eflux = fltarr(96, 64, ntimes)
  eflux[*] = 0.0
  data = bytarr(96, 64, ntimes)
  data[*] = 0
  for i=0,ntimes-1 do begin
;Instead of using get_fa1 routines and fa_convert_esa_units.pro, it is
;faster to convert to EFLUX here.
;EFLUX=COUNTS(after dead time correction)/(GEOM_FACTOR*GF*EFF*DT)
;data0 is 48 energiesx32 angles
;data0 is 48 energiesx64 angles
;data0 is 96 energiesx32 angles
     case all_dat.mode_ind[i] of
        0: begin
           data_tmp=ccvt[all_dat.data0[*,*,all_dat.data_ind[i]]]
           gf_tmp=all_dat.geom_factor[i]*all_dat.gf[0:47,0:31,all_dat.gf_ind[i]]*all_dat.eff[0:47,0:31,0]
           dt=all_dat.integ_t[i]
           denom = 1.- dead/dt_arr*data_tmp/dt
           void = where(denom lt .1,count)
           if count gt 0 then begin
              dprint,dlevel=1,min(denom,ind)
              denom = denom>.1 
              dprint,dlevel=1,' Error: convert_peace_units dead time error.'
           endif
           data_tmp=data_tmp/denom
           data_tmp=data_tmp/(gf_tmp*dt)
           eflux[0,0,i]=data_tmp
           data[0,0,i] = all_dat.data0[*,*,all_dat.data_ind[i]]
        end
        1: begin
           data_tmp=ccvt[all_dat.data1[*,*,all_dat.data_ind[i]]]
           gf_tmp=all_dat.geom_factor[i]*all_dat.gf[0:47,0:63,all_dat.gf_ind[i]]*all_dat.eff[0:47,0:63,1]
           dt=all_dat.integ_t[i]
           denom = 1.- dead/dt_arr*data_tmp/dt
           void = where(denom lt .1,count)
           if count gt 0 then begin
              dprint,dlevel=1,min(denom,ind)
              denom = denom>.1 
              dprint, dlevel=1,' Error: convert_peace_units dead time error.'
           endif
           data_tmp=data_tmp/denom
           data_tmp=data_tmp/(gf_tmp*dt)
           eflux[0,0,i]=data_tmp
           data[0,0,i] = all_dat.data1[*,*,all_dat.data_ind[i]]
        end
        2: begin
           data_tmp=ccvt[all_dat.data2[*,*,all_dat.data_ind[i]]]
           gf_tmp=all_dat.geom_factor[i]*all_dat.gf[0:95,0:31,all_dat.gf_ind[i]]*all_dat.eff[0:95,0:31,2]
           dt=all_dat.integ_t[i]
           denom = 1.- dead/dt_arr*data_tmp/dt
           void = where(denom lt .1,count)
           if count gt 0 then begin
              dprint,dlevel=1,min(denom,ind)
              denom = denom>.1 
              dprint,dlevel=1,' Error: convert_peace_units dead time error.'
           endif
           data_tmp=data_tmp/denom
           data_tmp=data_tmp/(gf_tmp*dt)
           eflux[0,0,i]=data_tmp
           data[0,0,i] = all_dat.data2[*,*,all_dat.data_ind[i]]
        end
     endcase
  endfor

  str_element, all_dat, 'eflux', eflux, /add_replace
  str_element, all_dat, 'data', data, /add_replace
  str_element, all_dat, 'orbit_start', min(orbit), /add_replace
  str_element, all_dat, 'orbit_end', max(orbit), /add_replace

  return

end

