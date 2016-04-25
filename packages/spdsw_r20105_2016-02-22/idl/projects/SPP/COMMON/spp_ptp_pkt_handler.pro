
function spp_spc_met_to_unixtime,met
  epoch =  946771200d - 12L*3600   ; long(time_double('2000-1-1/12:00'))  ;Early SWEM definition
  epoch =  1262304000   ; long(time_double('2010-1-1/0:00'))  ; Correct SWEM use
  unixtime =  met +  epoch
  return,unixtime
end



function thermistor_temp,R,parameter=p,b2252=b2252,L1000=L1000
  if not keyword_set(p) then begin
    p = {func:'thermistor_temp',note:'YSI 46006 (H10000)',R0:10000.,  $
      T0:24.988792d, t1:-24.809236d, t2:1.6864476d, t3:-0.12038317d, $
      t4:0.0081576555d, t5:-0.00057545026d ,t6:3.1337558d-005}
    if keyword_set(B2252) then p={func:'thermistor_temp',note:'YSI (B2252)',R0:2252.,  $
      T0:24.990713d, t1:-22.808501d, t2:1.5334736d, t3:-0.10485403d, $
      t4:0.0076653446d, t5:-0.00084656440d ,t6:6.1095571d-005}
    if keyword_set(L1000) then p={func:'thermistor_temp',note:'YSI (L1000)',R0:1000.,  $
      T0:25.00077d, t1:-27.123102d, t2:2.2371834d, t3:-0.20295066d, $
      t4:0.022239779d, t5:-0.0024144851d ,t6:0.00013611146d}
;    if keyword_set(YSI4908) then p = {func:'thermistor_temperature_ysi4908',note:'YSI4908'}
  endif
  if n_params() eq 0 then return,p

  x = alog(R/p.r0)
  T = p.t0 + p.t1*x + p.t2*x^2 + p.t3*x^3 + p.t4*x^4 +p.t5*x^5 +p.t6*x^6
  return,t

end




function spp_sweap_therm_temp,dval,parameter=p
  if not keyword_set (p) then begin
;    p = {func:'mvn_sep_therm_temp2',R1:10000d, xmax:1023d, Rv:1d8, thm:thermistor_temp()}
     p = {func:'spp_sweap_therm_temp',R1:10000d, xmax:1023d, Rv:1d7, thm:'thermistor_resistance_ysi4908'}
  endif

  if n_params() eq 0 then return,p

;print,dval
  x = dval/p.xmax
  rt = p.r1*(x/(1-x*(1+p.R1/p.Rv)))
  tc = thermistor_resistance_ysi4908(rt,/inverse)
 ; print,dval,x,rt,tc
  return,float(tc)
end


;coeff = [0.00E+00,  0.00E+00,  -5.76E-20, 5.01E-15,  -1.68E-10, 2.69E-06,  -2.33E-02, 9.33E+01]





function spp_swp_spanai_rates_decom_50x,ccsds, ptp_header=ptp_header, apdat=apdat 
  b = ccsds.data
  psize = 84
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif
  
  sf0 = ccsds.data[11] and 3
;  print,sf0
;hexprint,ccsds.data[0:29]

  rates = float( reform( spp_sweap_log_decomp( ccsds.data[20:83] , 0 ) ,4,16))
;  rates = float( reform( float( ccsds.data[20:83] ) ,4,16))
  
  time = ccsds.time 
  if 0 then begin               ;     cluge to correct times
     if keyword_set(apdat) && size(/type,*apdat.last_ccsds) eq 8 then begin
        ltime =  (*apdat.last_ccsds).time
        dt = time - ltime
        if dt le 0 then begin
           time += .86/4 - dt
           ccsds.time = time
        endif else rates=rates/2 
     endif
  endif else if 1 then begin
     if sf0 eq 1 then  rates=rates/2
     
  endif
    
  rates_str = { $
    time: time, $
    met: ccsds.met,  $
    seq_cntr: ccsds.seq_cntr, $
    valid_cnts: reform( rates[0,*]) , $
    multi_cnts: reform( rates[1,*]), $
    start_cnts: reform( rates[2,*] ), $
    stop_cnts:  reform( rates[3,*]) }


  return,rates_str
end



function spp_swp_spanai_rates_decom_64x,ccsds, ptp_header=ptp_header, apdat=apdat
  b = ccsds.data
  psize = 105+7
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif
  
  if (ccsds.data[11] and 1) eq 1 then return,0
  
  ;dprint,time_string(ccsds.time)

  sf0 = ccsds.data[11] and 3
  ;  print,sf0
  ;hexprint,ccsds.data[0:29]

  rates = float( reform( spp_sweap_log_decomp( ccsds.data[20:83] , 0 ) ,4,16))
  ;  rates = float( reform( float( ccsds.data[20:83] ) ,4,16))

  time = ccsds.time

  rates2 = float( reform( spp_sweap_log_decomp( ccsds.data[20+16*4:*] , 0 ) ))
  ;  rates = float( reform( float( ccsds.data[20:83] ) ,4,16))

  startbins = [0,0,3,3,6,6, 9, 9,12,12,15,17,19,21,23,25]
  stopbins =  [1,2,4,5,7,8,10,11,13,14,16,18,20,22,24,26]
;dprint,'rates2'
;printdat,rates2

;dprint,rates2

  rates_str = { $
    time: time, $
    met: ccsds.met,  $
    seq_cntr: ccsds.seq_cntr, $
    mode:  b[13] , $
    valid_cnts: reform( rates[0,*]) , $
    multi_cnts: reform( rates[1,*]), $
    start_nostop_cnts: reform( rates[2,*] ), $
    stop_nostart_cnts:  reform( rates[3,*]) , $
    starts_cnts: rates2[startbins] , $
    stops_cnts:  rates2[stopbins] , $   
    gap: 0 }

  return,rates_str
end



function spp_swp_spanai_event_decom,ccsds, ptp_header=ptp_header, apdat=apdat
  b = ccsds.data
  psize = 2048
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  time = ccsds.time
 ; dprint,time_string(time)
  
  wrds = swap_endian(ulong(ccsds.data,20,(2048-20)/4) ,/swap_if_little_endian )
  tf = (wrds and '80000000'x) ne 0
  w_tt = where(tf,n_tt)
  w_dt= where(~tf,n_dt)
  tt =  uint(wrds)   ; and 'ffff'x
  dt = ishft(wrds,-16) and '1fff'x
  tof = wrds and 'fff'x
