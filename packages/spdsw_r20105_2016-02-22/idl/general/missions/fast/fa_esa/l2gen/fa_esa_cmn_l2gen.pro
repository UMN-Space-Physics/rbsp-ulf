;+
;NAME:
; fa_esa_cmn_l2gen.pro
;PURPOSE:
; turn a FAST ESA common block into a L2 CDF.
;CALLING SEQUENCE:
; fa_esa_cmn_l2gen, cmn_dat
;INPUT:
; cmn_dat = a structrue with the data:
;   PROJECT_NAME    STRING    'FAST'
;   DATA_NAME       STRING    'Iesa Burst'
;   DATA_LEVEL      STRING    'Level 1'
;   UNITS_NAME      STRING    'Compressed'
;   UNITS_PROCEDURE STRING    'fa_convert_esa_units'
;   VALID           INT       Array[59832]
;   DATA_QUALITY    BYTE      Array[59832]
;   TIME            DOUBLE    Array[59832]
;   END_TIME        DOUBLE    Array[59832]
;   INTEG_T         DOUBLE    Array[59832]
;   DELTA_T         DOUBLE    Array[59832]
;   NBINS           BYTE      Array[59832]
;   NENERGY         BYTE      Array[59832]
;   GEOM_FACTOR     FLOAT     Array[59832]
;   DATA_IND        LONG      Array[59832]
;   GF_IND          INT       Array[59832]
;   BINS_IND        INT       Array[59832]
;   MODE_IND        BYTE      Array[59832]
;   THETA_SHIFT     FLOAT     Array[59832]
;   THETA_MAX       FLOAT     Array[59832]
;   THETA_MIN       FLOAT     Array[59832]
;   BKG             FLOAT     Array[59832]
;   DATA0           BYTE      Array[48, 32, 59832]
;   DATA1           FLOAT     NaN (48, 64, ntimes) (here single NaN means no data)
;   DATA2           FLOAT     NaN (96, 32, ntimes)
;   ENERGY          FLOAT     Array[96, 32, 2]
;   BINS            BYTE      Array[96, 32]
;   THETA           FLOAT     Array[96, 32, 2]
;   GF              FLOAT     Array[96, 64]
;   DENERGY         FLOAT     Array[96, 32, 2]
;   DTHETA          FLOAT     Array[96, 32, 2]
;   EFF             FLOAT     Array[96, 32, 2]
;   DEAD            FLOAT       1.10000e-07
;   MASS            FLOAT         0.0104389
;   CHARGE          INT              1
;   SC_POT          FLOAT     Array[59832]
;   BKG_ARR         FLOAT     Array[96, 64]
;   HEADER_BYTES    BYTE      Array[44, 59832]
;   DATA            BYTE      Array[96, 64, 59832] ;save this and not data0,1,2
;   EFLUX           FLOAT     Array[96, 64, 59832]
;KEYWORDS:
; otp_struct = this is the structure that is passed into
;              cdf_save_vars to create the file
; directory = Set this keyword to direct the output into this
;             directory; the default is to populate the MAVEN STA
;             database. /disks/data/maven/pfp/sta/l2
; no_compression = if set, do not compress the CDF file
;HISTORY:
; Hacked from mvn_sta_cmn_l2gen.pro, 22-jul-2015
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-08-28 13:51:59 -0700 (Fri, 28 Aug 2015) $
; $LastChangedRevision: 18665 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2gen/fa_esa_cmn_l2gen.pro $
;-
Pro fa_esa_cmn_l2gen, cmn_dat, esa_type=esa_typ, $
                      otp_struct = otp_struct, directory = directory, $
                      no_compression = no_compression, _extra = _extra

;Keep track of software versioning here
  sw_vsn = fa_esa_current_sw_version()
  sw_vsn_str = 'v'+string(sw_vsn, format='(i2.2)')

  If(~is_struct(cmn_dat)) Then Begin
     message,/info,'No Input Structure'
     Return
  Endif
  If(cmn_dat.orbit_start Ne cmn_dat.orbit_end) Then Begin
     message,/info,'No multiple orbit files plaese'
     Return
  Endif
     
