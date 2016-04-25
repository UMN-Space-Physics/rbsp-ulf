function spp_swp_ccsds_header_decom,buffer
  

return, hdr
end




function spp_swp_spani_product_decom,ccsds, ptp_header=ptp_header, apdat=apdat
  b = ccsds.data
;  psize = 269+7
;  if n_elements(b) ne psize then begin
;    dprint,dlevel=1,dwait=30., 'Size error ',string(ccsds.size + 7,ccsds.apid,format='(i4," - ",z03)')
;  endif
  
  time = ccsds.time
  
  apid_name = string(format='(z02)',b[1])

  data_size = n_elements(b) - 20                  ; size of data (20 bytes of header)
 
  cnts =  float( spp_sweap_log_decomp( b[20:*], 0) )
  total_cnts = total(cnts)
  spec1 = cnts
  spec2 = 0
  spec3 = 0
  cnts_full = cnts
  case data_size of 
    4096: begin
      cnts = reform(cnts,8,32,16,/overwrite)
      spec1 = total(total(cnts,3),2)
      spec2 = total(total(cnts,1),2)
      spec3 = total(total(cnts,1),1)
;      printdat,spec1,spec2,spec3
    end
    256: begin
      cnts = reform(cnts,32,8,/overwrite)
      spec1 = total(cnts,2)
      spec2 = total(cnts,1)
    end
    16: begin
      spec1 = cnts
 ;     printdat,cnts
    end
    else: dprint,dlevel=2,dwait=10.,string(ccsds.apid,data_size,format='("Packet 0x",z04, " Unknown size:",i5)')
  endcase
    
  prod_str = { $
    time: time, $
;    name:apid_name, $
;    apid: b[1], $
;    met: ccsds.met,  $
    seq_cntr: ccsds.seq_cntr, $
    mode:  b[13] , $
    cnts1: spec1 , $
    cnts2: spec2 , $
    cnts3: spec3 , $
    cnts_full: cnts_full, $
    cnts_total: total_cnts, $
    gap: 0 }

;printdat,prod_str
  return,prod_str
end


