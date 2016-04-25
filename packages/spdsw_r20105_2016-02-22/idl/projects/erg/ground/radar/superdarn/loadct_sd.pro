;+
; PROCEDURE loadct_sd
; 
; :DESCRIPTION:
; Basically this procedure is the same as loadct2.pro except for
; yellow (color=5) replaced with grey. In addition, if you run 
; this with an argument of 44 (e.g., loadct_sd, 44), then it 
; loads the Cutlass color table often used for SuperDARN data. 
; Using this with 45 as an argument gives you a color table similar to 
; the one that was used in the JHU/APL SD site. 
; 
; :AUTHOR:
;   Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
; :HISTORY:
;   2010/11/20: created 
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-02-10 16:54:11 -0800 (Mon, 10 Feb 2014) $
; $LastChangedRevision: 14265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/loadct_sd.pro $
;-

;To define the cutlass color table. The RGB values are loaded 
;from cut_col_tab.dat which should be placed in the same directory.
PRO cut_col_tab

  ; Number of colours for current device
  ncol=(!D.N_COLORS<256)-1
  
  red  =INTARR(ncol)
  green=INTARR(ncol)
  blue =INTARR(ncol)
    
  colour_table=INTARR(4,256)
  
  stack = SCOPE_TRACEBACK(/structure)
  filename = stack[SCOPE_LEVEL()-1].filename
  dir = FILE_DIRNAME(filename)
  fname_cut_coltbl = dir+'/col_tbl/cut_col_tab.dat'
  OPENR,colorfile,fname_cut_coltbl,/GET_LUN
  READF,colorfile,colour_table
  FREE_LUN,colorfile
  
  ; Stretch this colour scale coz it's no good at the ends
  colour_stretch=INTARR(4,256)
  scale_start=65
  scale_end=240
  skip=(scale_end-scale_start)/256.0
  FOR col=0,255 DO BEGIN
    colour_stretch(*,col)=colour_table(*,FIX(scale_start+skip*col))
  ENDFOR
  colour_table=colour_stretch
  
  indx=1.0
  skip=255.0/(ncol-1)
  FOR col=1,ncol-1 DO BEGIN
    red(col)  =colour_table(1,FIX(indx))
    green(col)=colour_table(3,FIX(indx))
    blue(col) =colour_table(2,FIX(indx))
    indx=indx+skip
  ENDFOR
  
  ; Swap colour bar so that color goes red -> yellow -> green -> blue 
  red_swap  =red
  blue_swap =blue
  green_swap=green
  FOR col=1,ncol-1 DO BEGIN
    red(ncol-col)  =red_swap(col)
    blue(ncol-col) =blue_swap(col)
    green(ncol-col)=green_swap(col)
  ENDFOR
  
  IF !D.NAME NE 'NULL' AND !d.name NE 'HP'THEN BEGIN
  
    TVLCT,red,green,blue
    
  ENDIF
  
END

;-----------------------------------------------------------------------
PRO cut_col_tab2, bottom_c 
  
  if n_params() ne 1 then bottom_c = 7 ;default
  
  ;Load the Cutlass table first
  cut_col_tab
  
  ;Obtain RGB values for the color table
  tvlct, r, g, b, /get
  top_c = !d.table_size-2   ; color=!d.table_size-1 is assigned to white in TDAS
  
  negative_top = bottom_c + fix(ceil((top_c - bottom_c)/2.)) -1  
  positive_bottom = negative_top + 1
  
  ;For debugging
