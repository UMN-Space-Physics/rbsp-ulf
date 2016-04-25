;+ 
;NAME:
;  elf_ui_load_data
;
;PURPOSE:
;  This routine provides examples for building load data panel widgets and 
;  handles the widget events it produces. This is a template only and creates 
;  basic widgets that are common to most missions. 
;  Each mission is different. Some widgets may need to be added to fully specify
;  the data set to be loaded or some may not be needed. 
;
;HISTORY:
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/tags/spedas_1_00/spedas/gui/api_examples/load_data_tab/elf_ui_load_data.pro $
;
;--------------------------------------------------------------------------------
pro elf_ui_load_data_event,event

  compile_opt hidden,idl2

  ;handle and report errors, reset variables
  err_xxx = 0
  Catch, err_xxx
  IF (err_xxx NE 0) THEN BEGIN
    Catch, /Cancel
    Help, /Last_Message, Output = err_msg
    if is_struct(state) then begin
      ;send error message
      FOR j = 0, N_Elements(err_msg)-1 DO state.historywin->update,err_msg[j]
      
      if widget_valid(state.baseID) && obj_valid(state.historyWin) then begin 
        spd_gui_error,state.baseid,state.historyWin
      endif
      
      ;update central tree, if possible
      if obj_valid(state.loadTree) then begin
        *state.treeCopyPtr = state.loadTree->getCopy()
      endif  
      
      ;restore the state structure 
      Widget_Control, event.TOP, Set_UValue=state, /No_Copy
      
    endif
    Print, 'Error--See history'
    ok=error_message('An unknown error occured and the window must be restarted. See console for details.',$
       /noname, /center, title='Error in Load Data')

    widget_control, event.top,/destroy
  
    RETURN
  ENDIF

  ;retrieve the state variable 
  widget_control, event.handler, Get_UValue=state, /no_copy
  
  ;retrieve event information and the uvalue (or widget name)
  ;note, not all widgets are assigned uvalues
  widget_control, event.id, get_uvalue = uval

  if is_string(uval) then begin
    case uval of
      'INSTRUMENT': begin
        ;retrieve the instrument type that was selected by the user and 
        ;update state
        ;instrlist = widget_info(event.handler,find_by_uname='instrument')
        ;stop 
        ;widget_control,instrlist,set_value=state.instrumentArray[event.index],set_list_select=0
        datalist = widget_info(event.handler,find_by_uname='datalist')
        if event.index eq 0 then dataArray = state.fgmTypeArray
        if event.index eq 1 then dataArray = state.epdTypeArray
        if event.index eq 2 then dataArray = state.engTypeArray
        ;stop
        widget_control, datalist, set_value=dataArray
      end    
      'CLEARTYPE': begin
        ;clear the data type list widget of all selections
        datalist = widget_info(event.handler,find_by_uname='datalist')
        widget_control,datalist,set_list_select=-1
      end
      'CLEARDATA': begin
        ;clear the actual data that has been loaded. this will delete all 
        ;data loaded into the gui memory so warn user first
        ok = dialog_message("This will delete all currently loaded data.  Are you sure you wish to continue?",/question,/default_no,/center)
        
        if strlowcase(ok) eq 'yes' then begin
          datanames = state.loadedData->getAll(/parent)
          if is_string(datanames) then begin
            for i = 0,n_elements(dataNames)-1 do begin
              result = state.loadedData->remove(datanames[i])
              if ~result then begin
                ;report errors to the status bar for the user to see and log the
                ;error to the history window
                state.statusBar->update,'Unexpected error while removing data.'
                state.historyWin->update,'Unexpected error while removing data.'
              endif
            endfor
          endif
          ;update the data tree and add the delete commands to the callSequence
          ;object which tracks sequences of calls during the gui session
          state.loadTree->update
          state.callSequence->clearCalls
        endif
        
      end   
      'DEL': begin
        ;get the current list of loaded data
        dataNames = state.loadTree->getValue()
        
        if ptr_valid(datanames[0]) then begin
          for i = 0,n_elements(dataNames)-1 do begin
            ;delete the selected data from the gui memory and loaded data tree
            result = state.loadedData->remove((*datanames[i]).groupname)
            if ~result then begin
              ;report errors to the status bar for the user to see and log the
              ;error to the history window
              state.statusBar->update,'Unexpected error while removing data.'
              state.historyWin->update,'Unexpected error while removing data.'
            endif
          endfor
        endif
        state.loadTree->update      
   
      end
      'ADD': begin
      
        ;retrieve the data types that were selected by the user
        datalist = widget_info(event.handler,find_by_uname='datalist')
        typeSelect = widget_info(datalist,/list_select)      
        ;if no selections were made, report this to the user via the 
        ;status bar and log the error to the history window
        state.statusBar->update,'Nothing to load. Widgets for probe and data type selection have not yet been provided.'
        state.historyWin->update,'There are no widgets for probe and data type selection.'
        if typeSelect[0] eq -1 then begin
          state.statusBar->update,'You must select at least one data type'
          state.historyWin->update,'elf add attempted without selecting data type'
          break
        endif    
        ;retrieve the probes that were selected by the user
         
        instlist = widget_info(event.handler,find_by_uname='instrument')
        instrument = widget_info(instlist,/combobox_gettext)        
        instNum = widget_info(instlist,/combobox_number)        
        if instrument eq 'fgm' then typeArray = state.fgmTypeArray
        if instrument eq 'epd' then typeArray = state.epdTypeArray
        if instrument eq 'eng' then typeArray = state.engTypeArray
        types = typeArray[typeSelect]
        ;report errors to status bar and history window
        if  instNum eq -1 then begin
          state.statusBar->update,'You must select at least one instrument'
          state.historyWin->update,'elf add attempted without selecting an instrument'
          break
        endif

        ;get the start and stop times 
        timeRangeObj = state.timeRangeObj      
        timeRangeObj->getProperty,startTime=startTimeObj,endTime=endTimeObj      
        startTimeObj->getProperty,tdouble=startTimeDouble,tstring=startTimeString
        endTimeObj->getProperty,tdouble=endTimeDouble,tstring=endTimeString
        
        ;report errors
        if startTimeDouble ge endTimeDouble then begin
          state.statusBar->update,'Cannot add data unless end time is greater than start time.'
          state.historyWin->update,'elf add attempted with start time greater than end time.'
          break
        endif
        
        ;turn on the hour glass while the data is being loaded
        widget_control, /hourglass
        
        ;create a load structure to pass the parameters needed by the load
        ;procedure
        loadStruc = { instrument:instrument, $
                      datatypes:types, $
                      timeRange:[startTimeString, endTimeString] }
  
        ;call the routine that loads the data and update the loaded data tree
        ;this routine is specific to each mission 
        elf_ui_load_data_load_pro, $
                         loadStruc,$
                         state.loadedData,$
                         state.statusBar,$
                         state.historyWin,$
                         state.baseid,$  ;needed for appropriate layering and modality of popups
                         replay=replay,$
                         overwrite_selections=overwrite_selections ;allows replay of user overwrite selections from spedas 

         ;update the loaded data object
         state.loadTree->update

         ;create a structure that will be used by the call sequence object. the
         ;call sequence object tracks the sequences of dprocs that have been 
         ;executed during a gui session. This is so it can be replayed in a 
         ;later session. The callSeqStruc.type for ALL new missions is 
         ;'loadapidata'.
         callSeqStruc = { type:'loadapidata', $
                          subtype:'elf_ui_load_data_load_pro', $
                          loadStruc:loadStruc, $
                          overwrite_selections:overwrite_selections }
         ; add the information regarding this load to the call sequence object
         state.callSequence->addSt, callSeqStruc
         
         ;NOTE: In order to replay a session the user must save the sequence of
         ;commands by selecting 'Save SPEDAS document' under the 'File' 
         ;pull down menu prior to exiting the gui session. 
              
      end
      else:
    endcase
  endif
  
  ;set the state structure before returning to the panel
  ;stop
  Widget_Control, event.handler, Set_UValue=state, /No_Copy
  
  return
  
