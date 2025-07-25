/*
MIT License

Copyright (c) 2024 Dominic Wise

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

--====================================================
::class DebuggerUI public
--====================================================

::attribute fontsize get unguarded

------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("AppendUIConsoleText", .Method~new("", self~method("AppendUIConsoleText")~source)~~setUnguarded)

------------------------------------------------------
::method BuildGetThreadIDRoutine class
------------------------------------------------------
if .context~hasmethod("Thread") then code  = "return .context~Thread"
else code = "return SysQueryProcessRoutine('TID')"

return .Routine~new("", code)

------------------------------------------------------
::method init
------------------------------------------------------
expose debugdialog debugger fontsize


use arg debugger,watchhelperclass

fontsize = 8
if datatype(.local~rexxdebugger.uifontsize) = 'NUM'  then  do
  fontsize = .local~rexxdebugger.uifontsize~floor
  if fontsize < 8 then fontsize = 8
  if fontsize > 16 then fontsize = 16
end


if .WatchHelper~class~defaultname \= .Class~defaultname then .context~package~addclass("WatchHelper", watchhelperclass)
.WatchDialog~inherit(.WatchHelper)

debugdialog = .DebugDialog~new(debugger, self, .rexxdebugger.startuphelptext)

------------------------------------------------------
::method RunUI
------------------------------------------------------
expose debugdialog

debugdialog~popup("SHOWTOP")

------------------------------------------------------
::method AppendUIConsoleText unguarded
------------------------------------------------------
expose debugdialog debugger
use  arg text, newline = .true
if debugdialog \= .nil & \debugger~isshutdown then debugdialog~appendtext(text, newline)

------------------------------------------------------
::method GetUINextResponse unguarded
------------------------------------------------------
expose debugdialog debugger

if debugdialog \= .nil & \debugger~isshutdown then return debugdialog~GetNextResponse
else return ''

------------------------------------------------------
::method InitUISource
------------------------------------------------------
expose debugdialog debugger
use arg arrSource, sourcename

if debugdialog \= .nil & \debugger~isshutdown then debugdialog~InitSource(arrsource, sourcename)


------------------------------------------------------
::method UpdateUICodeView 
------------------------------------------------------
expose debugdialog debugger
use arg arrStack, activateindex

if debugdialog \= .nil & \debugger~isshutdown then debugdialog~UpdateCodeView(arrStack, activateindex)

------------------------------------------------------
::method UpdateUIControlStates
------------------------------------------------------
expose debugdialog debugger
use arg arrStack, activateindex

if debugdialog \= .nil & \debugger~isshutdown then debugdialog~UpdateControlStates


------------------------------------------------------
::method UpdateUIWatchWindows 
------------------------------------------------------
expose debugdialog debugger
use arg varsroot

if debugdialog \= .nil & \debugger~isshutdown then debugdialog~UpdateWatchWindows(varsroot, .True)

------------------------------------------------------
::method SetUISourceListInfoText 
------------------------------------------------------
expose debugdialog debugger
use arg sourcelist

if debugdialog \= .nil & \debugger~isshutdown then debugdialog~SetSourceListInfoText(sourcelist)

------------------------------------------------------
::method ResetUISourceState
------------------------------------------------------
expose debugdialog debugger

if debugdialog \= .nil & \debugger~isshutdown then debugdialog~ResetSourceState

------------------------------------------------------
::method ClearUIConsole
------------------------------------------------------
expose debugdialog debugger

if debugdialog \= .nil & \debugger~isshutdown then debugdialog~ClearConsole


--====================================================
::class DebugDialog subclass UserDialog inherit ResizingAdmin DialogControlHelper
--====================================================

::constant EDITSOURCENAME     100
::constant LISTSOURCE         101
::constant LISTSTACK          102
::constant EDITDEBUGLOG       103
::constant BUTTONNEXT         104
::constant BUTTONRUN          105
::constant BUTTONEXIT         106
::constant BUTTONVARS         107
::constant BUTTONHELP         108
::constant BUTTONOPEN         109
::constant EDITCOMMAND        110
::constant BUTTONEXEC         111
::constant BPSETTINGSMENUITEM 112
::constant SOURCECOPYMENUITEM 114
::constant STACKCOPYMENUITEM  115
::constant MENUSEPARATOR1       1
------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("AppendText", .Method~new("", self~method("AppendText")~source)~~setUnguarded)
self~define("DoConsoleAppend", .Method~new("", self~method("DoConsoleAppend")~source)~~setUnguarded)
self~define("EnsureFinalConsoleUpdates", .Method~new("", self~method("EnsureFinalConsoleUpdates")~source)~~setUnguarded)

------------------------------------------------------
::method ok  
------------------------------------------------------
return .False

------------------------------------------------------
::method cancel unguarded
------------------------------------------------------
expose waiting debugger hfnt watchwindows controls consoleupdateactive
close = .True
numeric digits 20
if waiting | (\debugger~canopensource & .local~rexxdebugger.commandlineisrexxdebugger) | TIME('F') - debugger~lastexecfulltime < 250000 then do
   ret = RxMessageBox("Do you really want to quit and end the program?", "Program still running", "YESNO", "QUESTION")
   if ret = 7 then close = .False
end
if close then do
  debugger~informshutdown
  self~ListDeleteAllItems(controls, self~LISTSOURCE)
  self~ListDeleteAllItems(controls, self~LISTSTACK)
  self~deletefont(hfnt)
  watchlist = watchwindows~allitems~section(1)
  do watchwindow over watchlist~allitems
     watchwindow~cancel
  end  
  guard off when consoleupdateactive = .False 
  self~CANCEL:super
  if waiting then self~HereIsResponse('say "Debugger closed - exiting"')
end

------------------------------------------------------
::method UpdateControlStates unguarded
------------------------------------------------------
expose waiting controls watchwindows debugger activesourcename

do control over .array~of(SELF~LISTSOURCE, SELF~LISTSTACK, self~BUTTONNEXT, self~BUTTONEXIT, self~BUTTONVARS, self~BUTTONEXEC, self~BUTTONHELP)
  if control = self~LISTSOURCE | control = self~LISTSTACK then self~ControlEnable(controls, control, waiting | debugger~canopensource |(activesourcename = .nil))
  else self~ControlEnable(controls, control, waiting)
end    
self~ControlEnable(controls, self~BUTTONRUN,   \debugger~canopensource)
self~ControlEnable(controls, self~EDITCOMMAND, \debugger~canopensource)
self~ControlEnable(controls, self~BUTTONOPEN,  debugger~canopensource)
if debugger~canopensource then self~focusControl(self~BUTTONOPEN)

if waiting & self~ButtonGetText(controls, self~BUTTONRUN) \= "Run" then self~ButtonSetText(controls, self~BUTTONRUN, "&Run")
do watchwindow over watchwindows~allitems
  watchwindow~SetListState(waiting)
end
------------------------------------------------------
::method init 
------------------------------------------------------
expose debugger controls waiting arrcommands commandnum arrstack activesourcename loadedsources watchwindows startuphelptext checkedsources debugconsoletextlength debugconsoleappendbuffer consoleupdateactive debugconsolelastupdate debugconsolefinalupdatemessage scrollcharpos gui
use strict arg debugger, gui, startuphelptext

arrstack = .nil
activesourcename = .nil
loadedsources = .Directory~new
watchwindows = .Set~new
checkedsources = .List~new
scrollcharpos = 1
waiting = .false
controls = .Directory~new

forward class (super) continue array(.nil)

self~fontsize = gui~fontsize

self~create(6, 15, 280, 302, debugger~GetCaption, "THICKFRAME, CENTER, MAXIMIZEBOX,MINIMIZEBOX")
self~connectResize("onResize")

arrcommands = .Array~new
commandnum = 0
debugconsoletextlength = 0
debugconsoleappendbuffer = ''
debugconsolefinalupdatemessage = .Nil
debugconsolelastupdate = 0
consoleupdateactive = .False
------------------------------------------------------
::method GetNextResponse unguarded
------------------------------------------------------
expose  waiting response

waiting = .True
response = .Nil
self~UpdateControlStates
self~focusControl(self~EDITCOMMAND)
guard off when waiting = .False
returnstring = response
self~UpdateControlStates

return returnstring

------------------------------------------------------
::method HereIsResponse unguarded
------------------------------------------------------
expose waiting response varsroot
use arg response
varsroot = .Nil
waiting = .False

------------------------------------------------------
::method defineDialog 
------------------------------------------------------
expose u 

self~createEdit(self~EDITSOURCENAME, 3, 2, 273, 12, "READONLY")
self~createListBox(self~LISTSOURCE, 3, 16, 273, 132, "HSCROLL VSCROLL PARTIAL NOTIFY")
self~createListBox(self~LISTSTACK, 3, 150, 273,29, "VSCROLL AUTOVSCROLL PARTIAL NOTIFY")
self~createEdit(self~EDITDEBUGLOG, 3, 181, 240, 100, "HSCROLL VSCROLL MULTILINE")
self~createPushButton(self~BUTTONNEXT, 246, 181, 30, 15,  ,"&Next", "OnNextButton") 
self~createPushButton(self~BUTTONRUN, 246, 198, 30, 15,  ,"&Run", "OnRunButton") 
self~createPushButton(self~BUTTONEXIT, 246, 215, 30, 15,  ,"E&xit", "OnExitButton") 
self~createPushButton(self~BUTTONVARS, 246, 232, 30, 15,  ,"&Watch", "OnVarsButton") 
self~createPushButton(self~BUTTONHELP, 246, 249, 30, 15,  ,"&Help", "OnHelpButton") 
self~createPushButton(self~BUTTONOPEN, 246, 266, 30, 15,  ,"&Open", "OnOpenButton") 
self~createEdit(self~EDITCOMMAND, 3, 283, 240, 15, "WANTRETURN")
self~createPushButton(self~BUTTONEXEC, 246, 283,  30, 15, "DEFPUSHBUTTON"  ,"&Exec", "OnExecButton")


------------------------------------------------------
::method defineSizing 
------------------------------------------------------

self~controlLeft(self~EDITSOURCENAME, 'STATIONARY', 'LEFT') 
self~controlRight(self~EDITSOURCENAME, 'STATIONARY', 'RIGHT') 
self~controlTop(self~EDITSOURCENAME, 'STATIONARY', 'TOP') 
self~controlBottom(self~EDITSOURCENAME, 'STATIONARY', 'TOP') 

self~controlLeft(self~LISTSOURCE, 'STATIONARY', 'LEFT') 
self~controlRight(self~LISTSOURCE, 'STATIONARY', 'RIGHT') 
self~controlTop(self~LISTSOURCE, 'STATIONARY', 'TOP') 
self~controlBottom(self~LISTSOURCE, 'STATIONARY', 'BOTTOM') 

self~controlLeft(self~LISTSTACK, 'STATIONARY', 'LEFT') 
self~controlRight(self~LISTSTACK, 'STATIONARY', 'RIGHT') 
self~controlTop(self~LISTSTACK, 'STATIONARY', 'BOTTOM', self~LISTSOURCE) 
self~controlBottom(self~LISTSTACK, 'STATIONARY', 'BOTTOM') 


self~controlLeft(self~EDITDEBUGLOG, 'STATIONARY', 'LEFT') 
self~controlRight(self~EDITDEBUGLOG, 'STATIONARY', 'RIGHT') 
self~controlTop(self~EDITDEBUGLOG, 'STATIONARY', 'BOTTOM', self~LISTSTACK) 
self~controlBottom(self~EDITDEBUGLOG, 'STATIONARY', 'BOTTOM') 


do id over .List~of(self~BUTTONRUN, self~BUTTONNEXT, self~BUTTONEXIT, self~BUTTONEXEC, self~BUTTONVARS, self~EDITCOMMAND, self~BUTTONHELP, self~BUTTONOPEN)
  self~controlLeft(id, 'STATIONARY', 'RIGHT') 
  self~controlRight(id, 'MYLEFT', 'LEFT') 
  self~controlTop(id, 'STATIONARY', 'BOTTOM', self~LISTSTACK) 
  self~controlBottom(id, 'MYTOP', 'TOP') 
end
self~controlTop(self~BUTTONEXEC, 'STATIONARY', 'BOTTOM') 


self~controlLeft(self~EDITCOMMAND, 'STATIONARY', 'LEFT') 
self~controlRight(self~EDITCOMMAND, 'STATIONARY', 'RIGHT') 
self~controlTop(self~EDITCOMMAND, 'STATIONARY', 'BOTTOM') 
self~controlBottom(self~EDITCOMMAND, 'MYTOP', 'BOTTOM') 


return 0

------------------------------------------------------
::method OnNextButton unguarded
------------------------------------------------------
expose waiting controls
if waiting then do
  instructions = controls[self~EDITCOMMAND]~gettext~strip
  self~ButtonSetText(controls, self~BUTTONRUN, "B&reak")
  if instructions~word(1)~translate\='NEXT' then instructions = 'NEXT 'instructions
  self~HereIsResponse(instructions)
end
------------------------------------------------------
::method OnRunButton unguarded
------------------------------------------------------
expose waiting debugger controls
if waiting then do
  self~ButtonSetText(controls, self~BUTTONRUN, "B&reak")
  self~HereIsResponse('RUN')
end
else if \debugger~GetManualBreak then do
  self~ButtonSetText(controls, self~BUTTONRUN, "&Run")
  self~appendtext(debugger~DebugMsgPrefix||'Automatic breakpoint set for the next line of traceable code.')
  debugger~SetManualBreak(.True)
end
else do
  debugger~SetManualBreak(.False)
  self~appendtext(debugger~DebugMsgPrefix||'Automatic breakpoint removed. Program will run normally.')
  self~ButtonSetText(controls, self~BUTTONRUN, "B&reak")
end   
------------------------------------------------------
::method OnExitButton 
------------------------------------------------------
expose waiting debugger
if waiting then do
   ret = RxMessageBox("Do you really want to exit the program?", "Program still running", "YESNO", "QUESTION")
   if ret \= 7 then  do
    self~appendtext(debugger~DebugMsgPrefix||"Debug session terminated", .true, .true)
    self~HereIsResponse('EXIT')
   end  
end

------------------------------------------------------
::method OnVarsButton 
------------------------------------------------------
expose waiting watchdialog debugger varsroot
if waiting then do
  self~AddWatchWindow(self)
end

-----------------------------------------------------
::method OnHelpButton 
------------------------------------------------------
expose waiting 
if waiting then do
  self~HereIsResponse('HELP')
end

-----------------------------------------------------
::method OnOpenButton unguarded
------------------------------------------------------
expose debugger controls gui

newsessionDialog = .NewSessionDialog~new(gui)
newsessionDialog~ownerDialog = self
self~disable
dlgres = newsessiondialog~Execute
self~enable
if dlgres = self~IDOK then do
  self~ListDeleteAllItems(controls, self~LISTSOURCE)
  self~ListDeleteAllItems(controls, self~LISTSTACK)
  self~start("SetForeground")
  reply
  debugger~OpenNewProgram(.local~rexxdebugger.rexxfile, .local~rexxdebugger.rawargstring, .local~rexxdebugger.multipleargs)
end
else self~start("SetForeground")

  

------------------------------------------------------
::method SetForeground unguarded
------------------------------------------------------
do i = 1 to 5
  call SysSleep(0.1)
  self~setforegroundwindow(self~hwnd)
end

------------------------------------------------------
::method OnExecButton unguarded
------------------------------------------------------
expose waiting controls arrCommands commandnum
if waiting then do
  returnstring = controls[self~EDITCOMMAND]~gettext~strip
  controls[self~EDITCOMMAND]~select()
  if returnstring \= '' then do
    if \arrCommands~hasitem(returnstring) then do
      arrCommands~append(returnstring)
      commandnum = arrCommands~items + 1
    end
    else commandnum = arrCommands~index(returnstring) + 1
  end    
  if returnstring~strip~translate = 'RUN' then self~ButtonSetText(controls, self~BUTTONRUN, "B&reak")
  self~HereIsResponse(returnstring)
end

------------------------------------------------------
::method OnPrevCommand 
------------------------------------------------------
expose arrCommands commandnum controls
commandnum = commandnum - 1
if commandnum <= 0 then do
  commandnum = 0
  controls[self~EDITCOMMAND]~settext('')
end 
else if arrCommands~items >= commandnum then controls[self~EDITCOMMAND]~settext(arrCommands[commandnum])

------------------------------------------------------
::method OnNextCommand 
------------------------------------------------------
expose arrCommands commandnum controls
commandnum = commandnum + 1
if commandnum > arrCommands~items then do
  commandnum = arrCommands~items + 1
  controls[self~EDITCOMMAND]~settext('')
end  
else if arrCommands~items >= commandnum then controls[self~EDITCOMMAND]~settext(arrCommands[commandnum])

------------------------------------------------------
::METHOD AddWatchWindow
------------------------------------------------------
expose watchwindows  childready rootlist debugger gui
use arg  parentwindow, parentlist = .nil
if parentlist = .nil then do
  if \VAR("rootlist") then rootlist = .list~new
  parentlist = rootlist
end  
existingwindow = .WatchHelper~FindWatchWindow(watchwindows,parentlist)
if existingwindow \=.nil then self~setforegroundWindow(existingwindow~hwnd)
else do
  childready = .False
  watchdialog = .Watchdialog~new(self, gui, parentwindow, parentlist, debugger)
  watchdialog~popup("SHOWTOP")
  watchwindows~put(watchdialog)
  guard off when childready = .True
end

self~UpdateWatchWindows

------------------------------------------------------
::METHOD NotifyChildReady unguarded
------------------------------------------------------
expose childready
childready = .True

------------------------------------------------------
::METHOD RemoveWatchWindow
------------------------------------------------------
expose watchwindows
use arg watchwindow
watchwindows~removeitem(watchwindow)

------------------------------------------------------
::method InitDialog 
------------------------------------------------------
expose u controls buttonpushed debugger hfnt startuphelptext sourcepopupmenu stackpopupmenu

controls[self~EDITSOURCENAME] = self~newEdit(.DebugDialog~EDITSOURCENAME)
self~setTabStop(self~EDITSOURCENAME, .False)
controls[self~EDITDEBUGLOG] = self~newEdit(.DebugDialog~EDITDEBUGLOG)
controls[self~EDITDEBUGLOG]~setreadonly
controls[self~EDITDEBUGLOG]~setlimit(0)

controls[self~EDITCOMMAND] = self~newEdit(.DebugDialog~EDITCOMMAND)
controls[self~BUTTONEXEC] = self~newPushButton(self~BUTTONEXEC)
controls[self~LISTSOURCE] = self~newListBox(self~LISTSOURCE)
controls[self~LISTSTACK] = self~newListBox(self~LISTSTACK)
controls[self~BUTTONRUN] = self~newPushButton(self~BUTTONRUN)

controls[self~EDITCOMMAND]~connectkeypress("OnPrevCommand", .VK~UP)
controls[self~EDITCOMMAND]~connectkeypress("OnNextCommand", .VK~DOWN)
controls[self~EDITCOMMAND]~wantreturn("EditReturn")
controls[self~EDITCOMMAND]~connectCharEvent("EditCommandChar")

sourcepopupmenu = .PopupMenu~new(self~LISTSOURCE)
sourcepopupmenu~insertItem(self~BPSETTINGSMENUITEM, self~BPSETTINGSMENUITEM, "Breakpoint Settings")
sourcepopupmenu~insertSeparator(1, self~MENUSEPARATOR1, .True)
sourcepopupmenu~insertItem(self~MENUSEPARATOR1, self~SOURCECOPYMENUITEM, "Copy")
sourcepopupmenu~assignTo(self)
sourcepopupmenu~connectContextMenu("onListSourceContext", controls[self~LISTSOURCE]~hwnd) 
sourcepopupmenu~connectCommandEvent(self~BPSETTINGSMENUITEM, "BreakpointSettings")
sourcepopupmenu~connectCommandEvent(self~SOURCECOPYMENUITEM, "OnCopySource")

stackpopupmenu = .PopupMenu~new(self~LISTSTACK)
stackpopupmenu~insertItem(self~STACKCOPYMENUITEM, self~STACKCOPYMENUITEM, "Copy")
stackpopupmenu~assignTo(self)
stackpopupmenu~connectContextMenu("onListStackContext", controls[self~LISTSTACK]~hwnd) 
sourcepopupmenu~connectCommandEvent(self~STACKCOPYMENUITEM, "OnCopyStack")

self~connectkeypress("OnCopyKeyCommand", .VK~C, "CONTROL")
self~connectkeypress("OnCopyKeyCommand2", .VK~INSERT, "CONTROL")

if \.local~rexxdebugger.commandlineisrexxdebugger = .True then do
  self~hidecontrol(self~BUTTONOPEN)
end
buttonpushed = .False

minsize = .Size~new(self~pixelCX, self~pixelCY)
self~minSize = minsize

hfnt = self~createFontEx("Courier New", self~fontsize)
controls[self~LISTSOURCE]~setFont(hfnt, .true)
controls[self~LISTSTACK]~setFont(hfnt, .true)

if \startuphelptext~isA(.list) then startuphelptext = .List~of("No startup help text is available") 
self~SetSourceListInfoText(startuphelptext)


self~connectListBoxEvent(self~LISTSTACK, "SELCHANGE", "StackFrameChanged")
self~connectListBoxEvent(self~LISTSOURCE, "DBLCLK", "SourceLineDoubleClicked")

offsetDirection = debugger~offsetdirection 
offsetletter = offsetDirection~left(1)~upper 

if "LRUD"~pos(offsetletter) \= 0 then do
  parent = FindWindow(debugger~windowname)
  if parent \= 0 then do
  
    parentpos = self~windowRect(parent)
    mypos = self~getRealpos

    if offsetletter = "L" then do 
      offsetx = parentpos~left - (mypos~x + self~pixelCX)
      offsety = 0
    end
    if offsetletter = "R" then do 
      offsetx = parentpos~right - mypos~x
      offsety = 0
    end  
    if offsetletter = "U" then do 
      offsetx = 0
      offsety = parentpos~top - (mypos~y + self~pixelCy)
    end
    if offsetletter = "D" then do 
      offsetx = 0
      offsety = parentpos~bottom - mypos~y
    end  

    mypos~incr(offsetx, offsety)
    self~moveto(mypos)
    self~ensurevisible
  end
end

debugger~FlagUIStartupComplete

------------------------------------------------------
::method OnListSourceContext
------------------------------------------------------
expose sourcepopupmenu controls 
use arg hwnd,x,y
listbox = controls[self~LISTSOURCE]

if x == -1, y == -1 then do
  rect = listbox~windowRect
  x = rect~right - .SM~cxVScroll + 15
  y = rect~bottom - 15
end
index = self~ListGetSelectedIndex(controls, self~LISTSOURCE)
enable = .False
if index > 0  then do
  listtext = self~ListGetItem(controls, self~LISTSOURCE, index)
  if listtext~left(1) = '*' | listtext~left(1) = '?' then enable = .True
end
if enable then sourcepopupmenu~enable(self~BPSETTINGSMENUITEM)
else  sourcepopupmenu~disable(self~BPSETTINGSMENUITEM)
sourcepopupmenu~show(.Point~new(x,y))

------------------------------------------------------
::method OnListStackContext
------------------------------------------------------
expose stackpopupmenu controls 
use arg hwnd,x,y
listbox = controls[self~LISTSTACK]

if x == -1, y == -1 then do
  rect = listbox~windowRect
  x = rect~right - .SM~cxVScroll + 15
  y = rect~bottom - 15
end
stackpopupmenu~show(.Point~new(x,y))

--------------------------------------------
::method BreakPointSettings 
--------------------------------------------
expose activesourcename controls debugger gui
debugsettingsdialog = .BreakPointSettingsDialog~new(gui)

linenum = self~ListGetSelectedIndex(controls, self~LISTSOURCE)
debugsettingsdialog~breakpointcondition = debugger~GetBreakPointTest(activesourcename, linenum)

debugsettingsdialog~ownerDialog = self
self~disable
dlgres = debugsettingsdialog~Execute
self~enable

if dlgres = self~IDOK then do
  debugger~SetBreakPointTest(activesourcename, linenum, debugsettingsdialog~breakpointcondition)
end

self~start("SetForeground")

------------------------------------------------------
::method OnCopyStack unguarded
------------------------------------------------------
expose controls debugger
index = self~ListGetSelectedIndex(controls, self~LISTSTACK)
if index > 0  then do
  text = self~ListGetItem(controls, self~LISTSTACK, index)
  parse value text with lineno stuff text
  clipboard = .WindowsClipboard~new
  clipboard~copy(text)
end

------------------------------------------------------
::method OnCopySource unguarded
------------------------------------------------------
expose controls debugger
index = self~ListGetSelectedIndex(controls, self~LISTSOURCE)
if index > 0  then do
  text = self~ListGetItem(controls, self~LISTSOURCE, index)
  if \debugger~canopensource then parse value text with 2 lineno text
  clipboard = .WindowsClipboard~new
  clipboard~copy(text~strip)
end

------------------------------------------------------
::method OnCopyKeyCommand unguarded
------------------------------------------------------
if self~getFocus = self~getControlHandle(self~LISTSOURCE) then self~OnCopySource
else if self~getFocus = self~getControlHandle(self~LISTSTACK) then self~OnCopyStack

------------------------------------------------------
::method OnCopyKeyCommand2 unguarded
------------------------------------------------------
self~OnCopyKeyCommand

------------------------------------------------------
::method EditCommandChar 
------------------------------------------------------
use arg char
if char \= 13 then return .true
else return .false

------------------------------------------------------
::method EditReturn 
------------------------------------------------------
expose controls
self~newPushButton(self~BUTTONEXEC)~click
return 0

------------------------------------------------------
::Method AppendText unguarded
------------------------------------------------------
expose debugger debugconsoleappendbuffer  debugconsolelastupdate debugconsolefinalupdatemessage
use arg newtext, newline = .true, forcenow = .false
if newline then newtext = newtext||.endofline
debugconsoleappendbuffer = debugconsoleappendbuffer||newtext
if \debugger~isshutdown then do
  numeric digits 20
  if TIME('F') - debugconsolelastupdate > 150 * 1000 | forcenow then do
    debugconsolelastupdate = TIME('F')
    self~DoConsoleAppend
  end  
  if debugconsolefinalupdatemessage = .nil then debugconsolefinalupdatemessage = self~start("EnsureFinalConsoleUpdates", 180)
end  

------------------------------------------------------
::Method ClearConsole unguarded
------------------------------------------------------
expose debugger debugconsoleappendbuffer  debugconsolelastupdate debugconsoletextlength controls

if \debugger~isshutdown then do
  controls[self~EDITDEBUGLOG]~hidefast
  controls[self~EDITDEBUGLOG]~select(1, debugconsoletextlength + 1)
  controls[self~EDITDEBUGLOG]~replaceseltext('', .False)
  controls[self~EDITDEBUGLOG]~showfast
  controls[self~EDITDEBUGLOG]~ensureCaretVisibility
  controls[self~EDITDEBUGLOG]~redraw

  debugconsolelastupdate = TIME('F')
  debugconsoleappendbuffer = ''
  debugconsoletextlength = 0
end

------------------------------------------------------
::method EnsureFinalConsoleUpdates unguarded
------------------------------------------------------
expose debugconsolefinalupdatemessage debugconsolelastupdate debugger
use arg timeout
numeric digits 20 
complete = .False
do while  \complete & \debugger~isshutdown
  if TIME('F') - debugconsolelastupdate > timeout * 1000 then complete = .True
  else call SysSleep .025
end
debugconsolefinalupdatemessage = .nil
self~DoConsoleAppend


------------------------------------------------------
::Method DoConsoleAppend unguarded
------------------------------------------------------
expose controls debugconsoletextlength debugger debugconsoleappendbuffer consoleupdateactive scrollcharpos
numeric digits 15
if \debugger~isshutdown then do
  if debugconsoleappendbuffer \= '' then do
    consoleupdateactive = .true
    newtext = debugconsoleappendbuffer
    debugconsoleappendbuffer = ''
    controls[self~EDITDEBUGLOG]~hidefast
    controls[self~EDITDEBUGLOG]~select(debugconsoletextlength + 1, debugconsoletextlength + 1)
    controls[self~EDITDEBUGLOG]~replaceseltext(newtext, .False)
    if newtext~pos(.endofline) \= 0 then scrollcharpos = newtext~left(newtext~length - .endofline~length)~lastpos(.endofline) + debugconsoletextlength + .endofline~length
    controls[self~EDITDEBUGLOG]~select(scrollcharpos,scrollcharpos)
    if newtext~length + 1 - newtext~lastpos(.endofline) \= .endofline~length then controls[self~EDITDEBUGLOG]~scrollcommand("DOWN", 1)
    debugconsoletextlength = debugconsoletextlength + newtext~length
    controls[self~EDITDEBUGLOG]~showfast
    controls[self~EDITDEBUGLOG]~ensureCaretVisibility
    controls[self~EDITDEBUGLOG]~redraw
    consoleupdateactive = .False
  end
end

------------------------------------------------------
::method SetListSource
------------------------------------------------------
expose controls hfnt debugger loadedsources checkedsources
use arg sourcefile 

controls[self~EDITSOURCENAME]~settext(sourcefile)
arrSource = loadedsources[sourcefile]
if \checkedsources~hasitem(sourcefile) then do
  do line over arrSource~allIndexes
    if arrSource[line]~strip~left(4) = '/**/' then debugger~SetBreakPoint(sourcefile, line)
  end
  checkedsources~append(sourcefile)
  end
