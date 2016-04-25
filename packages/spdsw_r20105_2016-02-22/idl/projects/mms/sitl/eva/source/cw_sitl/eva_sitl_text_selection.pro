FUNCTION eva_sitl_text_selection, unix_FOMstr, email=email
  
  msg = eva_sitl_buffdistr(/msg)

  msg = [msg,'']      
  vsep = '================================================='
  ;vsep = '---------------------------'
  msg = [msg, vsep,'List of selections',vsep]
  msg = [msg,'START TIME          - END TIME           ,  FOM,  ID,  DISCUSSION']
  
  nmax = unix_FOMstr.NSEGS
  for n=0,nmax-1 do begin; for each segment
    stime = time_string(unix_FOMstr.TIMESTAMPS[unix_FOMstr.START[n]])
    etime = time_string(unix_FOMstr.TIMESTAMPS[unix_FOMstr.STOP[n]]+10.d0)
    str_fom = strtrim(string(unix_FOMstr.FOM[n],format='(F5.1)'),2)
    discussion = unix_FOMstr.DISCUSSION[n]
    srcID   = unix_FOMstr.SOURCEID[n]
    msg = [msg,stime+' - '+etime+', '+str_fom+', '+srcID+', '+discussion]
  endfor
  msg = [msg, ' ']
  return, msg
END
