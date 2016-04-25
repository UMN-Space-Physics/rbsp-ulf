; docformat = 'rst'
;
; NAME:
;    unh_load_edi_amb
;
; PURPOSE:
;+
;   Fetch EDI Ambient mode SITL products from the SDC for display using tplot.
;   The routine creates tplot variables based on the names in the mms CDF files.
;   Data files are cached locally in !mms.local_data_dir.
;
; :Categories:
;    MMS, EDI, SITL, QL
;
; :Author:
;    Matthew Argall::
;    University of New Hampshire
;    Morse Hall Room 348
;    8 College Road
;    Durham, NH 03824
;    matthew.argall@unh.edu
;
; :History:
;    Modification History::
;       2015/07/20  -   Written by Matthew Argall
;       2015/09/06  -   Incorporated cdf reader. Read pitch angle info. - MRA
;       2015/10/09  -   Skip and inform of files that have no data. Added LEVEL and
;                           MODE keywords. - MRA
;-
;*****************************************************************************************
;+
;   Open an EDI ambient mode data file and return data in the form of a structure.
;
; :Keywords:
;        FILENAME:     in, required, type=string
;                      CDF filename from which variable data is to be loaded.
;        DATA_STRUCT:  in, optional, type=struct
;                      If data is to be read from multiple files, iteratively pass
;                          in the output of previous calls to append new and old data
;                          together.
;        MODE:         in, required, type=string
;                      Telementry mode of the file: 'slow', 'fast', 'srvy', 'brst'
;
; :Returns:
;        DATA_STRUCT:  A data structure with pitch angle and count data. Can be passed
;                         in via the `DATA_STRUCT` parameter on successive calls.
;
;-
function mms_load_edi_amb_cdf, filename, data_struct, mode
	compile_opt idl2
	on_error, 2
	
	;Read the data file
	cdf_struct = cdf_load_vars(filename, /SPDF_DEPENDENCIES, $
	                           VAR_TYPE = ['data', 'support_data'], $
	                           VARNAMES = varnames)

	;Make sure there are records in the file
	if cdf_struct.vars[0].numrec eq 0 then begin
		message, 'No records in file "' + filename + '".', /INFORMATIONAL
		return, data_struct
	endif

	;Create the initial structure
	if n_elements(data_struct) eq 0 then begin
		;BURST data
		if mode[0] eq 'brst' then begin
			data_struct = create_struct( cdf_struct.vars[0].name,   time_double(*cdf_struct.vars[0].dataptr, /TT2000), $ ;Epoch
			                             cdf_struct.vars[4].name,  *cdf_struct.vars[4].dataptr, $    ;gdu1_raw_counts1
			                             cdf_struct.vars[5].name,  *cdf_struct.vars[5].dataptr, $    ;gdu2_raw_counts1
			                             cdf_struct.vars[6].name,  *cdf_struct.vars[6].dataptr, $    ;gdu1_raw_counts2
			                             cdf_struct.vars[7].name,  *cdf_struct.vars[7].dataptr, $    ;gdu2_raw_counts2
			                             cdf_struct.vars[8].name,  *cdf_struct.vars[8].dataptr, $    ;gdu1_raw_counts3
			                             cdf_struct.vars[9].name,  *cdf_struct.vars[9].dataptr, $    ;gdu2_raw_counts3
			                             cdf_struct.vars[10].name, *cdf_struct.vars[10].dataptr, $   ;gdu1_raw_counts4
			                             cdf_struct.vars[11].name, *cdf_struct.vars[11].dataptr, $   ;gdu2_raw_counts4
;			                             cdf_struct.vars[1].name,   time_double(*cdf_struct.vars[1].dataptr, /TT2000), $ ;epoch_angle
			                             cdf_struct.vars[14].name, *cdf_struct.vars[14].dataptr, $   ;pitch_gdu1
			                             cdf_struct.vars[15].name, *cdf_struct.vars[15].dataptr  $   ;pitch_gdu2
			                           )
		;SLOW, FAST, SRVY data
		endif else begin
			data_struct = create_struct( cdf_struct.vars[0].name,  time_double(*cdf_struct.vars[0].dataptr, /TT2000), $ ;Epoch
			                             cdf_struct.vars[4].name, *cdf_struct.vars[4].dataptr, $   ;gdu1_raw_counts1
			                             cdf_struct.vars[5].name, *cdf_struct.vars[5].dataptr, $   ;gdu1_raw_counts1
			                             cdf_struct.vars[1].name,  time_double(*cdf_struct.vars[1].dataptr, /TT2000), $ ;epoch_angle
			                             cdf_struct.vars[8].name, *cdf_struct.vars[8].dataptr, $   ;pitch_gdu1
			                             cdf_struct.vars[9].name, *cdf_struct.vars[9].dataptr  $   ;pitch_gdu2
			                           )
		endelse
	
	;Append data to an existing structure
	endif else begin
		if mode[0] eq 'brst' then begin
			data_struct = create_struct( cdf_struct.vars[0].name,  [data_struct.(0),   time_double(*cdf_struct.vars[0].dataptr, /TT2000)], $
			                             cdf_struct.vars[4].name,  [data_struct.(1),  *cdf_struct.vars[4].dataptr],                        $
			                             cdf_struct.vars[5].name,  [data_struct.(2),  *cdf_struct.vars[5].dataptr],                        $
			                             cdf_struct.vars[6].name,  [data_struct.(3),  *cdf_struct.vars[6].dataptr],                        $
			                             cdf_struct.vars[7].name,  [data_struct.(4),  *cdf_struct.vars[7].dataptr],                        $
			                             cdf_struct.vars[8].name,  [data_struct.(5),  *cdf_struct.vars[8].dataptr],                        $
			                             cdf_struct.vars[9].name,  [data_struct.(6),  *cdf_struct.vars[9].dataptr],                        $
			                             cdf_struct.vars[10].name, [data_struct.(7),  *cdf_struct.vars[10].dataptr],                       $
			                             cdf_struct.vars[11].name, [data_struct.(8),  *cdf_struct.vars[11].dataptr],                       $
;			                             cdf_struct.vars[1].name,  [data_struct.(9),   time_double(*cdf_struct.vars[1].dataptr, /TT2000)], $
			                             cdf_struct.vars[14].name, [data_struct.(9),  *cdf_struct.vars[14].dataptr],                       $
			                             cdf_struct.vars[15].name, [data_struct.(10), *cdf_struct.vars[15].dataptr]                        $
			                           )
		endif else begin
			data_struct = create_struct( cdf_struct.vars[0].name, [data_struct.(0),  time_double(*cdf_struct.vars[0].dataptr, /TT2000)], $
			                             cdf_struct.vars[4].name, [data_struct.(1), *cdf_struct.vars[4].dataptr],                        $
			                             cdf_struct.vars[5].name, [data_struct.(2), *cdf_struct.vars[5].dataptr],                        $
			                             cdf_struct.vars[1].name, [data_struct.(3),  time_double(*cdf_struct.vars[1].dataptr, /TT2000)], $
			                             cdf_struct.vars[8].name, [data_struct.(4), *cdf_struct.vars[8].dataptr],                        $
			                             cdf_struct.vars[9].name, [data_struct.(5), *cdf_struct.vars[9].dataptr]                         $
			                           )
		endelse
	endelse

	;Build a structure
	return, data_struct
