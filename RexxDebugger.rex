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

-- Below is the help text that will initially be added to the source list 
.local~rexxdebugger.startuphelptext = .list~of( -
"A TRACE ?R statement near the start of your program and", - 
"::REQUIRES RexxDebugger.rex at the end will launch this", -
"debugger when the program runs.", -
"Source code will be shown when tracing is started.")

-- The line below can be moved into your program or a routine to control when the debugger launches and how the
-- debug window is positioned (UDLR) relative to the (named) application window
.local~rexxdebugger.debugger = .RexxDebugger~new(/*application window name*/, /*offset for debug window UDLR */)
-- Alternatively you can  include ::REQUIRES DeferRexxDebuggerLaunch.rex above the 
--  ::REQUIRES RexxDebugger.rex and call its LaunchRexxDebugger routine in your program  to set position

/*====================================================
The core code of the debugging library follows below
====================================================*/

::CONSTANT VERSION "1.001"

--====================================================
::class RexxDebugger public
--====================================================
::attribute windowname unguarded
::attribute offsetdirection unguarded

------------------------------------------------------
::method CreateDialogThread 
------------------------------------------------------
expose debugdialog dialogthreadinitialised

debugdialog = .nil
dialogthreadinitialised = .False

self~RunDialogThread

guard off when dialogthreadinitialised = .True --Wait for dialog to start up

------------------------------------------------------
::method SetDialogThreadInitialised unguarded
------------------------------------------------------
expose dialogthreadinitialised

dialogthreadinitialised = .True

------------------------------------------------------
::method RunDialogThread unguarded
------------------------------------------------------
expose debugdialog
REPLY /* Switch to a new thread */
debugdialog = .DebugDialog~new(self, .rexxdebugger.startuphelptext)

debugdialog~popup("SHOWTOP")


------------------------------------------------------
::method init 
------------------------------------------------------
expose  shutdown launched  breakpoints tracedprograms manualbreak windowname offsetdirection nulltracer

use arg windowname = "", offsetdirection = ""

shutdown = .False
launched = .False
breakpoints = .Set~new
tracedprograms = .Set~new
manualbreak = .false
nulltracer = .nil

if .local~rexxdebugger.deferlaunch \= .true then do
  .local~rexxdebugger.deferlaunch = .false
  self~launch(windowname, offsetdirection)
end

------------------------------------------------------
::method launch 
------------------------------------------------------
expose launched windowname offsetdirection
use arg windowname = "", offsetdirection = ""

if launched = .true then return

launched = .true
self~CreateDialogThread
ignore =  .debuginput~destination(self)

------------------------------------------------------
::method informshutdown unguarded
------------------------------------------------------
expose shutdown
shutdown = .True

------------------------------------------------------
::method  isshutdown unguarded
------------------------------------------------------
expose shutdown
return shutdown

------------------------------------------------------
::method SetBreakPoint unguarded
------------------------------------------------------
expose breakpoints
use arg sourcefile, sourceline

breakpoints~put(sourcefile':'sourceline)

------------------------------------------------------
::method ClearBreakPoint  unguarded
------------------------------------------------------
expose breakpoints
use arg sourcefile, sourceline

ignore = breakpoints~remove(sourcefile':'sourceline)

------------------------------------------------------
::method CheckBreakPoint 
------------------------------------------------------
expose breakpoints
use arg sourcefile, sourceline

return breakpoints~hasindex(sourcefile':'sourceline)

------------------------------------------------------
::method GetBreakPoints 
------------------------------------------------------
expose breakpoints
use arg sourcefile 
listBreakpoints = .List~new
do breakpoint over breakpoints
  if breakpoint~pos(sourcefile':') = 1 then listbreakpoints~append(breakpoint~changestr(sourcefile':', ''))
end

return listBreakpoints


------------------------------------------------------
::method SendDebugMessage unguarded
------------------------------------------------------
expose debugdialog
use  arg text, newline = .true
if debugdialog \= .nil then debugdialog~appendtext(text, newline)

------------------------------------------------------
::method CaptureConsoleOutput 
------------------------------------------------------
expose nulltracer
use arg discardtrace
IF TRACE() = 'N' THEN do /* If debugger is not tracing itself! */
  if discardtrace then do 
    if \nulltracer~IsA(.NullTracer) Then nulltracer = .NullTracer~new(self)
    ignore = .traceoutput~destination(nulltracer)
  end
  else  ignore = .traceoutput~destination(self)
  ignore = .output~destination(self)
  ignore = .error~destination(self)
  return .True
