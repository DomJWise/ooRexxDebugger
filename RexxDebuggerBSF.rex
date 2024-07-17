if .TraceObject~Class~defaultname = .Class~defaultname then .TraceObject~Option = 'F'
say '----------------------------- rexxdebugger.rex ' .TraceObject~identityhash

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
  "", -
  "Note: Window positioning is for Windows/ooDialog only.")
end

-- Set version
.local~rexxdebugger.version = GetPackageConstant("Version")
-- Launch debugger
.local~rexxdebugger.debugger = .RexxDebugger~new(parentwindowname, offsetdirection)

-- Run debuggee (if specified) with or without capture/trace
if .local~rexxdebugger.runroutine \= .nil then do
  if .local~rexxdebugger.captureoption = '/SHOWTRACE'  then .local~rexxdebugger.debugger~CaptureConsoleOutput(.False)
  else if .local~rexxdebugger.captureoption \= '/NOCAPTURE' then .local~rexxdebugger.debugger~CaptureConsoleOutput(.True)
  
  .local~rexxdebugger.runroutine~callwith(.local~rexxdebugger.runargs)
  call say 'Debuggee has finished running.'
end


/*====================================================
The core code of the debugging library follows below
====================================================*/

::CONSTANT VERSION "1.27"

--====================================================
::class RexxDebugger public
--====================================================
::attribute windowname unguarded
::attribute offsetdirection unguarded

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
expose debuggerui

REPLY /* Switch to a new thread */

debuggerui = .DebuggerUI~new(self)

debuggerui~RunUI


------------------------------------------------------
::method init 
------------------------------------------------------
expose  shutdown launched  breakpoints tracedprograms manualbreak windowname offsetdirection traceoutputhandler outputhandler errorhandler uiloaded debuggerui
use arg windowname = "", offsetdirection = ""
if windowname \= "" & offsetdirection = "" then offsetdirection = "R"
shutdown = .False
launched = .False
breakpoints = .Set~new
tracedprograms = .Set~new
manualbreak = .false
traceoutputhandler = .nil
outputhandler = .nil
errorhandler = .nil
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
::ROUTINE ConfigureCommandLineDebuggee
------------------------------------------------------
use arg debuggerargstring
retval = .False
entrypackage = .context~stackframes[.context~stackframes~items]~executable~package
if entrypackage \= .nil, entrypackage~name = .context~package~name then do
  if "/SHOWTRACE /NOCAPTURE"~wordpos(debuggerargstring~translate~word(1)) \= 0 then do
    .local~rexxdebugger.captureoption = debuggerargstring~translate~word(1)~translate
    parse value debuggerargstring with . debuggerargstring
  end
  else .local~rexxdebugger.captureoption = ''
  if debuggerargstring~translate~word(1) = "/JAVAUI" then do 
    parse value debuggerargstring with . debuggerargstring
    forcejava = .True
  end
  else forcejava = .false
  
  if debuggerargstring~translate~word(1) = "CALL" then do 
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
      if arrSource[1]~strip~left(2) = '#!' then arrSource[1] = arrSource[1]~insert('-- /*REXX.DEBUGGER.COMMENTOUT*/ ')
      arrsource~~append('')~append('/*REXX.DEBUGGER.INJECT*/ ::OPTIONS TRACE ?R')
      if forcejava & SysVersion()~translate~pos("WINDOWS") = 1 then arrSource~append('/*REXX.DEBUGGER.INJECT*/ ::REQUIRES RexxDebuggerBSFUI.rex')
      signal on ANY name HandleSyntaxError
      runroutine = .routine~new(rexxfile, arrSource)
      signal off ANY
      routinepackage = runroutine~package
      do i over routinepackage~importedpackages
        if i~findclass("DebuggerUI") \= .nil  then .context~package~addpackage(i)
      end  
      .context~package~addRoutine('REXXDEBUGGEEMAIN', runroutine)
      .local~rexxdebugger.runroutine = runroutine
      .local~rexxdebugger.runargs = runargs
    end  
  end
  else if forcejava & SysVersion()~translate~pos("WINDOWS") = 1 then call RexxDebuggerBSFUI.rex
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

::attribute awaitingmaindialogresponse  public unguarded
::attribute debugdialogresponse         public unguarded
::attribute fontFixed                   public unguarded

::attribute clsBorderLayout        public unguarded
::attribute clsDefaultListModel    public unguarded
::attribute clsDimension           public unguarded
::attribute clsEmptyBorder         public unguarded
::attribute clsFont                public unguarded
::attribute clsInsets              public unguarded 
::attribute clsJButton             public unguarded
::attribute clsJList               public unguarded
::attribute clsJPanel              public unguarded
::attribute clsJScrollPane         public unguarded
::attribute clsJTextField          public unguarded
::attribute clsJTextArea           public unguarded
::attribute clsKeyEvent            public unguarded
::attribute clsListSelectionModel  public unguarded
::attribute clsWindowConstants     public unguarded

