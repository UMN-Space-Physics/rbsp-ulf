;+
; PROCEDURE:
;         mms_load_dfg
;
; PURPOSE:
;         Load data from the Digital Fluxgate (DFG) Magnetometer onboard MMS
;
; KEYWORDS:
;         trange: time range of interest [starttime, endtime] with the format ['YYYY-MM-DD','YYYY-MM-DD']
;             or to specificy less than a day ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;         probes: list of probes, valid values for MMS probes are ['1','2','3','4']. If no probe
;             is specified the default is 1
;         level: indicates level of data processing. levels include ['l1a', 'l1b', 'ql']. 
;             The default if no level is specified is 'ql'
;         datatype: currently all data types are loaded.
;         data_rate: instrument data rates include ['brst', 'srvy', 'fast', 'slow']. The
;             default is 'srvy'.
;         local_data_dir: local directory to store the CDF files; should be set if
;             you're on *nix or OSX, the default currently assumes Windows (c:\data\mms\)
;         source: specifies a different system variable. By default the MMS mission system variable is !mms
;         get_support_data: not yet implemented. when set this routine will load any support data
;             (support data is specified in the CDF file)
;         tplotnames: names for tplot variables
;         no_color_setup: don't setup graphics configuration; use this keyword when you're using this load
;             routine from a terminal without an X server runningdo not set colors
;         time_clip: clip the data to the requested time range; note that if you do not use this keyword
;             you may load a longer time range than requested
;         no_update: set this flag to preserve the original data. if not set and newer data is found the
;             existing data will be overwritten
;         suffix:       appends a suffix to the end of the tplot variable name. this is useful for
;                       preserving original tplot variable.
;         varformat:    should be a string (wildcards accepted) that will match the CDF variables
;                       that should be loaded into tplot variables
;
; OUTPUT:
;
; EXAMPLE:
;     See crib sheets mms_load_fgm_crib.pro, mms_load_fgm_brst_crib.pro, mms_load_fgm_crib_qlplots.pro, 
;     and mms_load_data_crib.pro for usage examples.
;     
;     to load MMS QL DFG data for MMS 1 and MMS 2
;     MMS> mms_load_dfg, probes=[1, 2], trange=['2015-06-22', '2015-06-23'], level='ql'
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-29 11:47:45 -0800 (Fri, 29 Jan 2016) $
;$LastChangedRevision: 19843 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fgm/mms_load_dfg.pro $
;-

pro mms_load_dfg, trange = trange, probes = probes, datatype = datatype, $
    level = level, data_rate = data_rate, $
    local_data_dir = local_data_dir, source = source, $
    get_support_data = get_support_data, $
    tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
    no_update = no_update, suffix = suffix, no_attitude_data = no_attitude_data, $
    varformat = varformat, cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
    latest_version = latest_version, min_version = min_version

    if undefined(trange) then trange = timerange() else trange = timerange(trange)

    mms_load_fgm, trange = trange, probes = probes, level = level, instrument = 'dfg', $
        data_rate = data_rate, local_data_dir = local_data_dir, source = source, $
        datatype = datatype, get_support_data = get_support_data, $
        tplotnames = tplotnames, no_color_setup = no_color_setup, time_clip = time_clip, $
        no_update = no_update, suffix = suffix, no_attitude_data = no_attitude_data, $
        varformat = varformat, cdf_filenames = cdf_filenames, cdf_version = cdf_version, $
        latest_version = latest_version, min_version = min_version

end