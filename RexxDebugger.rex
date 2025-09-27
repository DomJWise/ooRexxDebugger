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

if .local~rexxdebugger.debuggerinit \= .nil then  return
.local~rexxdebugger.debuggerinit = .Object~new

-- Set version
.local~rexxdebugger.version = GetPackageConstant("Version")


-- Below is the help text List that will initially be added to the source list unless already set by the caller (or a source load error)
if .local~rexxdebugger.startuphelptext = .nil then do 
  .local~rexxdebugger.startuphelptext = .list~of( -
  "Command line usage:", - 
  "Rexxdebugger [/nocapture | /showtrace] [/javaui] [/tracemode:<modeflag>] [/fontsize:8-26] <program> <argstring>", - 
  "Rexxdebugger [/nocapture | /showtrace] [/javaui] [/tracemode:<modeflag>] [/fontsize:8-26] CALL <program> [<arg1>] [..<argn>]", - 
  "", - 
  "To launch from Rexx source include the following line:", - 
  "CALL RexxDebugger [parentwindowtitle, offset(UDL*R*)]", -
  "", - 
  "Below this add the following to start debugging:", -
  "TRACE ?A ", - 
  "", -
  "Source code will be shown when debugging is started.", -
  "To select a program to debug now, click the Open button.", -
  "", -
  "Note: Window positioning is for Windows/ooDialog only.")
  
end

if SetCommandLineIsRexxDebugger() then do
   
  call ConfigureCommandLineDebuggee(ARG(1)~strip)

  .local~rexxdebugger.deferlaunch = .true
  .local~rexxdebugger.debugger = .RexxDebugger~new
  .local~rexxdebugger.debugger~canopensource = .true

   if .local~rexxdebugger.rexxfile = '' then .local~rexxdebugger.debugger~launch
   else do
     .local~rexxdebugger.startuphelptext~empty
     .local~rexxdebugger.debugger~launch
     .local~rexxdebugger.debugger~OpenNewProgram(.local~rexxdebugger.rexxfile, .local~rexxdebugger.rawargstring, .local~rexxdebugger.multipleargs, .True)
   end  
  end  
else do
  parentwindowname = arg(1)
  offsetdirection = arg(2)

  if .local~rexxdebugger.parentwindowname \= .nil then parentwindowname = .local~rexxdebugger.parentwindowname
  if .local~rexxdebugger.offsetdirection \= .nil then offsetdirection = .local~rexxdebugger.offsetdirection

  -- Launch debugger
  .local~rexxdebugger.debugger = .RexxDebugger~new(parentwindowname, offsetdirection)
end  
if .local~rexxdebugger.debugger~debuggerui \= .nil then .local~rexxdebugger.debugger~debuggerui~UpdateUIControlStates
else return

if .local~rexxdebugger.commandlineisrexxdebugger then .local~rexxdebugger.debugger~WaitForUIToEnd
else .local~rexxdebugger.debugger~TrackMainContext

/*====================================================
The core code of the debugging library follows below
====================================================*/

::CONSTANT VERSION "1.43.17"

--====================================================
::class RexxDebugger public
--====================================================
::attribute windowname unguarded
::attribute offsetdirection unguarded
::attribute canopensource unguarded
::attribute debuggerui unguarded
::attribute lastexecfulltime unguarded
::attribute uithreadid unguarded

::constant DebugMsgPrefix '<-> '

------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("IsShutdown",           .Method~new("", self~method("IsShutdown")~source)~~setUnguarded)
self~define("SendDebugMessage",     .Method~new("", self~method("SendDebugMessage")~source)~~setUnguarded)
self~define("CaptureConsoleOutput", .Method~new("", self~method("CaptureConsoleOutput")~source)~~setUnguarded)

------------------------------------------------------
::method FlagUIStartupComplete unguarded
------------------------------------------------------
expose uistartupcomplete

uistartupcomplete = .True

------------------------------------------------------
::method StartUIThread unguarded
------------------------------------------------------
expose debuggerui uifinished

uifinished = .False

REPLY /* Switch to a new thread */

debuggerui = .DebuggerUI~new(self, .WatchHelper, .DebugHelper)

debuggerui~RunUI

uiFinished = .True

------------------------------------------------------
::method init 
------------------------------------------------------
expose  shutdown launched  breakpoints tracedprograms manualbreak windowname offsetdirection traceoutputhandler outputhandler errorhandler uiloaded debuggerui canopensource lastexecfulltime uifinished runroutine uithreadid getthreadidroutine conditionbackups stackhascontext codelocation trackingmaincontext
use arg windowname = "", offsetdirection = ""
if windowname \= "" & offsetdirection = "" then offsetdirection = "R"
shutdown = .False
launched = .False
breakpoints = .Properties~new
conditionbackups = .Properties~new
tracedprograms = .Set~new
manualbreak = .false
traceoutputhandler = .nil
outputhandler = .nil
errorhandler = .nil
debuggerui = .nil
canopensource = .False
lastexecfulltime = 0
uifinished = .True
runroutine = .nil
uithreadid = 0
getthreadidroutine = .Nil
codelocation = ""
trackingmaincontext = .False

.local~debug.channels = .Directory~new

stackhascontext = .context~stackframes[1]~hasmethod("context")

uiloaded = self~findandloadui()

if uiloaded then do
  getthreadidroutine = .DebuggerUI~BuildGetThreadIdRoutine
  ignore = .debuginput~destination(self)
end
if .local~rexxdebugger.deferlaunch \= .true then do
  .local~rexxdebugger.deferlaunch = .false
  self~launch(windowname, offsetdirection)
end

------------------------------------------------------
::method GetThreadId unguarded
------------------------------------------------------
expose getthreadidroutine
return getthreadidroutine~call

------------------------------------------------------
::method findandloadui 
------------------------------------------------------
uiloaded = .false

if .context~package~FindClass('DebuggerUI') \= .nil then do
  uiloaded = .True
end
if \uiloaded & SysVersion()~translate~pos("WINDOWS") = 1 then do
  do i over .context~stackframes~lastitem~executable~package~importedpackages while uiloaded = .False
    if i~findclass("DebuggerUI") \= .nil then do
      .context~package~addpackage(i)
      uiloaded = .true
    end
  end
  if uiloaded = .False then do
    if (SysSearchPath('PATH','RexxDebuggerWinUI.rex')  \= '' | .File~new('RexxDebuggerWinUI.rex')~canread)  then do 
      call RexxDebuggerWinUI.rex
      uiloaded = .true
    end  
  end  
end
if \uiloaded then do
    if (SysSearchPath('PATH','RexxDebuggerBSFUI.rex')  \= '' | .File~new('RexxDebuggerBSFUI.rex')~canread) & SysSearchPath('PATH','BSF.CLS') \= .Nil then do 
    call 'RexxDebuggerBSFUI.rex'
    uiloaded = .true
  end  
end

return uiloaded

------------------------------------------------------
::method launch 
------------------------------------------------------
expose launched windowname offsetdirection debuggerui uistartupcomplete uiloaded
use arg windowname = "", offsetdirection = ""

if launched = .true then return
if \uiloaded then do 
  say 'Error: No debugger front end is available to load.'
  if SysVersion()~translate~pos("WINDOWS") = 1 then say 'A front end for Windows is implemented in RexxDebuggerWinUI.rex'
  say 'A front end for Java + bsf4ooRexx is implemented in RexxDebuggerBSFUI.rex'
  return
end  

launched = .true
debuggerui = .nil
uistartupcomplete = .False

if .local~rexxdebugger.captureoption = 'SHOWTRACE'  then self~CaptureConsoleOutput(.False)
else if .local~rexxdebugger.captureoption \= 'NOCAPTURE' then self~CaptureConsoleOutput(.True)

self~StartUIThread

guard off when uistartupcomplete = .True --Wait for ui to start up


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
expose breakpoints conditionbackups
use arg sourcefile, sourceline
test = ''
location = sourcefile'>'sourceline
if conditionbackups~hasindex(location) then do
  test = conditionbackups[location]
  conditionbackups~remove(location)
end  
breakpoints[location] = test

------------------------------------------------------
::method SetBreakPointTest unguarded
------------------------------------------------------
expose breakpoints conditionbackups
use arg sourcefile, sourceline, test

