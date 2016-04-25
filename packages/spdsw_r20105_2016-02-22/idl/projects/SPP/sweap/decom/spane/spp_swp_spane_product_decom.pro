; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2016-02-17 11:22:25 -0800 (Wed, 17 Feb 2016) $
; $LastChangedRevision: 20031 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/decom/spane/spp_swp_spane_product_decom.pro $





function spp_swp_spane_product_decom, ccsds, ptp_header=ptp_header, apdat=apdat


  ;;-------------------------------------------
  ;; Parse data
  header    = ccsds.data[0:19]
  data      = ccsds.data[20:*]
  data_size = n_elements(data)
  apid_name = string(format='(z02)',ccsds.data[1])


  ;;---------------------------------------------
  ;; WORD 1 - 00001aaa aaaaaaaa   
  ;; a = APID bits 
  flag = ishft(ccsds.data[0],-3)
  ;apid = 

  ;;-------------------------------------------
  ;; WORD 6 - ssssssss ssssssxx  
  ;; s=MET subseconds, x=Cyclecnt LSBs
  MET = ishft(data[10],8) and ishft(data[11],-2)

  ;;-------------------------------------------
  ;; Use APID to determine packet side
  ;; '60' -> '360'x ...
  pkt_size = [ 16,  512,   16,  512] 
  apid_loc = ['60', '61', '62', '63']
  ns = pkt_size[where(apid_loc eq apid_name)]


  ;;-------------------------------------------
  ;; Check for compression
  compression = (ccsds.data[12] and '20'x) ne 0
  bps = (compression eq 0) * 4
  nbytes = ns * bps

  ;if n_elements(data) ne nbytes then begin
  ;   dprint,dlevel=3, 'Size error ',$
  ;          n_elements(data),ccsds.size,ccsds.apid
  ;   return, 0
  ;endif


  ;;-------------------------------------------
  ;; Decompress if necessary
  if compression then $
     cnts = spp_swp_log_decomp(data[0:ns-1],0) $
  else $
     cnts = swap_endian(ulong(data,0,ns) ,/swap_if_little_endian ) 


  ;; WORD 1 - 00001aaa aaaaaaaa - ApID bits


  ;; WORD 7
  log_flag    = header[12]

  status_flag = header[18]

  f_counter = swap_endian(ulong(data,16,1), /swap_if_little_endian)

  ;;--------------
  ;; Peaks
  peak_bin = header[19]


  case 1 of

     ;;-----------------------------------------
     ;;Product Full Sweep - 16A - '360'x
     ;(apid_name eq '60') and () : begin
     ;   str = { $
     ;         title:'[16A]',$
     ;         time:ccsds.time, $
     ;         seq_cntr:ccsds.seq_cntr,  $
     ;         seq_group: ccsds.seq_group,  $
     ;         ndat: n_elements(cnts), $
     ;         peak_bin: peak_bin, $
     ;         log_flag: log_flag, $
     ;         status_flag: status_flag,$
     ;         f_counter: f_counter,$
     ;         cnts: float(cnts)}
     ;end


     ;;-----------------------------------------
     ;;Product Full Sweep - 08D - '360'x
     (apid_name eq '60') : begin
        str = { $
              time:        ccsds.time, $
              seq_cntr:    ccsds.seq_cntr,  $
              seq_group:   ccsds.seq_group,  $
              ndat:        n_elements(cnts), $
              peak_bin:    peak_bin, $
              log_flag:    log_flag, $
              status_flag: status_flag,$
              f_counter:   f_counter,$
              cnts:        float(cnts)}
     end


     ;;-----------------------------------------
     ;;Product Full Sweep - 32Ex16A - '361'x
     (apid_name eq '61') : begin
        cnts = reform(cnts,16,32)
        str = { $
              time:      ccsds.time, $
              seq_cntr:  ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat:      n_elements(cnts), $
              peak_bin:  peak_bin, $
              log_flag:  log_flag, $
              status_flag: status_flag,$
              f_counter: f_counter,$
              cnts_a00:  float(reform(cnts[ 0,*])), $
              cnts_a01:  float(reform(cnts[ 1,*])), $
              cnts_a02:  float(reform(cnts[ 2,*])), $
              cnts_a03:  float(reform(cnts[ 3,*])), $
              cnts_a04:  float(reform(cnts[ 4,*])), $
              cnts_a05:  float(reform(cnts[ 5,*])), $
              cnts_a06:  float(reform(cnts[ 6,*])), $
              cnts_a07:  float(reform(cnts[ 7,*])), $
              cnts_a08:  float(reform(cnts[ 8,*])), $
              cnts_a09:  float(reform(cnts[ 9,*])), $
              cnts_a10:  float(reform(cnts[10,*])), $
              cnts_a11:  float(reform(cnts[11,*])), $
              cnts_a12:  float(reform(cnts[12,*])), $
              cnts_a13:  float(reform(cnts[13,*])), $
              cnts_a14:  float(reform(cnts[14,*])), $
              cnts_a15:  float(reform(cnts[15,*])), $
              cnts:      float(cnts)}
     end

     ;;-----------------------------------------
     ;;Product Targeted Sweep - 16A - '362'x
     (apid_name eq '62') : begin
        str = { $
              time:      ccsds.time, $
              seq_cntr:  ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat:      n_elements(cnts), $
              peak_bin:  peak_bin, $
              log_flag:  log_flag, $
              status_flag: status_flag,$
              f_counter: f_counter,$
              cnts:      float(cnts[*])}
     end

     ;;-----------------------------------------
     ;;Product Targeted Sweep - 32Ex16A - '363'x
     (apid_name eq '63') : begin
        cnts = reform(cnts,16,32)
        str = { $
              time:ccsds.time, $
              seq_cntr:ccsds.seq_cntr,  $
              seq_group: ccsds.seq_group,  $
              ndat: n_elements(cnts), $
              peak_bin: peak_bin, $
              log_flag: log_flag, $
              status_flag: status_flag,$
              f_counter: f_counter,$
              cnts: float(cnts[*]),$
              cnts_a00:  float(reform(cnts[ 0,*])), $
              cnts_a01:  float(reform(cnts[ 1,*])), $
              cnts_a02:  float(reform(cnts[ 2,*])), $
              cnts_a03:  float(reform(cnts[ 3,*])), $
              cnts_a04:  float(reform(cnts[ 4,*])), $
              cnts_a05:  float(reform(cnts[ 5,*])), $
              cnts_a06:  float(reform(cnts[ 6,*])), $
              cnts_a07:  float(reform(cnts[ 7,*])), $
              cnts_a08:  float(reform(cnts[ 8,*])), $
              cnts_a09:  float(reform(cnts[ 9,*])), $
              cnts_a10:  float(reform(cnts[10,*])), $
              cnts_a11:  float(reform(cnts[11,*])), $
              cnts_a12:  float(reform(cnts[12,*])), $
              cnts_a13:  float(reform(cnts[13,*])), $
              cnts_a14:  float(reform(cnts[14,*])), $
              cnts_a15:  float(reform(cnts[15,*]))}
     end
     else: print, data_size, ' ', apid_name
  endcase


  return, str


end
