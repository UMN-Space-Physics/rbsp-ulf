function get_mms_file_info, type, query=query
  ;type: science, ancillary, sitl_selection
  
  url_path = "/mms/sdc/sitl/files/api/v1/file_info/" + type
  if n_elements(query) eq 0 then query = ""
  
  connection = get_mms_sitl_connection()
  result = execute_mms_sitl_query(connection, url_path, query)
  ; Check for error (long integer code as opposed to array of strings)
  if (size(result, /type) eq 3) then return, result
  ;Note: empty array = !NULL not supported before IDL8
  
  
  ; Need to parse result to get file sizes
  
  ; trim first bracket
  bracket1 = strpos(result, '[')
  bracket2 = strpos(result, ']')
  result_trim = strmid(result, bracket1+1, bracket2-bracket1-1)
  
  file_elements = strsplit(result_trim, ",", /extract)
  
    
;  names = strsplit(result, ",", /extract)
  
  return, file_elements
end