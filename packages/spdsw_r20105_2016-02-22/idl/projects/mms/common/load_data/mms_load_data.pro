;+
; PROCEDURE:
;         mms_load_data
;         
; PURPOSE:
;         Generic MMS load data routine; typically called from instrument specific 
;           load routines - mms_load_???, i.e., mms_load_fgm, mms_load_fpi, etc.
; 
; KEYWORDS:
;         trange: time range of interest
;         probes: list of probes - values for MMS SC #
;         instrument: instrument, AFG, DFG, etc.
;         datatypes: not implemented yet 
;         levels: level of data processing 
;         data_rates: instrument data rate
;         local_data_dir: local directory to store the CDF files; should be set if 
;             you're on *nix or OSX, the default currently assumes the IDL working directory
;         source: sets a different system variable. By default the MMS mission system variable 
;             is !mms
;         login_info: string containing name of a sav file containing a structure named "auth_info",
;             with "username" and "password" tags with your API login information
;         tplotnames: set to override default names for tplot variables
;         get_support_data: when set this routine will load any support data
;             (support data is specified in the CDF file)
;         no_color_setup: don't setup graphics configuration; use this
;             keyword when you're using this load routine from a
;             terminal without an X server running
;         time_clip: clip the data to the requested time range; note that if you
;             do not use this keyword, you may load a longer time range than requested
;         no_update: use local data only, don't query the SDC for updated files. 
;         suffix: append a suffix to tplot variables names
;         varformat: should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
; 
; OUTPUT:
; 
; EXAMPLE:
;     See the instrument specific crib sheets in the examples/ folder for usage examples
; 
; NOTES:
;     1) I expect this routine to change significantly as the MMS data products are 
;         released to the public and feedback comes in from scientists - egrimes@igpp
;
;     2) See the following regarding rules for the use of MMS data:
;         https://lasp.colorado.edu/galaxy/display/mms/MMS+Data+Rights+and+Rules+for+Data+Use
;         
;     3) Updated to use the MMS web services API
;     
;     4) The LASP web services API uses SSL/TLS, which is only supported by IDLnetURL 
;         in IDL 7.1 and later. 
;         
;     5) CDF version 3.6 is required to correctly handle the 2015 leap second.  CDF versions before 3.6
;         will give incorrect time tags for data loaded after June 30, 2015 due to this issue.
;         
;     6) The local paths should be set to mirror the SDC directory structure to avoid
;         downloading data more than once
;         
;     7) Warning about datatypes and paths:
;           -- many of the MMS instruments contain datatype details in their path names; for these CDFs
;           to be stored in the correct location locally (i.e., mirroring the SDC directory structure)
;           these datatypes must be passed to this routine by a higher level routine via the "datatype"
;           keyword. If the datatype keyword isn't passed, or datatype "*" is passed, the directory names
;           won't currently match the SDC. We can fix this by defining what "*" is for datatypes 
;           (by a list of all datatypes) in the instrument specific load routine, and passing those to this one.
;           
;               Example for HPCA: mms1/hpca/srvy/l1b/moments/2015/07/
;               
;               "moments" is the datatype. without passing datatype=["moments", ..], the data are stored locally in:
;                                 mms1/hpca/srvy/l1b/2015/07/
;               
;      8) When looking for data availability, look for the CDFs at:
;               https://lasp.colorado.edu/mms/sdc/about/browse/
;             
;      9) Logging into the SDC: 
;           - If you have an internet connection, you'll be prompted for a username and password the 
;           first time you use the MMS plugin. There's an option in the widget that allows you 
;           to save your password in a save file on the local machine; if you select this option, 
;           the login prompt will never come up again and your saved password will be used to 
;           login to the SDC. This is insecure and should not be used if you use a common 
;           password with other services.
;
;           - If you don't have an internet connection or you can't login remotely, the plugin will 
;           look for the files on the local machine using a directory structure that matches 
;           the directory structure at the SDC.
;      
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-22 12:28:58 -0800 (Mon, 22 Feb 2016) $
;$LastChangedRevision: 20103 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_data.pro $
;-