END
else do
  self~SendDebugMessage("CAPTURE[X] cannot be used while tracing for the debugger is active")
  return .False
end

------------------------------------------------------
::method LINEOUT 
------------------------------------------------------
use arg text
self~SendDebugMessage(text)
return 0

------------------------------------------------------
::method CHAROUT 
------------------------------------------------------
use arg text
self~SendDebugMessage(text, .false)
return 0

------------------------------------------------------
::method SAY 
------------------------------------------------------
use arg text
self~SendDebugMessage(text)

------------------------------------------------------
::method LINEIN 
------------------------------------------------------
return self~ReplyWithTraceCommand


------------------------------------------------------
::method unknown 
------------------------------------------------------
expose target -- will receive all of the unknown messages
use arg name, arguments
self~SendDebugMessage("Error: Unsupported output command "name" sent to the debugger with args: '" arguments~toString"'")

------------------------------------------------------
::method ReplyWithTraceCommand 
------------------------------------------------------
expose debugdialog shutdown
if shutdown then return 'exit' 
else response =self~GetAutoResponse
if response \= "" | .debug.channel~status = "breakpointcheckgetlocation" then return response 

response =  debugdialog~GetNextResponse

if translate(response) = 'EXIT' then do
   self~informshutdown
   return 'say "Exiting as instructed by the debugger"; exit'
   end
if translate(response) = 'RUN' then do
  .debug.channel~status="breakpointcheckgetlocation"
  return ''
end  
if word(translate(response), 1) = 'TRACE' then .debug.channel~status="getprogramstatus"
if translate(response) = 'NEXT' | response = '' then do
  .debug.channel~status="getprogramstatus"
  return ''
end  
if translate(response)~word(1) = 'NEXT' & response~words > 1 then do
  .debug.channel~status="getprogramstatus "||response~DELWORD(1,1)
  return ''
end  
if translate(response) = 'UPDATEVARS' then do
  .debug.channel~status="getvars"
  return 'NOP'
end  
if translate(response) = 'CAPTURE' | translate(response) = 'CAPTUREX' then do 
   if translate(response) = 'CAPTURE' then discardtrace = .False
   else  discardtrace = .True
   if self~captureconsoleoutput(discardtrace) then do
     retstr = 'call SAY "Output redirected to the debugger if the program permits this."'
     if discardtrace = .False then retstr = retstr||'.endofline||"CAPTUREX does the same but discards trace text."'
     else retstr = retstr||'.endofline||"All trace apart from runtime error messages will be discarded."'
     return retstr
   end  
end
  
.debug.channel~status="getprogramstatus"
return response

------------------------------------------------------
::method GetAutoResponse 
------------------------------------------------------
expose debugdialog tracedprograms manualbreak

response =  ""

if .local~debug.channel = .nil then do
  .local~debug.channel = .Directory~new
  .debug.channel~status="getprogramstatus"
  .debug.channel~frames=.Nil
  .debug.channel~variables=.Nil
  response = ''
end
if .debug.channel~status="breakpointcheckgetlocation" then do
  response = '.debug.channel~status="breakpointchecklocationis ".context~line' '.context~package~name'
  .debug.channel~status = "breakpointchecklocationis"
end  
else if .debug.channel~status~word(1)="breakpointchecklocationis" then do
  parse value .debug.channel~status with ignore linenumber sourcefile -- Is this a breakpoint ?
  if self~CheckBreakpoint(sourcefile, linenumber) then do  
    response = 'NOP'
    .debug.channel~status="getprogramstatus"
 end
 else if \tracedprograms~hasitem(sourcefile) then do -- Is this a new program which traces ?
    tracedprograms~put(sourcefile)
    response = 'NOP'
    .debug.channel~status="getprogramstatus"
  end
  else if manualbreak then do -- Was a break issued from the dialog? 
   manualbreak = .false
   response = 'NOP'
    .debug.channel~status="getprogramstatus"
  end
  else do       
    .debug.channel~status = "breakpointcheckgetlocation"
    return ''
  end  
