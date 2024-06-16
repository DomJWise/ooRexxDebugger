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

if \ConfigureCommandLineDebuggee(ARG(1)~strip) then do 
  parentwindowname = arg(1)
  offsetdirection = arg(2)
end

if .local~rexxdebugger.parentwindowname \= .nil then parentwindowname = .local~rexxdebugger.parentwindowname
if .local~rexxdebugger.offsetdirection \= .nil then offsetdirection = .local~rexxdebugger.offsetdirection

-- Below is the help text List that will initially be added to the source list unless already set by the caller
if .local~rexxdebugger.startuphelptext = .nil then do 
  .local~rexxdebugger.startuphelptext = .list~of( -
  "Command line usage:", - 
  "Rexxdebugger [/showtrace] <program> <argstring>", - 
  "Rexxdebugger [/showtrace] CALL <program> [<arg1>] [..<argn>]", - 
  "", - 
  "To launch from Rexx source include the following line:", - 
  "CALL RexxDebugger [parentwindowtitle, offset(UDL*R*)]", -
  "", - 
  "Below this add the following to start debugging:", -
  "TRACE ?R ", - 
  "", -
  "Source code will be shown when debugging is started.", -
  "", -
  "Note: Window positioning is for Windows/ooDialog only.")
end

-- Set version
.local~rexxdebugger.version = GetPackageConstant("Version")
-- Launch debugger
.local~rexxdebugger.debugger = .RexxDebugger~new(parentwindowname, offsetdirection)

-- Run debuggee (if specified) with or without trace
if .local~rexxdebugger.runroutine \= .nil then do
  if .local~rexxdebugger.discardtrace = .True then .local~rexxdebugger.debugger~CaptureAndDiscardTrace
  .local~rexxdebugger.runroutine~callwith(.local~rexxdebugger.runargs)
  call say 'Debuggee has finished running.'
end

/*====================================================
The core code of the debugging library follows below
====================================================*/

::CONSTANT VERSION "1.203"

--====================================================
::class RexxDebugger public
--====================================================
::attribute windowname unguarded
::attribute offsetdirection unguarded


------------------------------------------------------
::method FlagUIStartupComplete unguarded
------------------------------------------------------
expose uistartupcomplete

uistartupcomplete = .True

------------------------------------------------------
::method StartUIThread unguarded
------------------------------------------------------
expose debuggerui

REPLY /* Switch to a new thread */

debuggerui = .DebuggerUI~new(self)

debuggerui~RunUI


------------------------------------------------------
::method init 
------------------------------------------------------
expose  shutdown launched  breakpoints tracedprograms manualbreak windowname offsetdirection debugwindowtracer uiloaded debuggerui

use arg windowname = "", offsetdirection = ""
if windowname \= "" & offsetdirection = "" then offsetdirection = "R"
shutdown = .False
launched = .False
breakpoints = .Set~new
tracedprograms = .Set~new
manualbreak = .false
debugwindowtracer = .DebugWindowTracer~new(self)
debuggerui = .nil

.local~debug.channel = .Directory~new
.debug.channel~status="getprogramstatus"
.debug.channel~frames=.Nil
.debug.channel~variables=.Nil

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
  uiloaded = .true
end  
else if SysVersion()~translate~pos("WINDOWS") = 1 then do
  if SysSearchPath('PATH','RexxDebuggerWinUI.rex') \= '' then do 
    call RexxDebuggerWinUI.rex
    uiloaded = .true
  end  
end
if \uiloaded then do
    if (SysSearchPath('PATH','RexxDebuggerBSFUI.rex')  \= '' | .File~new('RexxDebuggerBSFUI.rex')~canread) & SysSearchPath('PATH','BSF.cls') \= .Nil then do 
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

breakpoints~put(sourcefile'>'sourceline)

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
::method GetBreakPoints unguarded
------------------------------------------------------
expose breakpoints
use arg sourcefile 
listBreakpoints = .List~new
do breakpoint over breakpoints
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
::method CaptureAndDiscardTrace 
------------------------------------------------------
expose debugwindowtracer uiloaded

IF TRACE() = 'N' THEN do /* If debugger is not tracing itself! */
  if uiloaded then do
    ignore = .traceoutput~destination(debugwindowtracer)
    debugwindowtracer~SetDiscard(.True)
  end  
  return .True
END
else do
  self~SendDebugMessage("DISCARDTRACE cannot be used while tracing for the debugger is active")
  return .False
end

------------------------------------------------------
::method CaptureConsoleOutput 
------------------------------------------------------
expose debugwindowtracer uiloaded
use arg discardtrace
IF TRACE() = 'N' THEN do /* If debugger is not tracing itself! */
  if uiloaded then do 
    ignore = .traceoutput~destination(debugwindowtracer)
    debugwindowtracer~SetDiscard(discardtrace)
    ignore = .output~destination(self)
    ignore = .error~destination(self)
  end  
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
::method ReplyWithTraceCommand 
------------------------------------------------------
expose debuggerui shutdown launched
if shutdown then return 'trace off; exit' 
if launched = .false then return ''
else response =self~GetAutoResponse
if response \= "" | .debug.channel~status = "breakpointcheckgetlocation" then return response 

response =  debuggerui~GetUINextResponse

if translate(response) = 'EXIT' then do
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
if translate(response) = 'DISCARDTRACE', self~captureanddiscardtrace() then return 'call SAY "Trace (apart from error messages) will be discarded if the program permits console capture."'
  
if shutdown & reponse \= '' then response = response||'; trace off; exit'

.debug.channel~status="getprogramstatus"

return response

------------------------------------------------------
::method GetAutoResponse 
------------------------------------------------------
expose debuggerui tracedprograms manualbreak breakpoints

