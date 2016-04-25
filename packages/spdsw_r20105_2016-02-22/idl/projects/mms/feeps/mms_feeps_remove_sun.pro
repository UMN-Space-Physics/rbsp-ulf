;+
; PROCEDURE:
;       mms_feeps_remove_sun
;
; PURPOSE:
;       Removes the sunlight contamination from FEEPS data
;
; NOTES:
;       Will only work in IDL 8.0+, due to the hash table data structure
;     
;       Originally based on code from Drew Turner, 2/1/2016
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-02-17 14:30:36 -0800 (Wed, 17 Feb 2016) $
; $LastChangedRevision: 20052 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_remove_sun.pro $
;-

pro mms_feeps_remove_sun, probe = probe, datatype = datatype, data_units = data_units, data_rate = data_rate, suffix = suffix
    if undefined(data_units) then data_units = 'flux'
    if undefined(suffix) then suffix = ''
    if undefined(data_rate) then data_rate = 'srvy'
    if undefined(datatype) then datatype = 'electron'
    if undefined(probe) then probe = '1'
    
    
    ; the following works for srvy mode, but doesn't get all of the sensors for burst mode
    if datatype eq 'electron' then sensors = ['3', '4', '5', '11', '12'] else sensors = ['6', '7', '8']
  
    ; special case for burst mode data
    if data_rate eq 'brst' && datatype eq 'electron' then sensors = ['1','2','3','4','5','9','10','11','12']
    if data_rate eq 'brst' && datatype eq 'ion' then sensors = ['6','7','8']

    ; get the sector data
    get_data, 'mms'+probe+'_epd_feeps_spinsectnum'+suffix, data=spin_sector
    
    ; get the sector masks
    mask_sectors = mms_feeps_sector_masks()
    
    for data_units_idx = 0, n_elements(data_units)-1 do begin
        these_units = data_units[data_units_idx]
        
        if these_units eq 'cps' then these_units = 'count_rate'
        
        ; top sensors
        for sensor_idx = 0, n_elements(sensors)-1 do begin
          var_name = 'mms'+probe+'_epd_feeps_top_'+these_units+'_sensorID_'+sensors[sensor_idx]+suffix
          get_data, var_name, data = top_data, dlimits=top_dlimits
          if mask_sectors.haskey('mms'+probe+'imaskt'+sensors[sensor_idx]) && mask_sectors['mms'+probe+'imaskt'+sensors[sensor_idx]] ne !NULL then begin
            bad_sectors = mask_sectors['mms'+probe+'imaskt'+sensors[sensor_idx]]
    
            for bad_sector_idx = 0, n_elements(bad_sectors)-1 do begin
              this_bad_sector = where(spin_sector.Y eq bad_sectors[bad_sector_idx], bad_sect_count)
              if bad_sect_count ne 0 then top_data.Y[this_bad_sector, *] = !values.d_nan
            endfor
          endif
    
          ; resave the data, with the sunlight contamination removed
          store_data, var_name, data=top_data, dlimits=top_dlimits
        endfor
    
        ; bottom sensors
        for sensor_idx = 0, n_elements(sensors)-1 do begin
          var_name = 'mms'+probe+'_epd_feeps_bottom_'+these_units+'_sensorID_'+sensors[sensor_idx]+suffix
          get_data, var_name, data = bottom_data, dlimits=bottom_dlimits
          if mask_sectors.haskey('mms'+probe+'imaskb'+sensors[sensor_idx]) && mask_sectors['mms'+probe+'imaskb'+sensors[sensor_idx]] ne !NULL then begin
            bad_sectors = mask_sectors['mms'+probe+'imaskb'+sensors[sensor_idx]]
    
            for bad_sector_idx = 0, n_elements(bad_sectors)-1 do begin
              this_bad_sector = where(spin_sector.Y eq bad_sectors[bad_sector_idx], bad_sect_count)
              if bad_sect_count ne 0 then bottom_data.Y[this_bad_sector, *] = !values.d_nan
            endfor
          endif
    
          ; resave the data, with the sunlight contamination removed
          store_data, var_name, data=bottom_data, dlimits=bottom_dlimits
        endfor
    endfor
  
end