listbreakpoints = debugger~GetBreakpoints(sourcefile)

self~ListDeleteAllItems(controls, self~LISTSOURCE)
dc = self~getControlDC(self~LISTSOURCE)
oldfont = self~fonttodc(dc, hfnt)
maxwidth = 0
linecount = arrSource~items
do line over arrSource~allIndexes
  if listbreakpoints~hasItem(line) then do
    text = '*'
    if \self~IsBreakPointLikelyToBeHit(arrSource[line]) then text = '?'
    end
  else text=' '
  text = text||line~right(linecount~length)' 'arrSource[line]
  width = self~getTextExtent(dc, text)~width
  if width > maxwidth then maxwidth = width
  self~ListAddItem(controls, self~LISTSOURCE, text)
end

self~fonttodc(dc, oldfont)
self~freecontroldc(self~LISTSOURCE, oldfont)
self~setListWidthpx(self~LISTSOURCE, maxwidth)


------------------------------------------------------
::method SetSourceListSelectedRow unguarded
------------------------------------------------------
expose controls arrStack

-- Assumes the correct source is already loaded
-- This is just to set the position in the source listbox

newrow = arrStack[self~ListGetSelectedIndex(controls, self~LISTSTACK)]~line
if newrow <  1 | newrow >  self~ListGetRowCount(controls, self~LISTSOURCE) then return