location = sourcefile'>'sourceline
if conditionbackups~hasindex(location) then conditionbackups~remove(location)
breakpoints[location] = test

------------------------------------------------------
::method ClearBreakPoint  unguarded
------------------------------------------------------
expose breakpoints conditionbackups
use arg sourcefile, sourceline

location = sourcefile'>'sourceline
if breakpoints~hasindex(location), breakpoints[location] \= '' then conditionbackups[location] = breakpoints[location]
breakpoints~remove(location)

------------------------------------------------------
::method CheckBreakPoint 
------------------------------------------------------
expose breakpoints
use arg sourcefile, sourceline
return breakpoints~hasindex(sourcefile'>'sourceline)

------------------------------------------------------
::method GetBreakPointTest unguarded
------------------------------------------------------
expose breakpoints
use arg sourcefile, sourceline
location = sourcefile'>'sourceline
if \breakpoints~hasindex(location) then
  return ''
else  
  return breakpoints[location]


------------------------------------------------------
::method GetBreakPoints unguarded
------------------------------------------------------
expose breakpoints
use arg sourcefile 
listBreakpoints = .List~new
do breakpoint over breakpoints~allindexes
  if breakpoint~pos(sourcefile'>') = 1 then listbreakpoints~append(breakpoint~changestr(sourcefile'>', ''))
end

return listBreakpoints


------------------------------------------------------
::method SendDebugMessage unguarded
------------------------------------------------------
expose debuggerui 
use  arg text, newline = .true
if debuggerui \= .nil then debuggerui~AppendUIConsoleText(text, newline)

------------------------------------------------------
::method InstallOutputHandlers
------------------------------------------------------
expose traceoutputhandler errorhandler outputhandler
if outputhandler = .nil then do
  outputhandler = .DebugOutputHandler~new(self, .output)
  traceoutputhandler = .DebugTraceOutputHandler~new(self)  
  errorhandler = .DebugOutputHandler~new(self, .error)
end

------------------------------------------------------
::method CaptureConsoleOutput 
------------------------------------------------------
expose traceoutputhandler outputhandler errorhandler uiloaded
use arg discardtrace = .False
if uiloaded then do 
  self~InstallOutputHandlers
  outputhandler~SetCapture(.True)
  errorhandler~SetCapture(.True)
  traceoutputhandler~SetCapture(.True)
  traceoutputhandler~SetDiscard(discardtrace)
end
return .True

------------------------------------------------------
::method StopCaptureConsoleOutput 
------------------------------------------------------
expose traceoutputhandler outputhandler errorhandler uiloaded

if traceoutputhandler \= .nil then traceoutputhandler~SetCapture(.False)
if errorhandler \= .nil then errorhandler~SetCapture(.False)
if outputhandler \= .nil then outputhandler~SetCapture(.False)

------------------------------------------------------
::method LINEIN unguarded
------------------------------------------------------
expose uithreadid getthreadidroutine
tid = getthreadidroutine~call

if tid = uithreadid then return ''
else do
  guard on
  return self~ReplyWithTraceCommand(tid)
end
------------------------------------------------------
::method ReplyWithTraceCommand  unguarded
------------------------------------------------------
expose debuggerui shutdown launched canopensource lastexecfulltime
use arg threadid
lastexecfulltime = TIME('F')
if shutdown then return 'trace off; exit' 
if \launched then return ''
else do
  debugchannel = .debug.channels[threadid]
  if debugchannel = .nil then do
    debugchannel = .Directory~new
    debugchannel~status=.MutableBuffer~new("getprogramstatus", 256)
    debugchannel~frames=.Nil
    debugchannel~context=.Nil
    debugchannel~breakpointtestresult = .False
    .debug.channels[threadid] = debugchannel
  end
 response =self~GetAutoResponse(debugchannel, threadid)
end 
if response \= "" | debugchannel~status~string = "breakpointcheckgetlocation" then return response 

response =  debuggerui~GetUINextResponse

if translate(response) = 'EXIT' then do
   canopensource = .True
   debuggerui~UpdateUIControlStates
   self~informshutdown
   return 'say "Exiting as instructed by the debugger"; trace off; exit'
   
   end
if translate(response) = 'RUN' then do
  debugchannel~status~append("breakpointcheckgetlocation")
  return ''
end  
if word(translate(response), 1) = 'TRACE' then debugchannel~status~append("getprogramstatus")
if translate(response) = 'NEXT' | response = '' then do
  debugchannel~status~append("getprogramstatus")
  return ''
end  
if translate(response)~word(1) = 'NEXT' & response~words > 1 then do
   if "RUN EXIT HELP CAPTURE CAPTUREX NOCAPTURE CLS"~wordpos(response~word(2)~translate) \= 0 then debugchannel~status~append("getprogramstatus "||response~DELWORD(1,2))
   else debugchannel~status~append("getprogramstatus "||response~DELWORD(1,1))
  return ''
end  
if translate(response) = 'UPDATEVARS' then do
  debugchannel~status~append("getvars")
  return 'NOP'
end  
if translate(response) = 'CAPTURE' | translate(response) = 'CAPTUREX' then do 
  if translate(response) = 'CAPTURE' then discardtrace = .False
  else  discardtrace = .True
  if self~CaptureConsoleOutput(discardtrace) then do
    retstr = 'call SAY "'self~DebugMsgPrefix||'Output redirected to the debugger if the program permits this."'
    if discardtrace = .False then retstr = retstr||'.endofline||"'self~DebugMsgPrefix||'CAPTUREX does the same but discards trace text."||.endofline'
    else retstr = retstr||'.endofline||"'self~DebugMsgPrefix||'All trace apart from runtime error messages will be discarded."||.endofline'
    return retstr
  end  
end
if translate(response) = 'NOCAPTURE' then do
  self~StopCaptureConsoleOutput
  return 'call SAY "'self~DebugMsgPrefix||'If active, console redirection has been switched off."||.endofline||"'self~DebugMsgPrefix||'Use CAPTURE/CAPTUREX to switch it back on."||.endofline'
end  
if translate(response) = 'HELP' then do
  self~ShowHelpText
  return 'NOP'
end  
if translate(response) = 'CLS' then do
  debuggerui~ClearUIConsole
  return 'NOP'
end

if shutdown & response \= '' then response = response||'; trace off; exit'

debugchannel~status~append("getprogramstatus")

return response

------------------------------------------------------
::method GetAutoResponse unguarded
------------------------------------------------------
expose debuggerui tracedprograms manualbreak breakpoints runroutine stackhascontext codelocation
use arg debugchannel, threadid

status = debugchannel~status~string

debugchannel~status~delete(1)

if status="breakpointcheckgetlocation" then do
  if stackhascontext then do
    ---Fast track is possible in 5.1, for simple breakpoint checks at least
    context = .context~stackframes[5]~context
    program = context~package~name
    codelocation = program'>'context~line
    if \breakpoints~hasindex(codelocation) & \manualbreak & tracedprograms~hasitem(program) then do
      debugchannel~status~append("breakpointcheckgetlocation")
      return ''
    end  
    dobreak = .False
    if manualbreak then do
      dobreak = .True
      CALL SAY self~DebugMsgPrefix||'Automatic breakpoint hit.'
      manualbreak = .False
    end
    else if \tracedprograms~hasitem(program) then dobreak = .True
    if breakpoints[codelocation] = '' | dobreak then do
      frames = .context~stackframes~section(5)
      if runroutine \= .nil, frames~lastitem~executable~package \= .nil, frames~lastitem~executable~package~name = .context~package~name | frames~lastitem~executable~package~name = debuggerui~class~method("INIT")~package~name then frames = frames~section(1, frames~items-3)
      tracedprograms~put(program)
      self~CheckSetMainContext(frames, context)
      debuggerui~UpdateUICodeView(frames, 1)
      debuggerui~UpdateUIWatchWindows(context~variables)
      return ''
    end  
  end
  return '_rexdeebugeer_tmp = .debug.channels["'threadid'"]~status~append("breakpointchecklocationis ".context~package~name">".context~line);  drop _rexdeebugeer_tmp'
  end