end  
else if .debug.channel~status~word(1)="getprogramstatus" then do
  instructions = .debug.channel~status~delword(1,1)~strip
  if instructions \= '' then do 
     response = instructions
    .debug.channel~frames= .nil
    .debug.channel~variables= .nil
    .debug.channel~status="getprogramstatus"
  end
  else do  
    response = response||'.debug.channel~frames = .context~StackFrames~section(2); .debug.channel~variables=.context~variables;  .debug.channel~status="programstatusupdated"'
    .debug.channel~frames= .nil
    .debug.channel~variables= .nil
  end  
end      
else if .debug.channel~status="programstatusupdated" then do
  if .debug.channel~frames \=.nil then do
    tracedprograms~put(.debug.channel~frames~firstitem~executable~package~name)
    debugDialog~UpdateCodeView(.debug.channel~frames, 1)
  end  
  if .debug.channel~variables \=.nil then debugDialog~UpdateWatchWindows(.debug.channel~variables)
  .debug.channel~frames= .nil
  .debug.channel~variables= .nil
  .debug.channel~status=""
  response = ''
end
else if .debug.channel~status="getvars" then do
  .debug.channel~frames= .nil
  .debug.channel~variables= .nil
  response = response||'.debug.channel~variables=.context~variables;  .debug.channel~status="gotvars"'
end      
else if .debug.channel~status="gotvars" then do
  if .debug.channel~variables \=.nil then debugDialog~UpdateWatchWindows(.debug.channel~variables)
  .debug.channel~frames= .nil
  .debug.channel~variables= .nil
  .debug.channel~status=""
  response = 'NOP'
end
return response

------------------------------------------------------
::method SetManualBreak
------------------------------------------------------
expose manualbreak
manualbreak = .True

--====================================================
::class DebugDialog subclass UserDialog inherit ResizingAdmin
--====================================================

::constant LISTSOURCE   100
::constant LISTSTACK    101
::constant EDITDEBUGLOG 102
::constant BUTTONNEXT   103
::constant BUTTONRUN    104
::constant BUTTONEXIT   105
::constant BUTTONVARS   106
::constant BUTTONHELP   107
::constant EDITCOMMAND  108
::constant BUTTONEXEC   109

------------------------------------------------------
::method ok  
------------------------------------------------------
return .False

------------------------------------------------------
::method cancel unguarded
------------------------------------------------------
expose waiting debugger hfnt watchwindows controls
close = .True
if waiting = .True then do
   ret = RxMessageBox("Do you really want to quit and end the program?", "Program still running", "YESNO", "QUESTION")
   if ret = 7 then close = .False
end
if close then do
  controls[self~LISTSOURCE]~deleteall
  controls[self~LISTSTACK]~deleteall
  self~deletefont(hfnt)
  watchlist = watchwindows~allitems~section(1)
  do watchwindow over watchlist~allitems
     watchwindow~cancel
  end   
  self~CANCEL:super
  debugger~informshutdown
  if waiting then self~HereIsResponse('say "Debugger closed - exiting"')
end

------------------------------------------------------
::method UpdateControlStates 
------------------------------------------------------
expose waiting controls watchwindows
do control over .array~of(SELF~LISTSOURCE, SELF~LISTSTACK, self~BUTTONNEXT, /*self~BUTTONRUN, */self~BUTTONEXIT, self~BUTTONVARS, self~BUTTONEXEC, self~BUTTONHELP)
  if waiting then self~EnableControl(control)
  else self~DisableControl(control)  
end    
if waiting & controls[self~BUTTONRUN]~gettext \= "&Run" then controls[self~BUTTONRUN]~settext("&Run")
do watchwindow over watchwindows~allitems
  watchwindow~SetListState(waiting)
end
------------------------------------------------------
::method init 
------------------------------------------------------
expose debugger controls waiting arrcommands commandnum arrstack activesourcename loadedsources watchwindows startuphelptext checkedsources
use strict arg debugger, startuphelptext

arrstack = .nil
activesourcename = .nil
loadedsources = .Directory~new
watchwindows = .Directory~new
checkedsources = .List~new

waiting = .false
controls = .Directory~new

forward class (super) continue array(.nil)
self~create(6, 15, 280, 290, "Rexx Debugger Version "||GetPackageConstant("Version"), "THICKFRAME, CENTER, MAXIMIZEBOX,MINIMIZEBOX")
self~connectResize("onResize")

arrcommands = .Array~new
commandnum = 0

------------------------------------------------------
::method GetNextResponse 
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
expose waiting response
use arg response
waiting = .False

