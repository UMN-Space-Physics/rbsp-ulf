;+
;Procedure: mms_fpi_slice2d_rebin
;
;Purpose: creates a 2-D slice of the 3-D FPI ion or electron
;distribution function. Based on thm_esa_slice2d in the TDAS package
;

;Keywords:  SPECIES: 'i' or 'e' 
;           ROTATION: suggesting the x and y axis, which can be
;           specified as the followings (only work for GSE for now):
;             'BV': the x axis is V_para (to the magnetic field) and
;             the bulk velocity is in the x-y plane. (DEFAULT)
;             (Vpara-Vperp1 --Shan Wang)
;             'BE': the x axis is V_para (to the magnetic field) and
;             the VxB direction is in the x-y plane. (Vpara-Vperp2)
;             'xy': the x axis is V_x and the y axis is V_y.
;             'xz': the x axis is V_x and the y axis is V_z.
;             'yz': the x axis is V_y and the y axis is V_z.
;             'perp': the x-y plane is perpendicular to the B field, while the x axis is the velocity projection on the plane.

;             'lm': x: VL, y: VM
;             'ln': x:VL, y: VN
;             'mn': x:VM, y:VN
;           ANGLE: the lower and upper angle limits of the slice selected to plot (DEFAULT [-20,20]).
;           THIRDDIRLIM: the velocity limits of the slice. Once activated, the ANGLE keyword would be invalid..
;           FILETYPE: 'png' or 'ps'. (DEFAULT 'png')
;           OUTPUTFILE: the name of the output file.
;     THEBDATA: specifies magnetic data to use.
;     FINISHED: makes the output publication quality when using ps (NOT WORKING WELL). OBSELETE
;     VRANGE: vector specifying the vrange
;     ZRANGE: vector specifying the color range
;     ERANGE: specifies the energy range to be used
;     UNITS: specifies the units ('eflux','df',etc.) (Def. is 'df')
;     NOZLOG: specifies a linear Z axis
;     POSITION: positions the plot using a 4-vector
;     NOFILL: doesn't fill the contour plot with colors
;     NLINES: says how many lines to use if using NOFILL (DEFAULT 60, MAX 60)
;     NOOLINES: suppresses the black contour lines
;     NUMOLINES: how many black contour lines (DEFAULT 20, MAX 60)
;           REMOVEZERO: removes the data with zero counts for plotting
;     SHOWDATA: plots all the data points over the contour OBSELETE
;     VEL: tplot variable containing the velocity data
;          (default is calculated with v_3d)
;     NOGRID: forces no triangulation
;     NOSMOOTH: suppresses smoothing (IF NOT SET, DEFAULT IS SMOOTH)
;     NOSUN: suppresses the sun direction line
;     NOVELLINE: suppresses the velocity line
;           SUBTRACT: subtract the bulk velocity before plot
;     RESOLUTION: resolution of the mesh (DEFAULT 51)
;     RMBINS: removes the sun noise by cutting out certain bins
;     THETA: specifies the theta range for RMBINS (def 20)
;     PHI: specifies the phi range for RMBINS (def 40)
;     NR: removes background noise from ph using noise_remove
;     NOISELEVEL: background level in eflux
;     BOTTOM: level to set as min eflux for background. def. is 0.
;     SR, RS, RM2: removes the sun noise using subtraction
;       REQUIRES write_ph.doc to run
;     NLOW: used with rm2.  Sets bottom of eflux noise level
;       def. 1e4
;     M: marks the tplot at the current time
;     thevel2: takes a 3-vector velocity and puts it on the plot
;CREATED BY:    Arjun Raj
;EXAMPLES:  see the crib file: themis_cut_crib.pro
;REMARKS:   when calling with phb and rm2, use file='write_phb.doc'
;     also, set the noiselevel to 1e5.  This gives the best
;     results
;
;                       coord: 'gse','gsem','lmn','dsc','fac'
;                       inv_rot: tplot name for the matrix between dsc
;                       and requested coord sys.
;                       matrix format:1x3x3, rot[0,0,*]=L, etc.
;                       noerase: used for multi-panels
;                       closefile: used for the last panel of
;                       multi-panel plots
;                       nob: not to plot the B direction
;                       zcut: cut velocity in the third direction,
;                       either a number of 'bulk', default:0
;thm_esa_slice2d LAST EDITED BY XUZHI ZHOU 4-24-2008
;
;add lmn_rot keyword and corresponding rotation keywords, change
;ytitles, add keywords of noerase,closefile,nob,zcut   -Shan Wang
;09/25/2014
;mms_fpi_slice2d created on 07/09/2015 --Shan Wang
;add keyword of data_resolution 8/24/2015
;reconstruct regular vpara vperp bins 9/4/2015