else if status~pos("breakpointchecklocationis") = 1 then do
  parse value status with ignore codelocation -- Is this a breakpoint ?
  parse value codelocation with program">"line
  if \manualbreak & \breakpoints~hasindex(codelocation)  & tracedprograms~hasitem(program) then do
    debugchannel~status~append("breakpointcheckgetlocation")
    return ''
  end  
  else if manualbreak then do 
    CALL SAY self~DebugMsgPrefix||'Automatic breakpoint hit.'
    manualbreak = .false
    debugchannel~status~append("getprogramstatus")
    return 'NOP'
  end
  else if \tracedprograms~hasitem(program) then do -- Break (first time time only) when hitting a new program which traces.
    tracedprograms~put(program)
    debugchannel~status~append("getprogramstatus")
    return 'NOP'
  end
  else /*breakpoints~hasindex(codelocation)*/  do  
    if breakpoints[codelocation] = '' then do
      debugchannel~status~append("getprogramstatus")
      return 'NOP'
    end  
    else do
      debugchannel~status~append("breakpointprocesstestresult")
      debugchannel~breakpointtestresult = .True
      return '_rexdeebugeer_tmp = .debug.channels["'threadid'"]~~put('||breakpoints[codelocation]||', "BREAKPOINTTESTRESULT"); drop _rexdeebugeer_tmp'
    end
  end
end  
else if status~pos("breakpointprocesstestresult") = 1 then do
  testresult = debugchannel~breakpointtestresult
  debugchannel~breakpointtestresult = .False
  if testresult = .True then do
     debuggerui~AppendUIConsoleText(self~DebugMsgPrefix||"Breakpoint condition is satisfied")
    debugchannel~status~append("getprogramstatus")
    return 'NOP'
  end  
  else do
    debugchannel~status~append("breakpointcheckgetlocation")
    return ''
  end
end
else if status~word(1)="getprogramstatus" then do
  instructions = status~delword(1,1)~strip
  if instructions \= '' then do 
    debugchannel~frames= .nil
    debugchannel~context= .nil
    debugchannel~status~append("getprogramstatus")
    return instructions
  end
  else do  
    debugchannel~frames= .nil
    debugchannel~context= .nil
    debugchannel~status~append("programstatusupdated")
    return '_rexdeebugeer_tmp = .debug.channels["'threadid'"]~~put(.context~StackFrames~section(2), "FRAMES")~~put(.context, "CONTEXT"); drop _rexdeebugeer_tmp'
  end  
end      
else if status="programstatusupdated" then do
  self~CheckSetMainContext(debugchannel~frames, debugchannel~context)
  if debugchannel~frames \=.nil then do
    frames = debugchannel~frames
    if runroutine \= .nil, frames~lastitem~executable~package \= .nil, frames~lastitem~executable~package~name = .context~package~name | frames~lastitem~executable~package~name = debuggerui~class~method("INIT")~package~name then frames = frames~section(1, frames~items-3)
    tracedprograms~put(frames~firstitem~executable~package~name)
    debuggerui~UpdateUICodeView(frames, 1)
  end
  if debugchannel~context \= .nil, debugchannel~context~variables \=.nil then do
    debuggerui~UpdateUIWatchWindows(debugchannel~context~variables)
  end  
  debugchannel~context= .nil
  debugchannel~frames= .nil
  debugchannel~status~append("")
  return ''
end
else if status="getvars" then do
  debugchannel~frames= .nil
  debugchannel~context= .nil
  debugchannel~status~append("gotvars")
  return '_rexdeebugeer_tmp = .debug.channels["'threadid'"]~~put(.context, "CONTEXT"); drop _rexdeebugeer_tmp'
end     
else if status="gotvars" then do
  if debugchannel~context \= .nil, debugchannel~context~variables \=.nil then do
    debuggerui~UpdateUIWatchWindows(debugchannel~context~variables)
  end
  debugchannel~frames= .nil
  debugchannel~context = .nil
  debugchannel~status~append("")
  return 'NOP'
end
return ''

------------------------------------------------------
::method TrackMainContext unguarded
------------------------------------------------------
expose trackingmaincontext shutdown debuggerui canopensource
trackingmaincontext = .True
reply
do while shutdown = .False
  maincontext = .local~debuggermaincontext
  if maincontext~class = .context~class & maincontext \= .nil then do
    signal on syntax
    executable = maincontext~executable -- Will raise an error when the context becomes invalid
    signal off syntax
  end
  call SysSleep .20
end
return

syntax:
if debuggerui\ = .nil then do
  canopensource = .True  
  debuggerui~AppendUIConsoleText(self~DebugMsgPrefix||"Debug session ended")
  debuggerui~UpdateUIControlStates
end

------------------------------------------------------
::method CheckSetMainContext unguarded
------------------------------------------------------
expose trackingmaincontext
use arg frames, context

if \trackingmaincontext then return

maincontext = .local~debuggermaincontext
if \(maincontext~class = .context~class), frames \= .nil then do
  if context \= .nil, frames~items = 1, (context~executable~class = .routine) then do 
    .local~debuggermaincontext = context
  end
end
------------------------------------------------------
::method SetManualBreak unguarded
------------------------------------------------------
expose manualbreak
use arg manualbreak

------------------------------------------------------
::method GetManualBreak unguarded
------------------------------------------------------
expose manualbreak

return manualbreak

-----------------------------------------------------
::method GetLastSourceFile unguarded
------------------------------------------------------
expose codelocation
parse value codelocation with program">"linenumber
return program

-----------------------------------------------------
::method GetLastSourceLine unguarded
------------------------------------------------------
expose codelocation
parse value codelocation with program">"linenumber
return linenumber

-----------------------------------------------------
::method ShowHelptext 
------------------------------------------------------
self~SendDebugMessage("")
self~SendDebugMessage(self~DebugMsgPrefix||"- Commands: <instrs> | NEXT [<instrs>] | RUN | EXIT | CLS | HELP | CAPTURE | CAPTUREX | NOCAPTURE - use the Exec button to run the command.")
self~SendDebugMessage(self~DebugMsgPrefix||"- Buttons with the above labels execute the corresponding command.")
self~SendDebugMessage(self~DebugMsgPrefix||"- Command history for the session can be accessed with the up/down keys.")
self~SendDebugMessage(self~DebugMsgPrefix||"- The Watch button opens a realtime variable watch window.")
self~SendDebugMessage(self~DebugMsgPrefix||"- Double clicking many collection object types in a variables window will expand them in a new window.")
self~SendDebugMessage(self~DebugMsgPrefix||"- Clicking a stack row takes you to the specified source location and file.")
self~SendDebugMessage(self~DebugMsgPrefix||"- Double clicking a source row toggles a breakpoint, but this does not guarantee that the line will be hit.")
self~SendDebugMessage(self~DebugMsgPrefix||"  Some simple hit checks are carried out but there is no detailed code analysis.")
self~SendDebugMessage(self~DebugMsgPrefix||"  e.g. if it is empty, a comment, a directive or is END, THEN, ELSE, OTHERWISE, RETURN, EXIT or SIGNAL")
self~SendDebugMessage(self~DebugMsgPrefix||"  DO statements should be hit unless they mark the start of a loop that has looped once already.")
self~SendDebugMessage(self~DebugMsgPrefix||"  CALL statements (and what they call) may be hit, depending on what they are calling.")
self~SendDebugMessage(self~DebugMsgPrefix||"  A * means the debugger thinks the code will be hit, a ? means it thinks it likely it won't ever be hit.")
self~SendDebugMessage(self~DebugMsgPrefix||"  Hint: A line with just NOP can be inserted as an anchor for a breakpoint that will always be hit.")
self~SendDebugMessage(self~DebugMsgPrefix||"- /**/ at the start of traceable line (including NOP) causes a breakpoint to be automatically set for that line.")
self~SendDebugMessage(self~DebugMsgPrefix||"- The instruction CALL SAY ... will always send output here.")
self~SendDebugMessage(self~DebugMsgPrefix||"- So long as SAY is enabled in the target application, other output should appear there.")
self~SendDebugMessage(self~DebugMsgPrefix||"- CLS will delete all text in the console output window.")
self~SendDebugMessage(self~DebugMsgPrefix||"- If the application has no output, or you want the output here, you can try the CAPTURE command to capture all output.")
self~SendDebugMessage(self~DebugMsgPrefix||"  CAPTUREX is similar but will discard (eXclude) all trace output apart from program errors.")
self~SendDebugMessage(self~DebugMsgPrefix||"- NOCAPTURE switches off any capture that was previously active.")
self~SendDebugMessage(self~DebugMsgPrefix||"- The source window and watch windows go grey while the program is running, and the watch windows after it has finished.")
self~SendDebugMessage(self~DebugMsgPrefix||"Happy debugging!")
self~SendDebugMessage('')
------------------------------------------------------
::method GetCaption unguarded
------------------------------------------------------
return "ooRexx Debugger Version "||GetPackageConstant("Version")