;  tof = wrds and '7ff'x
;  nonve = (wrds and '800'x) ne 0
  ch  = ishft(wrds and 'ffff'x,-12 )
  
  ttw=tt[w_tt]
  dttw = ttw - shift(ttw,1)
  dttw[0] = ttw[0]
  ttw2= total(/cum,/preserve,ulong(dttw))
  
  tw = replicate(0ul, n_elements(wrds) )
  tw[w_tt] = dttw
  tw = total(/cumulative,/preserve,tw)
  
  tdt = tw[w_dt]

  events = replicate( {time:0d, seq_cntr15:ccsds.seq_cntr and 'f'x,  channel:0b,  TOF:0u, dt:0u } , n_dt )
  events.time = ccsds.time + (tdt-tdt[0])/ 2.^10 * (2d^17/150000d)
  events.channel = ch[w_dt]
  events.tof = tof[w_dt]
  events.dt = dt[w_dt]

  event_str = { $
    time: time, $
    met: ccsds.met,  $
    seq_cntr: ccsds.seq_cntr, $
    n_tt: n_tt,$
    n_dt: n_dt,$
    tt0: uint(wrds[w_tt[0]] and 'ffff'x), $
    wrds: wrds }
    
;  event_times = replicate( { time: 0d,seq_cntr15:ccsds.seq_cntr and 'f'x, valmod: 0u }, n_tt )
;  event_times.time = ccsds.time + (ttw2 - ttw2[0]) / 2.^10
;  event_times.valmod= ttw
  
  return, events
end





function spp_swp_spanai_slow_hkp_decom_version_50x,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping
b = ccsds.data
psize = 68
if n_elements(b) ne psize then begin
  dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
  return,0
endif

sf0 = ccsds.data[11] and 3
if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)

ref = 5. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)

spai = { $
  time: ccsds.time, $
  met: ccsds.met,  $
  delay_time: ptp_header.ptp_time - ccsds.time, $
  seq_cntr: ccsds.seq_cntr, $
  GND0: b[16],  $
  GND1: b[17],  $
  LVPS_TEMP: b[18] * 1.,  $
  Vmon_22VA: b[19] * 0.1118 ,  $
  vmon_1P5V: b[20] * .0068  ,  $
  Imon_3P3VA: b[21] * .0149 ,  $
  vmon_3P3VD: b[22] * .0149 ,  $
  Imon_N12VA: b[23] * .0456 ,  $
  Imon_N5VA: b[24]  * .0251 ,  $
  Imon_P12VA: b[25] * .0449 ,  $
  Imon_P5VA: b[26] * .0252 ,  $
  ANAL_TEMP: b[27] *1.,  $
  IMON_3P3I: b[28] * 1.15,  $
  IMON_1P5I: b[29] * .345,  $
  IMON_P5I: b[30] * 1.955,  $
  IMON_N5I: b[31] * 4.887,  $
  HVMON_ACC:  swap_endian(/swap_if_little_endian,  fix(b,32 ) ) * ref*3750./4095. , $
  HVMON_DEF1: swap_endian(/swap_if_little_endian,  fix(b,34 ) ) * ref*1000./4095., $
  HIMON_ACC: swap_endian(/swap_if_little_endian,  fix(b,36 ) ) * ref/130.*1000./4095. , $
  HVMON_DEF2: swap_endian(/swap_if_little_endian,  fix(b,38 ) ) * ref*1000./4095. , $
  HVMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,40 ) ) * ref*938./4095 , $
  HVMON_SPOIL:swap_endian(/swap_if_little_endian,  fix(b,42 ) ) * ref*80./4./4095. , $
  HIMON_MCP:  swap_endian(/swap_if_little_endian,  fix(b,44 ) ) * ref*20.408/4095 , $
  TDC_TEMP:  swap_endian(/swap_if_little_endian,  fix(b,46 ) ) * 1. , $
  HVMON_RAW: swap_endian(/swap_if_little_endian,  fix(b,48 ) ) *  ref*1250./4095 , $
  FPGA_TEMP: swap_endian(/swap_if_little_endian,  fix(b,50 ) ) * 1. , $
  HIMON_RAW:  swap_endian(/swap_if_little_endian,  fix(b,52 ) ) * ref*25./ 4095. , $
;  spare0
;  spare1
  HVMON_HEM: swap_endian(/swap_if_little_endian,   fix(b,56 ) ) *ref *1000./4095  , $
;  spare2
;  spare3
;  SPAI_0X11
  CMD_ERRS: ishft(b[61],-4), $
  CMD_REC:  swap_endian(/swap_if_little_endian, uint( b,61 ) ) and 'fff'x , $
;  SPAI_0X44
  MAXCNT: swap_endian(/swap_if_little_endian, uint(b, 64 ) ),  $
;  SPAI_00
  ACTSTAT_FLAG: b[67]  , $
  GAP: ccsds.gap }
  
  return,spai

end

function spp_swp_word_decom,buffer,n,signed=signed
   return,   swap_endian(/swap_if_little_endian,  uint(buffer,n) )
end

function spp_swp_int4_decom,buffer,n
   return,   swap_endian(/swap_if_little_endian,  long(buffer,n) )
end

function spp_swp_float_decom,buffer,n
   if n gt n_elements(buffer)-4 then begin
    dprint,'Outside buffer size ',n
    return, -99.
   endif
   return,   swap_endian(/swap_if_little_endian,  float(buffer,n) )
end



function spp_swp_spanai_slow_hkp_decom_version_64x,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

  b = ccsds.data
  psize = 69+7
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  ref = 4. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
n=0

  temp_par= spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095

  spai = { $
    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $
    REVN: b[12],  $
    CMDS_REC: spp_swp_word_decom(b,13),  $
    cmds_unk:  ishft(b[15],4), $
    cmds_err:  b[15] and 'f'x, $
    GND0: b[16],  $
    GND1: b[17],  $
    Vmon_22VA: b[19] * 0.1118 ,  $
    vmon_1P5V: b[20] * .0068  ,  $
    Imon_3P3VA: b[21] * .0149 ,  $
    vmon_3P3VD: b[22] * .0149 ,  $
    Imon_N12VA: b[23] * .0456 ,  $
    Imon_N5VA: b[24]  * .0251 ,  $
    Imon_P12VA: b[25] * .0449 ,  $
    Imon_P5VA: b[26] * .0252 ,  $
    IMON_3P3I: b[28] * 1.15,  $
    IMON_1P5I: b[29] * .345,  $
    IMON_P5I: b[30] * 1.955,  $
    IMON_N5I: b[31] * 4.887,  $
    LVPS_TEMP: func(b[18] * 1., param = temp_par_8bit),  $
    ANAL_TEMP: func(b[27] * 1., param = temp_par_8bit),  $
    TDC_TEMP:  func(spp_swp_word_decom(b,46 )  * 1. ,param = temp_par_12bit) , $
    FPGA_TEMP: func(spp_swp_word_decom(b,50 )  * 1. ,param = temp_par_12bit) , $
    HVMON_ACC:  swap_endian(/swap_if_little_endian,  uint(b,32 ) ) * ref*3750./4095. , $
    HVMON_DEF1: swap_endian(/swap_if_little_endian,  uint(b,34 ) ) * ref*1000./4095., $
    HIMON_ACC: swap_endian(/swap_if_little_endian,  uint(b,36 ) ) * ref/130.*1000./4095. , $
    HVMON_DEF2: swap_endian(/swap_if_little_endian,  uint(b,38 ) ) * ref*1000./4095. , $
    HVMON_MCP:  swap_endian(/swap_if_little_endian,  uint(b,40 ) ) * ref*938./4095 , $
    HVMON_SPOIL:swap_endian(/swap_if_little_endian,  uint(b,42 ) ) * ref*80./4./4095. , $
    HIMON_MCP:  swap_endian(/swap_if_little_endian,  uint(b,44 ) ) * ref*20.408/4095 , $
    HVMON_RAW: swap_endian(/swap_if_little_endian,  uint(b,48 ) ) *  ref*1250./4095 , $
    HIMON_RAW:  swap_endian(/swap_if_little_endian,  uint(b,52 ) ) * ref*25./ 4095. , $
    HVMON_HEM: swap_endian(/swap_if_little_endian,   uint(b,54 ) ) *ref *1000./4095  , $
    DAC_RAW: spp_swp_word_decom(b,56)   , $
    MAXCNT: swap_endian(/swap_if_little_endian, uint(b, 64 ) ),  $
    DAC_MCP: spp_swp_word_decom(b,60), $
    DAC_ACC: spp_swp_word_decom(b,62), $
    HV_STATUS_FLAG: spp_swp_word_decom(b,58), $
    Cycle_cnt: spp_swp_word_decom(b,66), $
    reset_cnt: spp_swp_word_decom(b,68), $
    user2: 0u, $
    ACTSTAT_FLAG: b[72]  , $
    user3: b[73] ,$
    user4: spp_swp_word_decom(b,74) ,$ 
    GAP: ccsds.gap }

  return,spai

