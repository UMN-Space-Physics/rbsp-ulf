pro mms_load_epd_eis, sc=sc, no_update = no_update, reload = reload

date_strings = mms_convert_timespan_to_date()
start_date = date_strings.start_date
end_date = date_strings.end_date


;on_error, 2
if keyword_set(no_update) and keyword_set(reload) then message, 'ERROR: Keywords /no_update and /reload are ' + $
  'conflicting and should never be used simultaneously.'

level = 'l1b'
mode = 'srvy'

; See if spacecraft id is set
if ~keyword_set(sc) then begin
  print, 'Spacecraft ID not set, defaulting to mms1'
  sc = 'mms1'
endif else begin
  ivalid = intarr(n_elements(sc))
  for j = 0, n_elements(sc)-1 do begin
    sc(j)=strlowcase(sc(j)) ; this turns any data type to a string
    if sc(j) ne 'mms1' and sc(j) ne 'mms2' and sc(j) ne 'mms3' and sc(j) ne 'mms4' then begin
      ivalid(j) = 1
    endif
  endfor
  if min(ivalid) eq 1 then begin
    message,"Invalid spacecraft ids. Using default spacecraft mms1",/continue
    sc='mms1'
  endif else if max(ivalid) eq 1 then begin
    message,"Both valid and invalid entries in spacecraft id array. Neglecting invalid entries...",/continue
    print,"... using entries: ", sc(where(ivalid eq 0))
    sc=sc(where(ivalid eq 0))
  endif
endelse

;fpi_status = intarr(n_elements(sc_id))

for j = 0, n_elements(sc)-1 do begin

  if keyword_set(no_update) then begin
    mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc(j), $
      instrument_id='epd-eis', mode=mode, optional_descriptor='electronenergy', $
      level=level, /no_update
  endif else begin
    if keyword_set(reload) then begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc(j), $
        instrument_id='epd-eis', mode=mode, optional_descriptor='electronenergy',$
        level=level, /reload
    endif else begin
      mms_data_fetch, local_flist, login_flag, download_fail, sc_id=sc(j), $
        instrument_id='epd-eis', mode=mode, optional_descriptor='electronenergy',$
        level=level
    endelse
  endelse

  loc_fail = where(download_fail eq 1, count_fail)

  if count_fail gt 0 then begin
    loc_success = where(download_fail eq 0, count_success)
    print, 'Some of the downloads from the SDC timed out. Try again later if plot is missing data.'
    if count_success gt 0 then begin
      local_flist = local_flist(loc_success)
    endif else if count_success eq 0 then begin
      login_flag = 1
    endif
  endif

  file_flag = 0
  if login_flag eq 1 then begin
    print, 'Unable to locate files on the SDC server, checking local cache...'
    mms_check_local_cache, local_flist, file_flag, $
      mode, 'epd-eis', level, sc(j), optional_descriptor='electronenergy'
  endif

  if login_flag eq 0 or file_flag eq 0 then begin
    ; We can safely verify that there is some data file to open, so lets do it

    if n_elements(local_flist) gt 1 then begin
      files_open = mms_sort_filenames_by_date(local_flist)
    endif else begin
      files_open = local_flist
    endelse
    ; Now we can open the files and create tplot variables
    ; First, we open the initial file

    eis_struct = mms_sitl_open_eis_cdf(files_open(0))
    times = eis_struct.times
    elec_t1 = eis_struct.elec_t1
    elec_t1_name = eis_struct.elec_t1_name
    
    if n_elements(files_open) gt 1 then begin
      for i = 1, n_elements(files_open)-1 do begin
        temp = mms_sitl_open_eis_cdf(files_open(0))
        times = [times, temp_struct.times]
        elec_t1 = [elec_t1, temp_struct.elec_t1]
      endfor
    endif

    store_data, elec_t1_name, data = {x:times, y:elec_t1}
    
  endif else begin
    print, 'No EIS data available locally or at SDC or invalid query!'
  endelse

endfor

end