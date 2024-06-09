

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

------------------------------------------------------
::method init
------------------------------------------------------
expose debugdialog debugger
use arg debugger
/* Create and build the "main" window" */
debugdialog = .DebugDialog~new(debugger, self,.rexxdebugger.startuphelptext)

------------------------------------------------------
::method RunUI unguarded
------------------------------------------------------
expose debugdialog debugger
/* Show the window */
debugdialog~~setVisible(.true) ~~toFront
debugdialog~repaint

debugger~FlagUIStartupComplete

/* Self explanatory */

debugdialog~waitForExit -- wait until we are allowed to end the program

/* This will close the window */
--debugdialog~dispose

--TODO: Launch main dialog
--debugdialog~popup("SHOWTOP")

------------------------------------------------------
::method AppendUIConsoleText unguarded
------------------------------------------------------
expose debugdialog

use  arg text, newline = .true
if debugdialog \= .nil then do
  awaitresult = .AwtGuiThread~runLater(debugdialog, "appendtext", "I", text, newline)
end  

------------------------------------------------------
::method GetUINextResponse unguarded 
------------------------------------------------------
expose debugdialog  debugdialogresponse awaitingmaindialogresponse

awaitingmaindialogresponse = .True
debugdialogresponse = ''

say '~~enter GetUINextResponse on thread 'GetWindowsThreadID()
debugdialog~SetWaiting(.true)
awaitresult = .AwtGuiThread~runLater(debugdialog, "UpdateControlStates")~result

say '~~waiting for dialog'
guard off when awaitingmaindialogresponse = .False
say '~~dialog returned 'debugdialogresponse

return debugdialogresponse

------------------------------------------------------
::method UpdateUICodeView unguarded
------------------------------------------------------
expose debugdialog
say '~~enter UpdateUICodeView on thread 'GetWindowsThreadID()
use arg arrStack, activateindex

if debugdialog \= .nil then
do 
  debugdialog~debugarrstack = arrStack
  debugdialog~debugactivateindex = activateindex
  awaitresult = .AwtGuiThread~runLater(debugdialog, "UpdateCodeView")~result
end
--debugdialog~UpdateCodeView(arrStack, activateindex)
say '~~leave UpdateUICodeView'

------------------------------------------------------
::method UpdateUIWatchWindows unguarded
------------------------------------------------------
expose debugdialog
use arg varsroot
say '~~enter UpdateUIWatchWindows on thread 'GetWindowsThreadID()

--debugdialog~UpdateWatchWindows(varsroot)
say '~~leave UpdateUIWatchWindows'

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

::attribute debugarrstack      unguarded
::attribute debugactivateindex unguarded
/*
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

*/
------------------------------------------------------
::method UpdateControlStates 
------------------------------------------------------
expose waiting controls watchwindows
do control over .array~of(SELF~LISTSOURCE, SELF~LISTSTACK, self~BUTTONNEXT, self~BUTTONEXIT, self~BUTTONVARS, self~BUTTONEXEC, self~BUTTONHELP)
  if waiting then controls[control]~setEnabled(.true)
  else  controls[control]~setEnabled(.false)
end    

if waiting & \controls[self~BUTTONRUN]~gettext()~equals("Run") then controls[self~BUTTONRUN]~settext("Run")
/*
do watchwindow over watchwindows~allitems
  watchwindow~SetListState(waiting)
end
*/

------------------------------------------------------
::method init 
------------------------------------------------------
expose debugger debuggerui controls waiting arrcommands commandnum arrstack activesourcename loadedsources watchwindows startuphelptext checkedsources
use arg debugger, debuggerui, startuphelptext
arrstack = .nil
activesourcename = .nil
loadedsources = .Directory~new
watchwindows = .Directory~new
checkedsources = .List~new

waiting = .false
controls = .Directory~new

--self~connectResize("onResize")

arrcommands = .Array~new
commandnum = 0
self~InitDialog

-------------------------------------------------------
::method WaitForExit unguarded
-------------------------------------------------------
do forever
  call syssleep 1
end

-------------------------------------------------------
::method SetWaiting
-------------------------------------------------------
expose waiting
use arg waiting

------------------------------------------------------
::method HereIsResponse unguarded
------------------------------------------------------
expose debuggerui waiting
use arg response

waiting = .False
self~UpdateControlStates

debuggerui~debugdialogresponse = response
debuggerui~awaitingmaindialogresponse = .False