------------------------------------------------------
::method OpenNewProgram unguarded
------------------------------------------------------
expose debuggerui shutdown breakpoints tracedprograms canopensource traceoutputhandler runroutine  codelocation

use arg rexxfile,argstring,multipleargs = .False, firsttime = .False

shutdown = .False
breakpoints~empty
tracedprograms~empty
codelocation = ''
if traceoutputhandler \= .nil then traceoutputhandler~dononwrappedchecks = .False
.debug.channels~empty
runroutine = .nil
strm = .stream~new(rexxfile)
signal on ANY name HandleSyntaxError
if strm~query('EXISTS') = '' then  raise syntax 3.1 ADDITIONAL (Rexxfile)
else do  
  signal off ANY 
  arrsource = strm~arrayin
  strm~close
  if arrSource~items = 0 then arrSource = .array~of('')
  if arrSource[1]~strip~left(2) = '#!' then arrSource[1] = arrSource[1]~insert('-- /*REXX.DEBUGGER.COMMENTOUT*/ ')
  arrSource~~append('')~append('/*REXX.DEBUGGER.INJECT*/ ::OPTIONS TRACE '.local~rexxdebugger.tracemode)

  if \firsttime then do
    debuggerui~AppendUIConsoleText("")
    debuggerui~AppendUIConsoleText(self~DebugMsgPrefix||"New debug session started for "rexxfile)
    debuggerui~AppendUIConsoleText("")
  end
  else do
    debuggerui~AppendUIConsoleText(self~DebugMsgPrefix||"Debug session started for "rexxfile)
    debuggerui~AppendUIConsoleText("")
  end

  self~canopensource = .False
  debuggerui~InitUISource(arrSource, rexxfile)

  signal on ANY name HandleSyntaxError
  runroutine = .routine~new(rexxfile, arrSource)
  routinepackage = runroutine~package

  signal off ANY

  debuggerui~ResetUISourceState
  debuggerui~UpdateUIControlStates

  -- Init code for classes is run on the next line
  signal on ANY name HandleRuntimeError
  packages = routinepackage~importedpackages 
  signal off ANY
  do i over packages~allitems
    if i~findclass("DebuggerUI") \= .nil  then .context~package~addpackage(i)
  end  

  signal off ANY
  .context~package~addRoutine('REXXDEBUGGEEMAIN', runroutine)

  
  if \multipleargs then runargs = .array~of(argstring)
  else do
    runargs = .array~new
    do while argstring \= ''
      if argstring~left(1) \= '"' then parse value argstring with nextarg argstring 
      else parse value  argstring with '"' nextarg '"' argstring
      runargs~append(nextarg~strip)
      argstring = argstring~strip
    end  
  end  

  signal on ANY name HandleRuntimeError
  DROP RESULT
  runroutine~callwith(runargs)
  signal off ANY
  
  proghasresult = .True
  if Symbol('RESULT') \= 'VAR' then proghasresult = .False; else progresult = RESULT
  
  canopensource = .True
  debuggerui~UpdateUIControlStates
  debuggerui~AppendUIConsoleText("")
  debuggerui~AppendUIConsoleText(self~DebugMsgPrefix||"Debug session ended normally")
  if proghasresult then debuggerui~AppendUIConsoleText(self~DebugMsgPrefix||"Program returned : "progresult~string)
end  

return

------------
HandleSyntaxError: 
------------
cond = .context~condition
sourceerrorline = cond~POSITION

errorlist = .list~new
if cond~CODE = 3.1 then do 
  filename = cond~MESSAGE~substr(cond~MESSAGE~pos('"'), cond~MESSAGE~lastpos('"') - cond~MESSAGE~pos('"') + 1)
  if filename = '"&1"' then errorlist~append("Error: No Rexx program specified")
  else errorlist~append('Error: Rexx program 'filename' not found')
  debuggerui~SetUISourceListInfoText(errorlist)
end
else do  
  strm = .stream~new(rexxfile)
  arrsource = strm~arrayin
  strm~close
  self~SendDebugMessage(self~DebugMsgPrefix||'Error: Syntax error parsing 'rexxfile' at line 'sourceerrorline)
  self~SendDebugMessage(self~DebugMsgPrefix)
  if sourceerrorline \= 0 then self~SendDebugMessage(self~DebugMsgPrefix||sourceerrorline~right(5)' *-* 'arrSource[sourceerrorline])
  self~SendDebugMessage(self~DebugMsgPrefix||'Error 'cond~RC' : 'cond~ERRORTEXT)
  self~SendDebugMessage(self~DebugMsgPrefix||'Error 'cond~CODE': 'cond~MESSAGE)
  self~SendDebugMessage('')  
  self~SendDebugMessage(self~DebugMsgPrefix||"Debug session was aborted")
end  

self~canopensource = .true
debuggerui~UpdateUIControlStates
return

------------
HandleRuntimeError: 
------------
self~SendDebugMessage(self~DebugMsgPrefix||'Runtime error:')   
cond = .context~condition
do lineidx = 0 to cond~Traceback~items -1
  if cond~Traceback[lineidx]~pos('runroutine~callwith(runargs)') \= 0 then leave
  self~SendDebugMessage(self~DebugMsgPrefix||cond~Traceback[lineidx])
end    
self~SendDebugMessage(self~DebugMsgPrefix||'Error 'cond~RC' running 'cond~package~name' line 'cond~Position': 'cond~ErrorText)   
self~SendDebugMessage(self~DebugMsgPrefix||'Error 'cond~code': 'cond~message)
self~SendDebugMessage("")  
self~SendDebugMessage(self~DebugMsgPrefix||"Debug session was aborted")
  

self~canopensource = .true
debuggerui~UpdateUIControlStates

return

------------------------------------------------------
::method RunNewProgram unguarded
------------------------------------------------------
expose canopensource debuggerui breakpoints tracedprograms

use arg rexxfile, runroutine,argstring,multipleargs, firsttime



if \multipleargs then runargs = .array~of(argstring)
else do
  runargs = .array~new
  do while argstring \= ''
    if argstring~left(1) \= '"' then parse value argstring with nextarg argstring 
    else parse value  argstring with '"' nextarg '"' argstring
    runargs~append(nextarg~strip)
    argstring = argstring~strip
  end  
end  

debuggerui~ResetUISourceState
debuggerui~UpdateUIControlStates

runroutine~callwith(runargs)

canopensource = .True
debuggerui~UpdateUIControlStates

------------------------------------------------------
::method WaitForUIToEnd
------------------------------------------------------
expose uifinished

guard on when uifinished = .True

------------------------------------------------------
::method CheckAddBreakpointFromSource unguarded
------------------------------------------------------
use arg sourcefile, line, code

if code~strip~left(4) = '/**/' then self~SetBreakPoint(sourcefile, line)
else if code~strip~left(7)~translate = '/'||'*WHEN:' then do
  parse caseless value code with . 'WHEN:'condition'*/' .
  self~SetBreakPointTest(sourcefile, line, condition)
end

-------------------------------------------------------
::method IsBreakpointLikelyToBeHit unguarded
-------------------------------------------------------
sourceline = arg(1)~strip
sourceline  = sourceline~translate
if sourceline~left(4) = '/**/' then sourceline = sourceline~substr(5)
else if sourceline~strip~left(7)~translate = '/'||'*WHEN:' then parse value sourceline with . 'WHEN:'.'*/'sourceline
if sourceline~strip = '' | "END THEN ELSE OTHERWISE RETURN EXIT SIGNAL"~wordpos(sourceline~word(1)) \= 0 | ":: -- /*"~wordpos(sourceline~left(2)) \= 0 then return .False

else return .True