end


;+
;   Fetch EDI Ambient mode SITL products from the SDC for display using tplot.
;   The routine creates tplot variables based on the names in the mms CDF files.
;   Data files are cached locally in !mms.local_data_dir.
;
; :Keywords:
;        LEVEL:        in, optional, type=string, default='l1a'
;                      Level of data product. Current choices are: ['l1a']
;        MODE:         in, optional, type=string, default=['fast', 'slow']
;                      Telemetry mode of data. Options are: 'slow', 'fast', 'srvy', 'brst'
;                          or ['fast', 'slow']. The last option reads in fast and slow
;                          survey data and combines them to resemble "srvy" data.
;        NO_UPDATE:    in, optional, type=boolean, default=0
;                      Set if you don't wish to replace earlier file versions
;                        with the latest version. If not set, earlier versions are deleted
;                        and replaced.
;        RELOAD:       in, optional, type=boolean, default=0
;                      Set if you wish to download all files in query, regardless
;                        of whether file exists locally. Useful if obtaining recent data files
;                        that may not have been full when you last cached them. Cannot
;                        be used with `NO_UPDATE`.
;        SC:           in, optional, type=string/strarr, default='mms1'
;                      Array of strings containing spacecraft ids.
;-
pro mms_sitl_get_edi_amb, $
LEVEL     = level, $
MODE      = mode, $
NO_UPDATE = no_update, $
RELOAD    = reload, $
SC_ID     = sc_id, $
TRANGE    = trange
	compile_opt idl2

