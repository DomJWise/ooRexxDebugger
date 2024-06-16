

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
::method init
------------------------------------------------------
expose debugger 
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

success = self~DidUICallSucceed(.AwtGuiThread~runLater(self, "InitSafe")~~result~errorCondition, .context)

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

success = self~DidUICallSucceed(.AwtGuiThread~runLater(self, "ShowMainDialogSafe")~~result~errorCondition, .context)

debugger~FlagUIStartupComplete

self~WaitForExit 

success = self~DidUICallSucceed(.AwtGuiThread~runLaterLatest(self, "NoOp")~~result~errorCondition, .context)

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
expose debugdialog

use  arg text, newline = .true
if debugdialog \= .nil then success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "appendtext", "I", text, newline)~~result~errorCondition, .context)


------------------------------------------------------
::method GetUINextResponse unguarded 
------------------------------------------------------
expose debugdialog  debugdialogresponse awaitingmaindialogresponse

awaitingmaindialogresponse = .True
debugdialogresponse = ''

debugdialog~SetWaiting(.true)
success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "UpdateControlStates")~~result~errorCondition, .context)

guard off when awaitingmaindialogresponse = .False

return debugdialogresponse

------------------------------------------------------
::method UpdateUICodeView unguarded
------------------------------------------------------
expose debugdialog
use arg arrStack, activateindex

if debugdialog \= .nil then  success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "UpdateCodeView", "I", arrStack, activateindex)~~result~errorCondition, .context)

------------------------------------------------------
::method UpdateUIWatchWindows unguarded
------------------------------------------------------
expose debugdialog
use arg varsroot

if debugdialog \= .nil then success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "UpdateWatchWindows", "I", varsroot)~~result~errorCondition, .context)

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
  if SysVersion()~translate~pos("WINDOWS") = 1 then message = cond~MESSAGE~changestr(d2c(10), .endofline)
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
::method Cancel unguarded
------------------------------------------------------
expose waiting debugger hfnt watchwindows controls gui
close = .True
if waiting = .True then do
  ret = .bsf.dialog~dialogbox("Do you really want to quit and end the program ?", "Program still running","question", "YesNo")
  if ret = 1 then close = .False
end  
if close then do

  watchlist = watchwindows~allitems~section(1)
  do watchwindow over watchlist~allitems
     watchwindow~cancel
  end   
  
  debugger~informshutdown
  if waiting then self~HereIsResponse('say "Debugger closed - exiting"')
  self~dispose
  gui~SetExit
end


------------------------------------------------------
::method UpdateControlStates 
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
::method SetWaiting
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
::method OnNextButton 
------------------------------------------------------
expose waiting controls 
if waiting then do
  instructions = controls[self~EDITCOMMAND]~gettext~strip
  firstword = instructions~word(1)~translate
  if "RUN EXIT HELP CAPTURE CAPTUREX DISCARDTRACE"~wordpos(instructions~word(1)~translate) \= 0 then do 
    self~appendtext('This command cannot be used with Next at this time')
    return
  end  
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


------------------------------------------------------
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

------------------------------------------------------
::method OnExecButton unguarded
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
self~init:super('javax.swing.JFrame',.array~of("Rexx Debugger Version "||.local~rexxdebugger.version))
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
::Method AppendText 
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
    if activesourcename \= .nil then debugger~SendDebugMessage('Switching source to 'thissourcename)
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
::method SetListState
------------------------------------------------------
expose controls varsvalid
use arg enablelist
if enablelist & varsvalid then controls[self~LISTVARS]~setEnabled(.true)
else  controls[self~LISTVARS]~setEnabled(.false)



::ROUTINE GetWindowsThreadID
if SysVersion()~translate~pos("WINDOWS") = 1 then return SysQueryProcess(TID) 
else return '?'

::REQUIRES BSF.CLS      -- get the Java support