;First, global attributes
  global_att = {Acknowledgment:'None', $
                Data_type:'CAL>Calibrated', $
                Data_version:'0', $
                Descriptor:'FA_ESA>Fast Auroral SnapshoT Explorer, Electrostatic Analyzer', $
                Discipline:'Space Physics>Planetary Physics>Particles', $
                File_naming_convention: 'fa_esa_descriptor_datatype_yyyyMMdd', $
                Generated_by:'FAST SOC' , $
                Generation_date:'2015-07-28' , $
                HTTP_LINK:'http://sprg.ssl.berkeley.edu/fast/', $
                Instrument_type:'Particles (space)' , $
                LINK_TEXT:'General Information about the FAST mission' , $
                LINK_TITLE:'FAST home page' , $
                Logical_file_id:'fa_l2_XXX_00000000_v00.cdf' , $
                Logical_source:'fa_l2_XXX' , $
                Logical_source_description:'FAST Ion and Electron Particle Distributions', $
                Mission_group:'FAST' , $
                MODS:'Rev-1 2015-07-28' , $
                PI_name:'J. P. McFadden', $
                PI_affiliation:'U.C. Berkeley Space Sciences Laboratory', $
                Planet:'Earth', $
                Project:'FAST', $
                Rules_of_use:'Open Data for Scientific Use' , $
                Source_name:'FAST>Fast Auroral SnapshoT Explorer', $
                TEXT:'ESA>Electrostatic Analyzer', $
                Time_resolution:'1 sec', $
                Title:'FAST ESA Electron and Ion Distributions'}

;Now variables and attributes
  cvars = strlowcase(tag_names(cmn_dat))

; Here are variable names, type, catdesc, and lablaxis
  rv_vt =  [['EPOCH', 'CDF_EPOCH', 'CDF EPOCH time, one element per ion distribution (NUM_DISTS elements)', 'CDF_EPOCH'], $
            ['TIME_UNIX', 'DOUBLE', 'Unix time (elapsed seconds since 1970-01-01/00:00 without leap seconds) for each data record, one element per distribution. This time is the center time of data collection. (NUM_DISTS elements)', 'Unix Time'], $
            ['TIME_START', 'DOUBLE', 'Unix time at the start of data collection. (NUM_DISTS elements)', 'Interval start time (unix)'], $
            ['TIME_END', 'DOUBLE', 'Unix time at the end of data collection. (NUM_DISTS elements)', 'Interval end time (unix)'], $
            ['TIME_DELTA', 'DOUBLE', 'Averaging time. (TIME_END - TIME_START). (NUM_DISTS elements).', 'Averaging time'], $
            ['TIME_INTEG', 'DOUBLE', 'Integration time. (TIME_DELTA/N_ENERGY). (NUM_DISTS elements).', 'Integration time'], $
            ['HEADER', 'BYTE', 'The packet header bytes. (44XNUM_DISTS elements)', 'Header'], $
            ['VALID', 'INTEGER', 'Validity flag codes valid data (bit 0), non-zero values are not necessarily valid (NUM_DISTS elements)', ' Valid flag'], $
            ['DATA_QUALITY', 'INTEGER', 'Quality flag (NUM_DISTS elements)', 'Quality flag'], $
            ['NBINS', 'INTEGER', 'Number of angluar bins (NUM_DISTS elements)', 'Number of bins'], $
            ['NENERGY', 'INTEGER', 'Number of energies (NUM_DISTS elements)', 'Number of energies'], $
            ['GEOM_FACTOR', 'DOUBLE', 'GEOM_FACTOR, Geometrical factor used in calibration (NUM_DISTS elements)', 'Geometric Factor'], $
            ['GF_IND', 'INTEGER', 'Index for the value of the Geometrical factor for data (NUM_DISTS elements)', 'GF index'], $
            ['BINS_IND', 'INTEGER', 'Index for the number of angular bins for data (NUM_DISTS elements)', 'Bins index'], $
            ['MODE_IND', 'INTEGER', 'Index for the data mode (0-2 for survey data, 0-1 for burst data) (NUM_DISTS elements)', 'Mode index'], $
            ['THETA_SHIFT', 'DOUBLE', 'Angular shift (NUM_DISTS elements)', 'Angular shift, converts theta bin values to pitch angles'], $
            ['THETA_MAX', 'DOUBLE', 'Angular maximum (NUM_DISTS elements)', 'Angular max'], $
            ['THETA_MIN', 'DOUBLE', 'Angular minimum (NUM_DISTS elements)', 'Angular min'], $
            ['BKG', 'FLOAT', 'Background counts array with dimensions (NUM_DISTS)', 'Background counts'], $
            ['SC_POT', 'FLOAT', 'Spacecraft potential (NUM_DISTS elements)', 'Spacecraft potential'], $
            ['DATA', 'BYTE', 'Raw Counts data with dimensions (NUM_DISTS, 96, 64)', 'Raw Counts'], $
            ['EFLUX', 'FLOAT', 'Differential energy flux array with dimensions (NUM_DISTS, 96, 64)', 'Energy flux'], $
            ['PITCH_ANGLE', 'FLOAT', 'Pitch Angule values for each distribution (NUM_DISTS, 96, 64); Virtual variable', 'Pitch Angle'], $
            ['ENERGY_FULL', 'FLOAT', 'Angular values for each distribution (NUM_DISTS, 96, 64); Virtual variable', 'Energy'], $
            ['DENERGY_FULL', 'FLOAT', 'Angular bin size for each distribution (NUM_DISTS, 96, 64); Virtual variable', 'DEnergy']]