;------------------------------------
; Input Verification \\\\\\\\\\\\\\\\
;------------------------------------
	;Constants
	instr   = 'edi'
	optdesc = 'amb'

	;Default Values
	if undefined(level) then level = 'l1a'
	if undefined(mode)  then mode  = ['slow', 'fast']
	if undefined(sc_id) then sc_id = 'mms1'
	if undefined(trange) || n_elements(trange) ne 2 $
		then tr = timerange() $
		else tr = timerange(trange)

	;Check SC_ID
	sc_match = (sc_id eq 'mms1') and (sc_id eq 'mms2') and (sc_id eq 'mms3') and (sc_id eq 'mms4')
	inomatch = where(sc_match eq 0)
	if inomatch[0] eq -1 then message, 'SC_ID invalid: "' + strjoin(sc_id[inomatch], '", ') + '".'
	

	;Check MODE
	;   - 'brst' mode data has many of the same variable names as the 'slow' and 'fast' modes
	;     (and hence also 'srvy' data). Do not allow 'brst' mode data with others
	;   - If ['slow', 'fast'], we will need to sort the data in time.
	nmode = n_elements(mode)
	if nmode gt 1 then begin
		if nmode gt 2 then message, 'MODE can have at most two elements.'
		if nmode eq 2 then begin
			srate = strupcase(mode[sort(mode)])
			if ~array_equal(srate, ['FAST', 'SLOW']) then $
				message, 'MODE must be scalar or ["fast", "slow"].'
		endif
		tf_sort = 1
	endif else begin
		tf_sort = 0
	endelse

;------------------------------------
; Time Interval \\\\\\\\\\\\\\\\\\\\\
;------------------------------------
	;Get the current time range
	;   - Convert it to YYYY-MM-DD/hh:mm:ss
	;   - Form start and end dates
	st         = time_string(tr)
	start_date = strmid(st[0],0,10)
	end_date   = strmatch(strmid(st[1],11,8),'00:00:00')  ? $   ;Midnight?
	                 strmid(time_string(tr[1]-10.d0),0,10) : $   ;Subtract 10 seconds to get previous day
	                 strmid(st[1],0,10)                         ;Use date as is

