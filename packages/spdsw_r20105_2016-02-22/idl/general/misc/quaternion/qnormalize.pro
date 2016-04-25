;+
;Function: qnormalize
;
;Purpose: normalize a quaternion or an array of quaternions
;
;Inputs: q: a 4 element array, or an Nx4 element array, representing quaternion(s)
;
;Returns: q/(sqrt(norm(q))) or -1L on fail
;
;Notes: Implementation largely copied from the euve c library for
;quaternions
;Represention has q[0] = scalar component
;                 q[1] = vector x
;                 q[2] = vector y
;                 q[3] = vector z
;
;The vector component of the quaternion can also be thought of as
;an eigenvalue of the rotation the quaterion performs
;
;
;Written by: Patrick Cruce(pcruce@igpp.ucla.edu)
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2007-11-11 17:12:08 -0800 (Sun, 11 Nov 2007) $
; $LastChangedRevision: 2027 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/cotrans/cotrans.pro $
;-

function qnormalize,q

compile_opt idl2

;this is to avoid mutating the input variable
qi = q

;check to make sure input has the correct dimensions
qi = qvalidate(qi,'q','qnormalize')

if(size(qi,/n_dim) eq 0 && qi[0] eq -1) then return,qi

qn = qnorm(qi)

;if norm fails
if(size(qn,/n_dim) eq 0 && qn[0] eq -1) then return,qi

qtmp0 = qi[*,0]/qn
qtmp1 = qi[*,1]/qn
qtmp2 = qi[*,2]/qn
qtmp3 = qi[*,3]/qn

qout = [[qtmp0],[qtmp1],[qtmp2],[qtmp3]]

;q[0] = cos(theta/2), so it _must_ be kept w/in domain of acos()

idx = where(qout[*,0] gt 1D)

if(idx[0] ne -1) then begin
   qout[idx,0] = 1D
   qout[idx,1:3] = 0D
endif

idx = where(qout[*,0] lt -1D)

if(idx[0] ne -1) then begin
   qout[idx,0] = -1D
   qout[idx,1:3] = 0D
endif

return,reform(qout)

end