;Use Lower case for variable names
  rv_vt[0, *] = strlowcase(rv_vt[0, *])

;No need for lablaxis values here, just use the name
  nv_vt = [['PROJECT_NAME', 'STRING', 'FAST'], $
           ['DATA_NAME', 'STRING', cmn_dat.data_name], $
           ['UNITS_NAME', 'STRING', 'eflux'], $
           ['UNITS_PROCEDURE', 'STRING', 'fa_esa_convert_esa_units, name of IDL routine used for units conversion '], $
           ['NUM_DISTS', 'INTEGER', 'Number of measurements or times in the file'], $
           ['BINS', 'INTEGER', 'Array with dimension NBINS containing 1 OR 0 used to flag bad angle bins'], $
           ['ENERGY', 'FLOAT', 'Energy array with dimension (96,64 or 32,nmode)'], $
           ['DENERGY', 'FLOAT', 'Delta Energy array with dimension (96, 64 or 32, 2 or 3)'], $
           ['THETA', 'FLOAT', 'Angle array with with dimension (96, 64 or 32, 2 or 3)'], $
           ['DTHETA', 'FLOAT', 'Delta Angle array with with dimension (96, 64 or 32, 2 or 3)'], $
           ['GF', 'FLOAT', 'Geometric Factor array with dimension (96, 64)'], $
           ['EFF', 'FLOAT', 'Efficiency array with dimension (96, 64 or 32, 2 or 3)'], $
           ['DEAD', 'FLOAT', 'Dead time in seconds for 1 processed count'], $
           ['MASS', 'FLOAT', 'Proton or Electron mass in units of MeV/c2'], $
           ['CHARGE', 'FLOAT', 'Proton or Electron charge (1 or -1)'], $
           ['BKG_ARR', 'FLOAT', 'Background counts array with dimension (96, 64)']]


;Use Lower case for variable names
  nv_vt[0, *] = strlowcase(nv_vt[0, *])

;Create variables for epoch
  cdf_leap_second_init
  date_range = time_double(['1996-08-21/00:00:00','2009-05-01/00:00:00'])
  epoch_range = time_epoch(date_range)

;Use center time for time variables
  center_time = 0.5*(cmn_dat.time+cmn_dat.end_time)
  num_dists = n_elements(center_time)

;Initialize
  otp_struct = -1
  count = 0L
;First handle RV variables
  lrv = n_elements(rv_vt[0, *])
  For j = 0L, lrv-1 Do Begin
;Either the name is in the common block or not, names not in the
;common block have to be dealt with as special cases. Vectors will
;need label and component variables
     is_tvar = 0b
     vj = rv_vt[0, j]
     Have_tag = where(cvars Eq vj, nhave_tag)
     If(nhave_tag Gt 0) Then Begin
        dvar = cmn_dat.(have_tag)
     Endif Else Begin
;Case by case basis
        Case vj of
           'epoch': Begin
              dvar = time_epoch(center_time)
              is_tvar = 1b
           End
           'time_unix': Begin
              dvar = center_time
              is_tvar = 1b
           End
           'time_start': Begin
              dvar = cmn_dat.time
              is_tvar = 1b
           End
           'time_end': Begin
              dvar = cmn_dat.end_time
              is_tvar = 1b
           End
           'time_delta': dvar = cmn_dat.delta_t
           'time_integ': dvar = cmn_dat.integ_t
           'pitch_angle': Begin ;Virtual variable
              message, /info, 'Variable '+vj+' is Virtual.'
              dvar = 0.0
           End
           'energy_full': Begin ;Virtual variable
              message, /info, 'Variable '+vj+' is Virtual.'
              dvar = 0.0
           End
           'denergy_full': Begin ;Virtual variable
              message, /info, 'Variable '+vj+' is Virtual.'
              dvar = 0.0
           End
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for.'
           End
        Endcase
     Endelse

     cdf_type = idl2cdftype(dvar, format_out = fmt, fillval_out = fll, validmin_out = vmn, validmax_out = vmx)