;  print, 'bottom_c=',bottom_c
;  print, 'negative_top=', negative_top
;  print, 'positive_bottom=', positive_bottom
;  print, 'top_c=', top_c
;  print, '# of negative colors=', negative_top - bottom_c +1
;  print, '# of positive colors=', top_c - positive_bottom +1
  
  ;Initialize
  red  =INTARR(top_c+2)
  green=INTARR(top_c+2)
  blue =INTARR(top_c+2)
  
  ;Stretch the negative part of the Cutlass color scale to fit in that of the new one
  bot = 1 & top = 110
  neg_r = reverse(r[bot:top])
  neg_g = reverse(g[bot:top])
  neg_b = reverse(b[bot:top])
  for i=0, negative_top-bottom_c do begin
    idx = fix( float(top-bot) * i / (negative_top-bottom_c)    )
    red[i+bottom_c] = neg_r[idx]
    green[i+bottom_c]=neg_g[idx]
    blue[i+bottom_c] =neg_b[idx]
  endfor
  ;Stretch the positive part of the Cutlass color scale to fit in that of the new one
  bot = 160 & top = 225
  pos_r = reverse(r[bot:top])
  pos_g = reverse(g[bot:top])
  pos_b = reverse(b[bot:top])
  for i=0, top_c-positive_bottom do begin
    idx = fix( float(top-bot) * i / (top_c-positive_bottom)    )
    red[i+positive_bottom] = pos_r[idx]
    green[i+positive_bottom]=pos_g[idx]
    blue[i+positive_bottom] =pos_b[idx]
  endfor
   
  
  
  IF !D.NAME NE 'NULL' AND !d.name NE 'HP'THEN BEGIN
  
    TVLCT,red,green,blue
    
  ENDIF
  
END

;-----------------------------------------------------------------------

PRO loadct_sd,ct,invert=invert,reverse=revrse,file=file,previous_ct=previous_ct
  COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
  @colors_com
  
  deffile = GETENV('IDL_CT_FILE')
  IF NOT KEYWORD_SET(deffile) THEN BEGIN  ; looks for color table file in same directory
    stack = SCOPE_TRACEBACK(/structure)
    filename = stack[SCOPE_LEVEL()-1].filename
    dir = FILE_DIRNAME(filename)
    deffile = FILE_SEARCH(dir+'/col_tbl/'+'colors*.tbl',count=nf)
    IF nf GT 0 THEN deffile=deffile[nf-1]              ; Use last one found
  ;dprint,'Using color table: ',deffile,dlevel=3
  ENDIF
  IF NOT KEYWORD_SET(file) AND KEYWORD_SET(deffile) THEN file=deffile
  
  black = 0
  magenta=1
  blue = 2
  cyan = 3
  green = 4
  grey = 5
  red = 6
  bottom_c = 7
  
  IF ~KEYWORD_SET(ct) THEN ct = 43 ;FAST-Special
  
  ;Error check for ct
  if ct lt 0 or ct gt 45 then begin
    print, 'The number of currently available color tables are 0-45.'
    print, 'Please specify a table number of the above range.'
    return
  endif 
  
  IF N_ELEMENTS(color_table) EQ 0 THEN color_table=ct
  previous_ct =  color_table
  IF !d.name EQ 'NULL' OR !d.name EQ 'HP' THEN BEGIN   ; NULL device and HP device do not support loadct
    dprint,'Device ',!d.name,' does not support color tables. Command Ignored'
    RETURN
  ENDIF
  
  IF ct LT 43 THEN BEGIN
    loadct,ct,bottom=bottom_c,file=file
  ENDIF ELSE IF ct EQ 43 THEN BEGIN
    loadct,ct,bottom=bottom_c,file=file,/silent
    PRINT, '% Loading table SD-Special'
  ENDIF ELSE IF ct EQ 44 THEN BEGIN
    cut_col_tab
    print, '% Loading table Cutlass color bar for SD'
  ENDIF ELSE IF ct EQ 45 THEN BEGIN
    cut_col_tab2, bottom_c
    print, '% Loading the color bar similar to the default in JHU/APL SD site'
  ENDIF
  color_table = ct
  
  top_c = !d.table_size-2
  white =top_c+1
  cols = [black,magenta,blue,cyan,green,grey,red,white]
  primary = cols[1:6]
  
  
  TVLCT,r,g,b,/get
  
  IF KEYWORD_SET(revrse) THEN BEGIN
    r[bottom_c:top_c] = reverse(r[bottom_c:top_c])
    g[bottom_c:top_c] = reverse(g[bottom_c:top_c])
    b[bottom_c:top_c] = reverse(b[bottom_c:top_c])
  ENDIF
  
  r[cols] = BYTE([0,1,0,0,0,0.553,1,1]*255)
  g[cols] = BYTE([0,0,0,1,1,0.553,0,1]*255)
  b[cols] = BYTE([0,1,1,1,0,0.553,0,1]*255)
  TVLCT,r,g,b
  
  r_curr = r  ;Important!  Update the colors common block.
  g_curr = g
  b_curr = b
  
  
END


