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
  "Rexxdebugger [/nocapture | /showtrace] [/javaui] <program> <argstring>", - 
  "Rexxdebugger [/nocapture | /showtrace] [/javaui] CALL <program> [<arg1>] [..<argn>]", - 
  "", - 
  "To launch from Rexx source include the following line:", - 
  "CALL RexxDebugger [parentwindowtitle, offset(UDL*R*)]", -
  "", - 
  "Below this add the following to start debugging:", -
  "TRACE ?R ", - 
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
  if .local~rexxdebugger.captureoption = '/SHOWTRACE'  then .local~rexxdebugger.debugger~CaptureConsoleOutput(.False)
  else if .local~rexxdebugger.captureoption \= '/NOCAPTURE' then .local~rexxdebugger.debugger~CaptureConsoleOutput(.True)

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

if .local~rexxdebugger.commandlineisrexxdebugger then .local~rexxdebugger.debugger~WaitForUIToEnd

/*====================================================
The core code of the debugging library follows below
====================================================*/

::CONSTANT VERSION "1.32.1"

--====================================================
::class RexxDebugger public
--====================================================
::attribute windowname unguarded
::attribute offsetdirection unguarded
::attribute canopensource unguarded
::attribute debuggerui unguarded
::attribute lastexecfulltime unguarded

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

debuggerui = .DebuggerUI~new(self, .WatchHelper)

debuggerui~RunUI

uiFinished = .True

------------------------------------------------------
::method init 
------------------------------------------------------
expose  shutdown launched  breakpoints tracedprograms manualbreak windowname offsetdirection traceoutputhandler outputhandler errorhandler uiloaded debuggerui canopensource lastexecfulltime uifinished
use arg windowname = "", offsetdirection = ""
if windowname \= "" & offsetdirection = "" then offsetdirection = "R"
shutdown = .False
launched = .False
breakpoints = .Properties~new
tracedprograms = .Set~new
manualbreak = .false
traceoutputhandler = .nil
outputhandler = .nil
errorhandler = .nil
debuggerui = .nil
canopensource = .False
lastexecfulltime = 0
uifinished = .True

.local~debug.channel = .Directory~new
.debug.channel~status="getprogramstatus"
.debug.channel~frames=.Nil
.debug.channel~variables=.Nil
.debug.channel~breakpointtestresult = .False

uiloaded = self~findandloadui()

if uiloaded then ignore = .debuginput~destination(self)

if .local~rexxdebugger.deferlaunch \= .true then do
  .local~rexxdebugger.deferlaunch = .false
  self~launch(windowname, offsetdirection)
end

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
expose breakpoints
use arg sourcefile, sourceline

breakpoints~put('',sourcefile'>'sourceline)

------------------------------------------------------
::method SetBreakPointTest unguarded
------------------------------------------------------
expose breakpoints
use arg sourcefile, sourceline, test

breakpoints~put(test, sourcefile'>'sourceline)

------------------------------------------------------
::method ClearBreakPoint  unguarded
------------------------------------------------------
expose breakpoints
use arg sourcefile, sourceline

ignore = breakpoints~remove(sourcefile'>'sourceline)

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
if \breakpoints~hasindex(sourcefile'>'sourceline) then
  return ''
else  
  return breakpoints~at(sourcefile'>'sourceline)


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
::method LINEIN 
------------------------------------------------------
return self~ReplyWithTraceCommand

------------------------------------------------------
::method ReplyWithTraceCommand unguarded
------------------------------------------------------
expose debuggerui shutdown launched canopensource lastexecfulltime
lastexecfulltime = TIME('F')
if shutdown then return 'trace off; exit' 
if launched = .false then return ''
else response =self~GetAutoResponse
if response \= "" | .debug.channel~status = "breakpointcheckgetlocation" then return response 

response =  debuggerui~GetUINextResponse

if translate(response) = 'EXIT' then do
   canopensource = .True
   debuggerui~UpdateUIControlStates
   self~informshutdown
   return 'say "Exiting as instructed by the debugger"; trace off; exit'
   
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
   if "RUN EXIT HELP CAPTURE CAPTUREX NOCAPTURE"~wordpos(response~word(2)~translate) \= 0 then .debug.channel~status="getprogramstatus "||response~DELWORD(1,2)
   else .debug.channel~status="getprogramstatus "||response~DELWORD(1,1)
  return ''
