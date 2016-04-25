pro spp_ccsds_pkt_handler,buffer,ptp_header=ptp_header

  ccsds=spp_swp_ccsds_decom(buffer)

  if ~keyword_set(ccsds) then begin
     dprint,dlevel=1,'Invalid CCSDS packet'
     dprint,dlevel=1,time_string(ptp_header.ptp_time)
     return
  endif

  ;if n_elements(buffer) ne ccsds.length+7  $
  ;then dprint,'size error',ccsds.apid,n_elements(buffer),ccsds.length+7

  common spp_ccsds_pkt_handler_com2,last_ccsds,last_time,total_bytes,rate_sm
  time = ptp_header.ptp_time
  time = systime(1)
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
     ;; Look for data gaps
     if (size(/type,*apdat.last_ccsds) eq 8)  then begin 
        if 1 then begin
           store_data,'APIDS_ALL',ccsds.time,ccsds.apid,$
                      /append,dlimit={psym:4,symsize:.2 ,ynozero:1}
        endif
        dseq = (( ccsds.seq_cntr - $
                  (*apdat.last_ccsds).seq_cntr ) and '3fff'x) -1
        if dseq ne 0  then begin
           ccsds.gap = 1
           dprint,dlevel=3,format='("Lost ",i5," ", Z03, " packets")',$
                  dseq,apdat.apid
           store_data,'APIDS_GAP',ccsds.time,ccsds.apid,$
                      /append,dlimit={psym:4,symsize:.4 ,ynozero:1, colors:'r'}
        endif
     endif
     if keyword_set(apdat.routine) then begin
        strct = call_function(apdat.routine,ccsds,$
                              ptp_header=ptp_header,apdat=apdat)
        if  apdat.save && keyword_set(strct) then begin
        ;if ccsds.gap eq 1 then append_array, *apdat.dataptr,
        ;fill_nan(strct), index = *apdat.dataindex
           append_array, *apdat.dataptr, strct, index = *apdat.dataindex
        endif
        if apdat.rt_flag && apdat.rt_tags then begin
        ;if ccsds.gap eq 1 then strct = [fill_nan(strct),strct]
           store_data,apdat.tname,data=strct, tagnames=apdat.rt_tags, /append
        endif
     endif
     *apdat.last_ccsds = ccsds
  endif

end