------------------------------------------------------
::method defineDialog 
------------------------------------------------------
expose u 

self~createListBox(self~LISTSOURCE, 3, 2, 273, 135, "HSCROLL VSCROLL NOTIFY")
self~createListBox(self~LISTSTACK, 3, 136, 273, 43, "VSCROLL AUTOVSCROLL NOTIFY")
self~createEdit(self~EDITDEBUGLOG, 3, 167, 240, 102, "HSCROLL VSCROLL MULTILINE")
self~createPushButton(self~BUTTONNEXT, 246, 167, 30, 15,  ,"&Next", OnNextButton) 
self~createPushButton(self~BUTTONRUN, 246, 184, 30, 15,  ,"&Run", OnRunButton) 
self~createPushButton(self~BUTTONEXIT, 246, 201, 30, 15,  ,"E&xit", OnExitButton) 
self~createPushButton(self~BUTTONVARS, 246, 218, 30, 15,  ,"&Vars", OnVarsButton) 
self~createPushButton(self~BUTTONHELP, 246, 235, 30, 15,  ,"&Help", OnHelpButton) 
self~createEdit(self~EDITCOMMAND, 3, 271, 240, 15, "WANTRETURN")
self~createPushButton(self~BUTTONEXEC, 246, 271,  30, 15, "DEFPUSHBUTTON"  ,"&Exec", OnExecButton)


------------------------------------------------------
::method defineSizing 
------------------------------------------------------

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


do id over .List~of(self~BUTTONRUN, self~BUTTONNEXT, self~BUTTONEXIT, self~BUTTONEXEC, self~BUTTONVARS, self~EDITCOMMAND, self~BUTTONHELP)
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
::method OnNextButton 
------------------------------------------------------
expose waiting controls
if waiting then do
  instructions = controls[self~EDITCOMMAND]~gettext~strip
  firstword = instructions~word(1)~translate
  if "RUN EXIT HELP CAPTURE"~wordpos(instructions~word(1)~translate) \= 0 then do 
    call SAY 'This command cannot be used with Next at this time'
    return
  end  
  if instructions~word(1)~translate\='NEXT' then instructions = 'NEXT 'instructions
  self~HereIsResponse(instructions)
end
------------------------------------------------------
::method OnRunButton 
------------------------------------------------------
expose waiting debugger controls
if waiting then do
  self~HereIsResponse('RUN')
  controls[self~BUTTONRUN]~settext("B&reak")
end
else do
  debugger~SetManualBreak
end

------------------------------------------------------
::method OnExitButton 
------------------------------------------------------
expose waiting 
if waiting then do
   ret = RxMessageBox("Do you really want to exit the program?", "Program still running", "YESNO", "QUESTION")
   if ret \= 7 then  self~HereIsResponse('EXIT')
end

------------------------------------------------------
::method OnVarsButton 
------------------------------------------------------
expose waiting watchdialog debugger varsroot
if waiting then do
  self~AddWatchWindow(self)
end
  ---------------------------------------------------
::method OnHelpButton 
------------------------------------------------------
expose debugger
debugger~SendDebugMessage("- Commands: <instrs> | NEXT [<instrs>] | RUN | EXIT | CAPTURE | CAPTUREX - use the Exec button to run the command.")
debugger~SendDebugMessage("- Buttons with the above labels execute the corresponding command.")
debugger~SendDebugMessage("- Command history for the session can be accessed with the up/down keys.")
debugger~SendDebugMessage("- The Vars button opens a realtime variables window.")
debugger~SendDebugMessage("- Double clicking many collection object types in a variables window will expand them in a new window.")
debugger~SendDebugMessage("- Clicking a stack row takes you to the specified source location and file.")
debugger~SendDebugMessage("- Double clicking a source row toggles a breakpoint, but this does not guarantee that the line will be hit.")
debugger~SendDebugMessage("  Some simple hit checks are carried out but there is no detailed code analysis.")
debugger~SendDebugMessage("  e.g. if it is empty, a comment, a directive or is END, THEN, ELSE, OTHERWISE, RETURN, EXIT or SIGNAL")
debugger~SendDebugMessage("  DO statements should be hit unless they mark the start of a loop that has looped once already.")
debugger~SendDebugMessage("  CALL statements (and what they call) may be hit, depending on what they are calling.")
debugger~SendDebugMessage("  A * means the debugger thinks the code will be hit, a ? means it thinks it likely it won't ever be hit.")
debugger~SendDebugMessage("  Hint: A line with just NOP can be inserted as an anchor for a breakpoint that will always be hit.")
debugger~SendDebugMessage("- /**/ at the start of traceable line (including NOP) causes a breakpoint to be automatically set for that line.")
debugger~SendDebugMessage("- The instruction CALL SAY ... will always send output here.")
debugger~SendDebugMessage("- So long as SAY is enabled in the target application, other output should appear there.")
debugger~SendDebugMessage("- If the application has no output, or you want the output here, you can try the CAPTURE command to capture all output.")
debugger~SendDebugMessage("  CAPTUREX is similar but will discard (eXclude) all trace output apart from program errors.")
debugger~SendDebugMessage("- The source window and watch windows go grey while the program is running and after it has finished.")
debugger~SendDebugMessage("Happy debugging!")

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
expose watchwindows  childready rootlist
use arg  parentwindow, parentlist = .nil
if parentlist = .nil then do
  if \rootlist~isA(.List) then rootlist = .list~new
  parentlist = rootlist