------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("AppendUIConsoleText", .Method~new("", self~method("AppendUIConsoleText")~source)~~setUnguarded)
self~define("DidUICallSucceed", .Method~new("", self~method("DidUICallSucceed")~source)~~setUnguarded)

------------------------------------------------------
::method init
------------------------------------------------------
expose debugger debugdialog
use arg debugger

self~clsBorderLayout       = bsf.importclass("java.awt.BorderLayout")
self~clsDefaultListModel   = bsf.importclass("javax.swing.DefaultListModel")
self~clsDimension          = bsf.importclass("java.awt.Dimension")
self~clsEmptyBorder        = bsf.importclass("javax.swing.border.EmptyBorder")
self~clsFont               = bsf.importclass("java.awt.Font") 
self~clsInsets             = bsf.importclass("java.awt.Insets") 
self~clsJButton            = bsf.importclass("javax.swing.JButton")
self~clsJList              = bsf.importclass("javax.swing.JList") 
self~clsJPanel             = bsf.importclass("javax.swing.JPanel")
self~clsJScrollPane        = bsf.importclass("javax.swing.JScrollPane")
self~clsJTextArea          = bsf.importclass("javax.swing.JTextArea")
self~clsJTextField         = bsf.importclass("javax.swing.JTextField")
self~clsKeyEvent           = bsf.importclass("java.awt.event.KeyEvent")
self~clsListSelectionModel = bsf.loadclass("javax.swing.ListSelectionModel")
self~clsWindowConstants    = bsf.loadclass("javax.swing.WindowConstants") 

graphicsenv = bsf.loadclass("java.awt.GraphicsEnvironment")
jarrfontfamilies = graphicsenv~getLocalGraphicsEnvironment~getAvailableFontFamilyNames()
arr = bsf.wrap(jarrfontfamilies)

self~fontFixed = ''
do i = 1 to arr~items
  if arr[i]~pos("Courier") = 1 then do
    self~fontFixed = arr[i]
    leave
  end
end 
debugdialog = .nil

if .AWTGuiThread~isGuiThread then self~InitSafe
else success = self~DidUICallSucceed(.AwtGuiThread~runLater(self, "InitSafe")~~result~errorCondition, .context)

------------------------------------------------------
::method InitSafe unguarded
------------------------------------------------------
expose  debugdialog debugger
 
/* Create and build the "main" window" */
debugdialog = .DebugDialog~new(debugger, self,.rexxdebugger.startuphelptext)


------------------------------------------------------
::method RunUI unguarded
------------------------------------------------------
expose debugdialog debugger

if debugdialog \= .nil then do 
  if .AWTGuiThread~isGuiThread then self~ShowMainDialogSafe
  else success = self~DidUICallSucceed(.AwtGuiThread~runLater(self, "ShowMainDialogSafe")~~result~errorCondition, .context)

  debugger~FlagUIStartupComplete

  self~WaitForExit 

  if \.AWTGuiThread~isGuiThread then success = self~DidUICallSucceed(.AwtGuiThread~runLaterLatest(self, "NoOp")~~result~errorCondition, .context)
end

------------------------------------------------------
::method ShowMainDialogSafe unguarded
-----------------------------------------------------
expose debugdialog

debugdialog~~setVisible(.true) ~~toFront
debugdialog~repaint

------------------------------------------------------
::method NoOp unguarded
------------------------------------------------------
------------------------------------------------------
::method AppendUIConsoleText unguarded
------------------------------------------------------
expose debugdialog debugger
use  arg text, newline = .true
if debugdialog \= .nil & \debugger~isshutdown then do 
  if .AWTGuiThread~isGuiThread then debugdialog~appendtext(text, newline)
  else success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "appendtext", "I", text, newline)~~result~errorCondition, .context)
end  


------------------------------------------------------
::method GetUINextResponse unguarded 
------------------------------------------------------
expose debugdialog  debugdialogresponse awaitingmaindialogresponse

awaitingmaindialogresponse = .True
debugdialogresponse = ''
if debugdialog \= .nil & \.AWTGuiThread~isGuiThread then do
  debugdialog~SetWaiting(.true)
  success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "UpdateControlStates")~~result~errorCondition, .context)
  --success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "OnNextButton")~~result~errorCondition, .context)

  guard off when awaitingmaindialogresponse = .False
end  
return debugdialogresponse

------------------------------------------------------
::method UpdateUICodeView unguarded
------------------------------------------------------
expose debugdialog debugger
use arg arrStack, activateindex

if debugdialog \= .nil & \debugger~isshutdown then do
  if .AWTGuiThread~isGuiThread then debugdialog~UpdateCodeView(arrStack, activateindex)
  else success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "UpdateCodeView", "I", arrStack, activateindex)~~result~errorCondition, .context)
end

------------------------------------------------------
::method UpdateUIWatchWindows unguarded
------------------------------------------------------
expose debugdialog debugger
use arg varsroot

