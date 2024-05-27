-- #!/usr/bin/env rexx
-- The above gives errors with CRLF line  (Unix is LF). The same is true of alternatives.
-- Using VS CODE, line endings cannot be set for individual lines, just the whole file
-- Might need a process to rewrite i.e. install script
-- OR supply an extra rexxdebugger file which IS LF and which calls the REX file with all parameters

/* Test code */
say 'Test run started'
.UITest~RunUIOnThread
--say 'Enter something to exit'
--pull nothing

::class UITest

::method RunUIOnThread class
REPLY
say '>> Creating debugger UI object'
ui = .DebuggerUI~new
say '>> Launching UI'
ui~RunUI
say '>> UI finished'
return

/*---- Below code comes from the BSF4ooRexx 1-010_HelloWorld.rxj sample - copyright included -----*/

/*
   Purpose:  create a window with a button to close it

             This version stresses Object Rexx and the wrapper class "BSF.CLS" which
             makes Java look like if it was Object Rexx ...

   Needs:    ooRexx, BSF4ooRexx

   Date:    2001-04-18, 2003-01-23, 2003-05-10, 2005-06-05

   Author:   Rony G. Flatscher, University of Essen, WU Wien University,
             derived from Peter Kalender's proof-of-concept work for the "Essener Ski Seminar",
             University of Essen (Oct 2000 to Feb 2001)


   last change: $Revision: 920 $ $Author: orexx $ $Date: 2022-08-02 19:37:58 +0200 (Di., 02 Aug 2022) $

   changed:
            2005-12-28, added Apache license
            2008-06-01, updated text
            2008-07-19, rgf, added hash-bang line at the top
            2008-08-23, ---rgf, if using BSF.CLS, then do not use BSF() directly (or
                                remove the first three chars from its result string)
            2009-07-05, Walter Pachl add help and correct description
            2010-05-16, rgf, - replacing bsf.addEventListener[WithEventObject] with a Rexx event handler
            2012-06-09, rgf, - inhibit callbacks from Java after Rexx ends (if Rexx loaded Java)
            2016-07-26, Eva Gerger, Julian Reindorf - minor changes of comments

   license:

    ------------------------ Apache Version 2.0 license -------------------------
       Copyright (C) 2001-2012 Rony G. Flatscher

       Licensed under the Apache License, Version 2.0 (the "License");
       you may not use this file except in compliance with the License.
       You may obtain a copy of the License at

           http://www.apache.org/licenses/LICENSE-2.0

       Unless required by applicable law or agreed to in writing, software
       distributed under the License is distributed on an "AS IS" BASIS,
       WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
       See the License for the specific language governing permissions and
       limitations under the License.
    -----------------------------------------------------------------------------
*/
--=============================================================================
::CLASS "awtFrame" SUBCLASS bsf
--=============================================================================
::METHOD init
  expose rexxCloseEH
  
  -- Create the frame
  self~init:super('java.awt.Frame', ARG(1, 'A'))
  
  -- Create a Java RexxProxy for controlling the closing of the application
  rexxCloseEH =.RexxCloseAppEventHandler~new   -- Rexx event handler
  -- Create Java RexxProxy for the Rexx event handler
  rpCloseEH=BsfCreateRexxProxy(rexxCloseEH, , "java.awt.event.ActionListener", -
                                              "java.awt.event.WindowListener" )

      
  self~addWindowListener(rpCloseEH)

  button = .bsf~new("java.awt.Button", 'Press Me !')
  button~addActionListener(rpCloseEH)
 
  /* create and add a Java awt button  */
  self~~add(button) ~~pack
  
::METHOD WaitForExit 
expose rexxCloseEH

rexxCloseEH~waitForExit

/* ------------------------------------------------------------------------ */
/* Rexx event handler to set "close app" indicator */
::class RexxCloseAppEventHandler
::method init        /* constructor */
  expose closeApp
  closeApp  = .false   -- if set to .true, then it is safe to close the app

::attribute closeApp          -- indicates whether app should be closed

::method unknown              -- intercept unhandled events, do nothing

::method actionPerformed      -- event method (from ActionListener)
  expose closeApp
  closeApp=.true              -- indicate that the app should close

::method windowClosing        -- event method (from WindowListener)
  expose closeApp
  closeApp=.true              -- indicate that the app should close

::method waitForExit          -- method blocks until attribute is set to .true
  expose closeApp
  guard on when closeApp=.true


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

------------------------------------------------------
::method init
------------------------------------------------------
expose debugdialog
use arg debugger

--TODO: Create dialog
--debugdialog = .DebugDialog~new(debugger, .rexxdebugger.startuphelptext)

