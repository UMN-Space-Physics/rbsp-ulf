function spp_power_supply_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  ;str = create_struct(ptp_header,ccsds)
  str = 0
  ;dprint,format="('Generic routine for',Z04)",ccsds.apid
  size = ccsds.size+7
  b = ccsds.data[12:*]
  if debug(3) then begin
     dprint,dlevel=2,'generic',ccsds.size+7, n_elements(ccsds.data),'  ',time_string(ccsds.time,/local)
     hexprint,ccsds.data
  endif
  case size of
     22: begin
        b = [ b , byte( ['80'x,'00'x] ) ] ;; correct error of truncation of data array
        ;hexprint,b
        ;dprint,spp_swp_float_decom(b,4),spp_swp_float_decom(b,8)
        str= { time: ptp_header.ptp_time, $
               gun_v: spp_swp_float_decom(b,4), $
               gun_i: spp_swp_float_decom(b,8), $
               gap: 0}
     end
     60:
     else: dprint,'Unknown size'
  endcase
  ;printdat,time_string(ptp_header.ptp_time,/local)
  ;printdat,str
  return,str
end

