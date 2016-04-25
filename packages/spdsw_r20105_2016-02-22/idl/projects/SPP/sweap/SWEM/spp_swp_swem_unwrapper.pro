; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-02-15 15:33:11 -0800 (Mon, 15 Feb 2016) $
; $LastChangedRevision: 20002 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_unwrapper.pro $



function spp_swp_swem_unwrapper,ccsds,ptp_header=ptp_header,apdat=apdat
  str = create_struct(ptp_header,ccsds)
  if debug(3) then begin
    dprint,dlevel=4,'swem',ccsds.size+7, n_elements(ccsds.data), ccsds.apid
    hexprint,ccsds.data[0:31]
 endif
  return,str
end