pro mms_fpi_slice2d_regbin,sat,$
                           current_time,$
                           timeinterval,$
                           species=species,$
                           rotation = rotation,$
                           angle = angle,$
                           ThirdDirlim = ThirdDirlim,$
                           filetype = filetype,$
                           outputfile = outputfile,$
                           thebdata = thebdata,$
                           finished = finished,$
                           vrange = vrange,$
                           zrange = zrange,$
                           erange = erange,$
                           units = units,$
                           nozlog = nozlog,$
                           position = position,$
                           nofill = nofill,$
                           nlines = nlines,$
                           noolines = noolines,$
                           numolines = numolines,$
                           removezero = removezero,$
                           showdata = showdata,$
                           vel=vel,$
                           nogrid=nogrid,$
                           nosmooth=nosmooth,$
                           nosun = nosun,$
                           nob=nob,$
                           novelline = novelline,$
                           subtract = subtract,$
                           resolution = resolution,$
                           theta = theta,$
                           phi = phi,$
                           nr = nr,$
                           noiselevel = noiselevel,$
                           bottom = bottom,$
                           sr = sr,$
                           rs = rs,$
                           rm2=rm2,$
                           nlow = nlow,$
                           m = m,$
                           thevel2 = thevel2,$
                           phb = phb,$
                           filename = filename,$
                           _EXTRA = e,$
                           inv_rot=inv_rot,$
                           coord=coord,$
                           noerase=noerase,$
                           closefile=closefile,$
                           zcut=zcut,$
                           data_resolution=data_resolution,$
                           method_reduce=method_reduce,$
                           cross=cross,$
                           ang_range_cross=ang_range_cross,$
                           fig_dim = fig_dim,$
                           nocolbar=nocolbar,$
                           notitle=notitle,$
                           theedata = theedata

;!p.charsize=1

if not keyword_set(filetype) then filetype='png'
if ~keyword_set(coord) then coord='fac'

if keyword_set(removezero) then leavezero=0 else leavezero=1

;cross=0

;if keyword_set(phb) then filename = 'write_phb.doc'

thedata = call_function('get_fpi_3dflux_2dbin',sat,species,time=current_time,$
                       dur=timeinterval,/ave,resolution=data_resolution,units_name=units)

thedata3 = thedata
bins_2d=fltarr(thedata.nenergy,thedata.nbins)
for i=0,thedata.nbins-1 do begin
;    bins_2d(*,i)=thedata.bins(i)
    bins_2d(*,i)=thedata.bins(*,i)
endfor

;if keyword_set(rmbins) then begin
; dprint,  'Removing bins (bin_remove)'
; thedata = bin_remove(thedata,theta=theta,phi = phi)
;endif ;else thedata = thedata2;;

;if keyword_set(sr) then rm2 = 1
;if keyword_set(rs) then rm2 = 1
;if keyword_set(nofill) then noolines = 1;

;if keyword_set(rm2) then begin
; dprint,  'Removing bins (bin_remove2)'
; leavezero = 1
; if not keyword_set(nosmooth) then nosmooth = 0
; ;nr = 1
; load_ph,new,filename = filename
; thedata = bin_remove2(thedata,theta = theta,phi = phi,new= new,nlow = nlow)
;endif ;else thedata = thedata2


;if keyword_set(nr) then begin
; dprint, 'Removing Noise'
;;dprint,  noiselevel
; thedata = noise_remove(thedata,nlevel=noiselevel,bottom = bottom)
; leavezero = 1
;endif

if keyword_set(m) then $
  new_time,'cut2d',thedata.time

numperrow=4

;MODIFICATIONS TO MAKE COMMAND LINE SMALLER

if not keyword_set(ThirdDirLim) and not keyword_set(angle) then angle = [-20.,20.]

if not keyword_set(nozlog) then zlog = 1
if not keyword_set(nogrid) then grid = 1

if not keyword_set(nosmooth) then smooth = 1
if not keyword_set(noolines) then begin
  if keyword_set(numolines) then olines = numolines else olines = 20
  endif
if not keyword_set(subtract) then nosubtract = 1
if not keyword_set(nosun) then sundir = 1
if ~keyword_set(nob) then bdir=1

if keyword_set(zlog) then dprint, 'zl'
if keyword_set(grid) then dprint, 'grid'
if keyword_set(cross) then dprint, 'cross'
if keyword_set(smooth) then dprint, 'smooth'
if keyword_set(olines) then dprint, 'olines'

if not keyword_set(units) then units = 'df'
if not keyword_set(nlines) then nlines = 70

if not keyword_set(rotation) then rotation='BV'

if ~keyword_set(method_reduce) then begin
   if keyword_set(angle) then begin
      if max(angle) eq 90 then method_reduce='sum' else $
         method_reduce = 'ave'
   endif else begin
      method_reduce='sum'
   endelse
endif

if ~keyword_set(noerase) then begin
  if ~keyword_set(fig_dim) then fig_dim=[600,800]
  loadct,34
  tvlct,r,g,b,/get
  r[0]=0 & g[0]=0 & b[0]=0
  r[255]=255 & g[255]=255 & b[255]=255
  tvlct,r,g,b
if filetype eq 'ps' then begin
    SET_PLOT, 'PS'
    popen,outputfile,/encap,land=(fig_dim[0] gt fig_dim[1])
    !p.font=0
    ;loadct,39
    ;DEVICE, FILENAME=outputfile+'.ps',/color,bits_per_pixel=8,/Times
 endif
if filetype eq 'png' then begin
   set_plot,'Z'
   device,decomposed=0,set_pixel_depth=24,set_resolution=fig_dim
   ;loadct,39
   !P.background=255
   !P.color=0
   !P.font=0
   erase
endif
if filetype eq 'x' then begin
   set_plot,'x'
   device,decomposed=0
   ;loadct,39
   !P.background=255
   !P.color=0
   window,0,xsize=fig_dim[0],ysize=fig_dim[1]
   !P.font=-1
endif
if filetype eq 'win' then begin
   set_plot,'win'
   device,decomposed=0
   ;loadct,39
   !P.background=255
   !P.color=0
   window,0,xsize=fig_dim[0],ysize=fig_dim[1]
   !P.font=-1
endif
endif

;END MODIFICATiONS


perpsym = byte(94)
perpsymbol = string(perpsym)

