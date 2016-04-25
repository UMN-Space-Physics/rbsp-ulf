; buffer should contain bytes for a single ccsds packet, header is
; contained in first 3 words (6 bytes)

function spp_swp_ccsds_decom,buffer             

  ;;--------------------------------
  ;; Error Checking
  buffer_length = n_elements(buffer)
  if buffer_length lt 12 then begin
     dprint,'Invalid buffer length: ',buffer_length,dlevel=1
     return, 0
  endif

  header = swap_endian(uint(buffer[0:11],0,6) ,/swap_if_little_endian )
  MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) + $
        ( (header[5] ) mod 4) * 2d^15/150000
  
  utime = spp_spc_met_to_unixtime(MET)
  ccsds = { $
          version_flag: byte(ishft(header[0],-8) ), $
          apid:         header[0] and '7FF'x , $
          seq_group:    ishft(header[1] ,-14) , $
          seq_cntr:     header[1] and '3FFF'x , $
          size:         header[2]   , $
          time:         utime,  $
          MET:          MET,   $
                                ;    time_diff: cmnblk.time - time,
                                ;    $   ; time to get transferred
                                ;    from PFDPU to GSEOS                                                               
          data:  buffer[0:*], $
          gap : 0b }

  
  if MET lt -1e5 then begin
     dprint,dlevel=1,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
     ccsds.time = !values.d_nan
  endif
  
                                ;  dprint,format='(04z," ",)'
  ;if ccsds.size ne (n_elements(ccsds.data))-7 then begin
  ;  dprint,dlevel=3,format='(a," x",z04,i7,i7)','CCSDS size
  ;  error',ccsds.apid,ccsds.size,n_elements(ccsds.data)
  ;endif

  return,ccsds
  
end


