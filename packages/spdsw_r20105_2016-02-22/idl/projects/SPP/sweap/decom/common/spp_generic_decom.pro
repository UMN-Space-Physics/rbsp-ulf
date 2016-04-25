function spp_generic_decom,ccsds,ptp_header=ptp_header,apdat=apdat

  str = create_struct(ptp_header,ccsds)
  ;dprint,format="('Generic routine for',Z04)",ccsds.apid                                                                                              
  if debug(3) then begin
     dprint,dlevel=2,'generic',ccsds.size+7, n_elements(ccsds.data)
     hexprint,ccsds.data
  endif
  ;print, format='(z, a10, i4, a10)',
  ;ccsds.apid, ' has
  ;',n_elements(ccsds.data),
  ;'bytes'                                                               
  return,str

end