parasym = byte(47)
parasymbol = string(parasym) + string(parasym)



;if keyword_set(finished) and units eq 'df' then thedata.data = thedata.data / 1000.  ;changing units to
                  ;s^-3 m^-6

;if keyword_set(finished) and keyword_set(plotlabel) and !d.name eq 'PS' then begin
; device,/bold
; xyouts, 0.0,.95,plotlabel+'!N!7',/normal
;endif


;if !d.name eq 'PS' then loadct,39

if not keyword_set(resolution) then resolution = 51
if resolution mod 2 eq 0 then resolution = resolution + 1

oldplot = !p.multi

if keyword_set(cross) then begin ;and  !d.name ne 'PS' then begin
  !p.multi = [0,2,1]
  grid = 1
endif

;if not keyword_set(vel) then vel = 'v_3d_ph'

if not keyword_set(position) then begin
  x_size = !d.x_size & y_size = !d.y_size
  xsize = .77
  yoffset = 0.
  d=1.
  if keyword_set(cross) then begin
    yoffset = yoffset + .5
    xsize = xsize/2.+.13/1.5
    y_size = y_size/2.
    x_size = x_size/2.
    d = .5
    if y_size le x_size then $
      pos2 = [.13*d+.1,.03+.13*d,.1+.13*d + xsize * y_size/x_size,.13*d + xsize+.03] else $
      pos2 = [.13*d+.1,.03+.13*d,.1+.13*d + xsize,.13*d + xsize *x_size/y_size+.03]

  endif
  if y_size le x_size then $
    position = [.13*d+.1,.13*d+yoffset,.1+.13*d + xsize * y_size/x_size,.13*d + xsize + yoffset] else $
    position = [.13*d+.1,.13*d+yoffset,.1+.13*d + xsize,.13*d + xsize *x_size/y_size + yoffset]
endif else begin
  if not keyword_set(pos2) then begin
    pos2 = position
    pos2(0) = position(0)
    pos2(2) = position(2)
    pos2(3) = position(1)-.08
    pos2(1) = .1
  endif
endelse

;;;theonecnt = thedata

;*************************to be added*******
;thedata = conv_units(thedata,units)


;stop

;thedata.data(*,120)=0


;theonecnt = conv_units(theonecnt,'counts')
;for i = 0,theonecnt.nenergy-1 do theonecnt.data(i,*) = 1
;theonecnt = conv_units(theonecnt,units)
;if theonecnt.units_name eq 'Counts' then theonecnt.data(*,*) = 1.

;**********************************************
;bad_bins=where((thedata.dphi eq 0) or (thedata.dtheta eq 0) or $
; ((thedata.data(0,*) eq 0.) and (thedata.theta(0,*) eq 0.) and $
; (thedata.phi(0,*) eq 180.)),n_bad)
;good_bins=where(((thedata.dphi ne 0) and (thedata.dtheta ne 0)) and not $
; ((thedata.data(0,*) eq 0.) and (thedata.theta(0,*) eq 0.) and $
; (thedata.phi(0,*) eq 180.)),n_good)

;if n_bad ne 0 then print,'There are bad bins'


;if thedata.valid ne 1 then begin;
; dprint, 'Not valid data'
; return
;endif

;bad120 = where(good_bins eq 120,count)
;if count eq 1 and thedata.data_name eq 'Pesa High' then begin
; print, 'Fixing bad 120 bin'
; if n_bad eq 0 then bad_bins = [120] else bad_bins = [bad_bins,120]
; good_bins = good_bins(where(good_bins ne 120))
; n_bad = n_bad + 1
; n_good = n_good -1
;endif



;*****************************

;In order to find out how many particles there are at all the different locations,
;we must transform the data into cartesian coordinates.


totalx = fltarr(1) & totaly = fltarr(1) & totalz = fltarr(1)
ncounts = fltarr(1)
all_theta = fltarr(1) & all_phi = fltarr(1)
all_dtheta=fltarr(1) & all_dphi=fltarr(1)
all_energy=fltarr(1) & all_denergy=fltarr(1)

if not keyword_set(erange) then begin
  erange = [thedata.energy(thedata.nenergy-1,0),thedata.energy(0,0)]
  erange = [min(thedata.energy), max(thedata.energy)]
  eindex = indgen(thedata.nenergy)
endif else begin
  eindex = where(thedata.energy(*,0) ge erange(0) and thedata.energy(*,0) le erange(1))
  erange = [min(thedata.energy(eindex,0)),max(thedata.energy(eindex,0))]
endelse


;stop

mass = thedata.mass/6.2508206e24

for i = 0, thedata.nenergy-1 do begin
  currbins = where(bins_2d(i,*) ne 0 and thedata.energy(i,*) le erange(1) and thedata.energy(i,*) ge erange(0) and finite(thedata.data(i,*)) eq 1,nbins)

  if nbins ne 0 then begin
;   print, i
    x = fltarr(nbins) & y = fltarr(nbins) & z = fltarr(nbins)
    sphere_to_cart,1,reform(thedata.theta(i,currbins)),reform(thedata.phi(i,currbins)),x,y,z
    totalx = [totalx, x * reform(sqrt(2*1.6e-19*thedata.energy(i,currbins)/mass))]
    totaly = [totaly, y * reform(sqrt(2*1.6e-19*thedata.energy(i,currbins)/mass))]
    totalz = [totalz, z * reform(sqrt(2*1.6e-19*thedata.energy(i,currbins)/mass))]

    ncounts = [ncounts,reform(thedata.data(i, currbins))]

    all_theta = [all_theta,reform(thedata.theta[i,currbins])]
    all_phi = [all_phi,reform(thedata.phi[i,currbins])]
    all_dtheta = [all_dtheta,reform(thedata.dtheta[i,currbins])]
    all_dphi = [all_dphi,reform(thedata.dphi[i,currbins])]
    all_energy= [all_energy,reform(thedata.energy[i,currbins])]
    all_denergy=[all_denergy,reform(thedata.denergy[i,currbins])]
 endif
