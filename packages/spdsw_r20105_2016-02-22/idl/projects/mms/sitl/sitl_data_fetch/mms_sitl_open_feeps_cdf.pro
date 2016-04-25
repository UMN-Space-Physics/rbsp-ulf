function mms_sitl_open_feeps_cdf, filename

  ;var_type = ['data']
  CDF_str = cdf_load_vars(filename, varformat=varformat, /all, $
    spdf_depend=0, varnames=varnames2, verbose=verbose, record=record, $
    convert_int1_to_int2=convert_int1_to_int2)

  ; Find out what variables are in here

  for i = 0, n_elements(cdf_str.vars.name)-1 do begin
    print, i, '  ', cdf_str.vars(i).name
  endfor

  time_tt2000 = *cdf_str.vars(0).dataptr
  time_unix = time_double(time_tt2000, /tt2000)

  elec_t1 = *cdf_str.vars(47).dataptr
  
  elec_t1_name = cdf_str.vars(47).name

  elec_t1_chans = *cdf_str.vars(47).dataptr

  outstruct = {times: time_unix, $
               elec_t1: elec_t1, $
               elec_t1_chans: elec_t1_chans, $
               elec_t1_name: elec_t1_name}
               
  return, outstruct

end