/* Create and build the "main" window" */
debugdialog = .awtFrame~new('Hello World!')

------------------------------------------------------
::method RunUI
------------------------------------------------------
expose debugdialog

/* Show the window */
debugdialog~~setVisible(.true) ~~toFront

/* Self explanatory */
debugdialog~waitForExit -- wait until we are allowed to end the program

/* This will close the window */
debugdialog~dispose

--TODO: Launch main dialog
--debugdialog~popup("SHOWTOP")

------------------------------------------------------
::method AppendUIConsoleText unguarded
------------------------------------------------------
expose debugdialog

use  arg text, newline = .true
if debugdialog \= .nil then debugdialog~appendtext(text, newline)

------------------------------------------------------
::method GetUINextResponse unguarded
------------------------------------------------------
expose debugdialog

return debugdialog~GetNextResponse

------------------------------------------------------
::method UpdateUICodeView 
------------------------------------------------------
expose debugdialog
use arg arrStack, activateindex

debugdialog~UpdateCodeView(arrStack, activateindex)

------------------------------------------------------
::method UpdateUIWatchWindows 
------------------------------------------------------
expose debugdialog
use arg varsroot

debugdialog~UpdateWatchWindows(varsroot)

/*
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
do control over .array~of(SELF~LISTSOURCE, SELF~LISTSTACK, self~BUTTONNEXT, self~BUTTONEXIT, self~BUTTONVARS, self~BUTTONEXEC, self~BUTTONHELP)
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
self~create(6, 15, 280, 290, "Rexx Debugger Version "||.local~rexxdebugger.version, "THICKFRAME, CENTER, MAXIMIZEBOX,MINIMIZEBOX")
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
  if "RUN EXIT HELP CAPTURE CAPTUREX DISCARDTRACE"~wordpos(instructions~word(1)~translate) \= 0 then do 
    call SAY 'This command cannot be used with Next at this time'
    return
  end  
  controls[self~BUTTONRUN]~settext("B&reak")
  controls[self~BUTTONRUN]~redraw
  if instructions~word(1)~translate\='NEXT' then instructions = 'NEXT 'instructions
  self~HereIsResponse(instructions)
end
------------------------------------------------------
::method OnRunButton 
------------------------------------------------------
expose waiting debugger controls
if waiting then do
  controls[self~BUTTONRUN]~settext("B&reak")
  controls[self~BUTTONRUN]~redraw
  self~HereIsResponse('RUN')
end
else if \debugger~GetManualBreak then do
  debugger~SetManualBreak(.True)
  controls[self~BUTTONRUN]~settext("&Run")
   call SAY 'Automatic breakpoint set for the next line of traceable code.'
end
else do
  debugger~SetManualBreak(.False)
  call SAY 'Automatic breakpoint removed. Program will run normally.'
  controls[self~BUTTONRUN]~settext("B&reak")
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
debugger~SendDebugMessage("- Commands: <instrs> | NEXT [<instrs>] | RUN | EXIT | CAPTURE | CAPTUREX | DISCARDTRACE - use the Exec button to run the command.")
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
debugger~SendDebugMessage("- <slash><star><star><slash> at the start of traceable line (including NOP) causes a breakpoint to be automatically set for that line.")
debugger~SendDebugMessage("- The instruction CALL SAY ... will always send output here.")
debugger~SendDebugMessage("- So long as SAY is enabled in the target application, other output should appear there.")
debugger~SendDebugMessage("- If the application has no output, or you want the output here, you can try the CAPTURE command to capture all output.")
debugger~SendDebugMessage("  CAPTUREX is similar but will discard (eXclude) all trace output apart from program errors.")
debugger~SendDebugMessage("- DISCARDTRACE attempts to capture trace in order to discard it (apart from program errors).")
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

debugger~FlagUIStartupComplete

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
    if arrSource[line]~strip~left(4) = '<slash><star><star><slash>' then debugger~SetBreakPoint(sourcefile, line)
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
if arrstack[activateindex]~executable~source \= .Nil, arrstack[activateindex]~executable~source~items \= 0 then do 
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
if sourceline~left(4) = '<slash><star><star><slash>' then sourceline = sourceline~substr(5)
if sourceline = '' | "END THEN ELSE OTHERWISE RETURN EXIT SIGNAL"~wordpos(sourceline~word(1)) \= 0 | ":: -- <slash><star>"~wordpos(sourceline~left(2)) \= 0 then return .False
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
    else if controls[self~LISTVARS]~items \= 0 then controls[self~LISTVARS]~makefirstvisible(1)

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

::requires oodialog.cls
*/

::REQUIRES BSF.CLS      -- get the Java support