status = .debug.channel~status
if status="breakpointcheckgetlocation" then return '.debug.channel~result = result;.debug.channel~status="breakpointchecklocationis ".context~package~name">".context~line; result =.debug.channel~result'
else if status~pos("breakpointchecklocationis") = 1 then do
  parse value status with ignore breakpoint -- Is this a breakpoint ?
  if breakpoints~hasindex(breakpoint) then do  
    return '.debug.channel~result = result;.debug.channel~status="getprogramstatus"; result =.debug.channel~result'
  end
  else if \tracedprograms~hasitem(breakpoint~makearray('>')[1]) then do -- Break (first time time only) when hitting a new program which traces.
    tracedprograms~put(breakpoint~makearray('>')[1])
    return '.debug.channel~result = result;.debug.channel~status="getprogramstatus"; result =.debug.channel~result'
  end
  else if manualbreak then do -- Was a break issued from the dialog? 
    CALL SAY 'Automatic breakpoint hit.'
    manualbreak = .false
    return '.debug.channel~result = result;.debug.channel~status="getprogramstatus"; result =.debug.channel~result'
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
     return instructions
  end
  else do  
    .debug.channel~frames= .nil
    .debug.channel~variables= .nil
    return '.debug.channel~result = result ; .debug.channel~frames = .context~StackFrames~section(2); .debug.channel~variables=.context~variables;  .debug.channel~status="programstatusupdated";  result=.debug.channel~result;'
  end  
end      
else if status="programstatusupdated" then do
  if .debug.channel~frames \=.nil then do
    frames = .debug.channel~frames
    if .local~rexxdebugger.runroutine \=.nil then frames = frames~section(1, frames~items-2)
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
  return '.debug.channel~result = result;.debug.channel~variables=.context~variables;  .debug.channel~status="gotvars"; result = .debug.channel~result ;'
end     
else if status="gotvars" then do
  if .debug.channel~variables \=.nil then debuggerui~UpdateUIWatchWindows(.debug.channel~variables)
  .debug.channel~frames= .nil
  .debug.channel~variables= .nil
  .debug.channel~status=""
  return '.debug.channel~result = result;.debug.channel~status=""; result = .debug.channel~result; '
end
return ''
------------------------------------------------------
::method SetManualBreak
------------------------------------------------------
expose manualbreak
use arg manualbreak

------------------------------------------------------
::method GetManualBreak
------------------------------------------------------
expose manualbreak

return manualbreak

--====================================================
::class DebugWindowTracer
--====================================================

------------------------------------------------------
::method init
------------------------------------------------------
expose debugger discard
use arg debugger
discard = .False
return 0

------------------------------------------------------
::method SetDiscard
------------------------------------------------------
expose  discard
use arg discard

------------------------------------------------------
::method LINEOUT
------------------------------------------------------
expose debugger discard
use arg tracestring
if tracestring~word(1)~translate='ERROR' | tracestring~pos('+++ Interactive trace.  Error') = 1 | \discard then return debugger~lineout(tracestring)

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
val = ''
if  .METHODS[constname] \= .Nil then interpret 'val=.directory~new~~Setmethod("'constname'",.METHODS["'constname'"])~'constname
return val

------------------------------------------------------
::ROUTINE ConfigureCommandLineDebuggee
------------------------------------------------------
use arg debuggerargstring
retval = .False
entrypackage = .context~stackframes[.context~stackframes~items]~executable~package
if entrypackage \= .nil, entrypackage~name = .context~package~name then do
  if debuggerargstring~translate~word(1) = "/SHOWTRACE" then parse value debuggerargstring with . debuggerargstring
  else .local~rexxdebugger.discardtrace = .true
  if debuggerargstring~translate~word(1) = "CALL" then do 
    say debuggerargstring 
    parse value debuggerargstring with . debuggerargstring
    multipleargs = .True
  end
  else multipleargs = .False
  if debuggerargstring~left(1) \= '"' then parse value debuggerargstring with rexxfile debuggerargstring 
  else parse value  debuggerargstring with '"' rexxfile '"' debuggerargstring
  debuggerargstring = debuggerargstring~strip
  if \multipleargs then runargs = .array~of(debuggerargstring)
  else do
    runargs = .array~new
    do while debuggerargstring \= ''
      if debuggerargstring~left(1) \= '"' then parse value debuggerargstring with nextarg debuggerargstring 
      else parse value  debuggerargstring with '"' nextarg '"' debuggerargstring
      runargs~append(nextarg~strip)
      debuggerargstring = debuggerargstring~strip
    end  
  end  
    
  if rexxfile \= '' then do
    retval = .True
    strm = .stream~new(rexxfile)
    if strm~query('EXISTS') = '' then do 
      say 'Error: rexx file 'rexxfile ' not found.'
      .local~rexxdebugger.deferlaunch = .true
      return .True
    end  
    else do  
      arrsource = strm~arrayin
      strm~close
      signal on ANY name HandleSyntaxError
      runroutine = .routine~new(rexxfile, arrSource~~append('')~~append('/*REXX.DEBUGGER.INJECT*/ ::OPTIONS TRACE ?R'))
      .context~package~addRoutine('REXXDEBUGGEEMAIN', runroutine)
      .local~rexxdebugger.runroutine = runroutine
      .local~rexxdebugger.runargs = runargs
    end  
  end
end
return retval

HandleSyntaxError: 
cond = .context~condition
say .endofline||'Error: Syntax error parsing 'rexxfile' at line 'cond~POSITION||.endofline 
say cond~POSITION~right(5)' *-* 'arrSource[cond~POSITION]||.endofline
say 'Error 'cond~RC' : 'cond~ERRORTEXT
say 'Error 'cond~CODE': 'cond~MESSAGE
.local~rexxdebugger.deferlaunch = .true
return  .True


--::options trace R