if debugdialog \= .nil  & \debugger~isshutdown then do
  if .AWTGuiThread~isGuiThread then debugdialog~UpdateWatchWindows(varsroot)
  else success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "UpdateWatchWindows", "I", varsroot)~~result~errorCondition, .context)
end
-------------------------------------------------------
::method SetExit unguarded
-------------------------------------------------------
expose doexit
doexit = .True
-------------------------------------------------------
::method WaitForExit unguarded
-------------------------------------------------------
expose doexit

doexit = .False
guard on when doexit = .True
-------------------------------------------------------
::method DidUICallSucceed
-------------------------------------------------------
use arg cond, callercontext
success = .true
if cond \= .nil then do 
  success = .False
  say 'Error in UI thread call at line 'cond~POSITION' of '.context~package~name 
  say 'Error 'cond~RC' : 'cond~ERRORTEXT
  if IsWindows() then message = cond~MESSAGE~changestr(d2c(10), .endofline)
  else message = cond~MESSAGE  
  say 'Error 'cond~CODE': 'message
  say 'UI Stack:'
  say cond~TRACEBACK~makearray~makestring
  say
  say 'Caller Stack:'
  say callercontext~stackframes~section(2)
  say 
end  
return success


--====================================================
::class DebugDialogWindowListener public
--====================================================
::method windowopened
::method windowactivated
::method windowdeactivated
::method windowiconified
::method windowdeiconified
::method windowclosed

------------------------------------------------------
::method windowclosing 
------------------------------------------------------
use arg eventobj, slotdir
dialog = slotdir~userdata
dialog~Cancel

--====================================================
::class DebugDialogListStackMouseListener public
--====================================================
::method mousepressed
::method mousereleased
::method mouseexited
::method mouseentered

------------------------------------------------------
::method mouseclicked
------------------------------------------------------
use arg eventobj, slotdir

dialog = slotdir~userdata
dialog~StackFrameChanged

--====================================================
::class DebugDialogListSourceMouseListener public
--====================================================
::method mousepressed
::method mousereleased
::method mouseexited
::method mouseentered

------------------------------------------------------
::method mouseclicked
------------------------------------------------------
use arg eventobj, slotdir
if eventobj~getclickcount == 2 then do
  dialog = slotdir~userdata
  dialog~SourceLineDoubleClicked
end

--====================================================
::class DebugDialogCommandKeyListener public
--====================================================
::method keyTyped
::method keyReleased

------------------------------------------------------
::method init
------------------------------------------------------
expose vkup vkdown

vkup = bsf.getstaticvalue("java.awt.event.KeyEvent", "VK_UP")
vkdown = bsf.getstaticvalue("java.awt.event.KeyEvent", "VK_DOWN")

------------------------------------------------------
::method keyPressed
------------------------------------------------------
expose vkup vkdown
use arg event, slotdir
dialog = slotdir~userdata

if event~getKeycode = vkup then dialog~OnPrevCommand
if event~getKeycode = vkdown then dialog~OnNextCommand

--====================================================
::class DebugDialog subclass bsf
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
::constant PANESOURCE   110

------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("appendtext", .Method~new("", self~method("appendtext")~source)~~setUnguarded)

------------------------------------------------------
::method Cancel unguarded
------------------------------------------------------
expose waiting debugger hfnt watchwindows controls gui
close = .True
if waiting = .True then do
  ret = .bsf.dialog~dialogbox("Do you really want to quit and end the program ?", "Program still running","question", "YesNo")
  if ret = 1 then close = .False
end  
if close then do

  debugger~informshutdown
  watchlist = watchwindows~allitems~section(1)
  do watchwindow over watchlist~allitems
     watchwindow~cancel
  end   

  if waiting then self~HereIsResponse('say "Debugger closed - exiting"')
  self~dispose
  gui~SetExit
end


------------------------------------------------------
::method UpdateControlStates unguarded
------------------------------------------------------
expose waiting controls watchwindows
do control over .array~of(SELF~LISTSOURCE, SELF~LISTSTACK, self~BUTTONNEXT, self~BUTTONEXIT, self~BUTTONVARS, self~BUTTONEXEC, self~BUTTONHELP)
  if waiting then controls[control]~setEnabled(.true)
  else  controls[control]~setEnabled(.false)
end    

if waiting & \controls[self~BUTTONRUN]~gettext()~equals("Run") then controls[self~BUTTONRUN]~settext("Run")
if waiting then controls[self~EDITCOMMAND]~requestFocus

do watchwindow over watchwindows~allitems
  watchwindow~SetListState(waiting)
end

if waiting then  .AwtGuiThread~runLater(self, "OnNextButton")


------------------------------------------------------
::method init 
------------------------------------------------------
expose debugger gui controls waiting arrcommands commandnum arrstack activesourcename loadedsources watchwindows startuphelptext checkedsources
use arg debugger, gui, startuphelptext
arrstack = .nil
activesourcename = .nil
loadedsources = .Directory~new
watchwindows = .Directory~new
checkedsources = .List~new

