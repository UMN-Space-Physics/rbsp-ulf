function debug,dlevel,verbose

common dprint_com, dprint_struct
if not keyword_set(dprint_struct) then dprint,'Defining Dprint_struct'

dl = n_elements(dlevel) ne 0  ? dlevel :  2
vb = n_elements(verbose) ne 0 ? verbose :  dprint_struct.debug 

return,dl le vb

end