endfor

totalx = totalx(1:*)
totaly = totaly(1:*)
totalz = totalz(1:*)
ncounts = ncounts(1:*)
all_theta = all_theta[1:*]*!DTOR
all_phi = all_phi[1:*]*!DTOR
all_dtheta = all_dtheta[1:*]*!DTOR
all_dphi = all_dphi[1:*]*!DTOR
;set domega
Const = (thedata.mass)^(-1.5)*(2.)^(.5)*1.0e15
if thedata.units_name eq 'counts' then begin
   domega = all_phi
   domega[*] = 1.0
   weight = domega
endif else begin
   domega=2.*all_dphi*cos(all_theta)*sin(0.5*all_dtheta)
   weight = const*sqrt(all_energy)*all_denergy*domega
endelse


;*****HERES SOMETHING NEW
;sto
newdata = {dir:fltarr(n_elements(totalx),3), n:fltarr(n_elements(totalx))}

newdata.dir(*,0) = totalx
newdata.dir(*,1) = totaly
newdata.dir(*,2) = totalz
newdata.n = ncounts

;stop


;
if keyword_set(thebdata) then begin
bfield = dat_avg(thebdata, thedata.time, thedata.end_time)
bfield = bfield[0:2]
endif else begin
bfield = thedata.magf
endelse
;dprint,  'BFIELD is ',bfield

;dprint,  'All data interpolated to ' + time_string(mgf.x)
if keyword_set(theedata) then begin
   efield=dat_avg(theedata,thedata.time,thedata.end_time)
endif


if keyword_set(nosubtract) then dprint, 'No velocity transform' else begin
  if keyword_set(vel) then print,'Velocity used for subtraction is '+vel else dprint,  'Velocity used for subtraction is V_3D'
endelse


if keyword_set(vel) then begin
  dprint, 'Using '+vel+' for velocity vector'

  thevel = 1000. * dat_avg(vel, thedata3(0).time, thedata.end_time)

  factor = 1.
endif else begin
  dprint,  'Calculating V with v_3d_tmp...';using df in unit of s^3/cm^6
  thevel = 1000. * v_3d_tmp(thedata)
; thevel = 0.01 * j_3d(thedata)/n_3d(thedata)
; for in=0,inumber do begin
;   if in eq 0 then begin
;   flux=j_3d(thedata3(0))
;   density=n_3d(thedata3(0))
;   endif else begin
;     flux=flux+j_3d(thedata3(in))
;     density=density+n_3d(thedata3(in))
;   endelse
; endfor
; thevel = 0.01 * flux/density
  factor = 1.
endelse
print,'bulk vel (km/s): ',thevel/1000

if not keyword_set(nosubtract) then begin
  newdata.dir(*,0) = newdata.dir(*,0) - thevel(0)*factor
  newdata.dir(*,1) = newdata.dir(*,1) - thevel(1)*factor
  newdata.dir(*,2) = newdata.dir(*,2) - thevel(2)*factor
endif else begin
   newdata.dir(*,0) = newdata.dir(*,0)
   newdata.dir(*,1) = newdata.dir(*,1)
   newdata.dir(*,2) = newdata.dir(*,2)
endelse





;**************NOW CONVERT TO THE DATA SET REQUIRED*****************
if coord ne 'fac' then begin
   if coord ne 'dsc' then begin
      get_data,inv_rot,data=drot
      rotinv=fltarr(3,3)
      case rotation of
         'xy':begin
            rotinv[0,*]=drot.y[0,0,*]
            rotinv[1,*]=drot.y[0,1,*]
            rotinv[2,*]=drot.y[0,2,*]
         end
         'xz':begin
            rotinv[0,*]=drot.y[0,0,*]
            rotinv[1,*]=drot.y[0,2,*]
            rotinv[2,*]=-drot.y[0,1,*]
         end
         'yz':begin
            rotinv[0,*]=drot.y[0,1,*]
            rotinv[1,*]=drot.y[0,2,*]
            rotinv[2,*]=drot.y[0,0,*]
         end
      endcase
         rot=invert(rotinv)
      endif else begin
      case rotation of
         'xy':begin
            rot=cal_rot([1,0,0],[0,1,0])
         end
         'xz':begin
            rot=cal_rot([1,0,0],[0,0,1])
         end
         'yz':begin
            rot=cal_rot([0,1,0],[0,0,1])
         end
      endcase
      endelse
endif

if ~keyword_set(efield) then begin
   if rotation eq 'BV' then rot=cal_rot(bfield,thevel)
   if rotation eq 'BE' then rot=cal_rot(bfield,crossp(bfield,thevel))
endif else begin
   if rotation eq 'BV' then rot=cal_rot(bfield,crossp(efield,bfield))
   if rotation eq 'BE' then rot=cal_rot(bfield,efield)
