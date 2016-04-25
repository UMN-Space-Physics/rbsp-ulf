;+
;Procedure:
;  spd_download_handler
;
;
;Purpose:
;  Handle errors thrown by the IDLnetURL object used in spd_download_file.
;  HTTP responses will be caught and handled.  All other exceptions will 
;  be reissued for a higher level error handler to catch.
;
;
;Calling Sequence:
;  spd_download_handler, net_object=net_object, url=url, filename=filename
;
;
;Input:
;  net_object:  Reference to IDLnetURL object
;  url:  String specifying URL of remote file
;  filename:  String specifying path (full or partial) to (requested) local file
;  callback_error:  Flag denoting that an exception occured in the the callback function
;
;
;Output:
;  None - Will reissue last error in case of no valid HTTP response
;
;
;Notes:
;
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-02-18 16:27:58 -0800 (Wed, 18 Feb 2015) $
;$LastChangedRevision: 17004 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_download/spd_download_handler.pro $
;
;-

pro spd_download_handler, net_object=net_object, $
                          url=url, $
                          filename=filename, $
                          callback_error=callback_error

    compile_opt idl2, hidden


;catch exceptions from idlneturl callback function and reissue
;  -if caught normally the file will remain locked by idl
if keyword_set(callback_error) then begin
  message, 'Error in callback function; scroll up for details'
  return  
endif

;get response code and header
net_object->getproperty, response_code=response_code, response_header=response_header


;Handle http responses.
;  -handle common responses separately, other's will be printed with header
;  -if there's no valid http response then it is likely a programatic error;
;   the safest thing to do is to reissue the error for a higher level handler to catch
case response_code of
 
    0: message, /reissue_last
    
    2: dprint, dlevel=0, sublevel=1, 'Unknown error initializing; cannot download:  '+url

   42: dprint, dlevel=2, sublevel=1, 'Download canceled by user: '+url

  301: dprint, dlevel=1, sublevel=1, 'File "'+url+'" permanently moved: ', response_header
  304: dprint, dlevel=2, sublevel=1, 'File is current:  '+filename
  400: dprint, dlevel=0, sublevel=1, 'Bad request; cannot download:  '+url
  401: dprint, dlevel=1, sublevel=1, 'Unauthorized to access:  '+url
  403: dprint, dlevel=1, sublevel=1, 'Access forbidden:  '+url
  404: dprint, dlevel=1, sublevel=1, 'File not found:  '+url

  else: begin
    dprint, dlevel=1, sublevel=1,  'Unable to download file:  '+url
    dprint, dlevel=2, sublevel=1,  ' HTTP Response: '+strtrim(response_code,2)+'
    dprint, dlevel=2, sublevel=1,  ' HTTP Header: '+response_header
  endelse

endcase


end