waiting = .false
controls = .Directory~new


arrcommands = .Array~new
commandnum = 0
self~InitDialog

-------------------------------------------------------
::method SetWaiting unguarded
-------------------------------------------------------
expose waiting
use arg waiting

------------------------------------------------------
::method HereIsResponse unguarded
------------------------------------------------------
expose gui waiting
use arg response

waiting = .False
self~UpdateControlStates

gui~debugdialogresponse = response
gui~awaitingmaindialogresponse = .False


------------------------------------------------------
::method OnNextButton unguarded
------------------------------------------------------
expose waiting controls 
if waiting then do
  instructions = controls[self~EDITCOMMAND]~gettext~strip
  controls[self~BUTTONRUN]~settext("Break")
  if instructions~word(1)~translate\='NEXT' then instructions = 'NEXT 'instructions
  self~HereIsResponse(instructions)
end


------------------------------------------------------
::method OnRunButton
------------------------------------------------------
expose waiting debugger controls
if waiting then do
  controls[self~BUTTONRUN]~settext("Break")
  self~HereIsResponse('RUN')
end
else if \debugger~GetManualBreak then do
  debugger~SetManualBreak(.True)
  controls[self~BUTTONRUN]~settext("Run")
  self~appendtext('Automatic breakpoint set for the next line of traceable code.')
end
else do
  debugger~SetManualBreak(.False)
  self~appendtext('Automatic breakpoint removed. Program will run normally.')
  controls[self~BUTTONRUN]~settext("Break")
end   


------------------------------------------------------
::method OnExitButton
------------------------------------------------------
expose waiting 
if waiting then do
  ret = .bsf.dialog~dialogbox("Do you really want to exit the program ?", "Program still running","question", "YesNo")
  if ret = 0 then do
    self~appendtext("Program requested to exit.")
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

------------------------------------------------------
::method OnExecButton 
------------------------------------------------------
expose waiting controls arrCommands commandnum

if waiting then do
  returnstring = controls[self~EDITCOMMAND]~gettext~strip
  
  controls[self~EDITCOMMAND]~selectall
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
::METHOD AddWatchWindow unguarded
------------------------------------------------------
expose watchwindows  childready rootlist gui
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
  watchdialog = .Watchdialog~new(self, gui, parentwindow, parentlist)
  watchwindows[watchwindowid] = watchdialog
  guard off when childready = .True
  
end
watchwindows[watchwindowid]~tofront

self~HereIsResponse("UPDATEVARS")


------------------------------------------------------
::METHOD NotifyChildReady unguarded
------------------------------------------------------
expose childready
childready = .True

------------------------------------------------------
::METHOD RemoveWatchWindow unguarded
------------------------------------------------------
expose watchwindows
use arg watchwindow
watchwindows~removeitem(watchwindow)


------------------------------------------------------
::method InitDialog 
------------------------------------------------------
expose controls debugtext buttonpushed debugger hfnt startuphelptext gui

-- Create the frame
title = debugger~GetCaption
if IsWindows() then title = title || " (Java UI)"
self~init:super('javax.swing.JFrame',.array~of(title))
self~setDefaultCloseOperation(gui~clsWindowConstants~DO_NOTHING_ON_CLOSE)
self~setSize(440, 510)
self~setMinimumSize(gui~clsDimension~new(440,510))
self~setLayout(gui~clsBorderLayout~new(5,5))
self~setLocationRelativeTo(.nil)

panelmain = gui~clsJPanel~new
panelmain~setBorder(gui~clsEmptyBorder~new(5,5,5,5))
panelmain~setLayout(gui~clsBorderLayout~new(5,5))

panellevel1lowercontrols = gui~clsJPanel~new
panellevel1lowercontrols~setLayout(gui~clsBorderLayout~new(3,3))
panellevel1lowercontrols~setPreferredSize(gui~clsDimension~new(0,250))
panelmain~add(panellevel1lowercontrols,gui~clsBorderLayout~SOUTH)

listsourcemodel = gui~clsDefaultListModel~new
listsource = gui~clsJList~new(listsourcemodel)

listsource~setSelectionMode(gui~clsListSelectionModel~SINGLE_SELECTION)
listsource~setLayoutOrientation(gui~clsJlist~VERTICAL)
if gui~fontFixed \= '' then listsource~setFont(gui~clsFont~new(gui~fontFixed, gui~clsFont~BOLD, 12))
listsource~setFixedCellHeight(14)

listsourcepane = gui~clsJScrollPane~new
listsourcepane~setPreferredSize(gui~clsDimension~new(440,50))
listsourcepane~setViewportView(listsource)

panelmain~add(listsourcepane, gui~clsBorderLayout~CENTER)

liststackmodel =  gui~clsDefaultListModel~new
liststack = gui~clsJlist~new(liststackmodel)