endelse
;if rotation eq 'xy' then rot=cal_rot([1,0,0],[0,1,0])
;if rotation eq 'xz' then rot=cal_rot([1,0,0],[0,0,1])
;if rotation eq 'yz' then rot=cal_rot([0,1,0],[0,0,1])
if rotation eq 'xvel' then rot=cal_rot([1,0,0],thevel)
if rotation eq 'perp' then begin
   if ~keyword_set(efield) then begin
      rot=cal_rot(crossp(crossp(bfield,thevel),bfield),crossp(bfield,thevel))
   endif else begin
      rot = cal_rot(crossp(efield,bfield),crossp(bfield,crossp(efield,bfield)))
   endelse
endif


newdata.dir = newdata.dir#rot
factor = 1000.
;vperp = (newdata.dir(*,1)^2 + newdata.dir(*,2)^2)^.5*newdata.dir(*,1)/abs(newdata.dir(*,1))/factor
vperp = newdata.dir(*,1)/factor
vpara = newdata.dir(*,0)/factor
vperp2= newdata.dir(*,2)/factor
zdata = newdata.n

;**********************

if keyword_set(sundir) then begin
  sund = [1,0,0]
  sund = sund#rot
  vperpsun = (sund(1)^2 + sund(2)^2)^.5*sund(1)/abs(sund(1))
  vparasun = sund(0)
endif

if keyword_set(bdir) then begin
  bd = bfield/norm(bfield)
  bd = bd#rot
  vperpb = bd[1]
  vparab = bd(0)
endif

veldir = thevel/1000.
veldir = veldir#rot
print,'vel in requested coord: ',veldir

;construct regular bins
;nv1d = ceil(sqrt(thedata.nbins*thedata.nenergy)/2.0)
ebin = [thedata.energy[0,0]-thedata.denergy[0,0]*0.5,thedata.energy[*,0]+thedata.denergy[*,0]*0.5]
vbin = reform(sqrt(2*1.6e-19*ebin/mass))/1000.
;nphi=360./thedata.dphi[0,0]
nphi = 32
dphi = 360./nphi
;angbin = (findgen(nphi+1)*thedata.dphi[0,0]+0.5*thedata.dphi[0,0])*!DTOR
angbin = (findgen(nphi+1)*dphi+0.51*dphi)*!DTOR
;angbin = (findgen(nphi+1)*dphi)*!DTOR
oneang=fltarr(nphi+1)+1
onev = fltarr(thedata.nenergy+1)+1
vbins = vbin#oneang
angbins = onev#angbin
vpara_bin = vbins*cos(angbins)
vperp_bin = vbins*sin(angbins)
zimage = fltarr(thedata.nenergy+1,nphi+1)
;stop
;phi in range of 0-360
eachphi = atan(vperp/vpara)
ind1=where(vpara lt 0)
eachphi[ind1] = eachphi[ind1] + !pi
ind2=where(vpara gt 0 and vperp lt 0)
eachphi[ind2] = eachphi[ind2] + 2*!pi


ind3 = where(eachphi ge 0 and eachphi le angbin[0],cc)
if cc gt 0 then eachphi[ind3]+=2*!pi
    if ~keyword_set(zcut) then zcut_now=0.
    if data_type(zcut) eq 7 then begin
       if zcut eq 'bulk' then begin
          zcut_now=veldir[2]
       endif
    endif else zcut_now = zcut
    print,'Cut at velocity '+string(zcut_now,format='(f11.2)')+ $
          ' in the third direction'


  if ~keyword_set(ThirdDirLim) then begin
    zmag = vperp2

    r = sqrt(vpara^2 + vperp^2+vperp2^2)

    eachangle = asin((zmag-zcut_now)/r)
    angle1=min(angle)
    angle2=max(angle)

    phi1=0.
    for i=0,31 do phi1=[phi1,reform(thedata.phi[i,*])]
    phi1=phi1[1:*]
    theta1=0.
    for i=0,31 do theta1=[theta1,reform(thedata.theta[i,*])]
    theta1=theta1[1:*]
;stop    
    for iv=0,thedata.nenergy-1 do begin
       for iphi=0,nphi-1 do begin
          index = where(sqrt(vpara^2+vperp^2) gt vbin[iv] and sqrt(vpara^2+vperp^2) le vbin[iv+1] and $
                        eachphi gt angbin[iphi] and eachphi le angbin[iphi+1] and $
                      eachangle/!dtor le angle2 and eachangle/!dtor ge angle1,count)
        


        if count gt 0 then begin
           if method_reduce eq 'ave' then begin
              index1 = where(zdata[index] ge 0,cn0)
              ;only take the average over non-zero bins
              if cn0 gt 0 then $
              zimage[iv,iphi] = $
                 total(zdata[index[index1]]*weight[index[index1]])/$
                 total(weight[index[index1]])
           endif
           if method_reduce eq 'sum' then begin
              zimage[iv,iphi] = total(zdata[index]*weight[index],/nan)
           endif
        endif

        ;if rotation eq 'zx' and iv eq 18 then begin
        ;   print,angbin[iphi]/!DTOR,count
        ;   print,'eachphi:'
        ;   print,eachphi[index]/!DTOR
        ;   print,'eachangle'
        ;   print,eachangle[index]/!DTOR
        ;   print,'phi'
        ;   print,phi1[index]
        ;   print,'theta'
        ;   print,theta1[index]
        ;   print,'----------------------'
        ;   ;stop
        ;endif
     endfor
       zimage[iv,iphi]= zimage[iv,iphi-1]
    endfor
    zimage[iv,*]=zimage[iv-1,*];for overlayed contour
    indfinite=where(zimage gt 0,cc)
    if cc eq 0 then begin
          message,'NO DATA POINTS AT THAT ANGLE!'
          return
    endif
          dprint,  'angle = ',angle
  endif