currentrow = self~ListGetSelectedIndex(controls, self~LISTSOURCE)
visiblelistrows = self~ListGetVisibleRowCount(controls, self~LISTSOURCE)

firstvisible =  self~ListGetFirstVisible(controls, self~LISTSOURCE)
self~ListSetSelectedIndex(controls, self~LISTSOURCE, newrow)
topbottomrows = min((visiblelistrows / 10)~ceiling, 4)
newfirstvisible = -1
if newrow < firstvisible | newrow > visiblelistrows + firstvisible then do 
  newfirstvisible = newrow - (visiblelistrows / 2)~floor
  if newfirstvisible < 1 then newfirstvisible = 1
end
else if newrow - firstvisible < topbottomrows then do 
  newfirstvisible = newrow - topbottomrows
  if newfirstvisible < 1 then newfirstvisible = 1
end
else if newrow - firstvisible >= visiblelistrows - topbottomrows then do 
  newfirstvisible = newrow - (visiblelistrows - topbottomrows)
end

if newfirstvisible \= -1 then do
  self~ListSetFirstVisible(controls, self~LISTSOURCE, newfirstvisible)
end

------------------------------------------------------
::method InitSource unguarded
------------------------------------------------------
expose loadedsources activesourcename
use arg source,sourcename

self~ResetSourceState