liststack~setSelectionMode(gui~clsListSelectionModel~SINGLE_SELECTION)
liststack~setLayoutOrientation(gui~clsJlist~VERTICAL)
if gui~fontFixed \= '' then liststack~setFont(gui~clsFont~new(gui~fontFixed, gui~clsfont~BOLD, 12))
liststack~setFixedCellHeight(14)

liststackpane = gui~clsJScrollPane~new
liststackpane~setPreferredSize(gui~clsDimension~new(440,50))
liststackpane~setViewportView(liststack)

panellevel1lowercontrols~add(liststackpane,gui~clsBorderLayout~NORTH)

	
panelllevel2forbuttons  = gui~clsjPanel~new
panelllevel2forbuttons~setPreferredSize(gui~clsDimension~new(50, 0))
panelllevel2forbuttons~setLayout(.nil)

buttonnext = gui~clsJButton~new("Next")
buttonnext~setMnemonic(gui~clsKeyEvent~VK_N)
buttonnext~setMargin(gui~clsInsets~new(0,0,0,0))
buttonnext~setBounds(0,0, 50,22)
panelllevel2forbuttons~add(buttonnext)

buttonrun = gui~clsJButton~new("Run")
buttonrun~setMnemonic(gui~clsKeyEvent~VK_R)
buttonrun~setMargin(gui~clsInsets~new(0,0,0,0))
buttonrun~setBounds(0,27, 50,22)
panelllevel2forbuttons~add(buttonrun)

buttonexit = gui~clsJButton~new("Exit")
buttonexit~setMnemonic(gui~clsKeyEvent~VK_X)
buttonexit~setMargin(gui~clsInsets~new(0,0,0,0))
buttonexit~setBounds(0,54, 50,22)
panelllevel2forbuttons~add(buttonexit)

buttonvars = gui~clsJButton~new("Vars")
buttonvars~setMnemonic(gui~clsKeyEvent~VK_V)
buttonvars~setMargin(gui~clsInsets~new(0,0,0,0))
buttonvars~setBounds(0,81, 50,22)
panelllevel2forbuttons~add(buttonvars)

buttonhelp = gui~clsJButton~new("Help")
buttonhelp~setMnemonic(gui~clsKeyEvent~VK_H)
buttonhelp~setMargin(gui~clsInsets~new(0,0,0,0))
buttonhelp~setBounds(0,108, 50,22)
panelllevel2forbuttons~add(buttonhelp)

buttonexec = gui~clsJButton~new("Exec")
buttonexec~setMnemonic(gui~clsKeyEvent~VK_E)
buttonexec~setMargin(gui~clsInsets~new(0,0,0,0))
buttonexec~setBounds(0,173, 50,22)
panelllevel2forbuttons~add(buttonexec)

panellevel1lowercontrols~add(panelllevel2forbuttons,gui~clsBorderLayout~EAST)

panellevel2entryfields = gui~clsjPanel~new
panellevel2entryfields~setLayout(gui~clsBorderLayout~new(3,3))

textareaconsoleoutput = gui~clsJTextArea~new
textconsoleoutputpane = gui~clsJScrollPane~new
textconsoleoutputpane~setViewportView(textareaconsoleoutput)

panellevel2entryfields~add(textconsoleoutputpane,gui~clsBorderLayout~CENTER)

textfieldcommand = gui~clsJTextField~new
textfieldcommand~setPreferredSize(gui~clsDimension~new(0,25))

panellevel2entryfields~add(textfieldcommand,gui~clsBorderLayout~SOUTH)

panellevel1lowercontrols~add(panellevel2entryfields)

self~add(panelmain)


controls[self~EDITDEBUGLOG] = textareaconsoleoutput
controls[self~EDITDEBUGLOG]~seteditable(.False)
controls[self~EDITCOMMAND] = textfieldcommand
controls[self~LISTSOURCE] = listsource
controls[self~LISTSTACK] = liststack
controls[self~BUTTONNEXT] = buttonnext
controls[self~BUTTONRUN] = buttonrun
controls[self~BUTTONEXIT] = buttonexit
controls[self~BUTTONVARS] = buttonvars
controls[self~BUTTONHELP] = buttonhelp
controls[self~BUTTONEXEC] = buttonexec
controls[self~PANESOURCE] = listsourcepane

windowlistener = .DebugDialogWindowListener~new
windowlistenerEH = BsfCreateRexxProxy(windowlistener, self, "java.awt.event.ActionListener", "java.awt.event.WindowListener")
self~addWindowListener(windowlistenerEH)

controls[self~BUTTONNEXT]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONNEXT, "java.awt.event.ActionListener"))
controls[self~BUTTONRUN]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONRUN, "java.awt.event.ActionListener"))
controls[self~BUTTONHELP]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONHELP, "java.awt.event.ActionListener"))
controls[self~BUTTONEXIT]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONEXIT, "java.awt.event.ActionListener"))
controls[self~BUTTONEXEC]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONEXEC, "java.awt.event.ActionListener"))
controls[self~BUTTONVARS]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONVARS, "java.awt.event.ActionListener"))