if keyword_set(ThirdDirlim) then begin
   if n_elements(ThirdDirlim) eq 2 then begin
      print,'ThirdDirLim: ',ThirdDirLim
      for iv=0,thedata.nenergy-1 do begin
         for iphi=0,nphi-1 do begin
            index = where(sqrt(vpara^2+vperp^2) gt vbin[iv] and sqrt(vpara^2+vperp^2) le vbin[iv+1] and $
                          eachphi gt angbin[iphi] and eachphi le angbin[iphi+1] and $
                          vperp2-zcut_now le max(ThirdDirlim) and vperp2-zcut_now ge min(ThirdDirlim),count)
            
            if count gt 0 then begin
               if method_reduce eq 'ave' then begin
                  index1 = where(zdata[index] ge 0.,cn0)
                  if cn0 gt 0 then $
                     zimage[iv,iphi] = $
                     total(zdata[index[index1]]*weight[index[index1]])/$
                           total(weight[index[index1]])
               endif
               if method_reduce eq 'sum' then begin
                  zimage[iv,iphi] = total(zdata[index]*weight[index],/nan)
               endif
            endif
            
         endfor      
      endfor
   endif else begin;use nearest 2 bins at zcut_now
      for iv=0,thedata.nenergy-1 do begin
         for iphi=0,nphi-1 do begin
            index = where(sqrt(vpara^2+vperp^2) gt vbin[iv] and sqrt(vpara^2+vperp^2) le vbin[iv+1] and $
                          eachphi gt angbin[iphi] and eachphi le angbin[iphi+1],count)
            
            if count gt 0 then begin
               index=index[sort(abs(vperp2[index]-zcut_now))]
               index=index[0:1]
               print,'vperp2-zcut_now'
               print,vperp2[index]-zcut_now
               if method_reduce eq 'ave' then begin
                  index1 = where(zdata[index] ge 0.,cn0)
                  print,'cn0'
                  print,cn0
                  if cn0 gt 0 then begin
                     zimage[iv,iphi] = $
                     total(zdata[index[index1]]*weight[index[index1]])/$
                           total(weight[index[index1]])
                     print,vperp2[index[index1]]-zcut_now 
                  endif
               endif
               if method_reduce eq 'sum' then begin
                  zimage[iv,iphi] = total(zdata[index]*weight[index],/nan)
               endif
            endif
            
         endfor      
      endfor
   endelse
endif


;MAKE SURE THERE ARE NO NEGATIVE VALUES!! ***********
index2 = where(zimage lt 0., count)
if count ne 0 then begin
  dprint, 'THERE ARE NEGATIVE DATA VALUES'
  zimage[index2]=0.
endif



;******************NOW TO PLOT THE DATA********************

if not keyword_set(vrange) then begin
  themax = max(vbin)
  vrange = [-1*themax,themax]
endif else themax = max(abs(vrange))


if not keyword_set(zrange) then begin
  if not keyword_set(vrange) then begin
    maximum = max(zimage)
    minimum = min(zimage(where(zimage ne 0)))
  endif else begin
    maximum = max(zimage(where(abs(vbin) le themax and abs(vbin) le themax)))
    minimum = min(zimage(where(zimage ne 0 and abs(vbin) le themax and abs(vbin) le themax)))
  endelse
endif else begin
  maximum = zrange(1)
  minimum = zrange(0)
endelse



if keyword_set(zlog) then $
  thelevels = 10.^(indgen(nlines)/float(nlines)*(alog10(maximum) - alog10(minimum)) + alog10(minimum)) $
else $
  thelevels = (indgen(nlines)/float(nlines)*(maximum-minimum)+minimum)
;**********EXTRA STUFF FOR THE CONTOUR LINE OVERPLOTS************
if keyword_set(olines) then begin
  if keyword_set(zlog) then $
    thelevels2 = 10.^(indgen(olines)/float(olines)*(alog10(maximum) - alog10(minimum)) + alog10(minimum)) $
  else $
    thelevels2 = (indgen(olines)/float(olines)*(maximum-minimum)+minimum)

endif
;**********END EXTRA STUFF FOR LINE OVERPLOTS (MORE LATER)*************************************


thecolors = round((indgen(nlines)+1)*(!d.table_size-9)/nlines)+7

if not keyword_set(nofill) then fill = 1 else fill = 0

if not keyword_set(finished) then begin
   if coord ne 'fac' then begin
      if coord eq 'lmn' then begin
         if rotation eq 'xy' then begin
            xtitle = 'VN (km/s)'
            ytitle = 'VN (km/s)'
         endif
         if rotation eq 'xz' then begin
            xtitle = 'VN (km/s)'
            ytitle = 'VN (km/s)'
         endif
         if rotation eq 'yz' then begin
            xtitle = 'VN (km/s)'
            ytitle = 'VN (km/s)'
         endif
      endif else begin
         if rotation eq 'xy' then begin
            xtitle = 'Vx (km/s)'
            ytitle = 'Vy (km/s)'
         endif
         if rotation eq 'xz' then begin
            xtitle = 'Vx (km/s)'
            ytitle = 'Vz (km/s)'
         endif
         if rotation eq 'yz' then begin
            xtitle = 'Vy (km/s)'
            ytitle = 'Vz (km/s)'
         endif
      endelse
   endif
   if rotation eq 'perp' then begin
      if ~keyword_set(efield) then begin
         xtitle = 'V!Dperp1!N (km/s)'
         ytitle = 'V!Dperp2!N (km/s)'
      endif else begin
         xtitle = 'V!DExB!N (km/s)'
         ytitle = 'V!DEperp!N (km/s)'
      endelse
   endif
   if rotation eq 'BV' then begin
      xtitle = 'V!Dpara!N (km/s)'
      if ~keyword_set(efield) then begin
         ytitle = 'V!Dperp1!N (km/s)'
      endif else begin
         ytitle = 'V!DExB!N (km/s)'
      endelse
   endif
   if rotation eq 'BE' then begin
      xtitle = 'V!Dpara!N (km/s)'
      if ~keyword_set(efield) then begin
         ytitle = 'V!Dperp2!N (km/s)'
      endif else begin
         ytitle = 'V!DEperp!N (km/s)'
      endelse
   endif
   if rotation eq 'xvel' then begin
      xtitle = 'Vx (km/s)'
      ytitle = 'Vyz (km/s)'
   endif
