;+
;Procedure:
;  mms_cotrans_qtransformer
;
;Purpose:
;  Helps simplify transformation logic code using a recursive formulation.
;  Rather than specifying the set of transformations for each combination of
;  in_coord & out_coord, this routine will perform only the nearest transformation
;  then make a recursive call to itself, with each call performing one additional
;  step in the chain.  This makes it so only neighboring coordinate transforms
;  need be specified.
;
;  The set of possible transformations forms the following graph:
;         GSE<->ECI<->GSE2000
;                |
;         GSM<->ECI<->SM
;                |
;         BCS<->ECI<->GEO
;
;Input:
;  in_name:  name ofvariable to be transformed
;  out_name:  output name for transformed variable
;  in_coord:  coordinate system of the input
;  out_coord:  coordinate system of the output
;  probe:  probe designation for input variable
;
;Output:
;  No explicit output, calls transformation routines and itself
;
;Notes:
;  Modeled after thm_cotrans_transform_helper
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2016-02-12 19:27:23 -0800 (Fri, 12 Feb 2016) $
;$LastChangedRevision: 19988 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/mms_cotrans_qtransformer.pro $
;-

pro mms_cotrans_qtransformer, $

  ; names and coords
  in_name, $
  out_name, $
  in_coord, $
  out_coord, $
  probe, $

  ; other
  ignore_dlimits=ignore_dlimits


  compile_opt idl2, hidden


  ; Final coordinate system reached
  ;------------------------------------------------
  if in_coord eq out_coord then begin
    if in_name ne out_name then begin
      copy_data, in_name, out_name
    endif
    return
  endif


  ; Execute next step in transformation tree
  ;   -everything goes through ECI at the moment, so this is very simple
  ;   -MMS quaternion naming convention reflects an INVERSE (left handed) rotation
  ;      e.g.  a default (right handed) rotation using "...eci_to_gse" is a GSE->ECI rotation
  ;------------------------------------------------
  case in_coord of

    ; ECI
    ;----------
    'eci': begin
      if in_set(out_coord[0],['bcs','gse','gse2000','gsm','sm','geo']) then begin
        q_name = 'mms'+probe+'_mec_quat_eci_to_'+out_coord
        spd_cotrans_validate_transform, in_name, in_coord, out_coord
        mms_cotrans_qrotate, in_name, q_name, out_name, /inverse
        recursive_in_coord = out_coord
      endif else begin
        dprint, dlevel=0, sublevel=1, 'Unknown transformation: "'+ in_coord+'" to "'+out_coord+'"'
        recursive_in_coord = out_coord
      endelse
    end


    ; Other
    ;---------------------------
    else: begin
      if in_set(in_coord[0],['bcs','gse','gse2000','gsm','sm','geo']) then begin
        q_name = 'mms'+probe+'_mec_quat_eci_to_'+in_coord
        spd_cotrans_validate_transform, in_name, in_coord, out_coord
        mms_cotrans_qrotate, in_name, q_name, out_name
        recursive_in_coord = 'eci'
      endif else begin
        dprint, dlevel=0, sublevel=1, 'Unknown transformation: "'+ in_coord+'" to "'+out_coord+'"'
        recursive_in_coord = out_coord
      endelse
    endelse

  endcase


  ; Recurse
  ;   -if this was the final step then the next iteration will return
  ;------------------------------------------------
  mms_cotrans_qtransformer,$
    out_name, $  ;don't create new vars as we iterate
    out_name, $
    recursive_in_coord, $  ;result of this iteration
    out_coord, $
    probe, $
    ignore_dlimits=ignore_dlimits

end