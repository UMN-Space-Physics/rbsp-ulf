;+
; PROCEDURE:
;         mms_load_fpi
;         
; PURPOSE:
;         Load data from the Fast Plasma Investigation (FPI) onboard MMS
; 
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format 
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day 
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes:       list of probes, valid values for MMS probes are ['1','2','3','4']. 
;                       If no probe is specified the default is probe '3'
;         level:        indicates level of data processing. fpi levels currently include 'sitl', 'ql', 'l1b'. 
;         datatype:     valid datatypes are:
;                         Quicklook: ['des', 'dis'] 
;                         SITL: '' (none; loads both electron and ion data from single CDF)
;                         L1b: ['des-dist', 'dis-dist', 'dis-moms', 'des-moms']
;         data_rate:    instrument data rates for MMS fpi include 'fast'. 
;         local_data_dir: local directory to store the CDF files; should be set if
;                       you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source:       specifies a different system variable. By default the MMS mission system 
;                       variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;                       (support data is specified in the CDF file)
;         tplotnames:   names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're 
;                       using  this load routine from a terminal without an X server runningdo 
;                       not set colors
;         time_clip:    clip the data to the requested time range; note that if you do not use 
;                       this keyword you may load a longer time range than requested
;         no_update:    set this flag to preserve the original data. if not set and newer 
;                       data is found the existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables 
;                       that should be loaded into tplot variables
;         cdf_filenames:  this keyword returns the names of the CDF files used when loading the data
; 
; 
; EXAMPLE:
;     See crib sheets mms_load_fpi_crib, mms_load_fpi_burst_crib, and mms_load_fpi_crib_qlplots
;     for usage examples
; 
;     MMS>  timespan, '2015-09-19', 1d
;     load fpi burst mode data
;     MMS>  mms_load_fpi, probes = ['1'], level='l1b', data_rate='brst', datatype='des-moms'
;     
;     load fast mode data
;     MMS>  mms_load_fpi, probes = '3', level='sitl', data_rate='fast', datatype='*'
;
; NOTES:
;     Please see the notes at:
;     
;        https://lasp.colorado.edu/galaxy/display/mms/FPI+Release+Notes
;        
;     for more information
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-19 15:36:47 -0800 (Fri, 19 Feb 2016) $
;$LastChangedRevision: 20069 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi.pro $
;-

pro mms_load_fpi, trange = trange_in, probes = probes, datatype = datatype, $
                  level = level, data_rate = data_rate, $
                  local_data_dir = local_data_dir, source = source, $
                  get_support_data = get_support_data, $
                  tplotnames = tplotnames, no_color_setup = no_color_setup, $
                  time_clip = time_clip, no_update = no_update, suffix = suffix, $
                  autoscale = autoscale, varformat = varformat, $
                  cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
                  latest_version = latest_version, min_version = min_version

    if undefined(trange_in) then trange = timerange() else trange = timerange(trange_in)
    if undefined(probes) then probes = ['3'] ; default to MMS 3
    if undefined(datatype) then datatype = '*' ; grab all data in the CDF
    if undefined(level) then level = 'sitl' 
    if undefined(data_rate) then data_rate = 'fast'
    if undefined(autoscale) then autoscale = 1
    
    ; different datatypes for burst mode files
    if data_rate eq 'brst' && (datatype[0] eq '*' || datatype[0] eq '') && level ne 'ql' then datatype=['des-dist', 'dis-dist', 'dis-moms', 'des-moms']
    if (datatype[0] eq '*' || datatype[0] eq '') && level eq 'ql' then datatype=['des', 'dis']
    if (datatype[0] eq '*' || datatype[0] eq '') && level ne 'ql' then datatype=['des-dist', 'dis-dist', 'dis-moms', 'des-moms']

    ; kludge for level = 'sitl' -> datatype shouldn't be defined for sitl data.
    if level eq 'sitl' then datatype = '*'

    mms_load_data, trange = trange, probes = probes, level = level, instrument = 'fpi', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, varformat = varformat, cdf_filenames = cdf_filenames, $
        cdf_version = cdf_version, latest_version = latest_version, min_version = min_version

    ; since the SITL files contain both ion and electron data, and datatype = '*' doesn't work
    ; in our 'fix'/'calc' routines for the FPI metadata
    if level eq 'sitl' then datatype = ['des-dist', 'dis-dist']
    
    ; correct the energies in the spectra for each probe
    if ~undefined(tplotnames) && n_elements(tplotnames) ne 0 then begin
        for probe_idx = 0, n_elements(probes)-1 do begin
            mms_load_fpi_fix_spectra, tplotnames, probe = strcompress(string(probes[probe_idx]), /rem), $
                level = level, data_rate = data_rate, datatype = datatype, suffix = suffix
            mms_load_fpi_fix_angles, tplotnames, probe = strcompress(string(probes[probe_idx]), /rem), $ 
                level = level, data_rate = data_rate, datatype = datatype, suffix = suffix
            mms_load_fpi_calc_omni, probes[probe_idx], autoscale = autoscale, level = level, $
                datatype = datatype, data_rate = data_rate, suffix = suffix
            mms_load_fpi_calc_pad, probes[probe_idx], level = level, datatype = datatype, $
                suffix = suffix, data_rate = data_rate
        endfor
    endif
end