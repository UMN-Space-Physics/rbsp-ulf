;+
;Procedure:
;  spd_pgs_make_theta_spec
;
;Purpose:
;  Builds theta (latitudinal) spectrogram from simplified particle data structure.
;
;
;Input:
;  data: single sanitized data structure
;
;
;Input/Output:
;  spec: The spectrogram (ny x ntimes)
;  yaxis: The y axis (ny OR ny x ntimes)
;  
;  -Each time this procedure runs it will concatenate the sample's data
;   to the SPEC variable.
;  -Both variables will be initialized if not set
;  -The y axis will remain a single dimension until a change is detected
;   in the data, at which point it will be expanded to two dimensions.
;
;
;Notes:
;  -Assumes theta values are exact and constant across energy
;  -Assumes bins do not overlap
;
;
;History:
;  2016-01-20: Changed algorithm to allow ungrouped theta values (~8% slower now)
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-01-20 10:57:13 -0800 (Wed, 20 Jan 2016) $
;$LastChangedRevision: 19765 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_make_theta_spec.pro $
;-


pro spd_pgs_make_theta_spec, data, spec=spec, sigma=sigma, yaxis=yaxis, _extra=ex

    compile_opt idl2, hidden
  
  
  if ~is_struct(data) then return
  
  
  dr = !dpi/180.
  rd = 1/dr
  
  enum = dimen1(data.energy)
  anum = dimen2(data.energy)

  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  
  ;get unique theta values
  values = data.theta[0,uniq( data.theta[0,*], sort(data.theta[0,*]) )]

  ;init this sample's piece of the spectrogram
  ave = replicate(!values.f_nan, n_elements(values))
  ave_s = ave
  nbins = fltarr(n_elements(values))
  
  ;loop over each unique theta to sum all active data 
  ;and bin flags for that value
  ;  -assumes theta constant across energy
  for i=0, n_elements(values)-1 do begin
    idx = where(data.theta[0,*] eq values[i])
    ave[i] = total( d[*,idx] )
    ave_s[i] = total( d[*,idx] * data.scaling[*,idx])
    nbins[i] = total( data.bins[*,idx] )
  endfor

  ;divide by total active bins to get average
  ave = ave / nbins
  ave_s = sqrt(ave_s / nbins^2)
  

  ;get values for the y axis
  y = values
  
  ;sort y axis and data
  s = sort(y)
  ave = ave[s]
  ave_s = ave_s[s]
  y = y[s]


  ;set the y axis
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    spd_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse
  
  
  ;concatenate spectra
  if undefined(spec) then begin
    spec = ave
  endif else begin
    spd_pgs_concat_spec, spec, ave
  endelse 
  
  
  ;concatenate standard deviation
  if undefined(sigma) then begin
    sigma = temporary(ave_s)
  endif else begin
    spd_pgs_concat_spec, sigma, ave_s
  endelse 

end