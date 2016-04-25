;+
;Procedure:
;  mms_cotrans_qrotate
;
;Purpose:
;  Perform a quaternion rotation on a tplot variable 
;
;Calling Sequence:
;  mms_cotrans_qrotate, name_in, quaternion_name [,name_out] [,inverse=inverse]
;
;Input:
;  name_in:  Tplot variable to be transformed
;  quaternion_name:  Tplot variable containing MMS rotation quaternion
;  name_out:  New name for output variable, if not specified the original is overwritten
;  inverse:  Flag to apply inverse rotation
;  
;Output:
;  none, may alter or create new tplot variable
;
;Notes:
;  -MMS quaternion naming convention reflects an INVERSE (left handed) rotation
;     e.g.  a default (right handed) rotation using "...eci_to_gse" is a GSE->ECI rotation
;  -This routine does not alter metadata
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-12 19:27:23 -0800 (Fri, 12 Feb 2016) $
;$LastChangedRevision: 19988 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_cotrans_qrotate.pro $
;-

pro mms_cotrans_qrotate, name_in, q_name, name_out, inverse=inverse

    compile_opt idl2, hidden


get_data, name_in, ptr=data_ptr, dl=dl, lim=l

get_data, q_name, ptr=q_ptr

if ~is_struct(data_ptr) || dimen2(*data_ptr.y) ne 3 then begin
  dprint, dlevel=0, '"'+name_in+'" is not a 3-vector; cannot transform'
  return
endif

if ~is_struct(q_ptr) ||  dimen2(*q_ptr.y) ne 4 then begin
  dprint, dlevel=0, '"'+q_name+'" is not a valid quaternion; transform canceled'
  return
endif

;interpolate quaternions to data resolution
;  -MMS quaternions are stored <x,y,z,w> but general routines assume <w,x,y,z>
q = qslerp( shift(*q_ptr.y,0,1), *q_ptr.x, *data_ptr.x )

;pad vectors with extra element
data = [  [replicate(0.,n_elements(*data_ptr.x))], [*data_ptr.y]  ]

;rotate
;  default - right handed (qvq^-1)
;  inverse - left handed (q^-1vq)
if keyword_set(inverse) then begin
  data_out = qham( qconj(q), qham(data,q) )
endif else begin
  data_out = qham( q, qham(data,qconj(q)) )
endelse

;store output
if undefined(name_out) then name_out = name_in
store_data, name_out, data={x:*data_ptr.x, y:data_out[*,1:3]}, dl=dl, l=l


end