end




function spp_swp_spanai_slow_hkp_decom_version_70x,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

  b = ccsds.data
  psize = 85+7
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  ref = 4. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
  n=0

  temp_par= spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095

  spai = { $
    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $
    REVN: b[12],  $
    CMDS_REC: spp_swp_word_decom(b,13),  $
    cmds_unk:  ishft(b[15],4), $
    cmds_err:  b[15] and 'f'x, $
    GND0: b[16],  $
    GND1: b[17],  $
    Vmon_22VA: b[19] * 0.1118 ,  $
    vmon_1P5V: b[20] * .0068  ,  $
    Imon_3P3VA: b[21] * .0149 ,  $
    vmon_3P3VD: b[22] * .0149 ,  $
    Imon_N12VA: b[23] * .0456 ,  $
    Imon_N5VA: b[24]  * .0251 ,  $
    Imon_P12VA: b[25] * .0449 ,  $
    Imon_P5VA: b[26] * .0252 ,  $
    IMON_3P3I: b[28] * 1.15,  $
    IMON_1P5I: b[29] * .345,  $
    IMON_P5I: b[30] * 1.955,  $
    IMON_N5I: b[31] * 4.887,  $
    LVPS_TEMP: func(b[18] * 1., param = temp_par_8bit),  $
    ANAL_TEMP: func(b[27] * 1., param = temp_par_8bit),  $
    TDC_TEMP:  func(spp_swp_word_decom(b,46 )  * 1. ,param = temp_par_12bit) , $
    FPGA_TEMP: func(spp_swp_word_decom(b,50 )  * 1. ,param = temp_par_12bit) , $
    HVMON_ACC:  swap_endian(/swap_if_little_endian,  uint(b,32 ) ) * ref*3750./4095. , $
    HVMON_DEF1: swap_endian(/swap_if_little_endian,  uint(b,34 ) ) * ref*1000./4095., $
    HIMON_ACC: swap_endian(/swap_if_little_endian,  uint(b,36 ) ) * ref/130.*1000./4095. , $
    HVMON_DEF2: swap_endian(/swap_if_little_endian,  uint(b,38 ) ) * ref*1000./4095. , $
    HVMON_MCP:  swap_endian(/swap_if_little_endian,  uint(b,40 ) ) * ref*938./4095 , $
    HVMON_SPOIL:swap_endian(/swap_if_little_endian,  uint(b,42 ) ) * ref*80./4./4095. , $
    HIMON_MCP:  swap_endian(/swap_if_little_endian,  uint(b,44 ) ) * ref*20.408/4095 , $
    HVMON_RAW: swap_endian(/swap_if_little_endian,  uint(b,48 ) ) *  ref*1250./4095 , $
    HIMON_RAW:  swap_endian(/swap_if_little_endian,  uint(b,52 ) ) * ref*25./ 4095. , $
    HVMON_HEM: swap_endian(/swap_if_little_endian,   uint(b,54 ) ) *ref *1000./4095  , $
    DAC_RAW: spp_swp_word_decom(b,56)   , $
    MAXCNT: swap_endian(/swap_if_little_endian, uint(b, 64 ) ),  $
    DAC_MCP: spp_swp_word_decom(b,60), $
    DAC_ACC: spp_swp_word_decom(b,62), $
    HV_STATUS_FLAG: spp_swp_word_decom(b,58), $
    Cycle_cnt: spp_swp_word_decom(b,66), $
    reset_cnt: spp_swp_word_decom(b,68), $
    user2: 0u, $
    ACTSTAT_FLAG: b[72]  , $
    user3: b[73] ,$
    user4: spp_swp_word_decom(b,74) ,$
    GAP: ccsds.gap }

  return,spai

end