loadedsources[sourcename] = source
activesourcename = sourcename

self~SetListSource(sourcename)

------------------------------------------------------
::method UpdateCodeView unguarded
------------------------------------------------------
expose controls arrStack activesourcename loadedsources debugger
use arg arrStack, activateindex

-- Ensure the (available) sources are loaded
do stackindex = 1 to arrstack~items
   if arrstack[stackindex]~executable~package \= .nil then do
     sourcename= arrstack[stackindex]~executable~package~name
     if \loadedsources~hasindex(sourcename) then do
      loadedsources[sourcename] = arrstack[stackindex]~executable~package~source
    end
  end  
end    

-- Populate the stack
self~ListDeleteAllItems(controls, self~LISTSTACK)
indent = arrStack~items
do frame over arrStack
  frametext = frame~makestring
  parse value frametext with pre '*-*' post
  finaltext =  pre' *-*'||" "~copies(indent *2)||strip(post)
  self~ListAddItem(controls, self~LISTSTACK, finaltext)
  indent = indent - 1
end  
self~ListSetSelectedIndex(controls, self~LISTSTACK, activateIndex)

-- Set to not redraw. Switched back on when selecting
controls[self~LISTSOURCE]~hidefast

--Ensure the correct source (if any) is loaded
if arrstack[activateindex]~executable~source \= .Nil, arrstack[activateindex]~executable~source~items \= 0 then do 
  thissourcename = arrstack[activateindex]~executable~package~name
  if thissourcename \= activesourcename then do
    if activesourcename \= .nil then self~appendtext(debugger~DebugMsgPrefix||'Switching source to 'thissourcename)
    activesourcename = thissourcename
    self~SetListSource(thissourcename)
    self~UpdateControlStates
  end  

  self~SetSourceListSelectedRow
