;+
;NAME: 
;  elf_load_data
;           This routine loads local ELFIN Lomonosov data. 
;           There is no server available yet so all files must
;           be local. The default value is currently set to
;          'C:/data/lomo/elfin/l1/'
;          If you do not want to place your cdf files there you 
;          must change the elfin system variable !elf.local_data_dir = 'yourdirectorypath'
;KEYWORDS (commonly used by other load routines):
;  INSTRUMENT = options are 'fgm', 'epd', 'eng' (This will probably change
;               after launch 
;  DATATYPE = This is not yet implemented and may not be needed
;  LEVEL    = This is not yet implemented but options will  most likely include 
;             levels 1 or 2. For Elfin lomo fgm will be the only instrument
;             that has level 2 data. epd and eng only have level 1. Levels
;             have also not been implemented in the load panel gui. 
;  TRANGE   = (Optional) Time range of interest  (2 element array), if
;             this is not set, the default is to prompt the user. Note
;             that if the input time range is not a full day, a full
;             day's data is loaded
;          
;EXAMPLE:
;   elf_load_data,probe='x'
; 
;NOTES:
;   Elfin lomo has not launched yet so naming conventions and file types
;   and levels will most likely change.
;   Since there is no data server - yet - files must reside locally.
;   Current file naming convention is lomo_APID_APIDNAME_YYMMDD.cdf.
;   It possible the Elfin load data gui will also include other missions
;   and this should be kept in mind as this routine is expanded. 
;     
;--------------------------------------------------------------------------------------
PRO elf_load_data, instrument=instrument, datatype=datatype, level=level, timerange=timerange

  ; this sets the time range for use with the thm_load routines
  timespan, timerange
  existing_tvar = tnames()

  ; set up system variable for MMS if not already set
  defsysv, '!elf', exists=exists
  if not(exists) then elf_init
  
  ts = time_struct(timerange[0])
  yr = strmid(timerange[0],0,4)
  mo = strmid(timerange[0],5,2)
  day = strmid(timerange[0],8,2)

  ; Construct file name
  ; TODO: The elfin lomo files must be located in the local_data_dir. Since the mission is not
  ; in flight yet - there is no server for the data. This will change. Also the file name is 
  ; currently lomo_APID_APIDNAME_YYMMDD.cdf. This will change - in the short term the names
  ; are more or less hard coded. 
  case instrument of 
    'fgm' : fileName = 'lomo_3_PRM_'+yr+mo+day+'.cdf' 
    'epd' : fileName = 'lomo_4_EPD_'+yr+mo+day+'.cdf' 
    'eng' : fileName = 'lomo_2_ENG_'+yr+mo+day+'.cdf'
  end

  fileName = !elf.local_data_dir + fileName

  init_time=systime(/sec)
  cdf2tplot, file=fileName, get_support_data=1

  tplotvars = tnames(create_time=create_times)
  new_vars_ind = where(create_times gt init_time, n_new_vars_ind)

  if n_new_vars_ind gt 0 then begin
     tplot_gui, tplotvars[new_vars_ind], /no_draw, /no_verify
     ; delete any new tplot variables (but not ones that overwrote existing variables)
     if n_elements(existing_tvar) eq 1 then existing_tvar = [existing_tvar]
     if n_elements(tplotvars) eq 1 then tplotvars = [tplotvars]
     tvar_to_delete = ssl_set_complement(existing_tvar, tplotvars)
     store_data, delete=tvar_to_delete
  endif else begin
     statusmsg = 'Unable to load data from file '+fileName+'. File may not conform to SPEDAS standards.'
     result=dialog_message(statusmsg, /info,/center, title='Load SPEDAS CDF')
  endelse

END