end  
if translate(response) = 'UPDATEVARS' then do
  .debug.channel~status="getvars"
  return 'NOP'
end  
if translate(response) = 'CAPTURE' | translate(response) = 'CAPTUREX' then do 
  if translate(response) = 'CAPTURE' then discardtrace = .False
  else  discardtrace = .True
  if self~CaptureConsoleOutput(discardtrace) then do
    retstr = 'call SAY "Output redirected to the debugger if the program permits this."'
    if discardtrace = .False then retstr = retstr||'.endofline||"CAPTUREX does the same but discards trace text."'
    else retstr = retstr||'.endofline||"All trace apart from runtime error messages will be discarded."'
    return retstr
  end  
end
if translate(response) = 'NOCAPTURE' then do
  self~StopCaptureConsoleOutput
  return 'call SAY "If active, console redirection has been switched off."||.endofline||"Use CAPTURE/CAPTUREX to switch it back on."'
end  
if translate(response) = 'HELP' then do
  self~ShowHelpText
  return 'NOP'
end  
  
if shutdown & response \= '' then response = response||'; trace off; exit'

.debug.channel~status="getprogramstatus"

return response

------------------------------------------------------
::method GetAutoResponse unguarded
------------------------------------------------------
expose debuggerui tracedprograms manualbreak breakpoints

status = .debug.channel~status
if status="breakpointcheckgetlocation" then do
  .debug.channel~remove('RESULT')
  return 'if Symbol(''RESULT'') = ''VAR'' THEN .debug.channel~result = RESULT; .debug.channel~status="breakpointchecklocationis ".context~package~name">".context~line; if .debug.channel~hasindex(''RESULT'') then result =.debug.channel~result; else DROP RESULT'
  end
else if status~pos("breakpointchecklocationis") = 1 then do
  parse value status with ignore codelocation -- Is this a breakpoint ?
  if breakpoints~hasindex(codelocation) then do  
    test = breakpoints[codelocation]
    if test = '' then do
      .debug.channel~status="getprogramstatus"
      return 'NOP'
    end  
    else do
      .debug.channel~status="breakpointprocesstestresult" 
      .debug.channel~breakpointtestresult = .True
      .debug.channel~remove('RESULT')
      return 'if Symbol(''RESULT'') = ''VAR'' THEN .debug.channel~result = result; .debug.channel~breakpointtestresult = ('||test||'); if .debug.channel~hasindex(''RESULT'') then result =.debug.channel~result; else DROP RESULT'
      end
  end
  else if \tracedprograms~hasitem(codelocation~makearray('>')[1]) then do -- Break (first time time only) when hitting a new program which traces.
    tracedprograms~put(codelocation~makearray('>')[1])
    .debug.channel~status="getprogramstatus"
    return 'NOP'
  end
  else if manualbreak then do -- Was a break issued from the dialog? 
    CALL SAY 'Automatic breakpoint hit.'
    manualbreak = .false
    .debug.channel~status="getprogramstatus"
    return 'NOP'
  end
  else do       
    .debug.channel~status = "breakpointcheckgetlocation"
    return ''
  end  
end  
else if status~pos("breakpointprocesstestresult") = 1 then do
  testresult = .debug.channel~breakpointtestresult
  .debug.channel~breakpointtestresult = .False
  if testresult = .True then do
    .debug.channel~status="getprogramstatus"
    return 'NOP'
  end  
  else do
    .debug.channel~status = "breakpointcheckgetlocation"
    return ''
  end