end  
watchwindowid = ""
do item over parentlist
  watchwindowid = watchwindowid||':'||item~makestring
end  
if \watchwindows~hasindex(watchwindowid) then do
  childready = .False
  watchdialog = .Watchdialog~new(self, parentwindow, parentlist)
  watchdialog~popup("SHOWTOP")
  watchwindows[watchwindowid] = watchdialog
  guard off when childready = .True
end
else self~setforegroundWindow(watchwindows[watchwindowid]~hwnd)


self~HereIsResponse("UPDATEVARS")

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
expose u controls debugtext buttonpushed debugger hfnt startuphelptext

controls[self~EDITDEBUGLOG] = self~newEdit(.DebugDialog~EDITDEBUGLOG)
controls[self~EDITDEBUGLOG]~setreadonly
controls[self~EDITCOMMAND] = self~newEdit(.DebugDialog~EDITCOMMAND)
controls[self~BUTTONEXEC] = self~newPushButton(self~BUTTONEXEC)
controls[self~LISTSOURCE] = self~newListBox(self~LISTSOURCE)
controls[self~LISTSTACK] = self~newListBox(self~LISTSTACK)
controls[self~BUTTONRUN] = self~newPushButton(self~BUTTONRUN)

controls[self~EDITCOMMAND]~connectkeypress(OnPrevCommand, .VK~UP)
controls[self~EDITCOMMAND]~connectkeypress(OnNextCommand, .VK~DOWN)
controls[self~EDITCOMMAND]~wantreturn("EditReturn")
controls[self~EDITCOMMAND]~connectCharEvent(EditCommandChar)

debugtext = ''
buttonpushed = .False
self~UpdateControlStates

minsize = .Size~new(self~pixelCX, self~pixelCY)
self~minSize = minsize

hfnt = self~createFontEx("Courier New", 8)
controls[self~LISTSOURCE]~setFont(hfnt, .true)
controls[self~LISTSTACK]~setFont(hfnt, .true)
if startuphelptext~isA(.list) then do listrow over startuphelptext
  controls[self~LISTSOURCE]~add(listrow)
end
else controls[self~LISTSOURCE]~add("No startup help text is available")
self~connectListBoxEvent(self~LISTSTACK, SELCHANGE, "StackFrameChanged")
self~connectListBoxEvent(self~LISTSOURCE, DBLCLK, "SourceLineDoubleClicked")

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

debugger~SetDialogThreadInitialised

------------------------------------------------------
::method CalculateVisibleListRows 
------------------------------------------------------
expose visiblelistrows controls
rowheight =  controls[self~LISTSOURCE]~itemHeightPX
listrect = self~getcontrolRect(self~LISTSOURCE)
listheight = listrect~bottom - listrect~top
visiblelistrows = (listheight / rowheight)~floor - 2


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
::Method AppendText 
------------------------------------------------------
expose controls debugtext debugger
use arg newtext, newline = .true

debugtext = debugtext||newtext
if newline  then debugtext = debugtext||.endofline
if \debugger~isshutdown then do
  controls[self~EDITDEBUGLOG]~hidefast
  controls[self~EDITDEBUGLOG]~settext(debugtext)
  scrollcharpos = debugtext~lastpos(.endofline) + .endofline~length
  controls[self~EDITDEBUGLOG]~select(scrollcharpos,scrollcharpos)
  controls[self~EDITDEBUGLOG]~showfast
  controls[self~EDITDEBUGLOG]~ensureCaretVisibility
  controls[self~EDITDEBUGLOG]~draw
