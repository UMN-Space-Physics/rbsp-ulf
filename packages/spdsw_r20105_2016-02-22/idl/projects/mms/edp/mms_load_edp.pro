;+
; PROCEDURE: mms_load_edp
;
; PURPOSE: Fetches desired data from the EDP (Electric field Double Probes) instrument.
;
; INPUT:
; :Keywords:
;    trange       : OPTIONAL - time range of desired data. Ex: ['2015-05-1', '2015-05-02']
;                    Default input is timespan input.
;    probes       : OPTIONAL - desired spacecraft, Ex: '1' for mms1, '2' for mms2, etc.
;                    Default input is all s/c
;    data_rate    : OPTIONAL - desired data sampling mode, DEFAULT: mode='srvy'
;                             due to cataloging at the SDC, WE REQUIRE YOU LOAD ONLY ONE MODE AT A TIME
;                    Default input, all but brst (to avoid destroying your hard drive)
;    level        : OPTIONAL - desired level, options are level 1a, 1b, ql, 2
;                    Default input - all levels
;    datatype    : OPTIONAL - desired data type. Ex: ['dce', 'dcv', 'ace', 'hmfe']
;                    Default input - all data types!
;    no_update    : OPTIONAL - /no_update to ensure your current data is not reloaded due to an update at the SDC
;    reload       : OPTIONAL - /reload to ensure current data is reloaded due to an update at the SDC
;    DO NOT DO BOTH /NO_UPDATE AND /RELOAD TOGETHER. THAT IS SILLY!
;    no_sweeps    : OPTIONAL - /no_sweeps to remove any sweeps done during commissioning.
;                              Hopefully you'll never have to use this outside of commissioning
;    get_support  : OPTIONAL - /get_support to get support data within the CDF
;                               Automatically called when /no_sweeps is called
;    suffix       : OPTIONAL - appended to end of tplot  variable
;
; EXAMPLE:
;
;    set the time frame
;    MMS1> timespan, '2015-08-15', 1, /day
;    load quicklook edp dce data for all probes
;    MMS1> mms_load_edp, data_rate='slow', probes=[1, 2, 3, 4], datatype='dce', level='ql'
;
; OUTPUT: tplot variables listed at the end of the procedure
; :Author: Katherine Goodrich, contact: katherine.goodrich@colorado.edu
;-
;
; MODIFICATION HISTORY:
;
;
;  $LastChangedBy: egrimes $
;  $LastChangedDate: 2015-12-10 14:14:24 -0800 (Thu, 10 Dec 2015) $
;  $LastChangedRevision: 19585 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/edp/mms_load_edp.pro $


pro mms_load_edp, trange=trange, $
  probes=probes, $
  data_rate=data_rate, $
  level=level, $
  datatype=datatype, $
  no_update=no_update, $
  reload=reload, $
  no_sweeps=no_sweeps, $
  get_support=get_support, $
  suffix = suffix

  if not keyword_set(probes) then sc = ['mms1', 'mms2', 'mms3', 'mms4'] else sc = 'mms' + strcompress(string(probes),/rem)

  if not keyword_set(suffix) then suffix=''