end

;this procedure is called by the main load data panel when this tab is 
;selected by the user. This is where the mission specific load data panel is
;created and initialized. This routine is an example only. Each mission may 
;choose to add or remove widgets as required by their data. The name of the
;load procedure (called later by the event handler) is the load procedure 
;in the spd_ui_load_data_config.txt file.
pro elf_ui_load_data,tabid,loadedData,historyWin,statusBar,treeCopyPtr,timeRangeObj,callSequence,loadTree=loadTree,timeWidget=timeWidget
  compile_opt idl2,hidden
  
  ;load bitmap resources
  getresourcepath,rpath
  rightArrow = read_bmp(rpath + 'arrow_000_medium.bmp', /rgb)
  trashcan = read_bmp(rpath + 'trashcan.bmp', /rgb)
  
  spd_ui_match_background, tabid, rightArrow 
  spd_ui_match_background, tabid, trashcan
  
  ;create all the bases needed for the widgets on the panel 
  topBase = Widget_Base(tabid, /Row, /Align_Top, /Align_Left, YPad=1,event_pro='elf_ui_load_data_event') 
  
  leftBase = widget_base(topBase,/col)
  middleBase = widget_base(topBase,/col,/align_center)
  rightBase = widget_base(topBase,/col)
  
  leftLabel = widget_label(leftBase,value='elf Data Selection:',/align_left)
  rightLabel = widget_label(rightBase,value='Data Loaded:',/align_left)
  
  selectionBase = widget_base(leftBase,/col,/frame)
  treeBase = widget_base(rightBase,/col,/frame)
  
  ;create the buttons to add or remove data to the gui. the bitmaps for 
  ;these buttons include a 'right arrow' for adding to the currently loaded 
  ;data, and a 'trashcan' for removing data from the data tree. 
  addButton = Widget_Button(middleBase, Value=rightArrow, /Bitmap,  UValue='ADD', $
              ToolTip='Load data selection')
  minusButton = Widget_Button(middleBase, Value=trashcan, /Bitmap, $
                Uvalue='DEL', $
                ToolTip='Delete data selected in the list of loaded data')
  
  ;this creates and copies the loaded data tree for use within this routine
  loadTree = Obj_New('spd_ui_widget_tree', treeBase, 'LOADTREE', loadedData, $
                     XSize=400, YSize=425, mode=0, /multi,/showdatetime)                   
  loadTree->update,from_copy=*treeCopyPtr
  
  ;create the buttons that removes all data
  clearDataBase = widget_base(rightBase,/row,/align_center)  
  clearDataButton = widget_button(clearDataBase,value='Delete All Data',uvalue='CLEARDATA',/align_center,ToolTip='Deletes all loaded data')
  
  ;the ui time widget handles all widgets and events that are associated with the 
  ;time widget and includes Start/Stop Time labels, text boxes, calendar icons, and
  ;other items associated with setting the time for the data to be loaded.
  timeWidget = spd_ui_time_widget(selectionBase,$
                                  statusBar,$
                                  historyWin,$
                                  timeRangeObj=timeRangeObj,$
                                  uvalue='TIME_WIDGET',$
                                  uname='time_widget')
    
  ;create the dropdown menu that lists the various instrument types for this mission
  instrumentArray = ['fgm','epd','eng']
  ;Note: these type arrays are temporarily commented out because LOMO data only has one type of data - level 1
  ;fgm may have level 2 data in the future
    ;fgmTypeArray = ['fgs','fgf','fgs_dsl_gei_mag','fgf_dsl_gei_mag']
    ;epdTypeArray = ['pis_en_counts','pif_en_counts','pis_en_eflux','pif_en_eflux']
    ;engTypeArray = ['temp','volt']
  fgmTypeArray = ['level 1']
  epdTypeArray = ['level 1']
  engTypeArray = ['level 1']
  instrumentBase = widget_base(selectionBase,/row) 
  instrumentLabel = widget_label(instrumentBase,value='Instrument Type: ')
  instrumentCombo = widget_combobox(instrumentBase,$
                                       value=instrumentArray,$
                                       uvalue='INSTRUMENT',$
                                       uname='instrument')
                                  
  ;create the list box that lists all the probes that are associated with this 
  ;mission along with the clear all button
  dataBase = widget_base(selectionBase,/row)
  
  ;create the list box and a clear all button for the data types for a given 
  ;instrument             
  typeBase = widget_base(dataBase,/col)
  typeLabel = widget_label(typeBase,value='Data Type:')
  typeList = widget_list(typeBase,$
                         value=fgmTypeArray,$
                         /multiple,$
                         uname='datalist',$
                         xsize=16,$
                         ysize=15)                         
  clearTypeButton = widget_button(typeBase,value='Clear Data Type',uvalue='CLEARTYPE',ToolTip='Deselect all parameter types')

  ;create the state variable with all the parameters that are needed by this 
  ;panels event handler routine                                                               
  state = {baseid:topBase,$
           loadTree:loadTree,$
           treeCopyPtr:treeCopyPtr,$
           timeRangeObj:timeRangeObj,$
           statusBar:statusBar,$
           historyWin:historyWin,$
           loadedData:loadedData,$
           callSequence:callSequence,$
           instrumentArray:instrumentArray,$
           fgmTypeArray:fgmTypeArray, $
           epdTypeArray:epdTypeArray, $
           engTypeArray:engTypeArray}            
  widget_control,topBase,set_uvalue=state
                                  
  return

end
