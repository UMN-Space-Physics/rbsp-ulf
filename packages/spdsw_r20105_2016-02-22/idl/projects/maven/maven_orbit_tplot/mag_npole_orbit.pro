;+
;PROCEDURE:   mag_npole_orbit
;PURPOSE:
;  Plots a set of [longitude,latitude] positions over a polar MAG map.
;
;USAGE:
;  mag_Npole_orbit, lon, lat
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
;       PSYM:      Symbol type (same as for plot).
;
;       LSTYLE:    Line style (same as for plot).
;
;       COLOR:     Line/symbol color (same as for plot).
;
;       RESET:     Read in the MAG-MOLA image and calculate the
;                  plot size and position.
;
;       NOERASE:   Do not refresh the plot for each [lon, lat] point.
;
;       TERMINATOR: Overlay the terminator.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2015-05-01 09:13:18 -0700 (Fri, 01 May 2015) $
; $LastChangedRevision: 17464 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mag_npole_orbit.pro $
;
;CREATED BY:	David L. Mitchell  04-02-03
;-
pro mag_npole_orbit, lon, lat, psym=psym, lstyle=lstyle, color=color, $
                     reset=reset, noerase=noerase, title=title, $
                     terminator=ttime

  common magpole_orb_com, img, ppos

  twin = !d.window
  owin = 27
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
    fname = file_which('MAG_Npole.jpg')

    if (fname eq '') then begin
      print, "MAG_Npole.jpg not found!"
      return
    endif
    read_jpeg, fname, img
    sz = size(img)

    xoff = 0
    yoff = 0
    i = sz[2] + (2*xoff)
    j = sz[3] + (2*yoff)

    window,owin,xsize=i,ysize=j

    px = [0.0, 1.0] * !d.x_vsize + xoff
    py = [0.0, 1.0] * !d.y_vsize + yoff
    ppos=[px[0],py[0],px[0]+sz[2]-1,py[0]+sz[3]-1]
    
    eflg = 1
  endif

  wset,owin

  if (eflg) then tv,img,ppos[0],ppos[1],/true

  plot,[-100.],[-100.],position=[22,112,501,590],/device, $
    xrange=[-35,35],yrange=[-35,35],xticks=6,xminor=3, $
    yticks=6,yminor=3,xstyle=5,ystyle=5,/noerase,charsize=csize, $
    xtitle = 'This Way', ytitle = 'That Way', title=title
  
  if (doterm) then begin
    mvn_mars_terminator, ttime, result=tdat
    r = 90. - tdat.tlat
    phi = (tdat.tlon - 90.)*!dtor
    oplot,r*cos(phi),r*sin(phi),linestyle=2,color=1,thick=2
  endif
  
  r = 90. - lat
  phi = (lon - 90.)*!dtor

  oplot,[r*cos(phi)],[r*sin(phi)],psym=psym,color=color, $
    linestyle=lstyle,thick=2,symsize=1.4

  wset,twin

  return

end