/*
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

*/
------------------------------------------------------
::method OnNextButton 
------------------------------------------------------
expose waiting controls 
say '@@OnNextButton'
if waiting then do
  say 'OnNextbutton in "waiting" code'
  /*instructions = controls[self~EDITCOMMAND]~gettext~strip*/
  instructions = ''
  firstword = instructions~word(1)~translate
  if "RUN EXIT HELP CAPTURE CAPTUREX DISCARDTRACE"~wordpos(instructions~word(1)~translate) \= 0 then do 
    self~appendtext('This command cannot be used with Next at this time')
    return
  end  
  controls[self~BUTTONRUN]~settext("Break")
  /*controls[self~BUTTONRUN]~redraw*/
  if instructions~word(1)~translate\='NEXT' then instructions = 'NEXT 'instructions
  self~HereIsResponse(instructions)
end


------------------------------------------------------
::method OnRunButton 
------------------------------------------------------
expose waiting debugger controls
if waiting then do
  controls[self~BUTTONRUN]~settext("Break")
  /*controls[self~BUTTONRUN]~redraw*/
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

/*
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

*/
---------------------------------------------------
::method OnHelpButton 
------------------------------------------------------
expose debugger
self~appendtext("- Commands: <instrs> | NEXT [<instrs>] | RUN | EXIT | CAPTURE | CAPTUREX | DISCARDTRACE - use the Exec button to run the command.")
self~appendtext("- Buttons with the above labels execute the corresponding command.")
self~appendtext("- Command history for the session can be accessed with the up/down keys.")
self~appendtext("- The Vars button opens a realtime variables window.")
self~appendtext("- Double clicking many collection object types in a variables window will expand them in a new window.")
self~appendtext("- Clicking a stack row takes you to the specified source location and file.")
self~appendtext("- Double clicking a source row toggles a breakpoint, but this does not guarantee that the line will be hit.")
self~appendtext("  Some simple hit checks are carried out but there is no detailed code analysis.")
self~appendtext("  e.g. if it is empty, a comment, a directive or is END, THEN, ELSE, OTHERWISE, RETURN, EXIT or SIGNAL")
self~appendtext("  DO statements should be hit unless they mark the start of a loop that has looped once already.")
self~appendtext("  CALL statements (and what they call) may be hit, depending on what they are calling.")
self~appendtext("  A * means the debugger thinks the code will be hit, a ? means it thinks it likely it won't ever be hit.")
self~appendtext("  Hint: A line with just NOP can be inserted as an anchor for a breakpoint that will always be hit.")
self~appendtext("- <slash><star><star><slash> at the start of traceable line (including NOP) causes a breakpoint to be automatically set for that line.")
self~appendtext("- The instruction CALL SAY ... will always send output here.")
self~appendtext("- So long as SAY is enabled in the target application, other output should appear there.")
self~appendtext("- If the application has no output, or you want the output here, you can try the CAPTURE command to capture all output.")
self~appendtext("  CAPTUREX is similar but will discard (eXclude) all trace output apart from program errors.")
self~appendtext("- DISCARDTRACE attempts to capture trace in order to discard it (apart from program errors).")
self~appendtext("- The source window and watch windows go grey while the program is running and after it has finished.")
self~appendtext("Happy debugging!")
/*
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
*/

------------------------------------------------------
::method InitDialog 
------------------------------------------------------
expose controls debugtext buttonpushed debugger hfnt startuphelptext debugger


-- Create the frame
self~init:super('java.awt.Frame',.array~of("Rexx Debugger Version "||.local~rexxdebugger.version))
--self~setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
self~setSize(440, 510);
self~setMinimumSize(.bsf~new("java.awt.Dimension", 440,510));
self~setLayout(.bsf~new("java.awt.BorderLayout", 5,5));
self~setLocationRelativeTo(.nil);

panelmain = .bsf~new("javax.swing.JPanel")
panelmain~setBorder(.bsf~new("javax.swing.border.EmptyBorder",5,5,5,5));
panelmain~setLayout(.bsf~new("java.awt.BorderLayout", 5,5));

panellevel1lowercontrols = .bsf~new("javax.swing.JPanel")
panellevel1lowercontrols~setLayout(.bsf~new("java.awt.BorderLayout", 3,3));
panellevel1lowercontrols~setPreferredSize(.bsf~new("java.awt.Dimension", 0,250));
panelmain~add(panellevel1lowercontrols,bsf.getStaticValue("java.awt.BorderLayout", "SOUTH"));
	   
listsourcemodel = .bsf~new("javax.swing.DefaultListModel")
listsource = .bsf~new("javax.swing.JList", listsourcemodel)