end

------------------------------------------------------
::method SetListSource 
------------------------------------------------------
expose controls hfnt debugger loadedsources checkedsources
use arg sourcefile 

arrSource = loadedsources[sourcefile]
if \checkedsources~hasitem(sourcefile) then do
  do line over arrSource~allIndexes
    if arrSource[line]~strip~left(4) = '/**/' then debugger~SetBreakPoint(sourcefile, line)
  end
  checkedsources~append(sourcefile)
  end
listbreakpoints = debugger~GetBreakpoints(sourcefile)

controls[self~LISTSOURCE]~deleteall
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
  controls[self~LISTSOURCE]~add(text)
end

self~fonttodc(dc, oldfont)
self~freecontroldc(self~LISTSOURCE, oldfont)
self~setListWidthpx(self~LISTSOURCE, maxwidth)


------------------------------------------------------
::method SetSourceListSelectedRow 
------------------------------------------------------
expose visiblelistrows controls arrStack

-- Assumes the correct source is already loaded
-- This is just to set the position in the source listbox

newrow = arrStack[controls[self~LISTSTACK]~selectedindex]~line
if newrow <  1 | newrow >  self~getListItems(self~LISTSOURCE) then return

currentrow = self~GetcurrentListIndex(self~LISTSOURCE)
firstvisible =  controls[self~LISTSOURCE]~getfirstvisible
topbottomrows = min((visiblelistrows / 10)~ceiling, 4)
self~setcurrentListIndex(self~LISTSOURCE, newrow)
if newrow < firstvisible | newrow > visiblelistrows + firstvisible then do 
  firstrow = newrow - (visiblelistrows / 2)~floor
  if firstrow < 1 then firstrow = 1
  controls[self~LISTSOURCE]~makefirstvisible(firstrow)
end
else if newrow - firstvisible < topbottomrows then do 
  firstrow = newrow - topbottomrows
  if firstrow < 1 then firstrow = 1
  controls[self~LISTSOURCE]~makefirstvisible(firstrow)
end
else if newrow - firstvisible >= visiblelistrows - topbottomrows then do 
  firstrow = newrow - (visiblelistrows - topbottomrows)
  controls[self~LISTSOURCE]~makefirstvisible(firstrow)
end

------------------------------------------------------
::method UpdateCodeView 
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
controls[self~LISTSTACK]~deleteall
indent = arrStack~items
do frame over arrStack
  frametext = frame~makestring
  parse value frametext with pre '*-*' post
  finaltext =  pre' *-*'||" "~copies(indent *2)||strip(post)
  controls[self~LISTSTACK]~add(finaltext)
  indent = indent - 1
end  
self~setcurrentListIndex(self~LISTSTACK, activateindex)

-- Set to not redraw. Switched back on when selecting
controls[self~LISTSOURCE]~hidefast

--Ensure the correct source (if any) is loaded
if arrstack[activateindex]~executable~package \= .nil then do 
  thissourcename = arrstack[activateindex]~executable~package~name
  if thissourcename \= activesourcename then do
    if activesourcename \= .nil then debugger~SendDebugMessage('Switching source to 'thissourcename)
    activesourcename = thissourcename
    self~SetListSource(thissourcename)
  end  

  self~CalculateVisibleListRows
  self~SetSourceListSelectedRow
 
end

-- Switch drawing back on
controls[self~LISTSOURCE]~showfast
controls[self~LISTSOURCE]~redraw

------------------------------------------------------
::method UpdateWatchWindows 
------------------------------------------------------
expose varsroot watchwindows
use arg varsroot

do watchwindow over watchwindows~allitems
  watchwindow~UpdateWatchWindow(varsroot)
end  

------------------------------------------------------
::method StackFrameChanged 
------------------------------------------------------
expose controls arrstack
self~UpdateCodeView(arrstack, controls[self~LISTSTACK]~selectedindex)
return 0

------------------------------------------------------
::method SourceLineDoubleClicked
------------------------------------------------------
expose controls debugger activesourcename 