function spp_swp_spanai_slow_hkp_decom_version_80x,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

  b = ccsds.data
  psize = 85+7   ; should be 94
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  ref = 4. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
  n=0

  temp_par= spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095

  spai = { $
    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $
    REVN: b[12],  $
    CMDS_REC: spp_swp_word_decom(b,13),  $
    cmds_unk:  ishft(b[15],4), $
    cmds_err:  b[15] and 'f'x, $
    GND0: spp_swp_word_decom(b,16) * 4.252,  $
    GND1: spp_swp_word_decom(b,18) * 4.252,  $
    MON_LVPS_TEMP: func(spp_swp_word_decom(b,20) * 1., param = temp_par_8bit),  $
    mon_22A_V: spp_swp_word_decom(b,22) * 0.0281 ,  $
    mon_1P5D_V: spp_swp_word_decom(b,24) * .0024  ,  $
    mon_3P3A_V: spp_swp_word_decom(b,26) * .0037 ,  $
    mon_3P3D_V: spp_swp_word_decom(b,28) * .0037 ,  $
    mon_N8VA_C:spp_swp_word_decom(b,30) * .0117 ,  $
    mon_N5VA_C: spp_swp_word_decom(b,32)  * .0063 ,  $
    mon_P8VA_C: spp_swp_word_decom(b,34) * .0117 ,  $
    mon_P5A_C: spp_swp_word_decom(b,36) * .0063 ,  $
    MON_ANAL_TEMP: func(spp_swp_word_decom(b,38) * 1., param = temp_par_8bit),  $
    MON_3P3_C: spp_swp_word_decom(b,40) * .572,  $
    MON_1P5_C: spp_swp_word_decom(b,42) * .172,  $
    MON_P5I_c: spp_swp_word_decom(b,44) * 2.434,  $
    MON_N5I_C: spp_swp_word_decom(b,46) * 2.434,  $
    MON_ACC_V: spp_swp_word_decom(b,48)  * 3.6630 , $
    MON_DEF1_V: spp_swp_word_decom(b,50) * .9768, $
    MON_ACC_C: spp_swp_word_decom(b,52)  *.0075, $
    MON_DEF2_V:spp_swp_word_decom(b,54) * .9768, $
    MON_MCP_V:  spp_swp_word_decom(b,56) * .9162, $
    MON_SPOIL_V:spp_swp_word_decom(b,58) *  0.0195  , $
    MON_MCP_C: spp_swp_word_decom(b,60)  * 0.0199  , $
    MON_TDC_TEMP:  func(spp_swp_word_decom(b,62 )  * 1. ,param = temp_par_12bit) , $
    MON_RAW_V: spp_swp_word_decom(b,64)  * 1.2210, $
    MON_FPGA_TEMP: func(spp_swp_word_decom(b,66 )  * 1. ,param = temp_par_12bit) , $
    MON_RAW_C:  spp_swp_word_decom(b,68) * .0244 , $
    MON_HEM_V:  spp_swp_word_decom(b,70)  * .9768, $
    DAC_RAW: spp_swp_word_decom(b,72)   , $
    HV_STATUS_FLAG: spp_swp_word_decom(b,74), $
    DAC_MCP: spp_swp_word_decom(b,76), $
    DAC_ACC: spp_swp_word_decom(b,78), $
    MAXCNT: spp_swp_word_decom(b,80), $
    Cycle_cnt: spp_swp_word_decom(b,82), $
    reset_cnt: spp_swp_word_decom(b,87), $
    user2: 0u, $
    ACTSTAT_FLAG: b[74]  , $
    user3: b[73] ,$
    user4: spp_swp_word_decom(b,74) ,$
    GAP: ccsds.gap }

  return,spai

end




function spp_swp_spanai_slow_hkp_decom_version_81x,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

  b = ccsds.data
  psize = 97+7   ; should be 94
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  ref = 4. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
  n=0

  temp_par= spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095

  spai = { $
    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $
    REVN: b[12],  $
    CMDS_REC: spp_swp_word_decom(b,13),  $
    cmds_unk:  ishft(b[15],4), $
    cmds_err:  b[15] and 'f'x, $
    GND0: spp_swp_word_decom(b,16) * 4.252,  $
    GND1: spp_swp_word_decom(b,18) * 4.252,  $
    MON_LVPS_TEMP: func(spp_swp_word_decom(b,20) * 1., param = temp_par_8bit),  $
    mon_22A_V: spp_swp_word_decom(b,22) * 0.0281 ,  $
    mon_1P5D_V: spp_swp_word_decom(b,24) * .0024  ,  $
    mon_3P3A_V: spp_swp_word_decom(b,26) * .0037 ,  $
    mon_3P3D_V: spp_swp_word_decom(b,28) * .0037 ,  $
    mon_N8VA_C:spp_swp_word_decom(b,30) * .0117 ,  $
    mon_N5VA_C: spp_swp_word_decom(b,32)  * .0063 ,  $
    mon_P8VA_C: spp_swp_word_decom(b,34) * .0117 ,  $
    mon_P5A_C: spp_swp_word_decom(b,36) * .0063 ,  $
    MON_ANAL_TEMP: func(spp_swp_word_decom(b,38) * 1., param = temp_par_8bit),  $
    MON_3P3_C: spp_swp_word_decom(b,40) * .572,  $
    MON_1P5_C: spp_swp_word_decom(b,42) * .172,  $
    MON_P5I_c: spp_swp_word_decom(b,44) * 2.434,  $
    MON_N5I_C: spp_swp_word_decom(b,46) * 2.434,  $
    MON_ACC_V: spp_swp_word_decom(b,48)  * 3.6630 , $
    MON_DEF1_V: spp_swp_word_decom(b,50) * .9768, $
    MON_ACC_C: spp_swp_word_decom(b,52)  *.0075, $
    MON_DEF2_V:spp_swp_word_decom(b,54) * .9768, $
    MON_MCP_V:  spp_swp_word_decom(b,56) * .9162, $
    MON_SPOIL_V:spp_swp_word_decom(b,58) *  0.0195  , $
    MON_MCP_C: spp_swp_word_decom(b,60)  * 0.0199  , $
    MON_TDC_TEMP:  func(spp_swp_word_decom(b,62 )  * 1. ,param = temp_par_12bit) , $
    MON_RAW_V: spp_swp_word_decom(b,64)  * 1.2210, $
    MON_FPGA_TEMP: func(spp_swp_word_decom(b,66 )  * 1. ,param = temp_par_12bit) , $
    MON_RAW_C:  spp_swp_word_decom(b,68) * .0244 , $
    MON_HEM_V:  spp_swp_word_decom(b,70)  * .9768, $
    DAC_RAW: spp_swp_word_decom(b,72)   , $
    HV_STATUS_FLAG: spp_swp_word_decom(b,74), $
    DAC_MCP: spp_swp_word_decom(b,76), $
    DAC_ACC: spp_swp_word_decom(b,78), $
    MAXCNT: spp_swp_word_decom(b,80), $
    Cycle_cnt: spp_swp_word_decom(b,82), $
    reset_cnt: spp_swp_word_decom(b,87), $
    user2: 0u, $
    ACTSTAT_FLAG: b[74]  , $
    user3: b[73] ,$
    user4: spp_swp_word_decom(b,74) ,$
    GAP: ccsds.gap }

  return,spai

end


