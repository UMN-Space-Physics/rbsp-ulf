;+
; PROCEDURE:
;         mms_login_lasp
;
; PURPOSE:
;         Authenticates the user with the SDC at LASP; if no keywords are provided, 
;             the user is prompted for their MMS user/password, and that is saved
;             locally in a sav file
;
; KEYWORDS:
;         login_info: string containing name of a sav file containing a structure named "auth_info",
;             with "username" and "password" tags with your API login information
;         
;         save_login_info: set this keyword to save the login information in a local sav file named
;             by the keyword login_info - or "mms_auth_info.sav" if the login_info keyword isn't set
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:33:38 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19596 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_login_lasp.pro $
;-

function mms_login_lasp, login_info = login_info, save_login_info = save_login_info
    common mms_sitl_connection, netUrl, connection_time, login_source
    if obj_valid(netUrl) then return, 1
    
    ; halt and warn the user if they're using IDL before 7.1 due to SSL/TLS issue
    if double(!version.release) lt 7.1d then begin
        dprint, dlevel = 0, 'Error, IDL 7.1 or later is required to use mms_load_data.'
        return, 0
    endif

    ; restore the login info
    if undefined(login_info) then login_info = 'mms_auth_info.sav'
    
    ; check that the auth file exists before trying to restore it
    file_exists = file_test(login_info, /regular)

    if file_exists eq 1 then begin
        restore, login_info
        if is_struct(auth_info) then begin
            username = auth_info.user
            password = auth_info.password
        endif else begin
            dprint, dlevel=1, 'No valid credentials found in '+file_expand_path(login_info)
        endelse
    endif 
    
    ; prompt the user for their SDC username/password none was found in file
    if undefined(username) || undefined(password) then begin
        ; catch errors from widget and ignore
        ;   -this is primarily to catch cases where no X server is running on linux
        ;   -login_widget has it's own handler that calls dialog_message, so
        ;    any error caught here is likely to be a lack of X server
        catch, err
        if err eq 0 then begin
            login_info_widget = spd_ui_login_widget(title='MMS SDC Login')
        endif
        catch, /cancel
        
        if is_struct(login_info_widget) then begin
            username = login_info_widget.username
            password = login_info_widget.password
            ; check if user wants credentials saved 
            if undefined(save_login_info) then begin
                ; use str_element in case of old login_widget version without tag
                str_element, login_info_widget, 'save', save_login_info
            endif
        endif
    endif
    
    connected_to_lasp = 0
    tries = 0
    ; retry connecting to LASP if the connection fails at first
    ; if no username/pw have been set then the user will be prompted on the command line
    while (connected_to_lasp eq 0 and tries lt 2) do begin
        ; the IDLnetURL object returned here is also stored in the common block
        ; (this is why we never use net_object after this line, but this call is still
        ; necessary to login)
        net_object = get_mms_sitl_connection(username=username, password=password)
        if obj_valid(net_object) then connected_to_lasp = 1
        tries += 1
    endwhile

    if obj_valid(net_object) then begin
        ; now save the user/pass to a sav file to remember it in future sessions
        ; (only if the user requested, which should never be by default)
        if keyword_set(save_login_info) then begin
            ; this assumes username and password are passed out of get_mms_sitl_connection
            ; the idlneturl getproperty method does not allow the pw to be retrieved (despite it being accessible with help command) 
            auth_info = {user:username, password:password}
            save, auth_info, filename = login_info
        endif
        return, 1
    endif else begin
        return, 0
    endelse

end