-------------------------------------------------------
::METHOD LoadSavedBreakpoints unguarded
-------------------------------------------------------
expose breakpoints
use arg sourcename
debugfile =self~GetDebugFile(sourcename)
if debugfile \= .nil, debugfile~IsFile then do
  strm = .stream~new(debugfile)
  info = strm~arrayin
  strm~close
  do line over info~allitems
    parse value line with linenum condition
    if linenum~datatype = 'NUM' then do
      condition = condition~strip
      self~SetBreakpointTest(sourcename, linenum, condition)
    end  
  end
end

-------------------------------------------------------
::METHOD SaveBreakpoints unguarded
-------------------------------------------------------
expose breakpoints
use arg sourcename
debugfile =self~GetDebugFile(sourcename)
if debugfile \= .nil then do
  if debugfile~IsFile then debugfile~delete
  strm = .stream~new(debugfile)
  do breakpoint over breakpoints~allindexes
    parse value breakpoint with itemsource'>'itemline
    if itemsource = sourcename then strm~lineout(itemline breakpoints[breakpoint])
  end  
  strm~close
end
  
-------------------------------------------------------
::METHOD GetDebugFile unguarded
-------------------------------------------------------
use arg sourcename
if sourcename='' then sourcename='default'
debugfile = .nil
if SysVersion()~translate~pos("WINDOWS") = 1 then home=value('HOMEDRIVE',,'ENVIRONMENT')||value('HOMEPATH',,'ENVIRONMENT')
else home=value('HOME',,'ENVIRONMENT')
rxddir = .File~new('.rexxdebugger',home)
if \rxddir~isDirectory then rxddir~makedir
if  rxddir~isDirectory then debugfile = .File~new(.File~new(sourcename)~name'-breakpoints', rxddir)
return debugfile

--====================================================
::class DebugOutputHandler
--====================================================

------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("LINEOUT", .Method~new("", self~method("LINEOUT")~source)~~setUnguarded)
self~define("CHAROUT", .Method~new("", self~method("CHAROUT")~source)~~setUnguarded)
self~define("SAY",     .Method~new("", self~method("SAY")~source)~~setUnguarded)

------------------------------------------------------
::method init
------------------------------------------------------
expose debugger capture originaloutput
use arg debugger, outputmonitor

capture = .False

originaloutput = outputmonitor~current
ign = outputmonitor~destination(self)

return 0

------------------------------------------------------
::method SetCapture
------------------------------------------------------
expose  capture
use arg capture

------------------------------------------------------
::method LINEOUT 
------------------------------------------------------
expose debugger capture originaloutput
use arg text

if \capture | debugger~isshutdown then forward to (originaloutput)

debugger~SendDebugMessage(text)
return 0

------------------------------------------------------
::method CHAROUT 
------------------------------------------------------
expose debugger capture originaloutput
use arg text

if \capture | debugger~isshutdown then forward to (originaloutput)

debugger~SendDebugMessage(text, .false)
return 0

------------------------------------------------------
::method SAY 
------------------------------------------------------
expose debugger capture originaloutput
use arg text

if \capture | debugger~isshutdown then forward to (originaloutput)

debugger~SendDebugMessage(text)



--====================================================
::class DebugTraceOutputHandler 
--====================================================
::attribute dononwrappedchecks unguarded

------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("LINEOUT", .Method~new("", self~method("LINEOUT")~source)~~setUnguarded)

------------------------------------------------------
::method init
------------------------------------------------------
expose debugger discard canusetraceobjects capture originaltraceoutput dononwrappedchecks

use arg debugger
discard = .False
capture = .False
dononwrappedchecks = .True

originaltraceoutput = .traceoutput~current
ign = .traceoutput~destination(self)

canusetraceobjects = .False
if .TraceObject~class~defaultname = .class~defaultname then canusetraceobjects = .True

return 0

------------------------------------------------------
::method SetCapture
------------------------------------------------------
expose  capture
use arg capture

------------------------------------------------------
::method SetDiscard
------------------------------------------------------
expose  discard
use arg discard

------------------------------------------------------
::method LINEOUT
------------------------------------------------------
expose debugger discard canusetraceobjects capture originaltraceoutput dononwrappedchecks
use arg tracestring

if \capture | debugger~isshutdown then forward to (originaltraceoutput)

if canusetraceobjects then tracestring = tracestring~makestring

if \discard | tracestring~pos('+++ Interactive trace.  Error') = 1  then debugger~SendDebugMessage(debugger~DebugMsgPrefix||tracestring)
else if dononwrappedchecks , tracestring~pos('Error') = 1, tracestring~word(2)~strip('T',':')~datatype='NUM' then debugger~SendDebugMessage(debugger~DebugMsgPrefix||tracestring)

return 0

/*====================================================
Routines
======================================================*/
------------------------------------------------------
::ROUTINE SAY public
------------------------------------------------------
use strict arg text
if .rexxdebugger.debugger~isA(.RexxDebugger) then do
  if .rexxdebugger.debugger~isshutdown then return
  else .rexxdebugger.debugger~SendDebugMessage(text)
end

------------------------------------------------------
::ROUTINE RexxDebuggerHandleExit public
------------------------------------------------------
if .rexxdebugger.debugger~isA(.RexxDebugger) then do
  .local~debuggermaincontext = .Nil
  debugger = .rexxdebugger.debugger
  if \.rexxdebugger.debugger~isshutdown then do
    debuggerui = debugger~debuggerui
    debugger~canopensource = .true

    debugger~debuggerui~AppendUIConsoleText("")
    debugger~debuggerui~AppendUIConsoleText(debugger~DebugMsgPrefix||"Debug session ended")
    debugger~debuggerui~UpdateUIControlStates

    .local~rexxdebugger.debugger~WaitForUIToEnd
  end  
end

------------------------------------------------------
::ROUTINE RexxDebuggerHandleError public
------------------------------------------------------
use arg context
if .rexxdebugger.debugger~isA(.RexxDebugger) then do
  .local~debuggermaincontext = .Nil
  debugger = .rexxdebugger.debugger
  if \.rexxdebugger.debugger~isshutdown then do
    debuggerui = debugger~debuggerui

    debugger~SendDebugMessage(debugger~DebugMsgPrefix||'Runtime error:')   
    cond = context~condition
    do lineidx = 0 to cond~Traceback~items -1
      debugger~SendDebugMessage(debugger~DebugMsgPrefix||cond~Traceback[lineidx])
    end    
    debugger~SendDebugMessage(debugger~DebugMsgPrefix||'Error 'cond~RC' running 'cond~package~name' line 'cond~Position': 'cond~ErrorText)   
    debugger~SendDebugMessage(debugger~DebugMsgPrefix||'Error 'cond~code': 'cond~message)
    debugger~SendDebugMessage("")  
    debugger~SendDebugMessage(debugger~DebugMsgPrefix||"Debug session was aborted")
  

    debugger~canopensource = .true
    debugger~debuggerui~UpdateUIControlStates

    .local~rexxdebugger.debugger~WaitForUIToEnd
  end  
end


------------------------------------------------------
::ROUTINE GetPackageConstant
------------------------------------------------------
use arg constname
constname = translate(constname)
val = ''
if  .METHODS[constname] \= .Nil then interpret 'val=.directory~new~~Setmethod("'constname'",.METHODS["'constname'"])~'constname
return val

------------------------------------------------------
::ROUTINE SetCommandLineIsRexxDebugger
------------------------------------------------------
retval = .False
entrypackage = .context~stackframes[.context~stackframes~items]~executable~package
if entrypackage \= .nil, entrypackage~name = .context~package~name then retval = .True
.local~rexxdebugger.commandlineisrexxdebugger = retval
  
return retval