pro mms_load_data, trange = trange, probes = probes, datatypes = datatypes_in, $
                  levels = levels, instrument = instrument, data_rates = data_rates, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, login_info = login_info, $
                  tplotnames = tplotnames, varformat = varformat, no_color_setup = no_color_setup, $
                  suffix = suffix, time_clip = time_clip, no_update = no_update, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, latest_version = latest_version, $
                  min_version = min_version

    ;temporary variables to track elapsed times
    t0 = systime(/sec)
    dt_query = 0d
    dt_download = 0d
    dt_load = 0d
   
    mms_init, remote_data_dir = remote_data_dir, local_data_dir = local_data_dir, no_color_setup = no_color_setup
    
    if undefined(source) then source = !mms

    if undefined(probes) then probes = ['1'] ; default to MMS 1
    probes = strcompress(string(probes), /rem) ; probes should be strings
    if undefined(levels) then levels = 'ql' ; default to quick look
    if undefined(instrument) then instrument = 'dfg'
    if undefined(data_rates) then data_rates = 'srvy'

    ;ensure datatypes are explicitly set for simplicity 
    if undefined(datatypes_in) || in_set('*',datatypes_in) then begin
        mms_load_options, instrument, rate=data_rates, level=levels, datatype=datatypes
    endif else begin
        datatypes = datatypes_in
    endelse

    if undefined(local_data_dir) then local_data_dir = !mms.local_data_dir
    ; handle shortcut characters in the user's local data directory
    spawn, 'echo ' + local_data_dir, local_data_dir
    if is_array(local_data_dir) then local_data_dir = local_data_dir[0]

   ; if undefined(varformat) then varformat = '*'
    if ~undefined(trange) && n_elements(trange) eq 2 $
      then tr = timerange(trange) $
      else tr = timerange()

    ;response_code = spd_check_internet_connection()
    response_code = 200

    ;combine these flags for now, if we're not downloading files then there is
    ;no reason to contact the server unless mms_get_local_files is unreliable
    no_download = !mms.no_download or !mms.no_server or (response_code ne 200) or ~undefined(no_update)

    ; only prompt the user if they're going to download data
    if no_download eq 0 then begin
        status = mms_login_lasp(login_info = login_info)
        if status ne 1 then no_download = 1
    endif
    
    ;clear so new names are not appended to existing array
    undefine, tplotnames
    ; clear CDF filenames, so we're not appending to an existing array
    undefine, cdf_filenames
    
    ;loop over probe, rate, level, and datatype
    ;omitting some tabbing to keep format reasonable
    for probe_idx = 0, n_elements(probes)-1 do begin
    for rate_idx = 0, n_elements(data_rates)-1 do begin
    for level_idx = 0, n_elements(levels)-1 do begin
    for datatype_idx = 0, n_elements(datatypes)-1 do begin
        ;options for this iteration
        probe = 'mms' + strcompress(string(probes[probe_idx]), /rem)
        data_rate = data_rates[rate_idx]
        level = levels[level_idx]
        datatype = datatypes[datatype_idx]

        ;ensure no descriptor is used if instrument doesn't use datatypes
        if datatype eq '' then undefine, descriptor else descriptor = datatype

        day_string = time_string(tr[0], tformat='YYYY-MM-DD') 
        ; note, -1 second so we don't download the data for the next day accidently
        end_string = time_string(tr[1]-1., tformat='YYYY-MM-DD-hh-mm-ss')
        
        ;get file info from remote server
        ;if the server is contacted then a string array or empty string will be returned
        ;depending on whether files were found, if there is a connection error the 
        ;neturl response code is returned instead
        if ~keyword_set(no_download) then begin
            qt0 = systime(/sec) ;temporary
            data_file = mms_get_science_file_info(sc_id=probe, instrument_id=instrument, $
                    data_rate_mode=data_rate, data_level=level, start_date=day_string, $
                    end_date=end_string, descriptor=descriptor)
            dt_query += systime(/sec) - qt0 ;temporary
        endif

        ;if a list of remote files was retrieved then compare remote and local files
        if is_string(data_file) then begin
          
            remote_file_info = mms_parse_json(data_file)
            ; limit the CDF files to the requested time range
            remote_file_info = mms_files_in_interval(remote_file_info, tr)

            if ~is_struct(remote_file_info) then begin
                dprint, dlevel = 0, 'Error getting the information on remote files'
                return
            endif

            filename = remote_file_info.filename
            num_filenames = n_elements(filename)
            
            for file_idx = 0, num_filenames-1 do begin
                ; For Survey and SITL products, the bottommost level are monthly directories,
                ; which are full of daily files. For Burst products, the bottommost level are daily
                ; directories
                dir_path = data_rate eq 'brst' ? '/YYYY/MM/DD' : '/YYYY/MM'

                ;daily_names = file_dailynames(file_format=dir_path, trange=tr, /unique, times=times)
                timetag = time_string(time_double(remote_file_info[file_idx].timetag), tformat ='YYYY-MM-DD')

                daily_names = file_dailynames(file_format=dir_path, /unique, trange=timetag)

                ; updated to match the path at SDC; this path includes data type for
                ; the following instruments: EDP, DSP, EPD-EIS, FEEPS, FIELDS, HPCA, SCM (as of 7/23/2015)
                sdc_path = instrument + '/' + data_rate + '/' + level
                sdc_path = datatype ne '' ? sdc_path + '/' + datatype + daily_names : sdc_path + daily_names
                file_dir = local_data_dir + strlowcase(probe + '/' + sdc_path)
                
                same_file = mms_check_file_exists(remote_file_info[file_idx], file_dir = file_dir)

                if same_file eq 0 then begin
                    td0 = systime(/sec) ;temporary
                    dprint, dlevel = 0, 'Downloading ' + filename[file_idx] + ' to ' + file_dir
                    status = get_mms_science_file(filename=filename[file_idx], local_dir=file_dir)

                    dt_download += systime(/sec) - td0 ;temporary
                    if status eq 0 then append_array, files, file_dir + '/' + filename[file_idx]
                endif else begin
                    dprint, dlevel = 0, 'Loading local file ' + file_dir + '/' + filename[file_idx]
                    append_array, files, file_dir + '/' + filename[file_idx]
                endelse
            endfor
        
        ;if no remote list was retrieved then search locally   
        endif else begin
            ; suppressed redundant error message
            ;dprint, dlevel = 2, 'No remote files found for: '+ $
            ;        probe+' '+instrument+' '+data_rate+' '+level+' '+datatype
            
            local_files = mms_get_local_files(probe=probe, instrument=instrument, $
                    data_rate=data_rate, level=level, datatype=datatype, trange=time_double([day_string, end_string]))