function spp_swp_spanai_slow_hkp_decom_version_84x,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

  b = ccsds.data
  psize = 97+7   ; should be 94
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  ref = 4. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
  n=0

  temp_par= spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095

  spai = { $
    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $
    REVN: b[12],  $
    CMDS_REC: spp_swp_word_decom(b,13),  $
    cmds_unk:  ishft(b[15],4), $
    cmds_err:  b[15] and 'f'x, $
    GND0: spp_swp_word_decom(b,16) * 4.252,  $
    GND1: spp_swp_word_decom(b,18) * 4.252,  $
    MON_LVPS_TEMP: func(spp_swp_word_decom(b,20) * 1., param = temp_par_8bit),  $
    mon_22A_V: spp_swp_word_decom(b,22) * 0.0281 ,  $
    mon_1P5D_V: spp_swp_word_decom(b,24) * .0024  ,  $
    mon_3P3A_V: spp_swp_word_decom(b,26) * .0037 ,  $
    mon_3P3D_V: spp_swp_word_decom(b,28) * .0037 ,  $
    mon_N8VA_C:spp_swp_word_decom(b,30) * .0117 ,  $
    mon_N5VA_C: spp_swp_word_decom(b,32)  * .0063 ,  $
    mon_P8VA_C: spp_swp_word_decom(b,34) * .0117 ,  $
    mon_P5A_C: spp_swp_word_decom(b,36) * .0063 ,  $
    MON_ANAL_TEMP: func(spp_swp_word_decom(b,38) * 1., param = temp_par_8bit),  $
    MON_3P3_C: spp_swp_word_decom(b,40) * .572,  $
    MON_1P5_C: spp_swp_word_decom(b,42) * .172,  $
    MON_P5I_c: spp_swp_word_decom(b,44) * 2.434,  $
    MON_N5I_C: spp_swp_word_decom(b,46) * 2.434,  $
    MON_ACC_V: spp_swp_word_decom(b,48)  * 3.6630 , $
    MON_DEF1_V: spp_swp_word_decom(b,50) * .9768, $
    MON_ACC_C: spp_swp_word_decom(b,52)  *.0075, $
    MON_DEF2_V:spp_swp_word_decom(b,54) * .9768, $
    MON_MCP_V:  spp_swp_word_decom(b,56) * .9162, $
    MON_SPOIL_V:spp_swp_word_decom(b,58) *  0.0195  , $
    MON_MCP_C: spp_swp_word_decom(b,60)  * 0.0199  , $
    MON_TDC_TEMP:  func(spp_swp_word_decom(b,62 )  * 1. ,param = temp_par_12bit) , $
    MON_RAW_V: spp_swp_word_decom(b,64)  * 1.2210, $
    MON_FPGA_TEMP: func(spp_swp_word_decom(b,66 )  * 1. ,param = temp_par_12bit) , $
    MON_RAW_C:  spp_swp_word_decom(b,68) * .0244 , $
    MON_HEM_V:  spp_swp_word_decom(b,70)  * .9768, $
    DAC_RAW: spp_swp_word_decom(b,72)   , $
    HV_STATUS_FLAG: spp_swp_word_decom(b,74), $
    DAC_MCP: spp_swp_word_decom(b,76), $
    DAC_ACC: spp_swp_word_decom(b,78), $
    MAXCNT: spp_swp_word_decom(b,80), $
    USRVAR: spp_swp_word_decom(b,82), $
    sram_ADDR:  ishft(b[84] and '3f'xUL,16)  + spp_swp_word_decom(b,85), $
    reset_cntr: b[87], $
    chksums: b[88:95] , $
    SLUT_chksum: b[88], $
    FSLUT_chksum: b[89], $
    TSLUT_chksum: b[90], $
    PILUT_chksum: b[91], $
    MLUT_chksum: b[92], $
    MRAN_chksum: b[93], $
    PSUM_chksum: b[94], $
    PADD_chksum: b[95], $
    time_cmds: b[96], $
    peadl_chksum: b[97], $
    PMBINS_chksum: b[98], $
    table_chksum: b[99], $
    cycle_cntr: ishft(spp_swp_word_decom(b,100) ,-5), $
    MRAM_ADDR:  ishft( b[101] and '1f'xul  ,16) + spp_swp_word_decom(b,102), $
    GAP: ccsds.gap }
    
    
    if debug(3) then printdat,spai,/hex

  return,spai

end


function spp_swp_spanai_slow_hkp_decom_version_91x,ccsds , ptp_header=ptp_header, apdat=apdat     ; Slow Housekeeping

  b = ccsds.data
  psize = 117+7   ; should be 94
  if n_elements(b) ne psize then begin
    dprint,dlevel=1, 'Size error ',ccsds.size,ccsds.apid
    return,0
  endif

  sf0 = ccsds.data[11] and 3
  if sf0 ne 0 then dprint, 'Odd time at: ',time_string(ccsds.time)
  ref = 4. ; Volts   (EM is 5 volt reference,  FM will be 4 volt reference)
  n=0

  temp_par= spp_sweap_therm_temp()
  temp_par_8bit = temp_par
  temp_par_8bit.xmax = 255
  temp_par_12bit = temp_par
  temp_par_12bit.xmax = 4095

  spai = { $
    time: ccsds.time, $
    met: ccsds.met,  $
    delay_time: ptp_header.ptp_time - ccsds.time, $
    seq_cntr: ccsds.seq_cntr, $
    REVN: b[12],  $
    CMDS_REC: spp_swp_word_decom(b,13),  $
    cmds_unk:  ishft(b[15],4), $
    cmds_err:  b[15] and 'f'x, $
    GND0: spp_swp_word_decom(b,16) * 4.252,  $
    GND1: spp_swp_word_decom(b,18) * 4.252,  $
    MON_LVPS_TEMP: func(spp_swp_word_decom(b,20) * 1., param = temp_par_8bit),  $
    mon_22A_V: spp_swp_word_decom(b,22) * 0.0281 ,  $
    mon_1P5D_V: spp_swp_word_decom(b,24) * .0024  ,  $
    mon_3P3A_V: spp_swp_word_decom(b,26) * .0037 ,  $
    mon_3P3D_V: spp_swp_word_decom(b,28) * .0037 ,  $
    mon_N8VA_C:spp_swp_word_decom(b,30) * .0117 ,  $
    mon_N5VA_C: spp_swp_word_decom(b,32)  * .0063 ,  $
    mon_P8VA_C: spp_swp_word_decom(b,34) * .0117 ,  $
    mon_P5A_C: spp_swp_word_decom(b,36) * .0063 ,  $
    MON_ANAL_TEMP: func(spp_swp_word_decom(b,38) * 1., param = temp_par_8bit),  $
    MON_3P3_C: spp_swp_word_decom(b,40) * .572,  $
    MON_1P5_C: spp_swp_word_decom(b,42) * .172,  $
    MON_P5I_c: spp_swp_word_decom(b,44) * 2.434,  $
    MON_N5I_C: spp_swp_word_decom(b,46) * 2.434,  $
    MON_ACC_V: spp_swp_word_decom(b,48)  * 3.6630 , $
    MON_DEF1_V: spp_swp_word_decom(b,50) * .9768, $
    MON_ACC_C: spp_swp_word_decom(b,52)  *.0075, $
    MON_DEF2_V:spp_swp_word_decom(b,54) * .9768, $
    MON_MCP_V:  spp_swp_word_decom(b,56) * .9162, $
    MON_SPOIL_V:spp_swp_word_decom(b,58) *  0.0195  , $
    MON_MCP_C: spp_swp_word_decom(b,60)  * 0.0199  , $
    MON_TDC_TEMP:  func(spp_swp_word_decom(b,62 )  * 1. ,param = temp_par_12bit) , $
    MON_RAW_V: spp_swp_word_decom(b,64)  * 1.2210, $
    MON_FPGA_TEMP: func(spp_swp_word_decom(b,66 )  * 1. ,param = temp_par_12bit) , $
    MON_RAW_C:  spp_swp_word_decom(b,68) * .0244 , $
    MON_HEM_V:  spp_swp_word_decom(b,70)  * .9768, $
    DAC_RAW: spp_swp_word_decom(b,72)   , $
    HV_STATUS_FLAG: spp_swp_word_decom(b,74), $
    DAC_MCP: spp_swp_word_decom(b,76), $
    DAC_ACC: spp_swp_word_decom(b,78), $
    MAXCNT: spp_swp_word_decom(b,80), $
    USRVAR: spp_swp_word_decom(b,82), $
    sram_ADDR:  ishft(b[84] and '3f'xUL,16)  + spp_swp_word_decom(b,85), $
    reset_cntr: b[87], $
    chksums: b[88:95] , $
    SLUT_chksum: b[88], $
    FSLUT_chksum: b[89], $
    TSLUT_chksum: b[90], $
    PILUT_chksum: b[91], $
    MLUT_chksum: b[92], $
    MRAN_chksum: b[93], $
    PSUM_chksum: b[94], $
    PADD_chksum: b[95], $
    time_cmds: b[96], $
    peadl_chksum: b[97], $
    PMBINS_chksum: b[98], $
    table_chksum: b[99], $
    cycle_cntr: ishft(spp_swp_word_decom(b,100) ,-5), $
    MRAM_ADDR:  ishft( b[101] and '1f'xul  ,16) + spp_swp_word_decom(b,102), $
    GAP: ccsds.gap }


  if debug(3) then printdat,spai,/hex

  return,spai

