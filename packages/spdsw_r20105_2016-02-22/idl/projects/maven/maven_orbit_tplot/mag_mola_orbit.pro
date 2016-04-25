;+
;PROCEDURE:   mag_mola_orbit
;PURPOSE:
;  Plots a set of [longitude,latitude] positions over a MAG-MOLA
;  map.
;
;USAGE:
;  mag_mola_orbit, lon, lat
;
;INPUTS:
;       lon:       East longitude (0 to 360 degrees).
;
;       lat:       Latitude (-90 to 90 degrees).
;
;                  Note: lon and lat must have the same number
;                        of elements.
;
;KEYWORDS:
;       PSYM:       Symbol type (same as for plot).
;
;       LSTYLE:     Line style (same as for plot).
;
;       COLOR:      Line/symbol color (same as for plot).
;
;       RESET:      Read in the MAG-MOLA image and calculate the
;                   plot size and position.
;
;       NOERASE:    Do not refresh the plot for each [lon, lat] point.
;
;       BIG:        Use a 1000x500 MAG-MOLA image.
;
;       TERMINATOR: Overlay the terminator.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-01 09:13:44 -0700 (Fri, 01 May 2015) $
; $LastChangedRevision: 17465 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mag_mola_orbit.pro $
;
;CREATED BY:	David L. Mitchell  04-02-03
;-
pro mag_mola_orbit, lon, lat, psym=psym, lstyle=lstyle, color=color, $
                    reset=reset, big=big, noerase=noerase, title=title, $
                    terminator=ttime

  common magmola_orb_com, img, ppos

  twin = !d.window
  owin = 29
  csize = 1.2

  if not keyword_set(title) then title = ''
  if (~size(psym,/type)) then psym = 1 else psym = fix(psym)
  if (~size(lstyle,/type)) then lstyle = 0 else lstyle = fix(lstyle)
  if (~size(color,/type)) then color = 2 else color = fix(color)
  if not keyword_set(noerase) then eflg = 1 else eflg = 0
  if keyword_set(ttime) then doterm = 1 else doterm = 0

  if (psym gt 7) then psym = 8
  a = 0.8
  phi = findgen(49)*(2.*!pi/49)
  usersym,a*cos(phi),a*sin(phi),/fill

  if ((size(img,/type) eq 0) or keyword_set(reset)) then begin
    if keyword_set(big) then fname = file_which('MAG_MOLA_lg.bmp') $
                        else fname = file_which('MAG_MOLA.bmp')

    if (fname eq '') then begin
      print, "MAG_MOLA.bmp not found!"
      return
    endif
    img = read_bmp(fname,/rgb)
    sz = size(img)

    xoff = round(34.*csize)
    yoff = round(30.*csize)
    i = sz[2] + (2*xoff)
    j = sz[3] + (2*yoff)

    window,owin,xsize=i,ysize=j

    px = [0.0, 1.0] * !d.x_vsize + xoff + 16
    py = [0.0, 1.0] * !d.y_vsize + yoff + 10
    ppos=[px[0],py[0],px[0]+sz[2]-1,py[0]+sz[3]-1]
    
    eflg = 1
  endif

  wset,owin

  if (eflg) then tv,img,ppos[0],ppos[1],/true

  plot,[-1.,-2.],[-1.,-2.],position=ppos,/device, $
    xrange=[0,360],yrange=[-90,90],xticks=4,xminor=3, $
    yticks=2,yminor=3,/xstyle,/ystyle,/noerase,charsize=csize, $
    xtitle = 'East Longitude', ytitle = 'Latitude', title=title
  
  if (doterm) then begin
    mvn_mars_terminator, ttime, result=tdat
    oplot,tdat.tlon,tdat.tlat,linestyle=2,color=1,thick=2
    oplot,[tdat.slon],[tdat.slat],color=5,psym=8,symsize=3
  endif

  oplot,[lon],[lat],psym=psym,color=color,linestyle=lstyle,thick=2,symsize=1.4

  wset,twin

  return

end