------------------------------------------------------
::ROUTINE ConfigureCommandLineDebuggee
------------------------------------------------------
use arg debuggerargstring
if .local~rexxdebugger.commandlineisrexxdebugger then do 
  .local~rexxdebugger.captureoption = ''
  .local~rexxdebugger.tracemode = '?A'
  forcejava = .false
  permittedflags = "/SHOWTRACE /NOCAPTURE /JAVAUI"
  traceoptions = 'ACEFILNOR'
  do i = 1 to traceoptions~length
    permittedflags = permittedflags||' /TRACEMODE:'traceoptions~substr(i,1)||' /TRACEMODE:?'traceoptions~substr(i,1)
  end
  fontsizes = .array~of(8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26)
  do i over fontsizes~allindexes
    permittedflags = permittedflags||' /FONTSIZE:'fontsizes[i]
  end
  do while permittedflags~wordpos(debuggerargstring~translate~word(1)) \= 0
    nextflag = debuggerargstring~translate~word(1)
    parse value debuggerargstring with . debuggerargstring
    if "/SHOWTRACE /NOCAPTURE"~wordpos(nextflag) \= 0 then do
      .local~rexxdebugger.captureoption = nextflag~substr(2)
    end
    else if nextflag = "/JAVAUI" then do 
      forcejava = .True
    end
    else if nextflag~pos('/TRACEMODE:') = 1 then .local~rexxdebugger.tracemode=nextflag~makearray(':')[2]
    else if nextflag~pos('/FONTSIZE:') = 1 then .local~rexxdebugger.uifontsize=nextflag~makearray(':')[2]
  end
  if debuggerargstring~translate~word(1) = "CALL" then do 
    parse value debuggerargstring with . debuggerargstring
    .local~rexxdebugger.multipleargs = .True
  end
  else .local~rexxdebugger.multipleargs = .False
  if debuggerargstring~left(1) \= '"' then parse value debuggerargstring with rexxfile debuggerargstring 
  else parse value  debuggerargstring with '"' rexxfile '"' debuggerargstring
  if forcejava & SysVersion()~translate~pos("WINDOWS") = 1 then call RexxDebuggerBSFUI.rex
  .local~rexxdebugger.rexxfile = rexxfile~strip
  .local~rexxdebugger.rawargstring = debuggerargstring~strip
  
end
return

--====================================================
::class DebugHelper mixinclass object public
--====================================================

::attribute lastgoto get public
::attribute lastfind get public

------------------------------------------------------
::method init
------------------------------------------------------
expose controls lastgoto lastfind
use arg controls

lastgoto = ''
lastfind = ''

------------------------------------------------------
::method DoSourceGoto
------------------------------------------------------
expose controls lastgoto
use arg line

lastgoto = line
self~SelectAndCentreLine(self~LISTSOURCE, line)

------------------------------------------------------
::method DoSourceFind
------------------------------------------------------
expose controls lastfind
use arg find, forward = .True
lastfind = find
  
found = .False
rows = self~ListGetRowCount(controls, self~LISTSOURCE)
currentsel = self~ListGetSelectedIndex(controls,self~LISTSOURCE)
foundline = 0

if forward then do 
  first = 0
  last = rows - 2
  step = 1
end 
else do
  first = rows - 2
  last = 0
  step = -1
end

do i = first to last by step
  testrow = (i + currentsel) // rows + 1
  seltext = self~ListGetItem(controls, self~LISTSOURCE, testrow)
  parse value seltext with 2 linenum seltext
  if seltext~translate~pos(find~translate) \= 0 then do
    foundline = testrow
    leave
  end
end    

if foundline \= 0 then self~SelectAndCentreLine(self~LISTSOURCE, foundline)

------------------------------------------------------
::method DoSourceFindNext
------------------------------------------------------
expose lastfind
if lastfind \= '' then self~DoSourceFind(lastfind)

------------------------------------------------------
::method DoSourceFindPrevious
------------------------------------------------------
expose lastfind
if lastfind \= '' then self~DoSourceFind(lastfind, .False)

------------------------------------------------------
::method SelectAndCentreLine
------------------------------------------------------
expose controls
use arg listcontrol, line
line = line~floor
maxline = self~ListGetRowCount(controls, self~LISTSOURCE)
if maxline = 0 then return
if line > maxline then line = maxline
if line < 1 then line = 1

self~ControlDeferRedraw(controls, self~LISTSOURCE, .True)
visiblelistrows = self~ListGetVisibleRowCount(controls, listcontrol)
firstrow = MAX(1, line - (visiblelistrows/2)~floor)
self~ListSetSelectedIndex(controls, listcontrol, line)
self~ListSetFirstVisible(controls, listcontrol, firstrow)
self~ControlDeferRedraw(controls, self~LISTSOURCE, .False)

--====================================================
::class WatchHelper mixinclass object public
--====================================================

::ATTRIBUTE isstringwindow        get public  unguarded
::ATTRIBUTE showglobals           get private unguarded
::ATTRIBUTE stringwatchshowsbytes get private unguarded


------------------------------------------------------
::METHOD FindWatchWindow class unguarded
------------------------------------------------------
use arg watchwindows, testparentlist

existingwindow = .nil
do window over watchwindows~allitems while existingwindow = .nil
  if window~HasIdenticalParentList(testparentlist) then existingwindow = window
end

return existingwindow

------------------------------------------------------
::METHOD init
------------------------------------------------------
expose currentselectioninfo varsvalid parentlist showglobals stringwatchshowsbytes
use arg parentlist

currentselectioninfo = .Nil
varsvalid = .False
showglobals = .False
stringwatchshowsbytes = .False

------------------------------------------------------
::METHOD HasIdenticalParentList
------------------------------------------------------
expose parentlist
use arg testparentlist
if parentlist~items \= testparentlist~items then return .False
myparentitems = parentlist~allitems
testparentitems = testparentlist~allitems
matches = .True
do i = 1 to myparentitems~items while matches = .True
  myitemindexref = myparentitems[i]~indexref
  myitemitemref = myparentitems[i]~itemref
  testitemindexref = testparentitems[i]~indexref
  testitemitemref = testparentitems[i]~itemref
  if myitemindexref~class \= testitemindexref~class then matches = .False
  else if myitemindexref~IsA(.String) then do
    if myitemindexref \= testitemindexref then matches = .False
    else if \CompareRefValues(myitemitemref, testitemitemref) then matches = .False
  end  
  else if myitemindexref~IsA(.Array) then 
  do j = 1 to myitemindexref~dimension(1) while matches = .True
    if  myitemindexref[j] \= testitemindexref[j] then matches = .False
  end
  else if myitemindexref~IsA(.WeakReference) then do
    if myitemindexref~value = .nil | myitemindexref~value \= testitemindexref~value then matches = .False
    else if \CompareRefValues(myitemitemref, testitemitemref) then matches = .False
  end
  else if \(myitemindexref = .Nil & testitemindexref = .Nil) then matches = .False
  else if \CompareRefValues(myitemitemref, testitemitemref) then matches = .False
end  

return matches

------------------------------------------------------
::METHOD WatchRowSelected
------------------------------------------------------
expose currentselectioninfo itemidentifiers isstringwindow
itemindex = self~ListGetSelectedIndex(self~controls, self~LISTVARS)
if itemindex \= 0 then do
  rowsbefore = itemindex - self~ListGetFirstVisible(self~controls, self~LISTVARS)
  if isStringWindow then currentselectioninfo = .WatchWindowRowSelection~new(itemindex, rowsbefore)
  else currentselectioninfo = .WatchWindowRowSelection~new(itemidentifiers[itemindex], rowsbefore)
end

------------------------------------------------------
::method WatchRowDoubleClicked
------------------------------------------------------
expose itemidentifiers parentlist isstringwindow
if isstringwindow then return
listindex = self~ListGetSelectedIndex(self~controls, self~LISTVARS)
if listindex \= 0 then do
  itemidentifier = itemidentifiers[listindex]
  if self~IsExpandable(itemidentifier~itemclass) then do
    if itemidentifier~indexref~IsA(.WeakReference), itemidentifier~indexref~value = .Nil then NOP
    else do
      if parentlist~items \= 0 then newlist = parentlist~section(0)
      else newlist = .List~new
      newlist~append(itemidentifier)
      self~debugwindow~AddWatchWindow(self, newlist)
    end
  end
end
------------------------------------------------------
::method SetListState unguarded 
------------------------------------------------------
expose varsvalid
use arg enablelist

self~ControlEnable(self~controls, self~LISTVARS, enablelist & varsvalid)

------------------------------------------------------
::method GetDialogTitle unguarded
------------------------------------------------------
expose parentlist