endif else begin
   xtitle = 'V!19!D'+parasymbol+'!N!7 (km/s)'
   ytitle = 'V!19!D'+perpsymbol+'!N!7 (km/s)'
endelse


;**************************************************
;********************************************************
;********************************************************
if species eq 'e' then begin
   vpara_bin = vpara_bin/1.e4
   vperp_bin=vperp_bin/1.e4
   vrange = vrange/1.e4
   veldir=veldir/1.e4
   xts=strsplit(xtitle,'(',/extract)
   xtitle=xts[0]+'(10!U4!N'+xts[1]
   yts=strsplit(ytitle,'(',/extract)
   ytitle=yts[0]+'(10!U4!N'+yts[1]
endif
if species eq 'i' then begin
   vpara_bin = vpara_bin/1.e3
   vperp_bin=vperp_bin/1.e3
   vrange = vrange/1.e3
   veldir=veldir/1.e3
   xts=strsplit(xtitle,'(',/extract)
   xtitle=xts[0]+'(10!U3!N'+xts[1]
   yts=strsplit(ytitle,'(',/extract)
   ytitle=yts[0]+'(10!U3!N'+yts[1]
endif


 ;thedata.data_name+' '+time_string(thedata.time)
 if data_resolution eq 'brst' then precision=3 else precision=0
 case species of
 'i': sp_str='ion'
 'e': sp_str='electron'
 endcase
 sat_str=string(sat,format='(I1)')
 tstr_tmp=strjoin(strsplit(time_string(thedata3(0).time,precision=precision,format=2),'_',/extract),'-')
  timetitle = 'mms'+sat_str+' '+sp_str+' '+tstr_tmp + '->' +$
  strmid(time_string(thedata.end_time,precision=precision,format=2),9,6+precision+keyword_set(precision))
  if ~keyword_set(notitle) then title=timetitle else title=''
  ;if keyword_set(finished) and keyword_set(plotlabel) then timetitle = '!B
                                ;if keyword_set(finished) and
                                ;keyword_set(plotlabel) then
                                ;timetitle = '!B
  ind_z0=where(zimage eq 0,cc)
  if cc gt 0 then zimage[ind_z0]=!values.f_nan
  if keyword_set(zlog) then begin
    zcolor = bytscl(alog10(zimage),max=alog10(zrange[1]),min=alog10(zrange[0]),$
                    top=254,/nan)
  endif else begin
    zcolor = bytscl(zimage,max=zrange[1],min=zrange[0],$
                    top=254,/nan)
  endelse
  ind_z2=where(zcolor lt 2,c2)
  if c2 gt 0 then zcolor[ind_z2]=2
  if cc gt 0 then zcolor[ind_z0]=!P.background
  
      plot,vpara_bin,vperp_bin, $
          position = position,$
          /nodata,xrange=vrange,yrange=vrange,/xstyle,/ystyle,$
          noerase=1,/isotropic,$
          xtickformat='(A1)',ytickformat='(A1)',ticklen=-0.03
     
  for iv=0,thedata.nenergy-1 do begin
     for iphi=0,nphi-1 do begin
        ifill=[iv,iv+1,iv+1,iv]
        jfill=[iphi,iphi,iphi+1,iphi+1]
        r=abs([vpara_bin[ifill,jfill],vperp_bin[ifill,jfill]])
        if max(r) gt max(vrange) then continue
        polyfill,vpara_bin[ifill,jfill],vperp_bin[ifill,jfill],color=zcolor[iv,iphi],/data

     endfor
   endfor
    plot,vpara_bin,vperp_bin, position = position,$
                /isotropic,$
                /nodata,xrange=vrange,yrange=vrange,/xstyle,/ystyle,$
                /noerase,xtitle=xtitle,ytitle=ytitle,$
                ticklen=-0.03, $
                ytickformat=ytickformat,$
                title = title,xthick=2,ythick=2
 
  ;contour,zimage,vgrids,vgrids,$
  ;  /closed,levels=thelevels,c_color = thecolors,fill=fill,$
  ;  title = timetitle, $
  ;  ystyle = 1,$
  ;  ticklen = -0.01,$
  ;  xstyle = 1,$
  ;  xrange = vrange,$
  ;  yrange = vrange,$
   ; xtitle = xtitle,$
   ; ytitle = ytitle,position = position,$
  ;              noerase=noerase,$
   ;             /isotropic,xticks=4
  if keyword_set(olines) then begin
    if !d.name eq 'PS' then somecol = !p.color else somecol = 0
    contour, zimage,vpara_bin,vperp_bin,closed=0,levels = thelevels2,ystyle = 1+4, $
      xstyle = 1+4,xrange = vrange, yrange = vrange, ticklen = 0,/noerase,position = position,col = somecol,$
      /isotropic;,xticks=4
  endif