;Change types for CDF time variables
     If(vj eq 'epoch') Then cdf_type = 'CDF_TIME_TT2000'

     dtype = size(dvar, /type)
;variable attributes here, but only the string attributes, the others
;depend on the data type
     vatt = {catdesc:'NA', display_type:'NA', fieldnam:'NA', $
             units:'None', depend_time:'NA', $
             depend_0:'NA', depend_1:'NA', depend_2:'NA', $
             depend_3:'NA', var_type:'NA', $
             coordinate_system:'sensor', $
             scaletyp:'NA', lablaxis:'NA',$
             labl_ptr_1:'NA',labl_ptr_2:'NA',labl_ptr_3:'NA', $
             form_ptr:'NA', monoton:'NA',var_notes:'None'}

;fix fill vals, valid mins and valid max's here
     str_element, vatt, 'fillval', fll, /add
     str_element, vatt, 'format', fmt, /add
     If(vj Eq 'epoch') Then Begin
        str_element, vatt, 'fillval', epoch_range[0], /add_replace
        str_element, vatt, 'validmin', epoch_range[0], /add
        str_element, vatt, 'validmax', epoch_range[1], /add
     Endif Else If(vj Eq 'time_unix' Or vj Eq 'time_start' Or vj Eq 'time_end') Then Begin
        str_element, vatt, 'validmin', date_range[0], /add
        str_element, vatt, 'validmax', date_range[1], /add
     Endif Else Begin
        str_element, vatt, 'validmin', vmn, /add
        str_element, vatt, 'validmax', vmx, /add
;scalemin and scalemax depend on the variable's values
        str_element, vatt, 'scalemin', vmn, /add
        str_element, vatt, 'scalemax', vmx, /add
        ok = where(finite(dvar), nok)
        If(nok Gt 0) Then Begin
           vatt.scalemin = min(dvar[ok])
           vatt.scalemax = max(dvar[ok])
        Endif
     Endelse
     vatt.catdesc = rv_vt[2, j]
;data is log scaled, everything else is linear, set data, support data
;display type here
     IF(vj Eq 'data' Or vj Eq 'eflux') Then Begin
        vatt.scaletyp = 'log' 
        vatt.display_type = 'spectrogram'
        vatt.var_type = 'data'
     Endif Else Begin
        vatt.scaletyp = 'linear'
        vatt.display_type = 'time_series'
        vatt.var_type = 'support_data'
     Endelse

     vatt.fieldnam = rv_vt[3, j] ;shorter name
;Units
     If(is_tvar) Then Begin     ;Time variables
        vatt.units = 'sec'
     Endif Else Begin
        If(strpos(vj, 'time') Ne -1) Then vatt.units = 'sec' $ ;time interval sizes
        Else If(strpos(vj, 'theta') Ne -1) Then vatt.units = 'degrees' $
        Else If(vj Eq 'sc_pot') Then vatt.units = 'volts' $
        Else If(vj Eq 'data') Then vatt.units = 'Counts' $
        Else If(vj Eq 'eflux') Then vatt.units = 'eV/sr/sec' ;check this
     Endelse

;Depends and labels
     vatt.depend_time = 'time_unix'
     vatt.depend_0 = 'epoch'
     vatt.lablaxis = rv_vt[3, j]

;Assign labels and components for vectors
     If(vj Eq 'data' Or vj Eq 'eflux' Or $
        vj Eq 'pitch_angle' Or vj Eq 'energy_full' Or $
        vj Eq 'denergy_full') Then Begin
;For ISTP compliance, it looks as if the depend's are switched,
;probably because we transpose it all in the file
        vatt.depend_2 = 'compno_96'
        vatt.depend_1 = 'compno_64'
        vatt.labl_ptr_2 = vj+'_energy_labl_96'
        vatt.labl_ptr_1 = vj+'_angle_labl_64'
     Endif
 
;Time variables are monotonically increasing:
     If(is_tvar) Then vatt.monoton = 'INCREASE' Else vatt.monoton = 'FALSE'