stackmouselistener = .DebugDialogListStackMouseListener~new
stackmouselistenerEH = BsfCreateRexxProxy(stackmouselistener, self, "java.awt.event.MouseListener")
controls[self~LISTSTACK]~addMouseListener(stackmouselistenerEH)

sourcemouselistener = .DebugDialogListSourceMouseListener~new
sourcemouselistenerEH = BsfCreateRexxProxy(sourcemouselistener, self, "java.awt.event.MouseListener")
controls[self~LISTSOURCE]~addMouseListener(sourcemouselistenerEH)

commandkeylistener = .DebugDialogCommandKeyListener~new
commandkeylistenerEH = BsfCreateRexxProxy(commandkeylistener, self, "java.awt.event.KeyListener")
controls[self~EDITCOMMAND]~addKeyListener(commandkeylistenerEH)

self~getRootPane~setDefaultButton(controls[self~BUTTONEXEC])


debugtext = ''
buttonpushed = .False

self~UpdateControlStates
if startuphelptext~isA(.list) then do listrow over startuphelptext
  controls[self~LISTSOURCE]~getModel~addElement(listrow)
end
else controls[self~LISTSOURCE]~getModel~addElement("No startup help text is available")
/*

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
*/



------------------------------------------------------
::method actionPerformed unguarded
------------------------------------------------------
expose controls 
use arg eventobj, slotdir
id = slotdir~userdata
if id = self~BUTTONNEXT then self~OnNextButton
if id = self~BUTTONRUN then self~OnRunButton
if id = self~BUTTONHELP then self~OnHelpButton
if id = self~BUTTONEXIT then self~OnExitButton
if id = self~BUTTONEXEC then self~OnExecButton
if id = self~BUTTONVARS then self~OnVarsButton

------------------------------------------------------
::Method AppendText unguarded
------------------------------------------------------
expose controls debugtext debugger
use arg newtext, newline = .true

if newline  then newtext = newtext||.endofline
debugtext = debugtext||newtext
if \debugger~isshutdown then do
  controls[self~EDITDEBUGLOG]~append(newtext)
end

------------------------------------------------------
::method SetListSource 
------------------------------------------------------
expose controls hfnt debugger loadedsources checkedsources
use arg sourcefile 

arrSource = loadedsources[sourcefile]
if \checkedsources~hasitem(sourcefile) then do
  do line over arrSource~allIndexes
    if arrSource[line]~strip~left(4) = '/'||'**'||'/' then do
      debugger~SetBreakPoint(sourcefile, line)
    end
  end
  checkedsources~append(sourcefile)
  end
listbreakpoints = debugger~GetBreakpoints(sourcefile)


listdata = controls[self~LISTSOURCE]~getModel
listdata~clear

linecount = arrSource~items
do line over arrSource~allIndexes
  if listbreakpoints~hasItem(line) then do
    text = '*'
    if \self~IsBreakPointLikelyToBeHit(arrSource[line]) then text = '?'
    end
  else text=' '
  text = text||line~right(linecount~length)' 'arrSource[line]
  listdata~addelement(text)

end


------------------------------------------------------
::method SetSourceListSelectedRow 
------------------------------------------------------
expose visiblelistrows controls arrStack


-- Assumes the correct source is already loaded
-- This is just to set the position in the source listbox
newrow = arrStack[controls[self~LISTSTACK]~getSelectedIndex + 1]~line

if newrow <  0 | newrow >=  controls[self~LISTSOURCE]~getmodel~getsize then return
currentrow = controls[self~LISTSOURCE]~getSelectedIndex + 1
visiblelistrows = controls[self~LISTSOURCE]~getlastVisibleIndex - controls[self~LISTSOURCE]~getfirstVisibleIndex

firstrow = 1
firstvisible =  controls[self~LISTSOURCE]~getfirstVisibleIndex + 1
controls[self~LISTSOURCE]~setSelectedIndex(newrow - 1)
topbottomrows = min((visiblelistrows / 10)~ceiling, 4)
newfirstvisible = -1
if newrow < firstvisible | newrow > visiblelistrows + firstvisible then do 
  firstrow = newrow - (visiblelistrows / 2)~floor
 if firstrow < 1 then firstrow = 1
   newfirstvisible  = firstrow
end
else if newrow - firstvisible < topbottomrows then do 
  firstrow = newrow - topbottomrows
  if firstrow < 1 then firstrow = 1
   newfirstvisible  = firstrow
end
else if newrow - firstvisible >= visiblelistrows - topbottomrows then do 
  firstrow = newrow - (visiblelistrows - topbottomrows)
   newfirstvisible  = firstrow
end
if newfirstvisible \= -1 then do
  originpoint = controls[self~LISTSOURCE]~indexToLocation(newfirstvisible - 1)
  controls[self~PANESOURCE]~getViewPort~setViewPosition(originpoint)
end  

------------------------------------------------------
::method UpdateCodeView unguarded
------------------------------------------------------
expose controls arrStack activesourcename loadedsources debugger 
use arg arrstack,activateindex

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
listdata = controls[self~LISTSTACK]~getModel
listdata~clear