end





function spp_log_message_decom,ccsds, ptp_header=ptp_header, apdat=apdat
;  printdat,ccsds
;  time=ccsds.time
;  printdat,ptp_header
;  hexprint,ccsds.data
  time = ptp_header.ptp_time
  msg = string(ccsds.data[10:*])
  dprint,dlevel=3,time_string(time)+  ' "'+msg+'"'
  str={time:time,seq:ccsds.seq_cntr,size:ccsds.size,msg:msg}
  return,str
end


function spp_power_supply_decom,ccsds,ptp_header=ptp_header,apdat=apdat
;  str = create_struct(ptp_header,ccsds)
  str = 0
  ;  dprint,format="('Generic routine for ',Z04)",ccsds.apid
  size = ccsds.size+7
  b = ccsds.data
  if debug(2) then begin
    dprint,dlevel=2,'generic',ccsds.size+7, n_elements(ccsds.data),'  ',time_string(ccsds.time,/local)
    hexprint,ccsds.data
  endif
  case size of
    78: begin                ; Agilent 3 power supply
 ;     hexprint,b
 ;     dprint,spp_swp_float_decom(b,4),spp_swp_float_decom(b,8)
      str= { time: ptp_header.ptp_time, $
             output:  b[29],  $
             P25V: spp_swp_float_decom(b,30), $
             P25I: spp_swp_float_decom(b,34), $
             P25Vlim: spp_swp_float_decom(b,38), $
             P25Ilim: spp_swp_float_decom(b,42), $
             N25V: spp_swp_float_decom(b,46), $
             N25I: spp_swp_float_decom(b,50), $
             N25Vlim: spp_swp_float_decom(b,54), $
             N25Ilim: spp_swp_float_decom(b,58), $
             P6V: spp_swp_float_decom(b,62), $
             P6I: spp_swp_float_decom(b,66), $
             P6Vlim: spp_swp_float_decom(b,70), $
             P6Ilim: spp_swp_float_decom(b,74), $
             gap: 0}
      end
    60:
    else: dprint,'Unknown size',size
  endcase
;  printdat,time_string(ptp_header.ptp_time,/local)
 ; printdat,str
  return,str
end





function spp_generic_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  str = create_struct(ptp_header,ccsds)
  ;  dprint,format="('Generic routine for ',Z04)",ccsds.apid
  if debug(3) then begin
    dprint,dlevel=2,'generic',ccsds.size+7, n_elements(ccsds.data)
    hexprint,ccsds.data
  endif
  return,str
end




function spp_swp_spanai_tof_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  str = create_struct(ptp_header,ccsds)
  ;  dprint,format="('Generic routine for ',Z04)",ccsds.apid
  if debug(3) then begin
    dprint,dlevel=2,'TOF',ccsds.size+7, n_elements(ccsds.data[20:*])
    hexprint,ccsds.data
  endif
  return,str
end



;;------------------------------------------------------------------
;; Added by Roberto Livi (2015-06-09)


function spp_ccsds_decom,buffer             ; buffer should contain bytes for a single ccsds packet, header is contained in first 3 words (6 bytes)
  buffer_length = n_elements(buffer)
  if buffer_length lt 12 then begin
    dprint,'Invalid buffer length: ',buffer_length,dlevel=1
    return, 0
  endif
  header = swap_endian(uint(buffer[0:11],0,6) ,/swap_if_little_endian )
  MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +( (header[5] ) mod 4) * 2d^15/150000 
  
  utime = spp_spc_met_to_unixtime(MET)
  ccsds = { $
    version_flag: byte(ishft(header[0],-8) ), $
    apid: header[0] and '7FF'x , $
    seq_group: ishft(header[1] ,-14) , $
    seq_cntr: header[1] and '3FFF'x , $
    size : header[2]   , $
    time: utime,  $
    MET:  MET,   $
    ;    time_diff: cmnblk.time - time, $   ; time to get transferred from PFDPU to GSEOS
    data:  buffer[0:*], $
    gap : 0b }


  if MET lt 1e5 then begin
    dprint,dlevel=1,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
    ccsds.time = !values.d_nan
  endif
  
  if ccsds.size + 7  ne n_elements(buffer) then begin
    dprint,dlevel=2,dwait=60,'CCSDS packet size mismatch',ccsds.size+7,n_elements(buffer),ccsds.apid
  endif

 ;  dprint,format='(04z," ",)'

;  if ccsds.size ne (n_elements(ccsds.data))-7 then begin
;    dprint,dlevel=3,format='(a," x",z04,i7,i7)','CCSDS size error',ccsds.apid,ccsds.size,n_elements(ccsds.data)
;  endif

  return,ccsds

end