end

-- Switch drawing back on
controls[self~LISTSOURCE]~showfast
controls[self~LISTSOURCE]~redraw

context = .nil
if arrstack[activateindex]~hasmethod("context") then do 
  context = arrstack[activateindex]~context
  signal on syntax name InvalidContext
  root = context~variables
  signal off syntax
  self~UpdateWatchWindows(root)
end    

InvalidContext:
return



------------------------------------------------------
::method UpdateWatchWindows 
------------------------------------------------------
expose varsroot watchwindows controls
use arg newroot = .Nil, setstacktotop = .False
if newroot \= .Nil then varsroot = newroot
do watchwindow over watchwindows~allitems
  watchwindow~UpdateWatchWindow(varsroot)
end  
if setstacktotop then self~ListSetSelectedIndex(controls, self~LISTSTACK, 1)

------------------------------------------------------
::method StackFrameChanged 
------------------------------------------------------
expose controls arrstack
self~UpdateCodeView(arrstack, self~ListGetSelectedIndex(controls, self~LISTSTACK))
return 0

------------------------------------------------------
::method SourceLineDoubleClicked
------------------------------------------------------
expose controls debugger activesourcename 

if activesourcename = .Nil then return

itemindex = self~ListGetSelectedIndex(controls, self~LISTSOURCE)
listtext = self~ListGetItem(controls, self~LISTSOURCE, itemindex)
if listtext~left(1) = ' ' then do
  checktext = listtext~delword(1,1)~translate~strip
  debugchar = '*'
  if \self~IsBreakpointLikelyToBeHit(checktext) then debugchar = '?'
  listtext = debugchar||listtext~substr(2)
  debugger~SetBreakpoint(activesourcename, itemindex)
end
else do
  listtext = ' '||listtext~substr(2)
  debugger~ClearBreakpoint(activesourcename, itemindex)
end
self~ListModifyItem(controls, self~LISTSOURCE, itemindex, listtext)
self~ListSetSelectedIndex(controls, self~LISTSOURCE, itemindex)