;Add tags for virtual variables
     If(vj Eq 'pitch_angle') Then Begin
        str_element, vatt, 'virtual', 'TRUE', /add_replace
        str_element, vatt, 'funct', 'fa_esa_pa', /add_replace
        str_element, vatt, 'component_0', 'theta', /add_replace
        str_element, vatt, 'component_1', 'theta_shift', /add_replace
        str_element, vatt, 'component_2', 'mode_ind', /add_replace
     Endif Else If(vj Eq 'energy_full') Then Begin
        str_element, vatt, 'virtual', 'TRUE', /add_replace
        str_element, vatt, 'funct', 'fa_esa_energy', /add_replace
        str_element, vatt, 'component_0', 'energy', /add_replace
        str_element, vatt, 'component_1', 'mode_ind', /add_replace
     Endif Else If(vj Eq 'energy_full') Then Begin
        str_element, vatt, 'virtual', 'TRUE', /add_replace
        str_element, vatt, 'funct', 'fa_esa_energy', /add_replace
        str_element, vatt, 'component_0', 'denergy', /add_replace
        str_element, vatt, 'component_1', 'mode_ind', /add_replace
     Endif

;delete all 'NA' tags
     vatt_tags = tag_names(vatt)
     nvatt_tags = n_elements(vatt_tags)
     rm_tag = bytarr(nvatt_tags)

     For k = 0, nvatt_tags-1 Do Begin
        If(is_string(vatt.(k)) && vatt.(k) Eq 'NA') Then rm_tag[k] = 1b
     Endfor
     xtag = where(rm_tag Eq 1, nxtag)
     If(nxtag Gt 0) Then Begin
        tags_to_remove = vatt_tags[xtag]
        For k = 0, nxtag-1 Do str_element, vatt, tags_to_remove[k], /delete
     Endif

;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 1b, $
            numrec:0L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = cdf_type
     vsj.type = dtype
     vsj.numrec = num_dists
;It looks as if you do not include the time variation?
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim-1
     If(ndim Gt 1) Then vsj.d[0:ndim-2] = dims[1:*]
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
     
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
;Now the non-record variables
  nrv = n_elements(nv_vt[0, *])
  For j = 0L, nrv-1 Do Begin
     vj = nv_vt[0, j]
     Have_tag = where(cvars Eq vj, nhave_tag)
     If(nhave_tag Gt 0) Then Begin
        dvar = cmn_dat.(have_tag)
;Set any 1d array value to a scalar, for ISTP
        If(n_elements(dvar) Eq 1) Then dvar = dvar[0]
     Endif Else Begin
;Case by case basis
        Case vj of
           'num_dists': Begin
              dvar = num_dists
           End        
           Else: Begin
              message, /info, 'Variable '+vj+' Unaccounted for.'
           End
        Endcase
     Endelse
     cdf_type = idl2cdftype(dvar, format_out = fmt, fillval_out = fll, validmin_out = vmn, validmax_out = vmx)
     dtype = size(dvar, /type)
;variable attributes here, but only the string attributes, the others
;depend on the data type, note that these are metadata, not support_data
     vatt = {catdesc:'NA', fieldnam:'NA', $
             units:'NA', var_type:'metadata', $
             coordinate_system:'sensor'}
     str_element, vatt, 'format', fmt, /add
;Don't need mins and maxes for string variables
     If(~is_string(dvar)) Then Begin
        str_element, vatt, 'fillval', fll, /add
        str_element, vatt, 'validmin', vmn, /add
        str_element, vatt, 'validmax', vmx, /add
;scalemin and scalemax depend on the variable's values
        str_element, vatt, 'scalemin', vmn, /add
        str_element, vatt, 'scalemax', vmx, /add
        ok = where(finite(dvar), nok)
        If(nok Gt 0) Then Begin
           vatt.scalemin = min(dvar[ok])
           vatt.scalemax = max(dvar[ok])
        Endif
     Endif
     vatt.catdesc = nv_vt[2, j]
     vatt.fieldnam = nv_vt[0, j]
     If(vj Eq 'energy' Or vj Eq 'denergy') Then vatt.units = 'eV' $
     Else If(vj Eq 'theta' Or vj Eq 'dtheta') Then vatt.units = 'Degrees'

;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = cdf_type
     vsj.type = dtype
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
     
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
     
;Now compnos, need 96, 64
  ext_compno = [96, 64]
  vcompno = 'compno_'+strcompress(/remove_all, string(ext_compno))
  For j = 0, n_elements(vcompno)-1 Do Begin
     vj = vcompno[j]
     xj = strsplit(vj, '_', /extract)
     nj = Fix(xj[1])