end
else if status~word(1)="getprogramstatus" then do
  instructions = status~delword(1,1)~strip
  if instructions \= '' then do 
    .debug.channel~frames= .nil
    .debug.channel~variables= .nil
    .debug.channel~status="getprogramstatus"
    .debug.channel~remove('RESULT')
     return 'if Symbol(''RESULT'') = ''VAR'' THEN .debug.channel~result = result ;'instructions'; if .debug.channel~hasindex(''RESULT'') then result =.debug.channel~result; else DROP RESULT'
  end
  else do  
    .debug.channel~frames= .nil
    .debug.channel~variables= .nil
    .debug.channel~status="programstatusupdated";
    .debug.channel~remove('RESULT')
    return 'if Symbol(''RESULT'') = ''VAR'' THEN .debug.channel~result = result ; .debug.channel~frames = .context~StackFrames~section(2); .debug.channel~variables=.context~variables;  if .debug.channel~hasindex(''RESULT'') then result =.debug.channel~result; else DROP RESULT'
  end  
end      
else if status="programstatusupdated" then do
  if .debug.channel~frames \=.nil then do
    frames = .debug.channel~frames
    if .local~rexxdebugger.runroutine \=.nil then frames = frames~section(1, frames~items-3)
    tracedprograms~put(frames~firstitem~executable~package~name)
    debuggerui~UpdateUICodeView(frames, 1)
  end  
  if .debug.channel~variables \=.nil then debuggerui~UpdateUIWatchWindows(.debug.channel~variables)
  .debug.channel~frames= .nil
  .debug.channel~variables= .nil
  .debug.channel~status=""
  return ''
end
else if status="getvars" then do
  .debug.channel~frames= .nil
  .debug.channel~variables= .nil
  .debug.channel~status="gotvars"
  .debug.channel~remove('RESULT')
  return 'if Symbol(''RESULT'') = ''VAR'' THEN .debug.channel~result = result;.debug.channel~variables=.context~variables; if .debug.channel~hasindex(''RESULT'') then result =.debug.channel~result; else DROP RESULT'
end     
else if status="gotvars" then do
  if .debug.channel~variables \=.nil then debuggerui~UpdateUIWatchWindows(.debug.channel~variables)
  .debug.channel~frames= .nil
  .debug.channel~variables= .nil
  .debug.channel~status=""
  return 'NOP'
end
return ''
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
::method ShowHelptext 
------------------------------------------------------
self~SendDebugMessage("")
self~SendDebugMessage("- Commands: <instrs> | NEXT [<instrs>] | RUN | EXIT | HELP | CAPTURE | CAPTUREX | NOCAPTURE - use the Exec button to run the command.")
self~SendDebugMessage("- Buttons with the above labels execute the corresponding command.")
self~SendDebugMessage("- Command history for the session can be accessed with the up/down keys.")
self~SendDebugMessage("- The Vars button opens a realtime variables window.")
self~SendDebugMessage("- Double clicking many collection object types in a variables window will expand them in a new window.")
self~SendDebugMessage("- Clicking a stack row takes you to the specified source location and file.")
self~SendDebugMessage("- Double clicking a source row toggles a breakpoint, but this does not guarantee that the line will be hit.")
self~SendDebugMessage("  Some simple hit checks are carried out but there is no detailed code analysis.")
self~SendDebugMessage("  e.g. if it is empty, a comment, a directive or is END, THEN, ELSE, OTHERWISE, RETURN, EXIT or SIGNAL")
self~SendDebugMessage("  DO statements should be hit unless they mark the start of a loop that has looped once already.")
self~SendDebugMessage("  CALL statements (and what they call) may be hit, depending on what they are calling.")
self~SendDebugMessage("  A * means the self thinks the code will be hit, a ? means it thinks it likely it won't ever be hit.")
self~SendDebugMessage("  Hint: A line with just NOP can be inserted as an anchor for a breakpoint that will always be hit.")
self~SendDebugMessage("- /**/ at the start of traceable line (including NOP) causes a breakpoint to be automatically set for that line.")
self~SendDebugMessage("- The instruction CALL SAY ... will always send output here.")
self~SendDebugMessage("- So long as SAY is enabled in the target application, other output should appear there.")
self~SendDebugMessage("- If the application has no output, or you want the output here, you can try the CAPTURE command to capture all output.")
self~SendDebugMessage("  CAPTUREX is similar but will discard (eXclude) all trace output apart from program errors.")
self~SendDebugMessage("- NOCAPTURE switches off any capture that was previously active.")
self~SendDebugMessage("- The source window and watch windows go grey while the program is running and after it has finished.")
self~SendDebugMessage("Happy debugging!")

