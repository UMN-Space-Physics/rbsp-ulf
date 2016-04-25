PRO eva_sitl_restore, auto=auto, dir=dir
  compile_opt idl2

  if keyword_set(auto) then begin
    if n_elements(dir) eq 0 then dir = spd_default_local_data_dir() + 'mms/'
    ;fname = thm_addslash(dir)+'eva-fom-modified.sav'
    fname = 'eva-fom-modified.sav'
  endif else begin
    fname = dialog_pickfile(/READ)
    if strlen(fname) eq 0 then begin
      answer = dialog_message('Cancelled',/center,/info)
      return
    endif
  endelse
  found = file_test(fname)
  if ~found then begin
    answer = dialog_message('File not found!',/center,/error)
    return
  endif
  ;-----------------------------
  restore, fname; save, eva_lim, eva_dl, filename=fname
  ;-----------------------------
  if strmatch(fname,'*eva-fom-modified*') then begin
    fomstr = eva_lim.UNIX_FOMSTR_MOD
  endif else begin
    mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
    fomstr = unix_FOMstr
  endelse
  
  if n_tags(fomstr) eq 0 then begin
    answer = dialog_message('Not a valid FOMstr!',/center,/error)
    return
  endif
  
  ;update 'mms_stlm_fomstr'
  tfom = eva_sitl_tfom(fomstr)
  D = eva_sitl_strct_read(fomstr,tfom[0])
  store_data,'mms_stlm_fomstr',data=D,lim=eva_lim,dl=eva_dl; update the tplot-variable
  eva_sitl_stack
  
  ;update 'mms_stlm_output_fom'
  eva_sitl_strct_yrange,'mms_stlm_output_fom'
  eva_sitl_strct_yrange,'mms_stlm_fomstr'
  
  tplot
  answer = dialog_message('FOMstr successfully restored!',/center,/info)
END