pro spp_apid_data,apid,name=name,clear=clear,reset=reset,save=save,finish=finish,apdata=apdat,tname=tname,tfields=tfields,rt_tags=rt_tags,routine=routine,increment=increment,rt_flag=rt_flag
  common spp_swp_raw_data_block_com, all_apdat
  if keyword_set(reset) then begin
    ptr_free,ptr_extract(all_apdat)
    all_apdat=0
    return
  endif
  
  if ~keyword_set(all_apdat) then begin
    apdat0 = {  apid:-1 ,name:'',counter:0uL,nbytes:0uL, maxsize: 0,  routine:   '',   tname: '',  tfields: '',  rt_flag:0b, rt_tags: '', save:0b, $
;       status_ptr: ptr_new(), $
       last_ccsds: ptr_new(),  dataptr:  ptr_new(),   dataindex: ptr_new() , dlimits:ptr_new() }
    all_apdat = replicate( apdat0,2^11 )
  endif
  if keyword_set(finish) then begin
    for i=0,n_elements(all_apdat)-1 do begin
      ap = all_apdat[i]
      if ptr_valid(ap.dataptr) then append_array,*ap.dataptr,index = *ap.dataindex
      if keyword_set(ap.tfields) then store_data,ap.tname,data= *ap.dataptr,tagnames=ap.tfields
    endfor
  endif

  if n_elements(apid) ne 0 then begin
    apdat = all_apdat[apid]
    if n_elements(name)     ne 0 then apdat.name = name
    if n_elements(routine)  ne 0 then apdat.routine=routine
    if n_elements(rt_flag)  ne 0 then apdat.rt_flag = rt_flag
    if n_elements(tname)    ne 0 then apdat.tname = tname
    if n_elements(tfields)  ne 0 then apdat.tfields = tfields  
    if n_elements(save)     ne 0 then apdat.save   = save  
    if n_elements(rt_tags)  ne 0 then apdat.rt_tags=rt_tags
    if keyword_set(increment) then apdat.counter += 1
    for i=0,n_elements(apdat)-1 do begin
      if apdat[i].apid lt 0 then begin
        if ~ptr_valid(apdat[i].last_ccsds) then apdat[i].last_ccsds = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dataptr)    then apdat[i].dataptr    = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dataindex)  then apdat[i].dataindex  = ptr_new(/allocate_heap)
        if ~ptr_valid(apdat[i].dlimits)    then apdat[i].dlimits    = ptr_new(/allocate_heap)
      endif
    endfor
    apdat.apid = apid
    all_apdat[apid] = apdat    ; put it all back in
  endif  else begin            ; all 
    w= where(all_apdat.apid ge 0,nw)
    if nw ne 0 then begin
      if n_elements(rt_flag) ne 0 then all_apdat[w].rt_flag=rt_flag
      if n_elements(save) ne 0 then all_apdat[w].save=save   
      apdat = all_apdat[w]       
    endif else apdat=0  
  endelse
  
  if keyword_set(clear) and keyword_set(apdat) then begin
    ptrs = ptr_extract(apdat,except=apdat.dlimits)
    for i=0,n_elements(ptrs)-1 do undefine,*ptrs[i]
    all_apdat.counter = 0   ; this is clearing all counters - not just the subset.
  endif
end



pro spp_swp_apid_data_init,save=save

if 0 then begin
  spp_apid_data,'3be'x,routine='spp_swp_spanai_slow_hkp_decom_version_50x',tname='spp_spanai_hkp_',   tfields='*',save=save
  spp_apid_data,'3bb'x,routine='spp_swp_spanai_rates_decom_50x',           tname='spp_spanai_rates_', tfields='*',save=save
  spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',               tname='spp_spanai_events_',tfields='*',save=save
  ;; Livi added manipulator decom
  ;;spp_apid_data,'7c3'x,routine='spp_swp_manip_decom',                      tname='spp_manip_',        tfields='*',save=save
endif
if 0 then  begin
  spp_apid_data,'3be'x,routine='spp_swp_spanai_slow_hkp_decom_version_64x',tname='spp_spanai_hkp_',   tfields='*',save=save
  spp_apid_data,'3bb'x,routine='spp_swp_spanai_rates_decom_64x',           tname='spp_spanai_rates_', tfields='*',save=save
  spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',               tname='spp_spanai_events_',tfields='*',save=save  
  ;; Livi added manipulator decom
  ;;spp_apid_data,'7c3'x,routine='spp_swp_manip_decom',                      tname='spp_manip_',        tfields='*',save=save
endif
if 0 then begin
  spp_apid_data,'3be'x,routine='spp_swp_spanai_slow_hkp_decom_version_70x',tname='spp_spanai_hkp_',tfields='*',save=save
  spp_apid_data,'3bb'x,routine='spp_swp_spanai_rates_decom_64x',tname='spp_spanai_rates_',tfields='*',save=save
  spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',tname='spp_spanai_events_',tfields='*',save=save
endif
if 1 then begin
  
  spp_apid_data,'3be'x,routine='spp_swp_spanai_slow_hkp_decom_version_84x',tname='spp_spanai_hkp_',tfields='*',save=save
  spp_apid_data,'3bb'x,routine='spp_swp_spanai_rates_decom_64x',tname='spp_spanai_rates_',tfields='*',save=save
  spp_apid_data,'3b9'x,routine='spp_swp_spanai_event_decom',tname='spp_spanai_events_',tfields='*',save=save
  spp_apid_data,'3ba'x,routine='spp_swp_spanai_tof_decom',tname='spp_spanai_tof_',tfields='*',save=save

  
  spp_apid_data,'380'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m1_',tfields='*',save=save
;spp_swp_spani_full_p1_m1_init
  spp_apid_data,'381'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m2_',tfields='*',save=save
  spp_apid_data,'382'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m3_',tfields='*',save=save
  spp_apid_data,'383'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p1_m4_',tfields='*',save=save
  spp_apid_data,'384'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m1_',tfields='*',save=save
  spp_apid_data,'385'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m2_',tfields='*',save=save
  spp_apid_data,'386'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m3_',tfields='*',save=save
  spp_apid_data,'387'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p2_m4_',tfields='*',save=save
  spp_apid_data,'388'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m1_',tfields='*',save=save
  spp_apid_data,'389'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m2_',tfields='*',save=save
  spp_apid_data,'38a'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m3_',tfields='*',save=save
  spp_apid_data,'38b'x,routine='spp_swp_spani_product_decom',tname='spp_spani_full_p3_m4_',tfields='*',save=save

  spp_apid_data,'38c'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p1_m1_',tfields='*',save=save
  spp_apid_data,'38d'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p1_m2_',tfields='*',save=save
  spp_apid_data,'38e'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p1_m3_',tfields='*',save=save
  spp_apid_data,'38f'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p1_m4_',tfields='*',save=save
  spp_apid_data,'390'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p2_m1_',tfields='*',save=save
  spp_apid_data,'391'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p2_m2_',tfields='*',save=save
  spp_apid_data,'392'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p2_m3_',tfields='*',save=save
  spp_apid_data,'393'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p2_m4_',tfields='*',save=save
  spp_apid_data,'394'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p3_m1_',tfields='*',save=save
  spp_apid_data,'395'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p3_m2_',tfields='*',save=save
  spp_apid_data,'396'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p3_m3_',tfields='*',save=save
  spp_apid_data,'397'x,routine='spp_swp_spani_product_decom',tname='spp_spani_targ_p3_m4_',tfields='*',save=save
endif
  
;  spp_apid_data,'359'x ,routine='spp_generic_decom',tname='spp_spane_events_',tfields='*', save=save
;  spp_apid_data,'360'x ,routine='spp_generic_decom',tname='spp_spane_events_',tfields='*', save=save


  spp_apid_data,'34f'x,routine='spp_swp_swem_unwrapper',tname='spp_swem_34f_',tfields='*',save=save
  
  spp_apid_data,'7c0'x,routine='spp_log_message_decom',tname='log_',tfields='MSG',save=1,rt_tags='MSG',rt_flag=1
  spp_apid_data,'7c1'x,routine='spp_power_supply_decom',tname='HV_',rt_tags='*_?',rt_flag=1,tfields='*'
  spp_swp_spane_init,save=save