------------------------------------------------------
::method GetCaption unguarded
------------------------------------------------------
return "ooRexx Debugger Version "||GetPackageConstant("Version")


------------------------------------------------------
::method OpenNewProgram unguarded
------------------------------------------------------
expose debuggerui shutdown breakpoints tracedprograms canopensource

use arg rexxfile,argstring,multipleargs = .False, firsttime = .False

shutdown = .False
breakpoints~empty
tracedprograms~empty
.debug.channel~status = "getprogramstatus"
.local~rexxdebugger.runroutine = runroutine

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
  arrSource~~append('')~append('/*REXX.DEBUGGER.INJECT*/ ::OPTIONS TRACE ?R')

  if \firsttime then do
    debuggerui~AppendUIConsoleText("")
    debuggerui~AppendUIConsoleText("New debug session started for "rexxfile)
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
  runroutine~callwith(runargs)
  signal off ANY
  canopensource = .True
  debuggerui~UpdateUIControlStates
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
end
else do  
  strm = .stream~new(rexxfile)
  arrsource = strm~arrayin
  strm~close
  errorlist~append('Error: Syntax error parsing 'rexxfile' at line 'sourceerrorline)
  errorlist~append('')
  if sourceerrorline \= 0 then errorlist~append(sourceerrorline~right(5)' *-* 'arrSource[sourceerrorline])
  errorlist~append('')
  errorlist~append('Error 'cond~RC' : 'cond~ERRORTEXT)
  errorlist~append('Error 'cond~CODE': 'cond~MESSAGE)
end  
debuggerui~SetUISourceListInfoText(errorlist)
self~canopensource = .true
debuggerui~UpdateUIControlStates
return

------------
HandleRuntimeError: 
------------
self~SendDebugMessage('Runtime error:')   
cond = .context~condition
do lineidx = 0 to cond~Traceback~items -1
  if cond~Traceback[lineidx]~pos('runroutine~callwith(runargs)') \= 0 then leave
  self~SendDebugMessage(cond~Traceback[lineidx])
end    
self~SendDebugMessage('Error 'cond~RC' running 'cond~package~name' line 'cond~Position': 'cond~ErrorText)   
self~SendDebugMessage('Error 'cond~code': 'cond~message)

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

------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("LINEOUT", .Method~new("", self~method("LINEOUT")~source)~~setUnguarded)

------------------------------------------------------
::method init
------------------------------------------------------
expose debugger discard canusetraceobjects capture originaltraceoutput 
use arg debugger
discard = .False
capture = .False

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
expose debugger discard canusetraceobjects capture originaltraceoutput
use arg tracething

if \capture | debugger~isshutdown then forward to (originaltraceoutput)

if canusetraceobjects, tracething~isA(.Traceobject) then tracestring = tracething~makestring
else tracestring = tracething

if tracestring~word(1)~translate='ERROR' | tracestring~pos('+++ Interactive trace.  Error') = 1 | \discard then debugger~SendDebugMessage(tracestring)

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
  forcejava = .false
  do while  "/SHOWTRACE /NOCAPTURE /JAVAUI"~wordpos(debuggerargstring~translate~word(1)) \= 0
    nextflag = debuggerargstring~translate~word(1)
    parse value debuggerargstring with . debuggerargstring
    if "/SHOWTRACE /NOCAPTURE"~wordpos(nextflag) \= 0 then do
      .local~rexxdebugger.captureoption = nextflag
    end
    else if nextflag = "/JAVAUI" then do 
      forcejava = .True
    end
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
::class WatchHelper mixinclass object public
--====================================================

------------------------------------------------------
::method IsExpandable
------------------------------------------------------
use arg itemclass
if itemclass =.Directory | -
  itemclass =.StringTable | -
  itemclass =.Properties | -
  itemclass =.Stem | -
  itemclass =.List | -
  itemclass =.Queue | -
  itemclass =.CircularQueue | -
  itemclass =.Array then return .True
else return .False

--::options trace R