indent = arrStack~items
do frame over arrStack~allitems
  frametext = frame~makestring
  parse value frametext with pre '*-*' post
  finaltext =  pre' *-*'||" "~copies(indent *2)||strip(post)
  listdata~addelement(finaltext)
  indent = indent - 1
end  

controls[self~LISTSTACK]~setSelectedIndex(activateindex - 1)


--Ensure the correct source (if any) is loaded
if arrstack[activateindex]~executable~source \= .Nil, arrstack[activateindex]~executable~source~items \= 0 then do 
  thissourcename = arrstack[activateindex]~executable~package~name
  if thissourcename \= activesourcename then do
    if activesourcename \= .nil then self~appendtext('Switching source to 'thissourcename)
    activesourcename = thissourcename
    self~SetListSource(thissourcename)
  end  

self~SetSourceListSelectedRow
 
end

------------------------------------------------------
::method UpdateWatchWindows  unguarded
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
self~UpdateCodeView(arrstack, controls[self~LISTSTACK]~getSelectedIndex + 1)
return 0

------------------------------------------------------
::method SourceLineDoubleClicked 
------------------------------------------------------
expose controls debugger activesourcename 

itemindex = controls[self~LISTSOURCE]~getSelectedIndex + 1
listtext = controls[self~LISTSOURCE]~getSelectedValue
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
controls[self~LISTSOURCE]~getmodel~set(itemindex - 1, listtext)

-------------------------------------------------------
::method IsBreakpointLikelyToBeHit 
-------------------------------------------------------
parse arg sourceline
sourceline  = sourceline~strip
commentmarker='/'||'**'||'/'
if sourceline~left(4) = '/'||'**'||'/' then sourceline = sourceline~substr(5)
if sourceline = '' | "END THEN ELSE OTHERWISE RETURN EXIT SIGNAL"~wordpos(sourceline~word(1)) \= 0 | (":: -- /"||"*")~wordpos(sourceline~left(2)) \= 0 then return .False
else return .True


--====================================================
::class WatchDialogWindowListener public
--====================================================
::method windowopened
::method windowactivated
::method windowdeactivated
::method windowiconified
::method windowdeiconified
::method windowclosed

------------------------------------------------------
::method windowclosing 
------------------------------------------------------
use arg eventobj, slotdir
dialog = slotdir~userdata
dialog~Cancel

--====================================================
::class WatchDialogListVarsMouseListener public
--====================================================
::method mousepressed
::method mousereleased
::method mouseexited
::method mouseentered

------------------------------------------------------
::method mouseclicked
------------------------------------------------------
use arg eventobj, slotdir
if eventobj~getclickcount == 1 then do

  dialog = slotdir~userdata
  dialog~VariableSelected
end

if eventobj~getclickcount == 2 then do
  dialog = slotdir~userdata
  dialog~VariableDoubleClicked
end


 --====================================================
::class WatchDialog subclass bsf
--====================================================
 
::CONSTANT LISTVARS 101
::CONSTANT PANEVARS 102

::CONSTANT ROOTCOLLECTIONNAME ":Root"
::CONSTANT MAXVALUESTRINGLENGTH 255



 ------------------------------------------------------
::method init 
------------------------------------------------------
expose debugwindow controls parentwindow parentlist currentselectioninfo varsvalid dialogtitle gui
use arg debugwindow, gui, parentwindow, parentlist


controls = .Directory~new
currentselectioninfo = ""
varsvalid = .False

dialogtitle = "Watch"
do elementname over parentlist
  dialogtitle = dialogtitle||' '
  if elementname~isA(.Array) then dialogtitle = dialogtitle || elementname~makestring(,",")
  else dialogtitle = dialogtitle || elementname
end

self~Initdialog


self~~setVisible(.true) ~~toFront
self~repaint

------------------------------------------------------
::method InitDialog 
------------------------------------------------------
expose controls debugwindow hfnt  parentwindow dialogtitle gui

self~init:super('javax.swing.JFrame',.array~of(dialogtitle))
self~setDefaultCloseOperation(gui~clsWindowConstants~DO_NOTHING_ON_CLOSE)
self~setSize(220, 130)
self~setMinimumSize(gui~clsDimension~new(220,130))
self~setLayout(gui~clsBorderLayout~new(5,5))
self~setLocationRelativeTo(.nil)

windowlistener = .WatchDialogWindowListener~new
windowlistenerEH = BsfCreateRexxProxy(windowlistener, self, "java.awt.event.ActionListener", "java.awt.event.WindowListener")
self~addWindowListener(windowlistenerEH)

panelmain = gui~clsJPanel~new
panelmain~setBorder(gui~clsEmptyBorder~new(5,5,5,5))
panelmain~setLayout(gui~clsBorderLayout~new(5,5))

listvarsmodel = gui~clsDefaultListModel~new
listvars = gui~clsJList~new(listvarsmodel)

