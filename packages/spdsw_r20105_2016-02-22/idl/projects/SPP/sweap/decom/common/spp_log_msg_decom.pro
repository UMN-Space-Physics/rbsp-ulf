function spp_log_msg_decom,ccsds, ptp_header=ptp_header, apdat=apdat

  ;printdat,ccsds
  ;time=ccsds.time
  ;printdat,ptp_header
  ;hexprint,ccsds.data
  time = ptp_header.ptp_time
  msg = string(ccsds.data[10:*])
  dprint,dlevel=2,time_string(time)+  ' "'+msg+'"'
  str={time:time,seq:ccsds.seq_cntr,size:ccsds.size,msg:msg}
  return,str

end