;            ;Filter files by time
;            if is_array(local_files) then local_files = unh_mms_file_filter(local_files, trange=time_double([day_string, end_string]), $
;                version=cdf_version, min_version = min_version, latest_version = latest_version)

            if is_string(local_files) then begin
                append_array, files, local_files
            endif else begin
                dprint, dlevel = 0, 'Error, no local or remote data files found: '+$
                         probe+' '+instrument+' '+data_rate+' '+level+' '+datatype
                continue
            endelse
        endelse       

        ; sort the data files in time (this is required by 
        ; HPCA (at least) due to multiple files per day
        ; the intention is to order in time before passing
        ; to cdf2tplot
        files = files[bsort(files)]

        if ~undefined(files) then begin
            lt0 = systime(/sec) ;temporary
            mms_cdf2tplot, files, tplotnames = loaded_tnames, varformat=varformat, $
                suffix = suffix, get_support_data = get_support_data, /load_labels, $
                min_version=min_version,version=cdf_version,latest_version=latest_version
            dt_load += systime(/sec) - lt0 ;temporary
        endif
        
        append_array, cdf_filenames, files
        if ~undefined(loaded_tnames) then append_array, tplotnames, loaded_tnames
        
        ; forget about the daily files for this probe
        undefine, files
        undefine, loaded_tnames

    ;end loops over probe, rate, leve, and datatype
    endfor
    endfor
    endfor
    endfor

    ; just in case multiple datatypes loaded identical variables
    ; (this occurs with hpca moments & logicals)
    if ~undefined(tplotnames) then tplotnames = spd_uniq(tplotnames)

    ; time clip the data
    if ~undefined(tr) && ~undefined(tplotnames) then begin
        dt_timeclip = 0.0
        if (n_elements(tr) eq 2) and (tplotnames[0] ne '') and ~undefined(time_clip) then begin
            tc0 = systime(/sec)
            time_clip, tplotnames, tr[0], tr[1], replace=1, error=error
            dt_timeclip = systime(/sec)-tc0
        endif
        ;temporary messages for diagnostic purposes
        dprint, dlevel=2, 'Successfully loaded: '+ $
            strjoin( ['mms'+probes, instrument, data_rates, levels, datatypes, time_string(tr)],' ')
        dprint, dlevel=2, 'Time querying remote server: '+strtrim(dt_query,2)+' sec'
        dprint, dlevel=2, 'Time downloading remote files: '+strtrim(dt_download,2)+' sec'
        dprint, dlevel=2, 'Time loading files into IDL: '+strtrim(dt_load,2)+' sec'
        dprint, dlevel=2, 'Time spent time clipping variables: '+strtrim(dt_timeclip,2)+' sec'
        dprint, dlevel=2, 'Total load time: '+strtrim(systime(/sec)-t0,2)+' sec'

    endif
end