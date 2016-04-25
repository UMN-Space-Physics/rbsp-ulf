;+
; PROCEDURE:
;         mms_load_dsp
;
; PURPOSE:
;         Load data from the Digital Signal Processing (DSP) board.
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4'].
;                       if no probe is specified the default is probe '1'
;         level:        indicates level of data processing. Current level is ['ql','l1a']. 
;                       if no level is specified the routine defaults to 'ql' (for survey mode).
;         datatype:     ['epsd', 'bpsd','tdn', 'swd']

;         data_rate:    instrument data rates include ['brst', 'fast', 'slow', 'srvy']. 
;                       the default is 'srvy'
;         local_data_dir: local directory to store the CDF files; should be set if you're on
;                       *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission 
;                       system variable is !mms
;         get_support_data:  loads any support data (support data is specified by var_type in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using this load routine from a terminal without an X server running
;                       do not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not 
;                       use this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;
; OUTPUT:
;
; EXAMPLE:
;     See crib sheet mms_load_dsp_crib.pro for usage examples
;
;     ; set time frame and load edp level 2 data
;     MMS>  timespan, '2015-06-22', 1, /day
;     MMS>  mms_load_dsp, data_rate='fast', probes=[1, 2, 3, 4], datatype='epsd', level='l2'
; 
;
;$LastChangedBy:  $
;$LastChangedDate:  $
;$LastChangedRevision: $
;$URL:  $
;-

pro mms_load_dsp_new, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, $
    time_clip = time_clip, no_update = no_update, suffix = suffix, $
    varformat = varformat

    if undefined(trange) then trange = timerange() else trange = timerange(trange)
    if undefined(probes) then probes = [1, 2, 3, 4] ; default to MMS 1
    if undefined(datatype) then datatype = ['epsd', 'bpsd','tdn', 'swd']
    if undefined(level) then level = ['l1a', 'l1b', 'l2']
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'srvy'
    
    if array_contains(level, 'l1a') || array_contains(level, 'l1b') then begin
        if array_contains(datatype, 'bpsd') then begin
            datatype_l1 = ['179', '17a', '17b']
            suffixes = '_'+['x', 'y', 'z']

            for datatype_idx = 0, n_elements(datatype_l1)-1 do begin
                mms_load_data, trange = trange, probes = probes, level = level, instrument = 'dsp', $
                    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
                    datatype = datatype_l1[datatype_idx], get_support_data = get_support_data, $
                    tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
                    no_update = no_update, suffix = suffixes[datatype_idx], varformat = varformat
            endfor
        endif
        if array_contains(datatype, 'epsd') then begin
            datatype_l1 = ['173', '174', '175', '176', '177', '178']
            suffixes = '_'+['x', 'y', 'z', 'x', 'y', 'z']
            ; only grab l1b if the user requested both l1a and l1b
            if array_contains(level, 'l1a') and array_contains(level, 'l1b') then $
                level = ssl_set_complement(['l1a'], level) 

            for datatype_idx = 0, n_elements(datatype_l1)-1 do begin
                mms_load_data, trange = trange, probes = probes, level = level, instrument = 'dsp', $
                    data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
                    datatype = datatype_l1[datatype_idx], get_support_data = get_support_data, $
                    tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
                    no_update = no_update, suffix = suffixes[datatype_idx], varformat = varformat
            endfor
        endif
    endif
    if array_contains(level, 'l2') then begin
        for datatype_idx = 0, n_elements(datatype)-1 do begin
            mms_load_data, trange = trange, probes = probes, level = level, instrument = 'dsp', $
                data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
                datatype = datatype[datatype_idx], get_support_data = get_support_data, $
                tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
                no_update = no_update, suffix = suffix, varformat = varformat
        endfor
        
    endif
    
end