dialogtitle = ''
do parentitem over parentlist
  parentindexref = parentitem~indexref
  if dialogtitle \= '' then dialogtitle = ' @ '||dialogtitle
  if parentindexref~isA(.Array) then itemtoadd = parentindexref~makestring(,",")
  else if parentindexref~IsA(.WeakReference) then itemtoadd = parentindexref~value~defaultname
  else if parentindexref = .nil then itemtoadd = .Nil~string
  else itemtoadd = parentindexref
  dialogtitle = itemtoadd||dialogtitle
end
dialogtitle = "Watch "||dialogtitle

return dialogTitle

------------------------------------------------------
::METHOD UpdateWatchWindow unguarded
------------------------------------------------------
expose currentselectioninfo varsvalid parentlist isarraywindow isstringwindow isrootwindow
use arg root
watchtarget = root~~put(.environment, ".ENVIRONMENT")~~put(.local, ".LOCAL")
do nextparentidentifier over parentlist while watchtarget \= .Nil
   nexparentindexref = GetRefValue(nextparentidentifier~indexref)
  if nexparentindexref = .nil then watchtarget = .Nil 
  else do
    if watchtarget~IsA(.Relation) then watchtarget = GetRefValue(nextparentidentifier~itemref)
    else watchtarget = GetRefValue(watchtarget[nexparentindexref])
    if watchtarget~IsA(.WeakReference) then watchtarget = watchtarget~value
  end
end
if watchtarget = .nil | \(watchtarget~IsA(.Collection) | watchtarget~IsA(.MutableBuffer) | watchtarget~IsA(.String)) then do
  self~ListClearSelection(self~controls, self~LISTVARS)
  varsvalid = .False
end
else do
  varsvalid = .True
  if parentlist~items \= 0 then self~ControlSetText(self~controls, self~STATICCLASS,watchtarget~defaultname)
  isstringwindow = watchtarget~IsA(.MutableBuffer) | watchtarget~IsA(.String)
  isarraywindow = watchtarget~IsA(.Array)
  isrootwindow = (parentlist~items = 0)

  self~ControlDeferRedraw(self~controls, self~LISTVARS, .True)
  self~ListDeleteAllItems(self~controls, self~LISTVARS)
  self~ListBeginSetHorizonalExtent(self~controls, self~LISTVARS)

  if isstringwindow then self~PopulateFromString(watchtarget)
  else self~PopulateFromCollection(watchtarget)
  
  self~ListEndSetHorizonalExtent(self~LISTVARS)

  if currentselectioninfo \= .Nil then self~NavigateToActiveSelection
 
  self~ControlDeferRedraw(self~controls, self~LISTVARS, .False)
end
self~SetListState(.True)
------------------------------------------------------
::method PopulateFromString
------------------------------------------------------
expose stringwatchshowsbytes

use arg stringvariable 

if stringvariable~IsA(.MutableBuffer) then stringvalue = stringvariable~string
else stringvalue = stringvariable
if \stringwatchshowsbytes then do
  lines = stringvalue~makearray(.endofline)
  do text over lines~allitems
    do while text~length > self~MAXVALUESTRINGLENGTH + 1
      nextline = text~substr(1,self~MAXVALUESTRINGLENGTH + 1)||' ...'
      nextline = nextline~changestr(.endofline, '<EOL>')~changestr(d2c(13), '<CR>')~changestr(d2c(10), '<LF>')~changestr(d2c(0), '<NUL>')
      self~ListUpdateMaxHorizonalExtent(nextline)
      self~ListAddItem(self~controls, self~LISTVARS, nextline)
      text = text~substr(self~MAXVALUESTRINGLENGTH + 2)
    end  
    text = text~changestr(.endofline, '<EOL>')~changestr(d2c(13), '<CR>')~changestr(d2c(10), '<LF>')~changestr(d2c(0), '<NUL>')
    self~ListUpdateMaxHorizonalExtent(text)
    self~ListAddItem(self~controls, self~LISTVARS, text)
   end 
end
else do
  blocklength = 10
  bytepos = 1
  bytesremaining = stringvalue~length
  if bytesremaining >= blocklength then maxbytesdisplayed = blocklength
  else maxbytesdisplayed = bytesremaining
  indexwidth = bytesremaining~length
  maxasciisupported = self~MAXASCIISUPPORTED
  self~ListUpdateMaxHorizonalExtent(' '~copies(indexwidth + 1 + maxbytesdisplayed * 3 + 1 + maxbytesdisplayed))
  do while bytesremaining >= blocklength
    text = bytepos~right(indexwidth, ' ')||' -'
    do i = 0 to blocklength - 1
      text = text||' '||c2x(stringvalue~subchar(bytepos + i))
    end
    text = text||' '
    do i = 0 to blocklength - 1
      char = stringvalue~subchar(bytepos + i)
      charval = c2d(char)
      if charval < 32 | charval > maxasciisupported then char = '.'
      text = text||char
    end
    self~ListAddItem(self~controls, self~LISTVARS, text)
    bytesremaining = bytesremaining - blocklength
    bytepos = bytepos + blocklength
  end
  if bytesremaining \= 0 then do 
    text = bytepos~right(indexwidth, ' ')||' -'
    do i = 0 to maxbytesdisplayed - 1 
      if i < bytesremaining then text = text||' '||c2x(stringvalue~subchar(bytepos + i))
      else text=text||'   '
    end
    text = text||' '
    do i = 0 to maxbytesdisplayed - 1
      if i < bytesremaining then do
        char = stringvalue~subchar(bytepos + i)
        charval = c2d(char)
        if charval < 32 | charval > maxasciisupported then char = '.'
        text = text||char
      end
      else text = text||' '    
    end
    self~ListAddItem(self~controls, self~LISTVARS, text)
  end
end  
------------------------------------------------------
::method PopulateFromCollection
------------------------------------------------------
expose isarraywindow isrootwindow itemidentifiers showglobals

use arg variablescollection
self~debugger~uithreadid = self~debugger~GetThreadID
showvariablenames = \(variablescollection~IsA(.Set) | variablescollection~IsA(.Bag))
  
if variablescollection~isA(.Directory) | -
    variablescollection~isA(.Properties) | -
    variablescollection~isA(.Stem) | -
    variablescollection~isA(.StringTable) -
then itemindexes = variablescollection~allindexes~sort
else itemindexes = variablescollection~allindexes

if isrootwindow then do
  count = itemindexes~items
  itemindexes~delete(itemindexes~index(".ENVIRONMENT"))
  itemindexes~delete(itemindexes~index(".LOCAL"))
  if showglobals then do
    itemindexes[count-1] = ".ENVIRONMENT"
    itemindexes[count]   = ".LOCAL"
  end
end
if  variablescollection~isA(.Relation) then relationsupplier = variablescollection~supplier
else  relationsupplier = .Nil

itemidentifiers = .Array~new(itemindexes~items)

