
;+
;Procedure:
;  spd_pgs_make_e_spec
;
;Purpose:
;  Builds energy spectrogram from simplified particle data structure.
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
;
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2016-01-04 15:38:57 -0800 (Mon, 04 Jan 2016) $
;$LastChangedRevision: 19672 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_part_products/spd_pgs_make_e_spec.pro $
;-

pro spd_pgs_make_e_spec, data, spec=spec, sigma=sigma, yaxis=yaxis, _extra=ex

    compile_opt idl2, hidden
  
  
  if ~is_struct(data) then return
  
  
  dr = !dpi/180.
  
  enum = dimen1(data.energy)
  anum = dimen2(data.energy)

  ;copy data and zero inactive bins to ensure
  ;areas with no data are represented as NaN
  d = data.data
  scaling = data.scaling
  idx = where(~data.bins,nd)
  if nd gt 0 then begin
    d[idx] = 0.
  endif
  
  ;weighted average to create spectrogram piece
  ;energies with no valid data should come out as NaN
  if anum gt 1 then begin
    ave = total(d,2) / total(data.bins,2)
    ave_s = sqrt(  total( d * scaling ,2) / total(data.bins,2)^2  )
  endif else begin
    ave = d / data.bins
    ave_s = sqrt(  ( d * scaling ) / data.bins^2  )
  endelse
  
  ;output the y-axis values
  ; *check for varying energy levels?
  y = data.energy[*,0]
  
  
  ;set y axis
  if undefined(yaxis) then begin
    yaxis = y
  endif else begin
    spd_pgs_concat_yaxis, yaxis, y, ns=dimen2(spec)
  endelse
  
  
  ;concatenate spectra
  if undefined(spec) then begin
    spec = temporary(ave)
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