itemindex = controls[self~LISTSOURCE]~selectedindex
listtext = controls[self~LISTSOURCE]~selected
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
controls[self~LISTSOURCE]~modify(itemindex, listtext)
controls[self~LISTSOURCE]~selectindex(itemindex)

-------------------------------------------------------
::method IsBreakpointLikelyToBeHit
-------------------------------------------------------
parse arg sourceline
sourceline  = sourceline~strip
if sourceline~left(4) = '/**/' then sourceline = sourceline~substr(5)
if sourceline = '' | "END THEN ELSE OTHERWISE RETURN EXIT SIGNAL"~wordpos(sourceline~word(1)) \= 0 | ":: -- /*"~wordpos(sourceline~left(2)) \= 0 then return .False
else return .True

 --====================================================
::class WatchDialog subclass UserDialog inherit ResizingAdmin
--====================================================
 
::CONSTANT LISTVARS 101
::CONSTANT ROOTCOLLECTIONNAME ":Root"
::CONSTANT MAXVALUESTRINGLENGTH 255


 ------------------------------------------------------
::method init 
------------------------------------------------------
expose debugwindow controls parentwindow parentlist currentselectioninfo varsvalid
use arg debugwindow, parentwindow, parentlist


controls = .Directory~new
currentselectioninfo = ""
varsvalid = .False
forward class (super) continue array(.nil)

dialogtitle = "Watch"
do elementname over parentlist
  dialogtitle = dialogtitle||' '
  if elementname~isA(.Array) then dialogtitle = dialogtitle || elementname~makestring(,",")
  else dialogtitle = dialogtitle || elementname
end

self~create(0, 0, 104, 56, dialogtitle, "THICKFRAME")

------------------------------------------------------
::method defineDialog 
------------------------------------------------------
expose variablescollection
style = "HSCROLL VSCROLL NOTIFY"
self~createListBox(self~LISTVARS, 2, 2, 100, 52, style)

------------------------------------------------------
::method defineSizing 
------------------------------------------------------

self~controlLeft(self~LISTVARS, 'STATIONARY', 'LEFT') 
self~controlRight(self~LISTVARS, 'STATIONARY', 'RIGHT') 
self~controlTop(self~LISTVARS, 'STATIONARY', 'TOP') 
self~controlBottom(self~LISTVARS, 'STATIONARY', 'BOTTOM') 

return 0

------------------------------------------------------
::method initdialog 
------------------------------------------------------
expose controls debugwindow hfnt  parentwindow 

controls[self~LISTVARS] = self~newListBox(self~LISTVARS)

minsize = .Size~new(self~pixelCX, self~pixelCY)
self~minSize = minsize

hfnt = self~createFontEx("Courier New", 8)
controls[self~LISTVARS]~setFont(hfnt, .true)

self~connectListBoxEvent(self~LISTVARS, DBLCLK, "VariableDoubleClicked")
self~connectListBoxEvent(self~LISTVARS, SELCHANGE, "VariableSelected")

parentsize = parentwindow~getrealsize
parentpos = parentwindow~getrealpos
mysize= self~getrealsize
if parentwindow = debugwindow then mystartpos = parentpos~~incr(parentsize~width, 0)
else mystartpos = parentpos~~incr(0, parentsize~height)
self~moveto(mystartpos)

self~ensurevisible
debugwindow~NotifyChildReady
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
::METHOD VariableSelected
------------------------------------------------------
expose controls itemidentifiers currentselectioninfo

itemindex = controls[self~LISTVARS]~selectedindex
if itemindex \= 0 then do
  selectedidentifierstring = itemidentifiers[itemindex]~makestring
  rowsbefore = itemindex - controls[self~LISTVARS]~getfirstvisible
  currentselectioninfo = rowsbefore':'selectedidentifierstring
end  
 

------------------------------------------------------
::METHOD UpdateWatchWindow
------------------------------------------------------
expose controls parentlist  hfnt itemidentifiers itemclasses currentselectioninfo varsvalid
use arg root

variablescollection = root
do nextchild over parentlist
  variablescollection = variablescollection[nextchild]
  if variablescollection = .nil then leave
end

if variablescollection = .nil then do
 self~setcurrentListIndex(self~LISTVARS, 0)
 varsvalid = .False