listvars~setSelectionMode(gui~clsListSelectionModel~SINGLE_SELECTION)
listvars~setLayoutOrientation(gui~clsJlist~VERTICAL)
if gui~fontFixed \= '' then listvars~setFont(gui~clsFont~new(gui~fontFixed, gui~clsFont~BOLD, 12))
listvars~setFixedCellHeight(14)

listvarspane = gui~clsJScrollPane~new
listvarspane~setPreferredSize(gui~clsDimension~new(440,50))
listvarspane~setViewportView(listvars)

panelmain~add(listvarspane, gui~clsBorderLayout~CENTER)
self~add(panelmain)

controls[self~LISTVARS] = listvars
controls[self~PANEVARS] = listvarspane

varsmouselistener = .WatchDialogListVarsMouseListener~new
varsmouselistenerEH = BsfCreateRexxProxy(varsmouselistener, self, "java.awt.event.MouseListener")
controls[self~LISTVARS]~addMouseListener(varsmouselistenerEH)

parentrect = parentwindow~getbounds
myrect = self~getbounds
if parentwindow = debugwindow then self~setlocation(parentrect~x + parentrect~width + 10, parentrect~y)
else self~setlocation(parentrect~x, parentrect~y + parentrect~height + 10)

debugwindow~NotifyChildReady


------------------------------------------------------
::method Cancel 
------------------------------------------------------

expose hfnt debugwindow
debugwindow~RemoveWatchWindow(self)
self~dispose


------------------------------------------------------
::METHOD VariableSelected
------------------------------------------------------
expose controls itemidentifiers currentselectioninfo
itemindex = controls[self~LISTVARS]~getselectedindex + 1
if itemindex \= 0 then do
  selectedidentifierstring = itemidentifiers[itemindex]~makestring
  rowsbefore = itemindex - (controls[self~LISTVARS]~getfirstVisibleIndex + 1)
  currentselectioninfo = rowsbefore':'selectedidentifierstring
end  


------------------------------------------------------
::METHOD UpdateWatchWindow unguarded
------------------------------------------------------
expose controls parentlist  hfnt itemidentifiers itemclasses currentselectioninfo varsvalid
use arg root
variablescollection = root
do nextchild over parentlist
  variablescollection = variablescollection[nextchild]
  if variablescollection = .nil then leave
end

if variablescollection = .nil then do
 varsvalid = .False
end
else do
  varsvalid = .True
  listdata = controls[self~LISTVARS]~getModel
  listdata~clear
  dosort = .False
  if variablescollection~isA(.Directory) | -
       variablescollection~isA(.Properties) | -
       variablescollection~isA(.Stem) -
  then  dosort = .True
  if .StringTable~class~defaultname = .class~defaultname, variablescollection~isA(.StringTable) then dosort = .True
  if dosort then itemidentifiers = variablescollection~allindexes~sort
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
    listdata~addelement(text)
    itemclasses~append(variablescollection[varname]~class)
  end
  
  parse value currentselectioninfo with prevrowsbefore':'prevselectedidentifierstring
  if currentselectioninfo \= "" then do 
    indextoselect = 0
    newfirstvisible = -1
    if prevselectedidentifierstring \= "" then do i = 1 to itemidentifiers~items
      if itemidentifiers[i]~makestring = prevselectedidentifierstring then do
        indextoselect = i
        leave
      end
    end    
    if indextoselect \= 0 then do
      controls[self~LISTVARS]~setSelectedIndex(indextoselect - 1)
      newfirstvisible = MAX(1,indextoselect - prevrowsbefore)
    end  
    else if controls[self~LISTVARS]~getFirstVisibleIndex \= -1  then newfirsvisible = 1
    if newfirstvisible \= -1 then do
      originpoint = controls[self~LISTVARS]~indexToLocation(newfirstvisible - 1)
      controls[self~PANEVARS]~getViewPort~setViewPosition(originpoint)
    end
  end  

end  


------------------------------------------------------
::method VariableDoubleClicked
------------------------------------------------------
expose controls debugwindow itemidentifiers itemclasses parentlist

itemindex = controls[self~LISTVARS]~getselectedindex + 1
if itemindex \= 0 then do
  itemidentifier = itemidentifiers[itemindex]
  itemclass = itemclasses[itemindex]
  if itemclass =.Directory | -
     itemclass =.StringTable | -
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
::method SetListState unguarded
------------------------------------------------------
expose controls varsvalid
use arg enablelist
if enablelist & varsvalid then controls[self~LISTVARS]~setEnabled(.true)
else  controls[self~LISTVARS]~setEnabled(.false)


------------------------------------------------------
::ROUTINE IsWindows
------------------------------------------------------
return SysVersion()~translate~pos("WINDOWS") = 1

::ROUTINE GetWindowsThreadID
if IsWindows() then return SysQueryProcess(TID) 
else return '?'

::REQUIRES BSF.CLS      -- get the Java support
::OPTIONS TRACE R