-------------------------------------------------------
::method IsBreakpointLikelyToBeHit
-------------------------------------------------------
parse arg sourceline
sourceline  = sourceline~strip
if sourceline~left(4) = '/**/' then sourceline = sourceline~substr(5)
if sourceline = '' | "END THEN ELSE OTHERWISE RETURN EXIT SIGNAL"~wordpos(sourceline~word(1)) \= 0 | ":: -- /*"~wordpos(sourceline~left(2)) \= 0 then return .False
else return .True

-------------------------------------------------------
::method SetSourceListInfoText
-------------------------------------------------------
expose controls activesourcename
use arg sourcelist

self~ListDeleteAllItems(controls, self~LISTSOURCE)

self~ListBeginSetHorizonalExtent(controls, self~LISTSOURCE)
do listrow over sourcelist
  self~ListAddItem(controls, self~LISTSOURCE, listrow)
  self~ListUpdateMaxHorizonalExtent(listrow)
end
self~ListEndSetHorizonalExtent(self~LISTSOURCE)

activesourcename = .nil
controls[self~EDITSOURCENAME]~settext("")

self~UpdateControlStates

-------------------------------------------------------
::method ResetSourceState
-------------------------------------------------------
expose loadedsources checkedsources activesourcename 

loadedsources~empty
checkedsources~empty
activesourcename=.nil

 --====================================================
::class WatchDialog subclass UserDialog inherit ResizingAdmin DialogControlHelper
--====================================================
 
::CONSTANT LISTVARS              101
::CONSTANT STATICCLASS           102
::CONSTANT SHOWGLOBALSMENUITEM   103
::CONSTANT HIDEGLOBALSMENUITEM   104
::CONSTANT CHARDISPLAYMENUITEM   105
::CONSTANT BYTEDISPLAYMENUITEM   106
::CONSTANT COPYMENUITEM          107
::CONSTANT MENUSEPARATOR1          1

::CONSTANT ROOTCOLLECTIONNAME ":Root"
::CONSTANT MAXVALUESTRINGLENGTH 255
::CONSTANT MAXNAMESTRINGLENGTH   64
::CONSTANT MAXASCIISUPPORTED    255

::ATTRIBUTE controls    private get unguarded
::ATTRIBUTE debugwindow private get unguarded
::ATTRIBUTE debugger    private get unguarded

 ------------------------------------------------------
::method init 
------------------------------------------------------
expose debugwindow controls parentwindow debugger
use arg debugwindow, gui, parentwindow, parentlist, debugger

self~init:.WatchHelper(parentlist)

controls = .Directory~new
forward class (super) continue array(.nil)

self~fontsize = gui~fontsize

dialogtitle = self~GetDialogTitle

self~create(0, 0, 180, 81, dialogtitle, "THICKFRAME")

------------------------------------------------------
::method defineDialog 
------------------------------------------------------
expose variablescollection
style = "HSCROLL VSCROLL NOTIFY PARTIAL"
self~createStaticText(self~STATICCLASS, 3, 1, 175, 9, "CENTER", "")
self~createListBox(self~LISTVARS, 2, 11, 176, 68, style)

------------------------------------------------------
::method defineSizing 
------------------------------------------------------

self~controlLeft(self~LISTVARS, 'STATIONARY', 'LEFT') 
self~controlRight(self~LISTVARS, 'STATIONARY', 'RIGHT') 
self~controlTop(self~LISTVARS, 'STATIONARY', 'TOP') 
self~controlBottom(self~LISTVARS, 'STATIONARY', 'BOTTOM') 
self~controlLeft(self~STATICCLASS, 'STATIONARY', 'LEFT') 
self~controlRight(self~STATICCLASS, 'STATIONARY', 'RIGHT') 
self~controlTop(self~STATICCLASS, 'STATIONARY', 'TOP') 
self~controlBottom(self~STATICCLASS, 'STATIONARY', 'TOP') 

return 0

------------------------------------------------------
::method initdialog 
------------------------------------------------------
expose controls debugwindow hfnt  parentwindow watchpopupmenu

watchpopupmenu = .nil
controls[self~LISTVARS] = self~newListBox(self~LISTVARS)
controls[self~STATICCLASS] = self~newstatic(self~STATICCLASS)

self~connectkeypress("OnCopyCommand", .VK~C, "CONTROL")
self~connectkeypress("OnCopyCommand2", .VK~INSERT, "CONTROL")

minsize = .Size~new(trunc(self~pixelCX / 1.75), trunc(self~pixelCY /1.2))
self~minSize = minsize

hfnt = self~createFontEx("Courier New", self~fontsize)
controls[self~LISTVARS]~setFont(hfnt, .true)

self~connectListBoxEvent(self~LISTVARS, "DBLCLK", "WatchRowDoubleClicked")
self~connectListBoxEvent(self~LISTVARS, "SELCHANGE", "WatchRowSelected")

controls[self~STATICCLASS]~setFont(hfnt, .true)
self~DisableControl(self~STATICCLASS)

parentsize = parentwindow~getrealsize
parentpos = parentwindow~getrealpos
mysize= self~getrealsize
if parentwindow = debugwindow then mystartpos = parentpos~~incr(parentsize~width, 0)
else mystartpos = parentpos~~incr(0, parentsize~height)
self~moveto(mystartpos)

.PopupMenu~connectContextMenu(self, "OnShowContextMenu", controls[self~LISTVARS]~hwnd)

self~ensurevisible
debugwindow~NotifyChildReady

------------------------------------------------------
::method OnShowContextMenu
------------------------------------------------------
expose controls parentwindow debugwindow watchopupmenu
use arg hwnd,x,y


popupmenu = .PopupMenu~new

if parentwindow = debugwindow then do
  popupmenu~insertItem(self~SHOWGLOBALSMENUITEM, self~SHOWGLOBALSMENUITEM, "Show global items")
  popupmenu~insertItem(self~HIDEGLOBALSMENUITEM, self~HIDEGLOBALSMENUITEM, "Hide global items")
  
  if self~showglobals then popupmenu~disable(self~SHOWGLOBALSMENUITEM)
  else popupmenu~disable(self~HIDEGLOBALSMENUITEM)
end

if self~isstringwindow then do
  popupmenu~insertItem(self~BYTEDISPLAYMENUITEM, self~BYTEDISPLAYMENUITEM, "Show bytes in hexdecimal")
  popupmenu~insertItem(self~CHARDISPLAYMENUITEM, self~charDISPLAYMENUITEM, "Show characters")
  if self~stringwatchshowsbytes then popupmenu~disable(self~BYTEDISPLAYMENUITEM)
  else popupmenu~disable(self~CHARDISPLAYMENUITEM)
end  

if popupmenu~getCount > 0 then popupmenu~insertSeparator(1, self~MENUSEPARATOR1, .True)
popupmenu~insertItem(self~MENUSEPARATOR1, self~COPYMENUITEM, "Copy")
if self~ListGetSelectedIndex(controls, self~LISTVARS) = 0 then popupmenu~disable(self~COPYMENUITEM)

if popupmenu~getCount > 0 then do
   selecteditem = popupmenu~track(.Point~new(x,y), self)
   if selecteditem \= 0 then do
     if selecteditem = self~SHOWGLOBALSMENUITEM then self~ShowGlobalItems
     if selecteditem = self~HIDEGLOBALSMENUITEM then self~HideGlobalItems
     if selecteditem = self~BYTEDISPLAYMENUITEM then self~DisplayStringBytes
     if selecteditem = self~CHARDISPLAYMENUITEM then self~DisplayStringCharacters
     if selecteditem = self~COPYMENUITEM        then self~OnCopyCommand
  end