if not keyword_set(cut_para) then cut_para = 0.
if not keyword_set(cut_perp) then cut_perp = 0.

;if keyword_set(cut_bulk_vel) then begin
;cut_para= veldir(0)
;cut_perp= veldir(1)
;endif

;oplot, vpara, vperp, PSYM=1

oplot,[cut_para,cut_para],vrange,linestyle = 2,thick = 2
oplot,vrange,[cut_perp,cut_perp],linestyle = 2,thick = 2
;oplot,[0,0],vrange,linestyle = 1
;oplot,vrange,[0,0],linestyle = 1
if keyword_set(sundir) then oplot,[0,vparasun*max(vrange)],[0,vperpsun*max(vrange)],linestyle=1
if keyword_set(bdir) then oplot,[0,vparab*max(vrange)],[0,vperpb*max(vrange)],thick=2,color=255

if keyword_set(thevel2) then begin

; stop
  thevel2 = thevel2#rot
  vperpvel2 = (thevel2(1)^2 + thevel2(2)^2)^.5*thevel2(1)/abs(thevel2(1))
  vparavel2 = thevel2(0)

  bbbb=findgen(36)*(!pi*2/32.)
  usersym,1.5*cos(bbbb),1.5*sin(bbbb),/fill

; oplot,[vparavel2],[vperpvel2],psym = 8,col= !d.table_size - 10,symsize =1
  oplot,[vparavel2],[vperpvel2],psym = 8,col= 2,symsize =1
endif


if not keyword_set(novelline) then begin
;oplot,[0,veldir(0)],[0,veldir(1)],col= 0,thick=2
oplot,vrange,[veldir[1],veldir[1]],linestyle=1,thick=2
oplot,[veldir[0],veldir[0]],vrange,linestyle=1,thick=2
endif


  circy=sin(findgen(360)*!dtor)*sqrt(2.*1.6e-19*erange(0)/mass)/1000.
  circx=cos(findgen(360)*!dtor)*sqrt(2.*1.6e-19*erange(0)/mass)/1000.  ;sqrt(2*1.6e-19*energy(i)/mass)
  oplot,circx,circy,thick = 2

  circy=sin(findgen(360)*!dtor)*sqrt(2.*1.6e-19*erange(1)/mass)/1000.
  circx=cos(findgen(360)*!dtor)*sqrt(2.*1.6e-19*erange(1)/mass)/1000.  ;sqrt(2*1.6e-19*energy(i)/mass)
  oplot,circx,circy,thick = 2

thetitle = units_string_fpi(thedata.units_name,reduce=(method_reduce eq 'sum'))

if keyword_set(plotlabel) then xyouts, 0.05,.95,plotlabel+'!N!7',/normal,charsize = 1.5


;if keyword_set(zlog) then thetitle = thetitle + ' (log)'
if ~keyword_set(nocolbar)then $
draw_color_scale,range=[minimum,maximum],log = zlog,title =thetitle,$
    ytickformat='(E9.1)',yticks = ceil(alog10(maximum)-alog10(minimum)),$
charsize=0.8*!P.charsize


;plot 1D cuts
if keyword_set(cross) then begin
   if species eq 'i' then cutxt = 'V (10!U3!N km/s)' else cutxt='V (10!U4!N km/s)'
   ncut=n_elements(ang_range_cross)/2
   if ncut gt 1 then cut_cols = findgen(ncut)/(ncut-1)*250 else cut_cols=0
   for icut=0, ncut-1 do begin
      ind_phi = where(angbin ge ang_range_cross[0,icut]*!DTOR and $
                      angbin le ang_range_cross[1,icut]*!DTOR,nnphi)
      if ind_phi[nnphi-1] eq n_elements(angbin) then nnphi-=1
      oplot,[0,vrange[1]]*cos(angbin[ind_phi[0]]),$
            [0,vrange[1]]*sin(angbin[ind_phi[0]]),$
            color=cut_cols[icut],thick=5,linestyle=0
      oplot,[0,vrange[1]]*cos(angbin[ind_phi[nnphi-1]+1]),$
            [0,vrange[1]]*sin(angbin[ind_phi[nnphi-1]+1]),$
            color=cut_cols[icut],thick=5,linestyle=0
   endfor

   for icut = 0, ncut-1 do begin
      ind_phi = where(angbin ge ang_range_cross[0,icut]*!DTOR and $
                      angbin le ang_range_cross[1,icut]*!DTOR)
      ycut = mean(zimage[*,ind_phi],dimension=2)
      if icut eq 0 then begin
         plot,vbin,ycut,vrange=[0,vrange[1]],ylog=zlog,$
              xtitle=cutxt,ytitle=thetitle,$
              position=pos2,/nodata,/noerase,/xstyle,thick=3
      endif
      oplot,vbin,ycut,thick=4,color=cut_cols[icut]      
   endfor
endif



if species eq 'e' then vrange=vrange*1.e4
if species eq 'i' then vrange=vrange*1.e3

if filetype eq 'ps' and keyword_set(closefile) then begin
    DEVICE, /CLOSE
endif

if !d.name ne 'PS' then !p.multi = oldplot

if filetype eq 'png' and keyword_set(closefile) then begin
   write_png,outputfile+'.png',tvrd(/true)
;  makepng, outputfile
endif

end

