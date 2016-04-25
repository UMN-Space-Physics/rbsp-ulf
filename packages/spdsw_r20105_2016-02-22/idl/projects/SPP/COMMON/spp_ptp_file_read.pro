
pro spp_ptp_file_read,files
  
  t0 = systime(1)
  spp_apid_data,/clear,rt_flag=0

  for i=0,n_elements(files)-1 do begin
    file = files[i]
    file_open,'r',file,unit=lun,dlevel=4
    sizebuf = bytarr(2)
    fi = file_info(file)
    dprint,dlevel=1,'Reading file: '+file+' LUN:'+strtrim(lun,2)+'   Size: '+strtrim(fi.size,2)
    while ~eof(lun) do begin
      point_lun,-lun,fp
      readu,lun,sizebuf
;      point_lun,lun,fp
      sz = sizebuf[0]*256 + sizebuf[1]
      if sz lt 17 then begin
        dprint,format="('Bad PTP packet size',i,' in file: ',a,' at file position: ',i)",sz,file,fp
        break
      endif
      buffer = bytarr(sz-2)
      readu,lun,buffer
      spp_ptp_pkt_handler,[sizebuf,buffer]   ;,time=systime(1)   ;,size=ptp_size
    endwhile
    free_lun,lun
  endfor
  dt = systime(1)-t0
  dprint,format='("Finished loading in ",f0.1," seconds")',dt
  spp_apid_data,/finish,rt_flag=1
end