listsource~setSelectionMode(bsf.getStaticValue("javax.swing.ListSelectionModel","SINGLE_SELECTION"));
listsource~setLayoutOrientation(bsf.getStaticValue("javax.swing.JList","VERTICAL"));
listsource~setFont(.bsf~new("java.awt.Font","Courier", bsf.getStaticValue("java.awt.Font","BOLD"), 11));
listsource~setFixedCellHeight(14);

listsourcepane = .bsf~new("javax.swing.JScrollPane")
listsourcepane~setPreferredSize(.bsf~new("java.awt.Dimension", 440,50));
listsourcepane~setViewportView(listsource);

panelmain~add(listsourcepane, bsf.getStaticValue("java.awt.BorderLayout", "CENTER"));

liststackmodel = .bsf~new("javax.swing.DefaultListModel")
liststack = .bsf~new("javax.swing.JList", liststackmodel)

liststack~setSelectionMode(bsf.getStaticValue("javax.swing.ListSelectionModel","SINGLE_SELECTION"));
liststack~setLayoutOrientation(bsf.getStaticValue("javax.swing.JList","VERTICAL"));
liststack~setFont(.bsf~new("java.awt.Font","Courier", bsf.getStaticValue("java.awt.Font","BOLD"), 11));
liststack~setFixedCellHeight(14);

liststackpane = .bsf~new("javax.swing.JScrollPane")
liststackpane~setPreferredSize(.bsf~new("java.awt.Dimension", 440,50));
liststackpane~setViewportView(liststack);

panellevel1lowercontrols~add(liststackpane,bsf.getStaticValue("java.awt.BorderLayout", "NORTH"));

	
panelllevel2forbuttons = .bsf~new("javax.swing.JPanel")
panelllevel2forbuttons~setPreferredSize(.bsf~new("java.awt.Dimension", 50, 0));
panelllevel2forbuttons~setLayout(.nil);

buttonnext = .bsf~new("javax.swing.JButton", "Next");
buttonnext~setMnemonic(bsf.getStaticValue("java.awt.event.KeyEvent", "VK_N"));
buttonnext~setMargin(.bsf~new("java.awt.Insets", 0,0,0,0));
buttonnext~setBounds(0,0, 50,22);
panelllevel2forbuttons~add(buttonnext);

buttonrun = .bsf~new("javax.swing.JButton", "Run");
buttonrun~setMnemonic(bsf.getStaticValue("java.awt.event.KeyEvent", "VK_R"));
buttonrun~setMargin(.bsf~new("java.awt.Insets", 0,0,0,0));
buttonrun~setBounds(0,27, 50,22);
panelllevel2forbuttons~add(buttonrun);

buttonexit = .bsf~new("javax.swing.JButton", "Exit");
buttonexit~setMnemonic(bsf.getStaticValue("java.awt.event.KeyEvent", "VK_X"));
buttonexit~setMargin(.bsf~new("java.awt.Insets", 0,0,0,0));
buttonexit~setBounds(0,54, 50,22);
panelllevel2forbuttons~add(buttonexit);

buttonvars = .bsf~new("javax.swing.JButton", "Vars");
buttonvars~setMnemonic(bsf.getStaticValue("java.awt.event.KeyEvent", "VK_V"));
buttonvars~setMargin(.bsf~new("java.awt.Insets", 0,0,0,0));
buttonvars~setBounds(0,81, 50,22);
panelllevel2forbuttons~add(buttonvars);

buttonhelp = .bsf~new("javax.swing.JButton", "Help");
buttonhelp~setMnemonic(bsf.getStaticValue("java.awt.event.KeyEvent", "VK_H"));
buttonhelp~setMargin(.bsf~new("java.awt.Insets", 0,0,0,0));
buttonhelp~setBounds(0,108, 50,22);
panelllevel2forbuttons~add(buttonhelp);

buttonexec = .bsf~new("javax.swing.JButton", "Exec");
buttonexec~setMnemonic(bsf.getStaticValue("java.awt.event.KeyEvent", "VK_E"));
buttonexec~setMargin(.bsf~new("java.awt.Insets", 0,0,0,0));
buttonexec~setBounds(0,173, 50,22);
panelllevel2forbuttons~add(buttonexec);

panellevel1lowercontrols~add(panelllevel2forbuttons,bsf.getStaticValue("java.awt.BorderLayout", "EAST"));

panellevel2entryfields = .bsf~new("javax.swing.JPanel")
panellevel2entryfields~setLayout(.bsf~new("java.awt.BorderLayout", 3,3));