;------------------------------------
; Check for EDI data first \\\\\\\\\\
;------------------------------------
	for j = 0, n_elements(sc_id)-1 do begin

	;------------------------------------
	; Search for Files \\\\\\\\\\\\\\\\\\
	;------------------------------------
		;fetch the data
		;   - Allows only one mode at a time
		;   - LOGIN_FLAG=1 IDLnetURL problem. Need to check local cache.
		;   - DOWNLOAD_FAIL=1 indicates download was unsuccessful
		mms_data_fetch, local_flist, login_flag, download_fail, $
		                SC_ID               = sc_id[j], $
		                INSTRUMENT_ID       = instr, $
		                MODE                = mode[0], $
		                OPTIONAL_DESCRIPTOR = optdesc, $
		                LEVEL               = level, $
		                NO_UPDATE           = no_update, $   ;Do not check for newer file versions
		                RELOAD              = reload         ;Download no matter what

		;Get the other mode
		if nmode eq 2 then begin
			mms_data_fetch, flist2, flag2, fail2, $
			                SC_ID               = sc_id[j], $
			                INSTRUMENT_ID       = instr, $
			                MODE                = mode[1], $
			                OPTIONAL_DESCRIPTOR = optdesc, $
			                LEVEL               = level, $
			                NO_UPDATE           = no_update, $
			                RELOAD              = reload

			;Combine results
			local_flist   = [local_flist, temporary(flist2)]
			login_flag    = login_flag    or temporary(flag2)
			download_fail = [download_fail, temporary(fail2)]
		endif

		;Which downloads succeeded/failed
		ifail = where(download_fail eq 1, nfail, COMPLEMENT=isuccess, NCOMPLEMENT=nsuccess)
		if nfail gt 0 then message, 'Some of the downloads from the SDC timed out. Try again later if plot is missing data.', /INFORMATIONAL
		
		;Were downloads successful?
		if nsuccess eq 0 $
			then login_flag = 1 $
			else local_flist = local_flist[isuccess]

		;Check local cache.
		;   - FILE_FLAG=1 means no file found.
		file_flag = 0
		if login_flag eq 1 or local_flist[0] eq '' or !mms.no_server eq 1 then begin
			message, 'Unable to locate files on the SDC server, checking local cache...', /INFORMATIONAL
			mms_check_local_cache, local_flist, file_flag, mode, instr, level, sc_id[j], $
			                       OPTIONAL_DESCRIPTOR = optdesc
		endif

	;------------------------------------
	; Load Data \\\\\\\\\\\\\\\\\\\\\\\\\
	;------------------------------------
		;Were files successfully found either on the server or locally?
		if login_flag eq 0 or file_flag eq 0 then begin
			;If more than one file was found, sort by date.
			;   - Guaranteed to have at least one file via flag checking.
			if n_elements(local_flist) gt 1 $
				 then files_open = mms_sort_filenames_by_date(local_flist) $
				 else files_open = local_flist

			;Load data
			for i = 0, n_elements(files_open)-1 do begin
				edi_struct = mms_load_edi_amb_cdf(files_open[i], edi_struct, mode)
			endfor

			;Open the initial file and get its data
			names = strlowcase(tag_names(edi_struct))

			;Store as TPlot variables.
			;   - If mode=['fast', 'slow'], we will need to sort the data in time.
			if tf_sort then begin
				isort1 = sort(edi_struct.(0))   ;Epoch for raw counts
				isort2 = sort(edi_struct.(3))   ;Epoch for pitch
				store_data, names[1], DATA = {x: edi_struct.(0)[isort1], y: edi_struct.(1)[isort1]}
				store_data, names[2], DATA = {x: edi_struct.(0)[isort1], y: edi_struct.(2)[isort1]}
				store_data, names[4], DATA = {x: edi_struct.(3)[isort2], y: edi_struct.(4)[isort2]}
				store_data, names[5], DATA = {x: edi_struct.(3)[isort2], y: edi_struct.(5)[isort2]}
			endif else begin
				if mode[0] eq 'brst' then begin
					store_data, names[1],  DATA = {x: edi_struct.(0), y: edi_struct.(1)}
					store_data, names[2],  DATA = {x: edi_struct.(0), y: edi_struct.(2)}
					store_data, names[3],  DATA = {x: edi_struct.(0), y: edi_struct.(3)}
					store_data, names[4],  DATA = {x: edi_struct.(0), y: edi_struct.(4)}
					store_data, names[5],  DATA = {x: edi_struct.(0), y: edi_struct.(5)}
					store_data, names[6],  DATA = {x: edi_struct.(0), y: edi_struct.(6)}
					store_data, names[7],  DATA = {x: edi_struct.(0), y: edi_struct.(7)}
					store_data, names[8],  DATA = {x: edi_struct.(0), y: edi_struct.(8)}
					store_data, names[9],  DATA = {x: edi_struct.(0), y: edi_struct.(9)}
					store_data, names[10], DATA = {x: edi_struct.(0), y: edi_struct.(10)}
				endif else begin
					store_data, names[1], DATA = {x: edi_struct.(0), y: edi_struct.(1)}
					store_data, names[2], DATA = {x: edi_struct.(0), y: edi_struct.(2)}
					store_data, names[4], DATA = {x: edi_struct.(3), y: edi_struct.(4)}
					store_data, names[5], DATA = {x: edi_struct.(3), y: edi_struct.(5)}
				endelse
			endelse
			
		;No data found
		endif else begin
			message, 'No EDI Ambient data available locally or at SDC or invalid query!', /INFORMATIONAL
		endelse
	endfor
end