end
else do
  varsvalid = .True
  controls[self~LISTVARS]~hidefast
  controls[self~LISTVARS]~deleteall
  dc = self~getControlDC(self~LISTVARS)
  oldfont = self~fonttodc(dc, hfnt)

  maxwidth = 0
  if variablescollection~isA(.Directory) | -
       variablescollection~isA(.Properties) | -
       variablescollection~isA(.Stem) -
  then  itemidentifiers = variablescollection~allindexes~sort
  else  itemidentifiers = variablescollection~allindexes

  itemclasses = .Array~new
  do varname over itemidentifiers
    if varname~isA(.Array) then vardisplayname = varname~makestring(,",")
    else vardisplayname = varname
    varvalue = variablescollection[varname]~defaultname
    if variablescollection[varname]~isA(.string) then
    varvalue = variablescollection[varname]~changestr(.endofline, '<EOL>')~changestr(d2c(13), '<CR>')~changestr(d2c(10), '<LF>')
    if varvalue~length > self~MAXVALUESTRINGLENGTH then varvalue = varvalue~left(self~MAXVALUESTRINGLENGTH)||'...'
    if variablescollection[varname]~isInstanceOf(.Collection) then do
      varvalue = varvalue' ('variablescollection[varname]~items' item'
      if variablescollection[varname]~items \=1 then varvalue=varvalue||'s'
      varvalue = varvalue||')'
    end  
    text= vardisplayname' = 'varvalue
    width = self~getTextExtent(dc, text)~width
    if width > maxwidth then maxwidth = width
    controls[self~LISTVARS]~add(text)
    itemclasses~append(variablescollection[varname]~class)
  end

  self~fonttodc(dc, oldfont)
  self~freecontroldc(self~LISTVARS, oldfont)
  self~setListWidthpx(self~LISTVARS, maxwidth)

  parse value currentselectioninfo with prevrowsbefore':'prevselectedidentifierstring
  if currentselectioninfo \= "" then do 
    indextoselect = 0
    if prevselectedidentifierstring \= "" then do i = 1 to itemidentifiers~items
      if itemidentifiers[i]~makestring = prevselectedidentifierstring then do
        indextoselect = i
        leave
      end
    end    
    if indextoselect \= 0 then do
      self~setcurrentListIndex(self~LISTVARS, indextoselect)
      newfirstvisible = MAX(1,indextoselect - prevrowsbefore)
      controls[self~LISTVARS]~makefirstvisible(newfirstvisible)
    end  
  end  
  controls[self~LISTVARS]~showfast
  controls[self~LISTVARS]~redraw
 
end

------------------------------------------------------
::method VariableDoubleClicked
------------------------------------------------------
expose controls debugwindow itemidentifiers itemclasses parentlist

itemindex = controls[self~LISTVARS]~selectedindex
if itemindex \= 0 then do
  itemidentifier = itemidentifiers[itemindex]
  itemclass = itemclasses[itemindex]
  if itemclass =.Directory | -
     itemclass =.Properties | -
     itemclass =.Stem | -
     itemclass =.List | -
     itemclass =.Queue | -
     itemclass =.CircularQueue | -
     itemclass =.Array then do

    if parentlist~items \= 0 then newlist =parentlist~section(0)
    else newlist = .List~new
    newlist~append(itemidentifier)
    debugwindow~AddWatchWindow(self, newlist)
  end
end  
------------------------------------------------------
::method SetListState
------------------------------------------------------
expose controls varsvalid
use arg enablelist

if enablelist & varsvalid then self~EnableControl(self~LISTVARS)
else  self~DisableControl(self~LISTVARS)

--====================================================
::class NullTracer
--====================================================

------------------------------------------------------
::method init
------------------------------------------------------
expose debugger
use arg debugger

return 0

------------------------------------------------------
::method LINEOUT
------------------------------------------------------
expose debugger
use arg tracestring
if tracestring~word(1)~translate='ERROR' then return debugger~lineout(tracestring)
else return 0

/*====================================================
Routines
======================================================*/
------------------------------------------------------
::ROUTINE SAY public
------------------------------------------------------
use strict arg text
if .rexxdebugger.debugger~isA(.RexxDebugger) then .rexxdebugger.debugger~SendDebugMessage(text)

------------------------------------------------------
::ROUTINE GetPackageConstant
------------------------------------------------------
use arg constname
constname = translate(constname)
interpret 'val=.directory~new~~Setmethod("'constname'",.METHODS["'constname'"])~'constname
return val



::requires oodialog.cls

--::options trace R