;  status = mms_login_lasp(login_info = login_info)
;  if status ne 1 then return

  ;ESTABLISH TIME RANGE
  ;for now this only works in date time ranges, will work on it
  instrument_id = 'edp'
  if not keyword_set(trange) then begin
    t = timerange(/current)
    st = time_string(t)
    datestrings=mms_convert_timespan_to_date()
    start_date = datestrings.start_date
    end_date = datestrings.end_date
  endif else begin
    t0 = time_double(trange[0])
    t1 = time_double(trange[1])
    t = [t0, t1]
    start_date = strmid(trange[0],0,10) + '-00-00-00'
    end_date = strmatch(strmid(trange[1],11,8),'00:00:00')?strmid(time_string(t[1]-10.d0),0,10):strmid(trange[1],0,10)
    end_date = end_date + '-23-59-59'
  endelse

  ; SET DEFAULT SETTINGS
  if not keyword_set(end_date) then end_date = start_date ; assumes 1 day time range if no end date is set
  ;if not keyword_set(sc) then sc = ['mms1', 'mms2', 'mms3', 'mms4'] ; ALL THE SATELLITES!!
  if not keyword_set(level) then level = ['l1a', 'l1b', 'l2', 'ql', 'sitl']; all levels
 ; if not keyword_set(mode) then mode = 'srvy' ; excludes burst data
  if not keyword_set(data_rate) then mode = 'fast' else mode = data_rate

  if n_elements(mode) gt 1 then begin
    dprint, 'Cannot select more than one mode at a time.'
    print, 'Please confine your query to one mode (Ex: mode="srvy")'
    print, 'Exiting, MMS_LOAD_EDP, no tplot variables loaded'
    return
  endif
  if keyword_set(no_update) and keyword_set(reload) then begin
    dprint,'Keywords NO_UPDATE and RELOAD are incompatible and cannot be called at once'
    print, 'you silly person'
    print, 'Exiting, MMS_LOAD_EDP, no tplot variables loaded'
    return
  endif

  if size(sc,/type) ne 7 then sc = strtrim(string(sc),1)
  sc_len = strlen(sc)
  if sc_len[0] eq 1 then sc = 'mms'+sc
  sc_len = strlen(sc)
  if sc_len[0] ne 4 or total(strmatch(['mms1', 'mms2', 'mms3', 'mms4'],sc[0])) eq 0 then begin
    dprint, 'MMS_LOAD_EDP: INVALID SC ENTRY. VALID INPUTS EITHER "MMS#" OR "#"'
    print, 'Exiting, MMS_LOAD_EDP, no tplot variables loaded'
    return
  endif
 ; names = []
  sc_id = sc

  ;FETCH THE DATA!!!!!!!
  mms_data_fetch, flist, login_flag, dwnld_flag ,sc_id = sc_id, instrument_id=instrument_id, $
    mode=mode, level=level, $
    optional_descriptor=datatype, reload=reload

  if strlen(flist[0]) eq 0 or login_flag eq 1 then begin
    mms_check_local_cache_multi, flist, file_flag, $
      sc_id = sc_id, level=level, $
      mode=mode, instrument_id=instrument_id, $
      optional_descriptor=datatype
  endif

  ;Exits if it can't find any files matching your criteria
  if strlen(flist[0]) eq 0 then begin
    dprint, 'MMS_LOAD_EDP: COULD NOT LOCATE ANY CDF FILES MATCHING CRITERIA'
    print, 'TIME RANGE = ', st
    print, 'SC = ', sc
    print, 'DATA_TYPE = ', datatype
    print, 'LEVEL = ', level
    print, 'MODE = ', mode
    print, 'PLEASE ALTER SEARCH'
    print, 'NO EDP tplot variables loaded'
    return
  endif


  ;Make sure you don't include files exceeding the end time
  flist = mms_sort_filenames_by_date(flist)
  mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
    descriptors, version_strings, start_strings, years, /contains_dir
  end_string = start_strings[n_elements(start_strings)-1]
  end_year = strmid(end_string, 0, 4)
  end_month = strmid(end_string, 4, 2)
  end_day = strmid(end_string, 6, 2)
  end_hour = strmid(end_string, 8, 2)
  end_min = strmid(end_string, 10, 2)
  end_sec = strmid(end_string, 12, 2)
  end_string = end_year+'-'+end_month+'-'+end_day+'/'+end_hour+':'+end_min+':'+end_sec
  t1 = time_double(end_string)
  ;end_string = start_strings[-1]
  end_string = start_strings[n_elements(start_strings)-1]
  if t1 ge t[1] then begin
    ind = where(start_strings ne end_string)
    flist = flist[ind]
  endif


  ;Now begins the sorting!
  ;MMS_DATA_FETCH doesn't put everything in order, which can muck things up later, so it's important to sort all the file names accordingly.
  ;The following code sorts the data in the following order
  ; S/C:
  ;   Mode:
  ;     Level:
  ;       Data Type:
  ;         Date

  nf = n_elements(flist)
  mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
    descriptors, version_strings, start_strings, years, /contains_dir
  ;  ind = sort(descriptors)
  ;  flist = flist[ind]
  ind = sort(modes)
  mds = modes[ind]
  mds = mds[uniq(modes)]
  nm = n_elements(mds)

  ind = sort(levels)
  lvls = levels[ind]
  lvls = lvls[uniq(lvls)]
  nl = n_elements(lvls)

  ind = sort(descriptors)
  dtypes = descriptors[ind]
  dtypes = dtypes[uniq(dtypes)]
  nd = n_elements(dtypes)

  if keyword_set(get_support) then var_type = ['data', 'support_data'] else var_type = 'data'
  if keyword_set(no_sweeps) then var_type = ['data', 'support_data']

  for obs = 0, n_elements(sc)-1 do begin ;S/C or Observatory
    mms_parse_file_name, flist, sc_ids, inst_ids, modes, levels, $
      descriptors, version_strings, start_strings, years, /contains_dir
    ind = where(sc_ids eq sc[obs])
    fles = flist[ind]
    for m=0,nm-1 do begin ; Mode
      mms_parse_file_name, fles, sc_ids, inst_ids, modes, levels, $
        descriptors, version_strings, start_strings, years, /contains_dir
      ind = where(modes eq mds[m])
      fles1 = fles[ind]
      for l=0, nl-1 do begin ; Level
        mms_parse_file_name, fles1, sc_ids, inst_ids, modes, levels, $
          descriptors, version_strings, start_strings, years, /contains_dir
        ind = where(levels eq lvls[l])
        fles2 = fles1[ind]
        for d=0, nd-1 do begin ; Data Type
          mms_parse_file_name, fles2, sc_ids, inst_ids, modes, levels, $
            descriptors, version_strings, start_strings, years, /contains_dir
          ind = where(descriptors eq dtypes[d])
          fles3 = fles2[ind]
          fles4 = mms_sort_filenames_by_date(fles3) ; Date, already done for you!
          ;   for f=0, nf-1 do begin
          cdfi = cdf_load_vars(fles4, var_type=var_type,varnames=varnames)

          if keyword_set(no_sweeps) then cdfi = mms_eliminate_sweeps(cdfi) ; <- need to rename this
          flename = cdfi.filename[0]
          mms_parse_file_name, flename, sc_str, inst_str, mode_str, level_str, $
            dat_str, version_string, start_string, year_str, /contains_dir
          cdf_info_to_tplot, cdfi, varnames

          ;Include mode string in tplot name
          ;dat_names = []
          id = cdf_open(flename)
          for v=0, n_elements(varnames)-1 do begin
            cdf_attget, id, 'VAR_TYPE', varnames[v], vtyp, /zvar
            strs = strsplit(varnames[v], '_', /extract)
           ; if vtyp eq 'data' then dat_names = [dat_names, varnames[v]]
           if vtyp eq 'data' then append_array, dat_names, varnames[v]
          endfor
          cdf_close, id
         
         ;Assign appropriate tplot names 
         ;format: obs_inst_mode_datatype_coord
         ;unless it's sweeps, then all bets are off
         ;This stuff is pretty gross, I know, I'll try to clean it up sometime
          for v=0, n_elements(dat_names) -1 do begin
 ;           newname = dat_names[v]
            get_data, dat_names[v], data=data, dlim=dlim
            strs = strsplit(dat_names[v], '_', /extract)
            ns = n_elements(strs)
            if ns gt 2 then dats = strs[2] else dats = ''
            if ns gt 3 then coord = '_'+strs[-1] else coord = ''
            if ns eq 6 then coord = coord + '_res'
            dlen = strlen(dat_str)
            if mode_str eq 'comm' then begin
              sl = strlen(dat_str)
              dat_str1 = strmid(dat_str, 0, 3)
              dat_str2 = strmid(dat_str, 3, sl - 3)
              if dat_str eq 'sweeps' then begin
                newname = dat_names[v]
              endif
              if dat_str1 eq 'dce' or dat_str1 eq 'dcv' then begin
                if dat_str2 eq 'comm' then newname = sc_str + '_'+inst_str+'_'+mode_str+'_'+dats+coord $
                  else newname = sc_str + '_'+inst_str+'_'+mode_str+'_'+dats+dat_str2+coord
              endif else begin
                newname = sc_str+'_'+inst_str+'_'+mode_str + '_' + dats +coord
              endelse
            endif else begin
              if dat_str eq 'sweeps' then begin
                newname = dat_names[v]
              endif else begin
                newname = sc_str+'_'+inst_str+'_'+mode_str + '_' + dats+coord
              endelse
            endelse

;            newname = strjoin(strs, '_')
            newname = newname[0] ; <- this is stupid
            store_data,newname+suffix, data=data, dlim=dlim
            ;            stop
            if newname+suffix ne dat_names[v] then del_data, dat_names[v]
            ;names = [names, newname]
            append_array, names, newname+suffix

          endfor
          undefine, dat_names
        endfor
      endfor
    endfor
  endfor
  PRINT, 'LOADED THE FOLLOWING VARIABLES:'
  tplot_names, names, /sort

  ;YAY we're done!
end
