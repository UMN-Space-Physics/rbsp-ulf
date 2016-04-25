;+
; PROCEDURE:
;         mms_eis_omni
;         
; PURPOSE:
;       Calculates the omni-directional flux for all 6 telescopes
;
; NOTES:
;       Originally based on Brian Walsh's EIS code from 7/29/2015
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-01-08 08:43:59 -0800 (Fri, 08 Jan 2016) $
;$LastChangedRevision: 19693 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/eis/mms_eis_omni.pro $
;-

pro mms_eis_omni, probe, species = species, datatype = datatype, tplotnames = tplotnames, suffix = suffix, data_units = data_units, data_rate = data_rate
  ; default to electrons
  if undefined(species) then species = 'electron'
  if undefined(datatype) then datatype = 'electronenergy'
  if undefined(suffix) then suffix = ''
  if undefined(data_units) then data_units = 'flux'
  if undefined(data_rate) then data_rate = 'srvy'
  units_label = data_units eq 'flux' ? '#/(cm!U2!N-sr-s-keV)' : 'Counts/s'
  ; 10 - 50 keV for PHxTOF data
  ; 40 - 1000 keV for ExTOF and electron data
  en_range = datatype eq 'phxtof' ?  [9., 50.] : [40., 1000.]

  probe = strcompress(string(probe), /rem)
  species_str = datatype+'_'+species
  if (data_rate) eq 'brst' then prefix = 'mms'+probe+'_epd_eis_brst_' else prefix = 'mms'+probe+'_epd_eis_'
  get_data, prefix+species_str+'_'+data_units+'_t0'+suffix, data = d, dlimits=dl

  if is_struct(d) then begin
    flux_omni = dblarr(n_elements(d.x),n_elements(d.v))
    for i=0, 5 do begin ; loop through each detector
      get_data, prefix+species_str+'_'+data_units+'_t'+STRTRIM(i, 1)+suffix, data = d
      flux_omni = flux_omni + d.Y
    endfor
    newname = prefix+species_str+'_'+data_units+'_omni'+suffix
    store_data, newname, data={x:d.x, y:flux_omni/6., v:d.v}, dlimits=dl

    options, newname, ylog = 1, spec = 1, yrange = en_range, $
      ytitle = 'MMS'+probe+' EIS '+species, ysubtitle='Energy [keV]', ztitle=units_label, ystyle=1, /default, minzlog = .01
    zlim, newname, 0., 0., 1.
    append_array, tplotnames, newname
    ; degap the data
    tdegap, newname, /overwrite
  endif
end