end
popupmenu~destroy


------------------------------------------------------
::method ok  
------------------------------------------------------
return .False

------------------------------------------------------
::method cancel 
------------------------------------------------------
expose hfnt debugwindow
self~deletefont(hfnt)
debugwindow~RemoveWatchWindow(self)
self~CANCEL:super

------------------------------------------------------
::method OnCopyCommand unguarded
------------------------------------------------------
expose controls
if self~getFocus = self~getControlHandle(self~LISTVARS) then do
  index = self~ListGetSelectedIndex(controls, self~LISTVARS)
  if index > 0  then do
    text = self~ListGetItem(controls, self~LISTVARS, index)
    if \self~isstringwindow then text = text~substr(2)
    clipboard = .WindowsClipboard~new
    clipboard~copy(text)
  end
end

------------------------------------------------------
::method OnCopyCommand2 unguarded
------------------------------------------------------
self~OnCopyCommand


--====================================================
::class BreakPointSettingsDialog subclass userdialog --inherit ResizingAdmin
--====================================================
::constant RADIOALWAYSBREAK           101
::constant RADIOCONDITIONALBREAK      102
::constant EDITBREAKCONDITION         103

::attribute BreakpointCondition unguarded

------------------------------------------------------
::method init
------------------------------------------------------
expose controls breakpointcondition gui
use arg gui
controls = .Directory~new
breakpointcondition = ''
forward class (super) continue 
self~fontsize = gui~fontsize
self~create(1,1, 260, 70, "Breakpoint Hit", "CENTER")

------------------------------------------------------
::method defineDialog
------------------------------------------------------
expose controls

self~createRadioButtonGroup(self~RADIOALWAYSBREAK , 4, 4 , , "&Always  &When", "NOBORDER")
self~createEdit(self~EDITBREAKCONDITION, 12, 30, 242, 15)
self~createPushButton(self~IDOK, 4, 50, 38, 15, "DEFPUSHBUTTON"  ,"Ok")
self~createPushButton(self~IDCANCEL, 42, 50, 35, 15, , "Cancel")

------------------------------------------------------
::method initAutoDetection
------------------------------------------------------
self~noAutoDetection

------------------------------------------------------
::method InitDialog 
------------------------------------------------------
expose controls breakpointcondition

controls[self~RADIOALWAYSBREAK] = self~NewRadioButton(self~RADIOALWAYSBREAK)
controls[self~RADIOCONDITIONALBREAK] = self~NewRadioButton(self~RADIOCONDITIONALBREAK)
controls[self~EDITBREAKCONDITION] = self~NewEdit(self~EDITBREAKCONDITION)
if breakpointcondition = '' then do 
  self~focusControl(self~RADIOALWAYSBREAK)
  controls[self~RADIOALWAYSBREAK]~check
  controls[self~EDITBREAKCONDITION]~disable
end  
else controls[self~RADIOCONDITIONALBREAK]~check
self~connectButtonEvent(self~RADIOALWAYSBREAK, "CLICKED", "OnBreakPointAlways")
self~connectButtonEvent(self~RADIOCONDITIONALBREAK, "CLICKED", "OnBreakPointWhen")

controls[self~EDITBREAKCONDITION]~settext(breakpointcondition)

------------------------------------------------------
::method OnBreakPointAlways 
------------------------------------------------------
expose controls
controls[self~EDITBREAKCONDITION]~disable

------------------------------------------------------
::method OnBreakPointWhen
------------------------------------------------------
expose controls
controls[self~EDITBREAKCONDITION]~enable

------------------------------------------------------
::method Ok
------------------------------------------------------
expose controls breakpointcondition

if controls[self~RADIOALWAYSBREAK]~checked then breakpointcondition = ''
else breakpointcondition = controls[self~EDITBREAKCONDITION]~gettext

self~Ok:super

--====================================================
::class NewSessionDialog subclass userdialog inherit ResizingAdmin
--====================================================
::constant EDITREXXFILE         101
::constant BUTTONFIND           102
::constant RADIOARGTYPESINGLE   103
::constant RADIOARGTYPEMULTIPLE 104
::constant EDITARGS             105

::constant STATICREXXFILETEXT   201
::constant STATICARGSGROUP      202

------------------------------------------------------
::method init
------------------------------------------------------
expose controls gui
use arg gui
controls = .Directory~new
forward class (super) continue 
self~fontsize = gui~fontsize
self~create(1,1, 260, 100, "New Debug Session", "THICKFRAME, CENTER")


------------------------------------------------------
::method defineDialog
------------------------------------------------------
expose controls
self~createStaticText(self~STATICREXXFILETEXT, 4, 9, 50, 13, , "Rexx program:")
self~createEdit(self~EDITREXXFILE, 54, 7, 174, 15)
self~createPushButton(self~BUTTONFIND, 230, 7, 25, 15,,"&Find", "OnFindButton")
self~createGroupBox(self~STATICARGSGROUP, 4, 23, 251, 55, ,"Arguments" )
self~createRadioButtonGroup(self~RADIOARGTYPESINGLE , 6, 33, ,"&Single &Multiple", "NOBORDER")
self~createEdit(self~EDITARGS, 7, 57, 243, 15)
self~createPushButton(self~IDOK, 4, 80, 35, 15, "DEFPUSHBUTTON"  ,"Ok")
self~createPushButton(self~IDCANCEL, 42, 80, 35, 15, , "Cancel")

------------------------------------------------------
::method defineSizing
------------------------------------------------------
do expandrightcontrol over .Array~of(self~EDITREXXFILE, self~STATICARGSGROUP, self~EDITARGS)
  self~controlLeft(expandrightcontrol, 'STATIONARY', 'LEFT') 
  self~controlRight(expandrightcontrol, 'STATIONARY', 'RIGHT') 
  self~controlTop(expandrightcontrol, 'STATIONARY', 'TOP') 
  self~controlBottom(expandrightcontrol, 'STATIONARY', 'TOP') 
end
do fixedcontrol over .Array~of(self~STATICREXXFILETEXT, self~RADIOARGTYPESINGLE, self~RADIOARGTYPEMULTIPLE)
  self~controlLeft(fixedcontrol, 'STATIONARY', 'LEFT') 
  self~controlRight(fixedcontrol, 'STATIONARY', 'LEFT') 
  self~controlTop(fixedcontrol, 'STATIONARY', 'TOP') 
  self~controlBottom(fixedcontrol, 'STATIONARY', 'TOP') 
end
do movedowncontrol over .Array~of(self~IDOK, self~IDCANCEL)
  self~controlLeft(movedowncontrol, 'STATIONARY', 'LEFT') 
  self~controlRight(movedowncontrol, 'STATIONARY', 'LEFT') 
  self~controlTop(movedowncontrol, 'STATIONARY', 'BOTTOM') 
  self~controlBottom(movedowncontrol, 'STATIONARY', 'BOTTOM') 
end
do moverightcontrol over .Array~of(self~BUTTONFIND)
  self~controlLeft(moverightcontrol, 'STATIONARY', 'RIGHT') 
  self~controlRight(moverightcontrol, 'STATIONARY', 'RIGHT') 
  self~controlTop(moverightcontrol, 'STATIONARY', 'TOP') 
  self~controlBottom(moverightcontrol, 'STATIONARY', 'TOP') 
