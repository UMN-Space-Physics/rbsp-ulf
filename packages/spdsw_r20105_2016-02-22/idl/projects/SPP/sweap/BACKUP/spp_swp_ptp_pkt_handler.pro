




pro spp_swp_ptp_stream_read,buffer,info=info  ;,time=time

  bsize= n_elements(buffer) * (size(/n_dimen,buffer) ne 0)
  time = info.time_received

  ;; Handle remainder of buffer from previous call
  if n_elements( *info.exec_proc_ptr ) ne 0 then begin   
     remainder =  *info.exec_proc_ptr
     dprint,dlevel=4,'Using remainder buffer from previous call'
     dprint,dlevel=3,/phelp, remainder
     undefine , *info.exec_proc_ptr
     if bsize gt 0 then  spp_swp_ptp_stream_read, [remainder,buffer],info=info
     return
  endif

  
  ;if debug() then dprint,/phelp,time_string(time),buffer,dlevel=3
  p=0L
  while p lt bsize do begin
     if p gt bsize-3 then begin
        dprint,dlevel=1,'Warning PTP stream size can not be read ',p,bsize
        ptp_size = 17  ; (minimum value possible) Dummy value that will trigger end of buffer                                                          
     endif else  ptp_size = swap_endian( uint(buffer,p) ,/swap_if_little_endian)
     if ptp_size lt 17 then begin
        dprint,dlevel=1,'PTP packet size is too small!'
        dprint,dlevel=1,p,ptp_size,buffer,/phelp
        break
     endif
     if p+ptp_size gt bsize then begin ; Buffer doesn't have complete pkt.                                                                             
        dprint,dlevel=3,'Buffer has incomplete packet. Saving ',n_elements(buffer)-p,' bytes for next call.'
        ;dprint,dlevel=1,p,ptp_size,buffer,/phelp
        *info.exec_proc_ptr = buffer[p:*] ; store remainder of buffer to be used on the next call to this procedure                     
        return
        break
     endif
     spp_swp_ptp_pkt_handler,buffer[p:p+ptp_size-1],time=time
     p += ptp_size
  endwhile
  if p ne bsize then dprint,dlevel=1,'Buffer incomplete',p,ptp_size,bsize
  return
end








pro spp_apid_data,apid,name=name,$
                  clear=clear,$
                  reset=reset,$
                  save=save,$
                  finish=finish,$
                  apdata=apdat,$
                  tname=tname,$
                  tfields=tfields,$
                  rt_tags=rt_tags,$
                  routine=routine,$
                  increment=increment,$
                  rt_flag=rt_flag

  common spp_swp_raw_data_block_com, all_apdat

  if keyword_set(reset) then begin
     ptr_free,ptr_extract(all_apdat)
     all_apdat=0
     return
  endif
  
  if ~keyword_set(all_apdat) then begin
     apdat0 = {  apid:-1 ,name:'',$
                 counter:0uL,$
                 nbytes:0uL, $
                 maxsize: 0,$
                 routine:   '',$
                 tname: '',$
                 tfields: '', $
                 rt_flag:0b,$
                 rt_tags: '',$
                 save:0b, $
                ;status_ptr: ptr_new(), $
                 last_ccsds: ptr_new(),  $
                 dataptr:  ptr_new(),   $
                 dataindex: ptr_new() , $
                 dlimits:ptr_new() }
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
  endif  else begin             ; all 
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
     all_apdat.counter = 0      ; this is clearing all counters - not just the subset.
  endif
end




pro spp_ccsds_pkt_handler,buffer,ptp_header=ptp_header

  ccsds=spp_swp_ccsds_decom(buffer)
  
  if ~keyword_set(ccsds) then begin
     dprint,dlevel=1,'Invalid CCSDS packet'
     dprint,dlevel=1,time_string(ptp_header.ptp_time)
     return
  endif
  
  ;if n_elements(buffer) ne  ccsds.length+7  $
  ;then dprint,'size error',ccsds.apid,n_elements(buffer) ,ccsds.length+7
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
     if (size(/type,*apdat.last_ccsds) eq 8)  then begin ; look for data gaps
        if 1 then begin
           store_data,'APIDS_ALL',ccsds.time,ccsds.apid,/append,dlimit={psym:4,symsize:.2 ,ynozero:1}
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


  ;+
  ;spp_swp_ptp_pkt_handler
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
  ;          updated by Roberto Livi Jan 28 2016
  ;
  ; $LastChangedBy: rlivi2 $
  ; $LastChangedDate: 2016-02-17 13:27:22 -0800 (Wed, 17 Feb 2016) $
  ; $LastChangedRevision: 20036 $
  ; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/BACKUP/spp_swp_ptp_pkt_handler.pro $
  ;
  ;-
pro spp_swp_ptp_pkt_handler,buffer,time=time,size=ptp_size
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