textareaconsoleoutput = .bsf~new("javax.swing.JTextArea")
textareaconsoleoutput~setFont(textareaconsoleoutput~getFont()~deriveFont(11)~deriveFont(bsf.getStaticValue("java.awt.Font", "BOLD"))); 
textconsoleoutputpane = .bsf~new("javax.swing.JScrollPane")
textconsoleoutputpane~setViewportView(textareaconsoleoutput);

panellevel2entryfields~add(textconsoleoutputpane,bsf.getStaticValue("java.awt.BorderLayout", "CENTER"));

textfieldcommand = .bsf~new("javax.swing.JTextField")
textfieldcommand~setPreferredSize(.bsf~new("java.awt.Dimension", 0,25));
textfieldcommand~setFont(textfieldcommand~getFont()~deriveFont(11)~deriveFont(bsf.getStaticValue("java.awt.Font", "BOLD"))); 

panellevel2entryfields~add(textfieldcommand,bsf.getStaticValue("java.awt.BorderLayout", "SOUTH"));

panellevel1lowercontrols~add(panellevel2entryfields);

self~add(panelmain);


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


controls[self~BUTTONNEXT]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONNEXT, "java.awt.event.ActionListener"))
controls[self~BUTTONRUN]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONRUN, "java.awt.event.ActionListener"))
controls[self~BUTTONHELP]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONHELP, "java.awt.event.ActionListener"))

/*
controls[self~EDITCOMMAND]~connectkeypress(OnPrevCommand, .VK~UP)
controls[self~EDITCOMMAND]~connectkeypress(OnNextCommand, .VK~DOWN)
controls[self~EDITCOMMAND]~wantreturn("EditReturn")
controls[self~EDITCOMMAND]~connectCharEvent(EditCommandChar)
*/

debugtext = ''
buttonpushed = .False

self~UpdateControlStates
if startuphelptext~isA(.list) then do listrow over startuphelptext
  controls[self~LISTSOURCE]~getModel~addElement(listrow)
end
else controls[self~LISTSOURCE]~getModel~addElement("No startup help text is available")
/*
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

/*
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

*/
------------------------------------------------------
::Method AppendText 
------------------------------------------------------
expose controls debugtext debugger
use arg newtext, newline = .true
say 'dialog appendtext started on thread 'GetWindowsThreadID()
say '^^^^^^^^^^^^^^  InAppendText '||.awtGuiThread~isGuiThread
say '~~~~~~~~~~~~~~ 'newtext, newline

if newline  then newtext = newtext||.endofline
debugtext = debugtext||newtext
if \debugger~isshutdown then do
  --controls[self~EDITDEBUGLOG]~hidefast
  say '++++++++++++Appending'
  --controls[self~EDITDEBUGLOG]~setEnabled
  --controls[self~EDITDEBUGLOG]~seteditable(.true)
  controls[self~EDITDEBUGLOG]~append(newtext)
  --controls[self~EDITDEBUGLOG]~seteditable(.false)
  
  --scrollcharpos = debugtext~lastpos(.endofline) + .endofline~length
  --controls[self~EDITDEBUGLOG]~select(scrollcharpos,scrollcharpos)
  --controls[self~EDITDEBUGLOG]~showfast
  --controls[self~EDITDEBUGLOG]~ensureCaretVisibility
  controls[self~EDITDEBUGLOG]~repaint
end
/*
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
*/
------------------------------------------------------
::method UpdateCodeView unguarded
------------------------------------------------------
expose controls arrStack activesourcename loadedsources debugger debugarrstack debugactivateindex
say '~~~~~~  UpdateCodeView on thread 'GetWindowsThreadID()

arrStack = debugarrstack
activateindex = debugactivateindex

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
controls[self~LISTSTACK]~repaint

--self~setcurrentListIndex(self~LISTSTACK, activateindex)
/*
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

--  self~CalculateVisibleListRows
--  self~SetSourceListSelectedRow
 
end

-- Switch drawing back on
controls[self~LISTSOURCE]~showfast
controls[self~LISTSOURCE]~redraw
*/
say '~~~~~~ Leave UpdateCodeView'

------------------------------------------------------
::method UpdateWatchWindows 
------------------------------------------------------
expose varsroot watchwindows
use arg varsroot
/*
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

::ROUTINE GetWindowsThreadID
if SysVersion()~translate~pos("WINDOWS") = 1 then return SysQueryProcess(TID) 
else return '?'

::REQUIRES BSF.CLS      -- get the Java support