end


return 0

------------------------------------------------------
::method initAutoDetection
------------------------------------------------------
self~noAutoDetection

------------------------------------------------------
::method initDialog
------------------------------------------------------
expose controls

minsize = .Size~new(self~pixelCX, self~pixelCY)
maxsize = .Size~new(1024, self~pixelCY)
self~minSize = minsize
self~maxSize = maxsize

parentsize = self~ownerdialog~getrealsize
parentpos = self~ownerdialog~getrealpos
mysize= self~getrealsize
mystartpos = parentpos~~incr(((parentsize~width - mysize~width) / 2)~floor, ((parentsize~height - mysize~height) / 2)~floor)
self~moveto(mystartpos)

controls[self~EDITREXXFILE] = self~NewEdit(self~EDITREXXFILE)
controls[self~EDITARGS] = self~NewEdit(self~EDITARGS)
controls[self~EDITARGS] = self~NewEdit(self~EDITARGS)
controls[self~RADIOARGTYPESINGLE] = self~NewRadioButton(self~RADIOARGTYPESINGLE)
controls[self~RADIOARGTYPEMULTIPLE] = self~NewRadioButton(self~RADIOARGTYPEMULTIPLE)


controls[self~EDITREXXFILE]~settext(.local~rexxdebugger.rexxfile)
controls[self~EDITARGS]~settext(.local~rexxdebugger.rawargstring)
if \.local~rexxdebugger.multipleargs then controls[self~RADIOARGTYPESINGLE]~check
else controls[self~RADIOARGTYPEMULTIPLE]~check

------------------------------------------------------
::method Ok
------------------------------------------------------
expose controls

.local~rexxdebugger.rexxfile = controls[self~EDITREXXFILE]~gettext
.local~rexxdebugger.rawargstring = controls[self~EDITARGS]~gettext
.local~rexxdebugger.multipleargs = controls[self~RADIOARGTYPEMULTIPLE]~checked

self~setforegroundWindow(self~ownerdialog~hwnd)

self~Ok:super

------------------------------------------------------
::method OnFindButton
------------------------------------------------------
expose controls

curdir = directory()

currentsel = controls[self~EDITREXXFILE]~gettext~strip
if currentsel \= '' then currentsel =.File~new(currentsel)~absoluteFile~string

delimiter = '0'x
rexxfiletypes = .Array~of('rex', 'orx', 'rexx', 'rxj', 'rxo')
rexxseltypes = 'Rexx Files ('
do ext over rexxfiletypes~allitems
  rexxseltypes = rexxseltypes||'*.'||ext||','
end
rexxseltypes = rexxseltypes~STRIP('T',',')||')'||delimiter
do ext over rexxfiletypes~allitems
  rexxseltypes = rexxseltypes||'*.'||ext||';'
end
rexxseltypes = rexxseltypes~STRIP('T',';')||delimiter
seltypes = rexxseltypes||'All Files'||delimiter||'*.*'||delimiter
findresult= FileNameDialog(currentsel, self~hwnd, seltypes,,"Find Program")
if findresult \= 0 then controls[self~EDITREXXFILE]~settext(findresult)

call directory curdir

--====================================================
::class DialogControlHelper mixinclass object 
--====================================================

------------------------------------------------------
::method ListSetSelectedIndex
------------------------------------------------------
use arg controls, listid, newindex

self~setcurrentListIndex(listid, newindex)

------------------------------------------------------
::method ListGetSelectedIndex
------------------------------------------------------
use arg controls, listid

return controls[listId]~selectedindex

------------------------------------------------------
::method ListGetRowCount
------------------------------------------------------
use arg controls, listid

return self~getListItems(listid)

------------------------------------------------------
::method ListGetFirstVisible
------------------------------------------------------
use arg controls, listid

return controls[listId]~getFirstVisible


------------------------------------------------------
::method ListGetVisibleRowcount
------------------------------------------------------
use arg controls, listid

rowheight =  controls[listid]~itemHeightPX
listrect = self~getcontrolRect(listid)
listheight = listrect~bottom - listrect~top
visiblelistrows = (listheight / rowheight)~floor - 2
listitems = self~getListItems(listid) - 1
if listitems >=0 & listitems < visiblelistrows then visiblelistrows = listitems
return visiblelistrows

------------------------------------------------------
::method ListSetFirstVisible
------------------------------------------------------
use arg controls, listid, newfirstvisible

controls[listid]~makefirstvisible(newfirstvisible)

------------------------------------------------------
::method ListClearSelection
------------------------------------------------------
use arg controls, listid

self~setcurrentListIndex(listid)

------------------------------------------------------
::method ListDeleteAllItems
------------------------------------------------------
use arg controls, listid

controls[listid]~deleteall

------------------------------------------------------
::method ListAddItem
------------------------------------------------------
use arg controls, listid, text

controls[listid]~add(text)

------------------------------------------------------
::method ListGetItem
------------------------------------------------------
use arg controls, listid, itemindex

return controls[listid]~getText(itemindex)

------------------------------------------------------
::method ListModifyItem
------------------------------------------------------
use arg controls, listid, itemindex, text

controls[listid]~modify(itemindex, text)


------------------------------------------------------
::method ListBeginSetHorizonalExtent
------------------------------------------------------
expose dc oldfont maxwidth
use arg controls, listid

dc = self~getControlDC(listid)
oldfont = self~fonttodc(dc, controls[listid]~getFont)
maxwidth = 0

------------------------------------------------------
::method ListUpdateMaxHorizonalExtent
------------------------------------------------------
expose dc maxwidth
use arg text

width = self~getTextExtent(dc, text)~width
if width > maxwidth then maxwidth = width

------------------------------------------------------
::method ListEndSetHorizonalExtent
------------------------------------------------------
expose dc oldfont maxwidth
use arg listid

self~fonttodc(dc, oldfont)
self~freecontroldc(listid, oldfont)
self~setListWidthpx(listid, maxwidth)

------------------------------------------------------
::method ControlEnable
------------------------------------------------------
use arg controls, controlid, enable

if enable then self~EnableControl(controlid)
else self~DisableControl(controlid)

------------------------------------------------------
::method ControlSetText
------------------------------------------------------
use arg controls, controlid, text

controls[controlid]~setText(text)


------------------------------------------------------
::method ControlDeferRedraw
------------------------------------------------------
use arg controls, controlid, defer
if defer then controls[controlid]~hidefast
else do
  controls[controlid]~showfast
  controls[controlid]~redraw
end


------------------------------------------------------
::method ButtonSetText
------------------------------------------------------
use arg controls, buttonid, text

controls[buttonid]~setText(text)
controls[buttonid]~redraw
  
------------------------------------------------------
::method ButtonGetText
------------------------------------------------------
use arg controls, buttonid

return controls[buttonid]~getText~changeStr("&", "")

------------------------------------------------------
::ROUTINE  "SysQueryProcessRoutine"  EXTERNAL "LIBRARY rexxutil SysQueryProcess"
------------------------------------------------------


::requires oodialog.cls
::requires winsystm.cls

--::OPTIONS NOVALUE SYNTAX /* ooRexx 5+ only */
--::options trace R