;Component attributes
     vatt =  {catdesc:vj, fieldnam:vj, $
              fillval:0, format:'I3', $
              validmin:0, dict_key:'number', $
              validmax:255, var_type:'metadata'}
;Also a data array
     dvar = 1+indgen(nj)

;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = 'CDF_INT2'
     vsj.type = 2
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
     
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
     
;Labels now
  lablvars = ['data_energy_labl_96', $
              'eflux_energy_labl_96', $
              'data_angle_labl_64', $
              'eflux_angle_labl_64']
  For j = 0, n_elements(lablvars)-1 Do Begin
     vj = lablvars[j]
     xj = strsplit(vj, '_', /extract)
     nj = Fix(xj[3])
     aj = xj[0]+'@'+strupcase(xj[1])
     dvar = aj+strcompress(/remove_all, string(indgen(nj)))
     ndv = n_elements(dvar)

     numelem = strlen(dvar[ndv-1]) ;needed for numrec
     fmt = 'A'+strcompress(/remove_all, string(numelem))

;Label attributes
     vatt =  {catdesc:vj, fieldnam:vj, $
              format:fmt, dict_key:'label', $
              var_type:'metadata'}
;Create and fill the variable structure
     vsj = {name:'', num:0, is_zvar:1, datatype:'', $
            type:0, numattr: -1, numelem: 1, recvary: 0b, $
            numrec:-1L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
            attrptr:ptr_new()}
     vsj.name = vj
     vsj.datatype = 'CDF_CHAR'
     vsj.type = 1
     vsj.numelem = numelem
;Include all dimensions
     ndim = size(dvar, /n_dimen)
     dims = size(dvar, /dimen)
     vsj.ndimen = ndim
     If(ndim Gt 0) Then vsj.d[0:ndim-1] = dims
     vsj.dataptr = ptr_new(dvar)
     vsj.attrptr = ptr_new(vatt)
     
;Append the variables structure
     If(count Eq 0) Then vstr = vsj Else vstr = [vstr, vsj]
     count = count+1
  Endfor
     
  nvars = n_elements(vstr)
  natts = n_tags(global_att)+n_tags(vstr[0])

  inq = {ndims:0l, decoding:'HOST_DECODING', $
         encoding:'IBMPC_ENCODING', $
         majority:'ROW_MAJOR', maxrec:-1,$
         nvars:0, nzvars:nvars, natts:natts, dim:lonarr(1)}

;time resolution and UTC start and end
  If(num_dists Gt 0) Then Begin
     tres = 86400.0/num_dists
     tres = strcompress(string(tres, format = '(f8.1)'))+' sec'
  Endif Else tres = '   0.0 sec'
  global_att.time_resolution = tres

  otp_struct = {filename:'', g_attributes:global_att, inq:inq, nv:nvars, vars:vstr}

;Create filename and call cdf_save_vars.
  If(keyword_set(directory)) Then Begin
     dir = directory
     If(~is_string(file_search(dir))) Then file_mkdir, dir
     temp_string = strtrim(dir, 2)
     ll = strmid(temp_string, strlen(temp_string)-1, 1)
     If(ll Ne '/' And ll Ne '\') Then temp_string = temp_string+'/'
     dir = temporary(temp_string)
  Endif Else dir = './'
  
;What type of data
  If(keyword_set(esa_type)) Then Begin
     ext = strlowcase(strcompress(/remove_all, esa_type[0])) 
  Endif Else Begin
     type_test = strlowcase(strcompress(/remove_all, cmn_dat.data_name))
     Case type_test Of
        'iesasurvey': ext = 'ies'
        'iesaburst': ext = 'ieb'
        'eesasurvey': ext = 'ees'
        'eesaburst': ext = 'eeb'
        Else: ext = 'oops'
     Endcase
  Endelse        

;date here, uses the median
  date = time_string(median(center_time), precision=-3, format=6)
  orb_string = string(long(cmn_dat.orbit_start), format = '(i5.5)')
  file0 = 'fa_l2_'+ext+'_'+date+'_'+orb_string+'_'+sw_vsn_str+'.cdf'
  fullfile0 = dir+file0
  
  otp_struct.g_attributes.data_type = 'l2_'+ext+'>Level 2 data: '+cmn_dat.data_name
  otp_struct.g_attributes.logical_file_id = file0
  otp_struct.g_attributes.logical_source = 'fa_l2_'+ext
;save the file -- full database management
  dummy = cdf_save_vars2(otp_struct, fullfile0, /no_file_id_update)


  Return
End
