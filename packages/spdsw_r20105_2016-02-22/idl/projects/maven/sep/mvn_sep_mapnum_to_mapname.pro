
function mvn_sep_mapnum_to_mapname,mapnum
defmapname = 'fullstack1'
defmapname = 'ATLO'
defmapname = 'SEP-A-O-alpha'
defmapname = 'SEP-B-O-alpha'
if ~keyword_set(mapname) && keyword_set(mapnum) && size(/type,mapnum) le 3 then begin
   case mapnum of
   4:     mapname='ATLO'
   6:     mapname='Flight1'
   8:     mapname='Flight2'
   9:     mapname='Flight3'
   25:    mapname='SEP-A-O-alpha_low'
   24:    mapname='SEP-A-O-alpha'
   52:    mapname='SEP-A-F-alpha'
  152:    mapname='SEP-B-O-alpha'             ; might be variable
  153:    mapname='SEP-B-O-alpha_low'            ; also 'SEP-B-O-alpha_low' on 10/22
  135:    mapname='fullstack1'           ; Possible conflict of maps
;  135:    mapname='SEP-B-F-alpha_low'
  201:    mapname='SEP-B-F-alpha_low'
  202:    mapname='SEP-B-F-alpha_low80'
    7:    mapname='fullstack0'   ; from sep2a cal
   33:    mapname='fullstack0'   ; SEP?-A fullstack
   41:    mapname='fullstack1'   ; SEP?-B-fullstack
   else: dprint,'Unknown map number',mapnum
   endcase
endif
if not keyword_set(mapname) then mapname = defmapname
;dprint,/phelp,mapname
return,mapname
end

