function spp_swp_spani_tof_decom,ccsds,ptp_header=ptp_header,apdat=apdat


  ;; IMPLEMENT DECOMPRESSION

  str = create_struct(ptp_header,ccsds)
                                ;  dprint,format="('Generic routine
                                ;  for
                                ;  ',Z04)",ccsds.apid                                                                                            
  if debug(3) then begin
     dprint,dlevel=2,'TOF',ccsds.size+7, n_elements(ccsds.data[24:*])
     hexprint,ccsds.data
  endif

  return,str

end