end





pro spp_ccsds_pkt_handler,buffer,ptp_header=ptp_header

  ccsds=spp_ccsds_decom(buffer)
      
  if ~keyword_set(ccsds) then begin
    dprint,dlevel=1,'Invalid CCSDS packet'
    dprint,dlevel=1,time_string(ptp_header.ptp_time)
    return
  endif
  
 ; if n_elements(buffer) ne  ccsds.length+7  then dprint,'size error',ccsds.apid,n_elements(buffer) ,ccsds.length+7
  
  common spp_ccsds_pkt_handler_com2,last_ccsds,last_time,total_bytes,rate_sm
  time = ptp_header.ptp_time
;  time = systime(1)
  if keyword_set(last_time) then begin  
    dt = time - last_time
    len = n_elements(buffer)
    total_bytes += len
    if dt gt .1 then begin
      rate = total_bytes/dt
      store_data,'AVG_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
      total_bytes =0
      last_time = time
    endif    
  endif else begin
    last_time = time
    total_bytes = 0
  endelse
  last_ccsds = ccsds
  
  
  
  if 1 then begin
    spp_apid_data,ccsds.apid,apdata=apdat,/increment
    if (size(/type,*apdat.last_ccsds) eq 8)  then begin    ; look for data gaps
      if 1 then begin
        store_data,'APIDS_ALL',ccsds.time,ccsds.apid,/append,dlimit={psym:3,ynozero:1}
      endif
      dseq = (( ccsds.seq_cntr - (*apdat.last_ccsds).seq_cntr ) and '3fff'x) -1
      if dseq ne 0  then begin
        ccsds.gap = 1
        dprint,dlevel=3,format='("Lost ",i5," ", Z03, " packets")',dseq,apdat.apid
        store_data,'APIDS_GAP',ccsds.time,ccsds.apid,/append,dlimit={psym:4,symsize:.4 ,ynozero:1, colors:'r'}
      endif
    endif
    
    if keyword_set(apdat.routine) then begin
      strct = call_function(apdat.routine,ccsds,ptp_header=ptp_header,apdat=apdat)
      if  apdat.save && keyword_set(strct) then begin
;        if ccsds.gap eq 1 then append_array, *apdat.dataptr, fill_nan(strct), index = *apdat.dataindex
        append_array, *apdat.dataptr, strct, index = *apdat.dataindex
      endif
      if apdat.rt_flag && apdat.rt_tags then begin
;        if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
        store_data,apdat.tname,data=strct, tagnames=apdat.rt_tags, /append
      endif
    endif
    *apdat.last_ccsds = ccsds 
  endif

end


;
;function ptp_pkt_add_header,buffer,time=time,spc_id=spc_id,path=path,source=source
;
;if ~keyword_set(time) then time=systime(1)
;if ~keyword_set(spc_id) then spc_id = 187
;if ~keyword_set(path) then path = 'a200'x
;if ~keyword_set(source) then source = 'a0'x
;size = n_elements(buffer)
;
;st = time_struct(time)
;day1958 = uint(st.daynum -714779)
;msec =  ulong(st.sod * 1000)
;usec = 0U
;
;b_size    = byte( swap_endian(/swap_if_little_endian, uint(size+17)), 0 ,2)
;b_sc_id   = byte( swap_endian(/swap_if_little_endian, uint(spc_id)), 0 ,2)
;b_day1958 = byte( swap_endian(/swap_if_little_endian, uint(day1958)), 0 ,2)
;b_msec    = byte( swap_endian(/swap_if_little_endian, ulong(msec)), 0 ,4)
;b_usec    = byte( swap_endian(/swap_if_little_endian, uint(usec)), 0 ,2)
;b_source  = byte(source)
;b_spare   = byte(0)
;b_path    = byte( swap_endian(/swap_if_little_endian, uint(path)), 0 ,2)
;
;hdr = [b_size, 3b, b_sc_id, b_day1958, b_msec, b_usec, b_source, b_spare, b_path]
;return, size ne 0 ? [hdr,buffer] : hdr
;end
;


  ;+
  ;spp_ptp_pkt_handler
  ; :Description:
  ;    Processes a single PTP packet
  ;
  ; :Params:
  ;    buffer - Array of bytes
  ;
  ; :Keywords:
  ;    time
  ;    size
  ;
  ; :Author: davin  Jan 1, 2015
  ;
  ; $LastChangedBy: $
  ; $LastChangedDate: $
  ; $LastChangedRevision: $
  ; $URL: $
  ;
  ;-
pro spp_ptp_pkt_handler,buffer,time=time,size=ptp_size
  if n_elements(buffer) le 2 then begin
    dprint,'buffer too small!'
    return
  endif
;  printdat,bufferdprint
  ptp_size = swap_endian( uint(buffer,0) ,/swap_if_little_endian)   ; first two bytes provide the size
  if ptp_size ne n_elements(buffer) then begin
    dprint,time_string(time,/local_time),' PTP size error- size is ',ptp_size
;    hexprint,buffer
;    savetomain,buffer,time
;    stop
    return
  endif
  ptp_code = buffer[2]
  if ptp_code eq 0 then begin
    dprint,'End of Transmission Code'
    printdat,buffer
    return
  endif
  if ptp_code eq 'ff'x then begin
    dprint,'PTP Message ',ptp_size
    dprint,string(buffer[3:*])
    return
  endif
  if ptp_code ne 3 then begin
    dprint,'Unknown PTP code: ',ptp_code
    return
  endif
  ga   = buffer[3:16]
  sc_id = swap_endian(/swap_if_little_endian, uint(ga,0))   
  days  = swap_endian(/swap_if_little_endian, uint(ga,2))
  ms    = swap_endian(/swap_if_little_endian, ulong(ga,4))
  us    = swap_endian(/swap_if_little_endian, uint(ga,8))
  source   =    ga[10]
  spare    =    ga[11]
  path  = swap_endian(/swap_if_little_endian, uint(ga,12))
  utime = (days-4383L) * 86400L + ms/1000d 
  if utime lt   1425168000 then utime += us/1d4   ;  correct for error in pre 2015-3-1 files
  if keyword_set(time) then dt = utime-time  else dt = 0
;  dprint,dlevel=4,time_string(utime,prec=3),ptp_size,sc_id,days,ms,us,source,path,dt,format='(a,i6," x",Z04,i6,i9,i6," x",Z02," x",Z04,f10.2)'
  if ptp_size le 17 then begin
    dprint,dlevel=2,'PTP size error - not enough bytes: '+strtrim(ptp_size,2)+ ' '+time_string(utime)
    if debug(3) then hexprint,buffer
    return
  endif
  ptp_header ={ ptp_time:utime, ptp_scid: sc_id, ptp_source:source, ptp_spare:spare, ptp_path:path, ptp_size:ptp_size }
  spp_ccsds_pkt_handler, buffer[17:*],ptp_header = ptp_header
 ; printdat,time_string(ptp_header.ptp_time)
  return
end