itemindexsuppplier = itemindexes~supplier
do while itemindexsuppplier~available
  if relationsupplier \= .nil then do
    thisindex = relationsupplier~index
    thisvalue = relationsupplier~item
    relationsupplier~next
  end
  else do
    thisindex = itemindexsuppplier~item
    thisvalue = variablescollection[thisindex]
  end  
  if \showvariablenames then vardisplayname = ''
  else do 
    if thisindex~isA(.Array) & isarraywindow then vardisplayname = thisindex~makestring(,",")
    else if thisindex~isA(.String) then vardisplayname = thisindex
    else if thisindex = .Nil then vardisplayname = .nil~string
    else do
      vardisplayname = thisindex~defaultname
      if thisindex~isInstanceOf(.Collection) then do
        vardisplayname = vardisplayname' ('thisindex~items' item'    
        if thisindex~items \=1 then vardisplayname=vardisplayname||'s'
        vardisplayname = vardisplayname||')'
      end
      if thisindex~hasmethod("makedebuggerstring") then vardisplayname = vardisplayname||' ['self~GetObjectDebuggerString(thisindex)']'
      vardisplayname = vardisplayname~changestr(.endofline, '<EOL>')~changestr(d2c(13), '<CR>')~changestr(d2c(10), '<LF>')
      if vardisplayname~length > self~MAXNAMESTRINGLENGTH then vardisplayname = vardisplayname~left(self~MAXNAMESTRINGLENGTH)||' ...'
    end
  end 
  
  if thisvalue = .Nil then varvalue = .Nil~string
  else if thisvalue~isA(.string) then varvalue = thisvalue
  else if thisvalue~isA(.MutableBuffer) then varvalue = thisvalue~string
  else varvalue = thisvalue~defaultname
  if thisvalue~isInstanceOf(.Collection) then do
    varvalue = varvalue' ('thisvalue~items' item'
    if thisvalue~items \=1 then varvalue=varvalue||'s'
    varvalue = varvalue||')'
  end  
  if thisvalue~hasmethod("makedebuggerstring") then varvalue = varvalue||' ['self~GetObjectDebuggerString(thisvalue)']'
  varvalue = varvalue~changestr(.endofline, '<EOL>')~changestr(d2c(13), '<CR>')~changestr(d2c(10), '<LF>')~changestr(d2c(0), '<NUL>')
  if varvalue~length > self~MAXVALUESTRINGLENGTH then varvalue = varvalue~left(self~MAXVALUESTRINGLENGTH)||'...'

  if self~IsExpandable(thisvalue~class) then do   
    if thisvalue~class~IsSubclassOf(.Collection) then text = '+'
    else text = ' '
  end
  else text = ' '
  if vardisplayname \= '' then text= text||vardisplayname' = 'varvalue
  else text=text||varvalue
  self~ListUpdateMaxHorizonalExtent(text)
  self~ListAddItem(self~controls, self~LISTVARS, text)
  
  
  itemclass = thisvalue~class
  if isarraywindow then do
    itemindexref = thisindex
    itemvalueref = .nil
  end    
  else do
    if thisindex~IsA(.String) | thisindex = .nil then itemindexref = thisindex
    else itemindexref = .WeakReference~new(thisindex)
    if relationsupplier = .Nil then itemvalueref = .Nil 
    else if thisvalue = .Nil | thisvalue~isA(.string) then itemvalueref = thisvalue
    else itemvalueref = .WeakReference~new(thisvalue)
  end
  itemidentifiers~append(.WatchItemIdentifier~new(itemindexref, itemvalueref, itemclass))
  
  itemindexsuppplier~next
end
self~debugger~uithreadid = 0


------------------------------------------------------
::routine CompareRefValues
------------------------------------------------------
use arg item1, item2
same = .False
if item1~class = item2~class then do
  if item1~IsA(.WeakReference) then do
    if item1~value = item2~value & item1~value \= .nil then same = .True
  end
  else if item1=item2 then  same = .True    
end  

return same

------------------------------------------------------
::routine GetRefValue
------------------------------------------------------
use arg object
if object~IsA(.WeakReference) then return object~value
else return object


------------------------------------------------------
::method GetObjectDebuggerString unguarded
------------------------------------------------------
use arg object

signal on any name BadCall
return object~makedebuggerstring

BadCall:
debugger = self~debugger
debugger~SendDebugMessage(debugger~DebugMsgPrefix||'Error calling makeDebuggerString for 'object~defaultname':')   
cond = .context~condition
do lineidx = 0 to cond~Traceback~items -1
  if cond~Traceback[lineidx]~pos('return object~makedebuggerstring') \= 0 then leave
  debugger~SendDebugMessage(debugger~DebugMsgPrefix||cond~Traceback[lineidx])
end    
if .context~package \= cond~package then debugger~SendDebugMessage(debugger~DebugMsgPrefix||'Error 'cond~RC' running 'cond~package~name' line 'cond~Position': 'cond~ErrorText)   
else debugger~SendDebugMessage(debugger~DebugMsgPrefix||'Error 'cond~RC': 'cond~ErrorText)   
debugger~SendDebugMessage(debugger~DebugMsgPrefix||'Error 'cond~code': 'cond~message)
debugger~SendDebugMessage('')
return "*Error*"

------------------------------------------------------
::method NavigateToActiveSelection
------------------------------------------------------
expose isstringwindow currentselectioninfo itemidentifiers
indextoselect = 0

if isstringwindow then do
 if \currentselectioninfo~selection~IsA(.WatchItemIdentifier) then indextoselect = min(currentselectioninfo~selection, self~ListGetRowCount(self~controls, self~LISTVARS))
end 
else if currentselectioninfo~selection~IsA(.WatchItemIdentifier) then do
  prevselectedindexref = currentselectioninfo~selection~indexref
  prevselecteditemref = currentselectioninfo~selection~itemref
  if prevselectedindexref \= "" & prevselectedindexref \=.Nil then do
    do i = 1 to itemidentifiers~items while indextoselect = 0
      itemidentifierindexref = itemidentifiers[i]~indexref
      itemidentifieritemref =  itemidentifiers[i]~itemref 
      if prevselectedindexref~IsA(.String) & itemidentifierindexref~IsA(.String) then do
        if prevselectedindexref = itemidentifierindexref & CompareRefValues(prevselecteditemref, itemidentifieritemref) then indextoselect = i
      end
      else if prevselectedindexref~IsA(.Array) & itemidentifierindexref~IsA(.Array) then do
        matches = .True
        do j = 1 to prevselectedindexref~dimension(1) while matches = .True
          if  prevselectedindexref[j] \= itemidentifierindexref[j] then matches = .False
        end
        if matches then indextoselect = i
      end
      else if prevselectedindexref~IsA(.WeakReference) & itemidentifierindexref~IsA(.WeakReference) then do
        if prevselectedindexref~value = itemidentifierindexref~value & prevselectedindexref~value \= .nil & CompareRefValues(prevselecteditemref, itemidentifieritemref) then indextoselect = i
      end  
    end
  end  
end
if indextoselect \= 0 then do
  self~ListSetSelectedIndex(self~controls, self~LISTVARS, indextoselect)
  newfirstvisible = MAX(1,indextoselect - currentselectioninfo~rowsbefore)
  self~ListSetFirstVisible(self~controls, self~LISTVARS, newfirstvisible)
end  
else if self~ListGetRowCount(self~controls, self~LISTVARS) \= 0 then self~ListSetFirstVisible(self~controls, self~LISTVARS, 1)

------------------------------------------------------
::method ShowGlobalItems
------------------------------------------------------
expose showglobals

showglobals = .True

self~debugwindow~UpdateWatchWindows


------------------------------------------------------
::method HideGlobalItems
------------------------------------------------------
expose showglobals

showglobals = .False

self~debugwindow~UpdateWatchWindows


------------------------------------------------------
::method DisplayStringBytes
------------------------------------------------------
expose stringwatchshowsbytes

stringwatchshowsbytes = .True

self~debugwindow~UpdateWatchWindows

------------------------------------------------------
::method DisplayStringCharacters
------------------------------------------------------
expose stringwatchshowsbytes

stringwatchshowsbytes = .False

self~debugwindow~UpdateWatchWindows


------------------------------------------------------
::method IsExpandable
------------------------------------------------------
use arg itemclass
if itemclass~IsSubClassOf(.Directory)     | -
   itemclass~IsSubClassOf(.StringTable)   | -
   itemclass~IsSubClassOf(.Properties)    | -
   itemclass~IsSubClassOf(.Stem)          | -
   itemclass~IsSubClassOf(.List)          | -
   itemclass~IsSubClassOf(.Queue)         | - 
   itemclass~IsSubClassOf(.CircularQueue) | -
   itemclass~IsSubClassOf(.Set)           | -
   itemclass~IsSubClassOf(.Bag)           | -
   itemclass~IsSubClassOf(.Relation)      | -
   itemclass~IsSubClassOf(.Table)         | -
   itemclass~IsSubClassOf(.IdentityTable) | -
   itemclass~IsSubClassOf(.String)        | -
   itemclass~IsSubClassOf(.MutableBuffer) | -
   itemclass~IsSubClassOf(.Array) then return .True
else return .False


--====================================================
::class WatchWindowRowSelection
------------------------------------------------------
::attribute selection
::attribute rowsbefore

------------------------------------------------------
::method init
------------------------------------------------------
expose selection rowsbefore
use arg selection, rowsbefore

--====================================================
::class WatchItemIdentifier
------------------------------------------------------

::attribute indexref
::attribute itemref
::attribute itemclass

------------------------------------------------------
::method init
------------------------------------------------------
expose indexref itemref itemclass
use arg indexref, itemref, itemclass

--::OPTIONS NOVALUE SYNTAX /* ooRexx 5+ only */
--::options trace R