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
::class BSFPackageDevTestingGlobals
--====================================================
------------------------------------------------------
::method activate class
------------------------------------------------------
.context~package~local[debugautonext]              = .false
.context~package~local[debugdisableawtthreadtrace] = .false

--====================================================
::class DebuggerUI public
--====================================================

::attribute awaitingmaindialogresponse  public unguarded
::attribute debugdialogresponse         public unguarded
::attribute fontFixed                   public unguarded

::attribute clsBorderLayout        public unguarded
::attribute clsBorderFactory       public unguarded
::attribute clsButtonGroup         public unguarded
::attribute clsDefaultListModel    public unguarded
::attribute clsDimension           public unguarded
::attribute clsEmptyBorder         public unguarded
::attribute clsFont                public unguarded
::attribute clsInsets              public unguarded 
::attribute clsJButton             public unguarded
::attribute clsJFileChooser        public unguarded
::attribute clsJLabel              public unguarded
::attribute clsJList               public unguarded
::attribute clsJMenuItem           public unguarded
::attribute clsJPanel              public unguarded
::attribute clsJPopupMenu          public unguarded
::attribute clsJRadioButton        public unguarded
::attribute clsJScrollPane         public unguarded
::attribute clsJTextField          public unguarded
::attribute clsJTextArea           public unguarded
::attribute clsKeyEvent            public unguarded
::attribute clsListSelectionModel  public unguarded
::attribute clsTimer               public unguarded
::attribute clsWindowConstants     public unguarded
::attribute clsKeyStroke           public unguarded
::attribute clsInputEvent          public unguarded
::attribute clsJComponent          public unguarded
::attribute clsRectangle           public unguarded

------------------------------------------------------
::method activate class
------------------------------------------------------
self~define("AppendUIConsoleText", .Method~new("", self~method("AppendUIConsoleText")~source)~~setUnguarded)
self~define("DidUICallSucceed", .Method~new("", self~method("DidUICallSucceed")~source)~~setUnguarded)

------------------------------------------------------
::method init
------------------------------------------------------
expose debugdialog debugger
use arg debugger,watchhelperclass

if .WatchHelper~class~defaultname \= .Class~defaultname then .context~package~addclass("WatchHelper", watchhelperclass)
.WatchDialog~inherit(.WatchHelper)

self~clsBorderLayout       = bsf.importclass("java.awt.BorderLayout")
self~clsBorderFactory      = bsf.importclass("javax.swing.BorderFactory")
self~clsButtonGroup        = bsf.importclass("javax.swing.ButtonGroup")
self~clsDefaultListModel   = bsf.importclass("javax.swing.DefaultListModel")
self~clsDimension          = bsf.importclass("java.awt.Dimension")
self~clsEmptyBorder        = bsf.importclass("javax.swing.border.EmptyBorder")
self~clsFont               = bsf.importclass("java.awt.Font") 
self~clsInsets             = bsf.importclass("java.awt.Insets") 
self~clsJButton            = bsf.importclass("javax.swing.JButton")
self~clsJFileChooser       = bsf.importclass("javax.swing.JFileChooser")
self~clsJLabel             = bsf.importclass("javax.swing.JLabel") 
self~clsJList              = bsf.importclass("javax.swing.JList") 
self~clsJMenuItem          = bsf.importclass("javax.swing.JMenuItem") 
self~clsJPanel             = bsf.importclass("javax.swing.JPanel")
self~clsJPopupMenu         = bsf.importclass("javax.swing.JPopupMenu")
self~clsJRadioButton       = bsf.importclass("javax.swing.JRadioButton")
self~clsJScrollPane        = bsf.importclass("javax.swing.JScrollPane")
self~clsJTextArea          = bsf.importclass("javax.swing.JTextArea")
self~clsJTextField         = bsf.importclass("javax.swing.JTextField")
self~clsKeyEvent           = bsf.importclass("java.awt.event.KeyEvent")
self~clsKeyStroke          = bsf.importclass("javax.swing.KeyStroke")
self~clsRectangle          = bsf.importclass("java.awt.Rectangle")
self~clsTimer              = bsf.importclass("javax.swing.Timer")

self~clsInputEvent         = bsf.loadclass("java.awt.event.InputEvent")
self~clsJComponent         = bsf.loadclass("javax.swing.JComponent")
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
if debugdialog \= .nil & \debugger~isshutdown then debugdialog~appendtext(text, newline)


------------------------------------------------------
::method GetUINextResponse unguarded 
------------------------------------------------------
expose debugdialog  debugdialogresponse awaitingmaindialogresponse

awaitingmaindialogresponse = .True
debugdialogresponse = ''
if debugdialog \= .nil then do
  if  \.AWTGuiThread~isGuiThread then do
    debugdialog~SetWaiting(.true)
    success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "UpdateControlStates")~~result~errorCondition, .context)

    guard off when awaitingmaindialogresponse = .False
  end
  else say '## Unexpected dialog response fetch from the GUI thread'  
end  
return debugdialogresponse


------------------------------------------------------
::method InitUISource unguarded
------------------------------------------------------
expose debugdialog debugger
use arg arrSource, sourceName

if debugdialog \= .nil & \debugger~isshutdown then do
  if .AWTGuiThread~isGuiThread then debugdialog~InitSource(arrSource, sourceName)
  else success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "InitSource", "I", arrSource, sourceName)~~result~errorCondition, .context)
end

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
::method UpdateUIControlStates unguarded
------------------------------------------------------
expose debugdialog debugger
use arg arrStack, activateindex

if debugdialog \= .nil & \debugger~isshutdown then do
  if .AWTGuiThread~isGuiThread then debugdialog~UpdateControlStates
  else success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "UpdateControlStates")~~result~errorCondition, .context)
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


------------------------------------------------------
::method SetUISourceListInfoText unguarded
------------------------------------------------------
expose debugdialog debugger
use arg sourcelist

if debugdialog \= .nil & \debugger~isshutdown then do
  if .AWTGuiThread~isGuiThread then debugdialog~SetSourceListInfoText(sourcelist)
  else success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "SetSourceListInfoText", "I", sourcelist)~~result~errorCondition, .context)
end

------------------------------------------------------
::method ReSetUISourceState unguarded
------------------------------------------------------
expose debugdialog debugger
use arg sourcelist

if debugdialog \= .nil & \debugger~isshutdown then do
  if .AWTGuiThread~isGuiThread then debugdialog~ResetSourceState
  else success = self~DidUICallSucceed(.AwtGuiThread~runLater(debugdialog, "ResetSourceState")~~result~errorCondition, .context)
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
::class DebugDialogConsoleUpdateTimerListener public
--====================================================

------------------------------------------------------
::method actionPerformed
------------------------------------------------------
use arg eventobj, slotdir
dialog = slotdir~userdata
dialog~DoConsoleUpdate

------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self
self~define("actionPerformed", .Method~new("", self~method("actionPerformed")~source))

--====================================================
::class DebugDialogCopyTextListener public
--====================================================

------------------------------------------------------
::method actionPerformed
------------------------------------------------------
-- Will only be activated for items that dont already intercept the keys e.g. buttons
NOP

------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

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
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self


------------------------------------------------------
::method windowclosing 
------------------------------------------------------
use arg eventobj, slotdir
dialog = slotdir~userdata
dialog~Cancel

--====================================================
::class DebugDialogListStackMouseListener public
--====================================================
------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

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
------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

::method mouseexited
::method mouseentered

------------------------------------------------------
::method mousepressed
------------------------------------------------------
use arg eventobj, slotdir
if eventobj~isPopupTrigger() then slotdir~userdata~ShowSourcePopupMenu(eventobj)

------------------------------------------------------
::method mousereleased
------------------------------------------------------
use arg eventobj, slotdir
if eventobj~isPopupTrigger() then slotdir~userdata~ShowSourcePopupMenu(eventobj)

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
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self


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
::class DebugDialog subclass bsf inherit DialogControlHelper
--====================================================

::constant EDITSOURCENAME 100
::constant LISTSOURCE     101
::constant LISTSTACK      102
::constant EDITDEBUGLOG   103
::constant BUTTONNEXT     104
::constant BUTTONRUN      105
::constant BUTTONEXIT     106
::constant BUTTONVARS     107
::constant BUTTONHELP     108
::constant BUTTONOPEN     109
::constant EDITCOMMAND    110
::constant BUTTONEXEC     111
::constant PANESOURCE     112
::constant SOURCEMENU     113
::constant BPSETTINGS     114

------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self
self~define("AppendText", .Method~new("", self~method("AppendText")~source))
self~define("SetConsoleUpdateTimer", .Method~new("", self~method("SetConsoleUpdateTimer")~source))
self~define("DoConsoleUpdate", .Method~new("", self~method("DoConsoleUpdate")~source))

------------------------------------------------------
::method Cancel unguarded
------------------------------------------------------
expose waiting debugger hfnt watchwindows controls gui
close = .True
numeric digits 20
if waiting | (\debugger~canopensource & .local~rexxdebugger.commandlineisrexxdebugger) | TIME('F') - debugger~lastexecfulltime < 250000 then do
  ret = .bsf.dialog~dialogbox("Do you really want to quit and end the program ?", "Program still running","question", "YesNo")
  if ret = 1 then close = .False
end  
if close then do

  debugger~informshutdown
  watchlist = watchwindows~allitems~section(1)
  do watchwindow over watchlist~allitems
     watchwindow~cancel
  end   
  self~CancelConsoleUpdateTimer

  if waiting then self~HereIsResponse('say "Debugger closed - exiting"')
  self~dispose
  gui~SetExit
end


------------------------------------------------------
::method UpdateControlStates unguarded
------------------------------------------------------
expose waiting controls watchwindows debugger activesourcename
do control over .array~of(SELF~LISTSOURCE, SELF~LISTSTACK, self~BUTTONNEXT, self~BUTTONEXIT, self~BUTTONVARS, self~BUTTONEXEC, self~BUTTONHELP)
  if control = self~LISTSOURCE | control = self~LISTSTACK then self~ControlEnable(controls, control, waiting | debugger~canopensource | (activesourcename = .nil))
  else self~ControlEnable(controls, control, waiting)
end    
self~ControlEnable(controls, self~BUTTONRUN, \debugger~canopensource)
self~ControlEnable(controls, self~EDITCOMMAND, \debugger~canopensource)
self~ControlEnable(controls, self~BUTTONOPEN,  debugger~canopensource)

if waiting & self~ButtonGetText(controls, self~BUTTONRUN) \= "Run" then self~ButtonSetText(controls, self~BUTTONRUN, "&Run")
if waiting then controls[self~EDITCOMMAND]~requestFocus

do watchwindow over watchwindows~allitems
  watchwindow~SetListState(waiting)
end
if .BSFPackageDevTestingGlobals~package~local~debugautonext = .true then .AwtGuiThread~runLater(self, "OnNextButton")


------------------------------------------------------
::method init 
------------------------------------------------------
expose debugger gui controls waiting arrcommands commandnum arrstack activesourcename loadedsources watchwindows startuphelptext checkedsources debugconsoleappendbuffer debugconsoleupdatetimer
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

debugconsoleappendbuffer = ''
debugconsoleupdatetimer = .Nil

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
  self~ButtonSetText(controls, self~BUTTONRUN, "B&reak")
  
  if instructions~word(1)~translate\='NEXT' then instructions = 'NEXT 'instructions
  self~HereIsResponse(instructions)
end


------------------------------------------------------
::method OnRunButton
------------------------------------------------------
expose waiting debugger controls
if waiting then do
  self~ButtonSetText(controls, self~BUTTONRUN, "B&reak")

  self~HereIsResponse('RUN')
end
else if \debugger~GetManualBreak then do
  debugger~SetManualBreak(.True)
  self~ButtonSetText(controls, self~BUTTONRUN, "&Run")
  self~appendtext(debugger~DebugMsgPrefix||'Automatic breakpoint set for the next line of traceable code.')
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
  ret = .bsf.dialog~dialogbox("Do you really want to exit the program ?", "Program still running","question", "YesNo")
  if ret = 0 then do
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
expose debugger gui

newsessionDialog = .NewSessionDialog~new(self, gui, debugger)
if newsessionDialog~okselected then do 
  reply
  debugger~OpenNewProgram(.local~rexxdebugger.rexxfile, .local~rexxdebugger.rawargstring, .local~rexxdebugger.multipleargs)
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
::method OnBreakpointSettings
------------------------------------------------------
expose gui debugger controls activesourcename

linenum = self~ListGetSelectedIndex(controls, self~LISTSOURCE)
breakpointcondition = debugger~GetBreakPointTest(activesourcename, linenum)
breakpointsettingsdialog = .BreakPointSettingsDialog~new(self, gui, breakpointcondition)

if breakpointsettingsdialog~okselected then debugger~SetBreakPointTest(activesourcename, linenum, breakpointsettingsdialog~breakpointcondition)

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
expose controls buttonpushed debugger hfnt startuphelptext gui

-- Create the frame
title = debugger~GetCaption
if IsWindows() then title = title || " (Java UI)"
self~init:super('javax.swing.JFrame',.array~of(title))
self~setDefaultCloseOperation(gui~clsWindowConstants~DO_NOTHING_ON_CLOSE)
self~setSize(440, 525)
self~setMinimumSize(gui~clsDimension~new(440,540))
self~setLayout(gui~clsBorderLayout~new(5,5))
self~setLocationRelativeTo(.nil)

self~ControlsInitPaneMap

panelmain = gui~clsJPanel~new
panelmain~setBorder(gui~clsEmptyBorder~new(5,5,5,5))
panelmain~setLayout(gui~clsBorderLayout~new(5,5))

panellevel1lowercontrols = gui~clsJPanel~new
panellevel1lowercontrols~setLayout(gui~clsBorderLayout~new(3,3))
panellevel1lowercontrols~setPreferredSize(gui~clsDimension~new(0,240))
panelmain~add(panellevel1lowercontrols,gui~clsBorderLayout~SOUTH)

textfieldsourcename = gui~clsJTextField~new
textfieldsourcename~setPreferredSize(gui~clsDimension~new(0,25))
panelmain~add(textfieldsourcename, gui~clsBorderLayout~NORTH)

listsourcemodel = gui~clsDefaultListModel~new
listsource = gui~clsJList~new(listsourcemodel)

listsource~setSelectionMode(gui~clsListSelectionModel~SINGLE_SELECTION)
listsource~setLayoutOrientation(gui~clsJlist~VERTICAL)
if gui~fontFixed \= '' then listsource~setFont(gui~clsFont~new(gui~fontFixed, gui~clsFont~BOLD, 12))
listsource~setFixedCellHeight(14)

sourcecontextmenu = gui~clsJPopupMenu~new("")
breakpointsettingsmenuitem = gui~clsJMenuItem~new("Breakpoint Settings")
sourcecontextmenu~add(breakpointsettingsmenuitem)

listsourcepane = gui~clsJScrollPane~new
listsourcepane~setPreferredSize(gui~clsDimension~new(440,65))
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

buttonopen = gui~clsJButton~new("Open")
buttonopen~setMnemonic(gui~clsKeyEvent~VK_O)
buttonopen~setMargin(gui~clsInsets~new(0,0,0,0))
buttonopen~setBounds(0,135, 50,22)
panelllevel2forbuttons~add(buttonopen)
if .local~rexxdebugger.commandlineisrexxdebugger \= .True then do
  buttonopen~setVisible(.False)
end  
buttonexec = gui~clsJButton~new("Exec")
buttonexec~setMnemonic(gui~clsKeyEvent~VK_E)
buttonexec~setMargin(gui~clsInsets~new(0,0,0,0))
buttonexec~setBounds(0,162, 50,22)
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

controls[self~EDITSOURCENAME] = textfieldsourcename
controls[self~EDITSOURCENAME]~seteditable(.False)
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
controls[self~BUTTONOPEN] = buttonopen
controls[self~BUTTONEXEC] = buttonexec
controls[self~PANESOURCE] = listsourcepane
controls[self~SOURCEMENU] = sourcecontextmenu
controls[self~BPSETTINGS] = breakpointsettingsmenuitem

self~ControlsSetPaneLink(self~LISTSOURCE, self~PANESOURCE)

windowlistener = .DebugDialogWindowListener~new
windowlistenerEH = BsfCreateRexxProxy(windowlistener, self, "java.awt.event.ActionListener", "java.awt.event.WindowListener")
self~addWindowListener(windowlistenerEH)

controls[self~BUTTONNEXT]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONNEXT, "java.awt.event.ActionListener"))
controls[self~BUTTONRUN]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONRUN, "java.awt.event.ActionListener"))
controls[self~BUTTONHELP]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONHELP, "java.awt.event.ActionListener"))
controls[self~BUTTONEXIT]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONEXIT, "java.awt.event.ActionListener"))
controls[self~BUTTONEXEC]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONEXEC, "java.awt.event.ActionListener"))
controls[self~BUTTONVARS]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONVARS, "java.awt.event.ActionListener"))
controls[self~BUTTONOPEN]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONOPEN, "java.awt.event.ActionListener"))
controls[self~BPSETTINGS]~addActionListener(BsfCreateRexxProxy(self, self~BPSETTINGS, "java.awt.event.ActionListener"))


stackmouselistener = .DebugDialogListStackMouseListener~new
stackmouselistenerEH = BsfCreateRexxProxy(stackmouselistener, self, "java.awt.event.MouseListener")
controls[self~LISTSTACK]~addMouseListener(stackmouselistenerEH)

sourcemouselistener = .DebugDialogListSourceMouseListener~new
sourcemouselistenerEH = BsfCreateRexxProxy(sourcemouselistener, self, "java.awt.event.MouseListener")
controls[self~LISTSOURCE]~addMouseListener(sourcemouselistenerEH)

commandkeylistener = .DebugDialogCommandKeyListener~new
commandkeylistenerEH = BsfCreateRexxProxy(commandkeylistener, self, "java.awt.event.KeyListener")
controls[self~EDITCOMMAND]~addKeyListener(commandkeylistenerEH)


-- This can't be used for custom copy for the lists because they already intercept these keys for the same tasks but it is a good template
-- Custom copy with just the source (no line numbers etc) would be nice but is very much a TODO
controls[self~LISTSOURCE]~getInputMap(gui~clsJComponent~WHEN_ANCESTOR_OF_FOCUSED_COMPONENT)~put(gui~clsKeyStroke~getKeyStroke(gui~clsKeyEvent~VK_F, gui~clsInputEvent~CTRL_MASK), "copytext")
controls[self~LISTSOURCE]~getInputMap(gui~clsJComponent~WHEN_ANCESTOR_OF_FOCUSED_COMPONENT)~put(gui~clsKeyStroke~getKeyStroke(gui~clsKeyEvent~VK_INSERT, gui~clsInputEvent~CTRL_MASK), "copytext")
findkeylistener = .DebugDialogCopyTextListener~new
findkeylistenerEH = BsfCreateRexxProxy(findkeylistener, self, "javax.swing.AbstractAction")
controls[self~LISTSOURCE]~getActionMap~put("copytext", findkeylistenerEH)

self~getRootPane~setDefaultButton(controls[self~BUTTONEXEC])

buttonpushed = .False

if \startuphelptext~isA(.list) then startuphelptext = .List~of("No startup help text is available") 
self~SetSourceListInfoText(startuphelptext)

self~UpdateControlStates
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
if id = self~BUTTONOPEN then self~OnOpenButton
if id = self~BPSETTINGS then self~OnBreakpointSettings

------------------------------------------------------
::method SetConsoleUpdateTimer 
------------------------------------------------------
expose debugconsoleupdatetimer gui
if debugconsoleupdatetimer = .nil then do 
  timerlistener = .DebugDialogConsoleUpdateTimerListener~new
  timerlistenerEH = BsfCreateRexxProxy(timerlistener, self, "java.awt.event.ActionListener")

  debugconsoleupdatetimer = gui~clsTimer~new(150, timerlistenerEH)
  debugconsoleupdatetimer~setInitialDelay(10)
  debugconsoleupdatetimer~bsf.invoke("Start")
end  
else if \debugconsoleupdatetimer~IsRunning then debugconsoleupdatetimer~Restart

------------------------------------------------------
::method CancelConsoleUpdateTimer unguarded
------------------------------------------------------
expose debugconsoleupdatetimer
if debugconsoleupdatetimer \= .nil then debugconsoleupdatetimer~Stop

------------------------------------------------------
::Method AppendText
------------------------------------------------------
expose controls debugger debugconsoleappendbuffer
use arg newtext, newline = .true, forcenow = .false

if newline  then newtext = newtext||.endofline
if \debugger~isshutdown then 
  do 
  debugconsoleappendbuffer = debugconsoleappendbuffer||newtext 
  if forcenow then self~DoConsoleUpdate
  self~SetConsoleUpdateTimer
end

------------------------------------------------------
::Method DoConsoleUpdate 
------------------------------------------------------
expose controls debugger debugconsoleappendbuffer
if debugconsoleappendbuffer \= '' then do
  if \debugger~isshutdown then do
    controls[self~EDITDEBUGLOG]~append(debugconsoleappendbuffer)
  end
  debugconsoleappendbuffer = ''
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
    if arrSource[line]~strip~left(4) = '/'||'**'||'/' then do
      debugger~SetBreakPoint(sourcefile, line)
    end
  end
  checkedsources~append(sourcefile)
  end
listbreakpoints = debugger~GetBreakpoints(sourcefile)


self~ListDeleteAllItems(controls,self~LISTSOURCE)

linecount = arrSource~items
do line over arrSource~allIndexes
  if listbreakpoints~hasItem(line) then do
    text = '*'
    if \self~IsBreakPointLikelyToBeHit(arrSource[line]) then text = '?'
    end
  else text=' '
  text = text||line~right(linecount~length)' 'arrSource[line]
  self~ListAddItem(controls,self~LISTSOURCE, text)

end


------------------------------------------------------
::method SetSourceListSelectedRow 
------------------------------------------------------
expose controls arrStack

-- Assumes the correct source is already loaded
-- This is just to set the position in the source listbox
newrow = arrStack[self~ListGetSelectedIndex(controls, self~LISTSTACK)]~line
if newrow <  1 | newrow > self~ListGetRowCount(controls, self~LISTSOURCE) then return
currentrow = self~ListGetSelectedIndex(controls, self~LISTSOURCE)
visiblelistrows = self~ListGetVisibleRowCount(controls, self~LISTSOURCE)

firstvisible =  self~ListGetFirstVisible(controls, self~LISTSOURCE)
self~ListSetSelectedIndex(controls, self~LISTSOURCE, newrow)
topbottomrows = min((visiblelistrows / 10)~ceiling, 4)
newfirstvisible = -1
if newrow < firstvisible | newrow > visiblelistrows + firstvisible then do 
  newfirstvisible  = newrow - (visiblelistrows / 2)~floor
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
self~ListDeleteAllItems(controls,self~LISTSTACK)

indent = arrStack~items
do frame over arrStack~allitems
  frametext = frame~makestring
  parse value frametext with pre '*-*' post
  finaltext =  pre' *-*'||" "~copies(indent *2)||strip(post)
  self~ListAddItem(controls,self~LISTSTACK, finaltext)
  indent = indent - 1
end  

self~ListSetSelectedIndex(controls, self~LISTSTACK, activateindex)


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
commentmarker='/'||'**'||'/'
if sourceline~left(4) = '/'||'**'||'/' then sourceline = sourceline~substr(5)
if sourceline = '' | "END THEN ELSE OTHERWISE RETURN EXIT SIGNAL"~wordpos(sourceline~word(1)) \= 0 | (":: -- /"||"*")~wordpos(sourceline~left(2)) \= 0 then return .False
else return .True

-------------------------------------------------------
::method SetSourceListInfoText
-------------------------------------------------------
expose controls activesourcename
use arg sourcelist

self~ListDeleteAllItems(controls, self~LISTSOURCE)
do listrow over sourcelist
  self~ListAddItem(controls, self~LISTSOURCE, listrow)
end

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

-------------------------------------------------------
::method ShowSourcePopupMenu
-------------------------------------------------------
expose gui controls
use arg eventobj

contextmenu = controls[self~SOURCEMENU]
breakpointsettingsmenuitem = controls[self~BPSETTINGS]
index = self~ListGetSelectedIndex(controls, self~LISTSOURCE)
enable = .False
if index > 0  then do
  listtext = self~ListGetItem(controls, self~LISTSOURCE, index)
  if listtext~left(1) = '*' | listtext~left(1) = '?' then enable = .True
end
breakpointsettingsmenuitem~setEnabled(enable)

contextmenu~show(eventobj~getcomponent, eventobj~getx, eventobj~gety)

--====================================================
::class WatchDialogWindowListener public
--====================================================
------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

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
------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

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
::class WatchDialog subclass bsf inherit DialogControlHelper
--====================================================
 
::CONSTANT LISTVARS 101
::CONSTANT PANEVARS 102

::CONSTANT ROOTCOLLECTIONNAME ":Root"
::CONSTANT MAXVALUESTRINGLENGTH 255

------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

 ------------------------------------------------------
::method init 
------------------------------------------------------
expose debugwindow controls parentwindow parentlist currentselectioninfo varsvalid dialogtitle gui
use arg debugwindow, gui, parentwindow, parentlist


controls = .Directory~new
currentselectioninfo = ""
varsvalid = .False

dialogtitle = ''
do elementname over parentlist
  if dialogtitle \= '' then dialogtitle = ' @ '||dialogtitle
  if elementname~isA(.Array) then dialogtitle = elementname~makestring(,",")||dialogtitle
  else dialogtitle = elementname||dialogtitle 
end
dialogtitle = "Watch "||dialogtitle

self~Initdialog


self~~setVisible(.true) ~~toFront
self~repaint

------------------------------------------------------
::method InitDialog 
------------------------------------------------------
expose controls debugwindow hfnt  parentwindow dialogtitle gui

self~init:super('javax.swing.JFrame',.array~of(dialogtitle))
self~setDefaultCloseOperation(gui~clsWindowConstants~DO_NOTHING_ON_CLOSE)
self~setSize(300, 180)
self~setMinimumSize(gui~clsDimension~new(220,130))
self~setLayout(gui~clsBorderLayout~new(5,5))
self~setLocationRelativeTo(.nil)

self~ControlsInitPaneMap

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
listvarspane~setPreferredSize(gui~clsDimension~new(300,180))
listvarspane~setViewportView(listvars)

panelmain~add(listvarspane, gui~clsBorderLayout~CENTER)
self~add(panelmain)

controls[self~LISTVARS] = listvars
controls[self~PANEVARS] = listvarspane

self~ControlsSetPaneLink(self~LISTVARS, self~PANEVARS)

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
itemindex = self~ListGetSelectedIndex(controls, self~LISTVARS)
if itemindex \= 0 then do
  selectedidentifierstring = itemidentifiers[itemindex]~makestring
  rowsbefore = itemindex - self~ListGetFirstVisible(controls, self~LISTVARS)
  currentselectioninfo = rowsbefore':'selectedidentifierstring
end  


------------------------------------------------------
::METHOD UpdateWatchWindow unguarded
------------------------------------------------------
expose controls parentlist  hfnt itemidentifiers itemclasses currentselectioninfo varsvalid
use arg root

variablescollection = root
if parentlist~items \= 0 then do
  variablescollection~put(.environment, ".ENVIRONMENT")
  variablescollection~put(.local, ".LOCAL")
end
do nextchild over parentlist
  variablescollection = variablescollection[nextchild]
  if variablescollection = .nil then leave
end
if variablescollection = .nil then do
  self~ListClearSelection(controls, self~LISTVARS)
  varsvalid = .False
end
else do
  varsvalid = .True
  self~ListDeleteAllItems(controls,self~LISTVARS)
  dosort = .False
  if variablescollection~isA(.Directory) | -
       variablescollection~isA(.Properties) | -
       variablescollection~isA(.Stem) -
  then  dosort = .True
  if .StringTable~class~defaultname = .class~defaultname, variablescollection~isA(.StringTable) then dosort = .True
  if dosort then itemidentifiers = variablescollection~allindexes~sort
  else  itemidentifiers = variablescollection~allindexes
  if parentlist~items = 0 then do
    variablescollection~put(.environment, ".ENVIRONMENT")
    itemidentifiers~append(".ENVIRONMENT")
    variablescollection~put(.local, ".LOCAL")
    itemidentifiers~append(".LOCAL")
  end
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
    if self~IsExpandable(variablescollection[varname]~class) then text = '+'
    else text = ' '
    text = text||vardisplayname' = 'varvalue
    self~ListAddItem(controls,self~LISTVARS, text)
    itemclasses~append(variablescollection[varname]~class)
  end
  
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
      self~ListSetSelectedIndex(controls, self~LISTVARS, indextoselect)
      newfirstvisible = MAX(1,indextoselect - prevrowsbefore)
      self~ListSetFirstVisible(controls, self~LISTVARS, newfirstvisible)
    end
    else if self~ListGetRowCount(controls, self~LISTVARS) \= 0  then self~ListSetFirstVisible(controls, self~LISTVARS, 1)
  end  

end  

------------------------------------------------------
::method VariableDoubleClicked
------------------------------------------------------
expose controls debugwindow itemidentifiers itemclasses parentlist

itemindex = self~ListGetSelectedIndex(controls, self~LISTVARS)
if itemindex \= 0 then do
  itemidentifier = itemidentifiers[itemindex]
  if self~IsExpandable(itemclasses[itemindex]) then do
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
self~ControlEnable(controls, self~LISTVARS, enablelist & varsvalid)

------------------------------------------------------
::ROUTINE IsWindows
------------------------------------------------------
return SysVersion()~translate~pos("WINDOWS") = 1

::ROUTINE GetWindowsThreadID
if IsWindows() then return SysQueryProcess(TID) 
else return '?'

------------------------------------------------------
::routine detracemethods
------------------------------------------------------
use arg classobj
if .context~package~trace \= 'N' then 
do with index methodname item method over classobj~methods
  if method~package~name = .context~package~name then do
    if \method~isconstant & \method~isattribute then do
      guarded = method~isguarded
      newmethod = .Method~new("", method~source)
      if guarded then newmethod~setguarded
      else newmethod~setunguarded
      classobj~define(methodname, newmethod)
    end    
  end  
end  

--====================================================
::class BreakpointSettingsDialogEscKeyListener public
--====================================================

------------------------------------------------------
::method actionperformed
------------------------------------------------------
use arg eventobj, slotdir
dialog = slotdir~userdata
dialog~dispose

------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self


--====================================================
::class BreakpointSettingsDialog subclass bsf 
--====================================================
::constant RADIOALWAYSBREAK      101
::constant RADIOCONDITIONALBREAK 102
::constant EDITBREAKCONDITION    103
::constant BUTTONOK              104
::constant BUTTONCANCEL          105

::attribute okselected
::attribute breakpointcondition

------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

------------------------------------------------------
::method init 
------------------------------------------------------
expose debugwindow gui controls okselected breakpointcondition
use arg debugwindow,gui, breakpointcondition

controls = .Directory~new
okselected = .False

self~InitDialog

------------------------------------------------------
::method InitDialog 
------------------------------------------------------
expose debugwindow gui controls breakpointcondition

-- Create the dialog
self~init:super('javax.swing.JDialog', debugwindow, "Breakpoint Hit", .True)

self~setDefaultCloseOperation(gui~clsWindowConstants~DISPOSE_ON_CLOSE)
self~setResizable(.False)
self~setLayout(.Nil)
self~getrootPane~setPreferredSize(gui~clsDimension~new(405,130))

radioalwaysbutton = gui~clsJRadioButton~new("Always")
radioalwaysbutton~setMnemonic(gui~clsKeyEvent~VK_A)
radioalwaysbutton~setbounds(5, 15, 90, 20)
radiowhenbutton = gui~clsJRadioButton~new("When")
radiowhenbutton~setMnemonic(gui~clsKeyEvent~VK_W)
radiowhenbutton~setbounds(5, 35, 90, 20)
buttongroup = gui~clsButtonGroup~new
buttongroup~add(radioalwaysbutton)
buttongroup~add(radiowhenbutton)

textfieldcondition = gui~clsJTextField~new
textfieldcondition~setbounds(20, 60, 375, 25)

buttonok = gui~clsJButton~new("Ok")
buttonok~setMargin(gui~clsInsets~new(0,0,0,0))
buttonok~setbounds(10, 95, 70, 25)

buttoncancel = gui~clsJButton~new("Cancel")
buttoncancel~setMargin(gui~clsInsets~new(0,0,0,0))
buttoncancel~setbounds(90, 95, 70, 25)

self~add(radiowhenbutton)
self~add(radioalwaysbutton)
self~add(textfieldcondition)
self~add(buttonok)
self~add(buttoncancel)

self~getrootpane~setdefaultbutton(buttonok)

self~getrootpane~getInputMap(gui~clsJComponent~WHEN_ANCESTOR_OF_FOCUSED_COMPONENT)~put(gui~clsKeyStroke~getKeyStroke("ESCAPE"), "escape")
esckeylistener = .BreakpointSettingsDialogEscKeyListener~new
esckeylistenerEH = BsfCreateRexxProxy(esckeylistener, self, "javax.swing.AbstractAction")
self~getrootpane~getActionMap~put("escape", esckeylistenerEH)

self~pack
self~setLocationRelativeTo(debugwindow)

if breakpointcondition = '' then do
  radioalwaysbutton~doclick
  textfieldcondition~setEnabled(.False)
end
else do
  textfieldcondition~setText(breakpointcondition)
  radiowhenbutton~doclick
end

controls[self~RADIOALWAYSBREAK]      = radioalwaysbutton
controls[self~RADIOCONDITIONALBREAK] = radiowhenbutton
controls[self~EDITBREAKCONDITION]    = textfieldcondition
controls[self~BUTTONOK]              = buttonok
controls[self~BUTTONCANCEL]          = buttoncancel

controls[self~RADIOALWAYSBREAK]~addActionListener(BsfCreateRexxProxy(self, self~RADIOALWAYSBREAK, "java.awt.event.ActionListener"))
controls[self~RADIOCONDITIONALBREAK]~addActionListener(BsfCreateRexxProxy(self, self~RADIOCONDITIONALBREAK, "java.awt.event.ActionListener"))
controls[self~BUTTONOK]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONOK, "java.awt.event.ActionListener"))
controls[self~BUTTONCANCEL]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONCANCEL, "java.awt.event.ActionListener"))


self~setVisible(.True)

------------------------------------------------------
::method actionPerformed unguarded
------------------------------------------------------
expose controls 
use arg eventobj, slotdir
id = slotdir~userdata
if id = self~RADIOALWAYSBREAK      then controls[self~EDITBREAKCONDITION]~setEnabled(.False)
if id = self~RADIOCONDITIONALBREAK then controls[self~EDITBREAKCONDITION]~setEnabled(.True)

if id = self~BUTTONOK then self~OnOk
if id = self~BUTTONCANCEL then self~dispose

------------------------------------------------------
::method OnOk unguarded
------------------------------------------------------
expose controls okselected breakpointcondition

if controls[self~RADIOALWAYSBREAK]~isSelected then breakpointcondition = ''
else breakpointcondition = controls[self~EDITBREAKCONDITION]~gettext

okselected = .True
self~dispose

--====================================================
::class NewSessionDialogEscKeyListener public
--====================================================

------------------------------------------------------
::method actionperformed
------------------------------------------------------
use arg eventobj, slotdir
dialog = slotdir~userdata
dialog~dispose

------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

--====================================================
::class NewSessionDialog subclass bsf 
--====================================================
::constant EDITREXXFILE         101
::constant BUTTONFIND           102
::constant RADIOARGTYPESINGLE   103
::constant RADIOARGTYPEMULTIPLE 104
::constant EDITARGS             105
::constant BUTTONOK             106
::constant BUTTONCANCEL         107

::attribute okselected

------------------------------------------------------
::method activate class
------------------------------------------------------
if .BSFPackageDevTestingGlobals~package~local~debugdisableawtthreadtrace = .true then call detracemethods self

------------------------------------------------------
::method init 
------------------------------------------------------
expose debugwindow gui debugger controls okselected
use arg debugwindow,gui,debugger

controls = .Directory~new
okselected = .False

self~InitDialog

------------------------------------------------------
::method InitDialog 
------------------------------------------------------
expose debugger debugwindow gui controls

-- Create the dialog
self~init:super('javax.swing.JDialog', debugwindow, "New Debug Session", .True)

self~setDefaultCloseOperation(gui~clsWindowConstants~DISPOSE_ON_CLOSE)
self~setResizable(.False)
self~setLayout(.Nil)
self~getrootPane~setPreferredSize(gui~clsDimension~new(405,170))

labelrexxfile = gui~clsJLabel~new("Rexx program:")
labelrexxfile~setbounds(5, 10, 95, 25)

textfieldrexxfile = gui~clsJTextField~new
textfieldrexxfile~setbounds(100, 10, 235, 25)

buttonfind = gui~clsJButton~new("Find")
buttonfind~setMnemonic(gui~clsKeyEvent~VK_F)
buttonfind~setMargin(gui~clsInsets~new(0,0,0,0))
buttonfind~setbounds(340, 10, 60, 25)

panelargumentgroup = gui~clsJPanel~new
panelargumentgroup~setbounds(5, 35, 395, 95)
panelargumentgroup~setBorder(gui~clsBorderFactory~createTitledBorder("Arguments"))
panelargumentgroup~setLayout(.Nil)

radiosinglearg = gui~clsJRadioButton~new("Single")
radiosinglearg~setMnemonic(gui~clsKeyEvent~VK_S)
radiosinglearg~setbounds(5, 15, 90, 20)
radiomultipleargs = gui~clsJRadioButton~new("Multiple")
radiomultipleargs~setMnemonic(gui~clsKeyEvent~VK_M)
radiomultipleargs~setbounds(5, 35, 90, 20)

buttongroup = gui~clsButtonGroup~new
buttongroup~add(radiosinglearg)
buttongroup~add(radiomultipleargs)

textfieldargstring = gui~clsJTextField~new
textfieldargstring~setbounds(10, 60, 375, 25)


panelargumentgroup~add(radiosinglearg)
panelargumentgroup~add(radiomultipleargs)
panelargumentgroup~add(textfieldargstring)

buttonok = gui~clsJButton~new("Ok")
buttonok~setMargin(gui~clsInsets~new(0,0,0,0))
buttonok~setbounds(10, 135, 70, 25)

buttoncancel = gui~clsJButton~new("Cancel")
buttoncancel~setMargin(gui~clsInsets~new(0,0,0,0))
buttoncancel~setbounds(90, 135, 70, 25)

self~add(textfieldrexxfile)
self~add(buttonfind)
self~add(labelrexxfile)
self~add(panelargumentgroup)
self~add(buttonok)
self~add(buttoncancel)

self~getrootpane~setdefaultbutton(buttonok)

self~getrootpane~getInputMap(gui~clsJComponent~WHEN_ANCESTOR_OF_FOCUSED_COMPONENT)~put(gui~clsKeyStroke~getKeyStroke("ESCAPE"), "escape")
esckeylistener = .NewSessionDialogEscKeyListener~new
esckeylistenerEH = BsfCreateRexxProxy(esckeylistener, self, "javax.swing.AbstractAction")
self~getrootpane~getActionMap~put("escape", esckeylistenerEH)

self~pack
self~setLocationRelativeTo(debugwindow)

textfieldrexxfile~settext(.local~rexxdebugger.rexxfile)
if \.local~rexxdebugger.multipleargs then radiosinglearg~doclick
else radiomultipleargs~doclick
textfieldargstring~settext(.local~rexxdebugger.rawargstring)

controls[self~EDITREXXFILE]         = textfieldrexxfile
controls[self~BUTTONFIND]           = buttonfind
controls[self~RADIOARGTYPESINGLE]   = radiosinglearg
controls[self~RADIOARGTYPEMULTIPLE] = radiomultipleargs
controls[self~EDITARGS]             = textfieldargstring
controls[self~BUTTONOK]             = buttonok
controls[self~BUTTONCANCEL]         = buttoncancel

controls[self~BUTTONFIND]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONFIND, "java.awt.event.ActionListener"))
controls[self~BUTTONOK]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONOK, "java.awt.event.ActionListener"))
controls[self~BUTTONCANCEL]~addActionListener(BsfCreateRexxProxy(self, self~BUTTONCANCEL, "java.awt.event.ActionListener"))

self~setVisible(.True)

------------------------------------------------------
::method actionPerformed unguarded
------------------------------------------------------
expose controls 
use arg eventobj, slotdir
id = slotdir~userdata
if id = self~BUTTONFIND then self~OnFindButton
if id = self~BUTTONOK then self~OnOk
if id = self~BUTTONCANCEL then self~dispose

------------------------------------------------------
::method OnFindButton unguarded
------------------------------------------------------
expose controls gui

curdir = directory()

currentsel = controls[self~EDITREXXFILE]~gettext~strip

startdirname = ''
startfilename = ''
if currentsel \= '' then do
  currentselfile = .File~new(currentsel)
  currentseldir = currentselfile~parentfile
  if currentseldir \= .nil, currentseldir~exists then do 
    startdirname = currentseldir~absolutePath~string
    if currentselfile~isFile & currentselfile~exists then startfilename = currentselfile~name
  end
end  

if startdirname = '' then do 
  filechooser = gui~clsJFileChooser~new
end
else do
  filechooser = gui~clsJFileChooser~new(startdirname)
  if startfilename \= '' then filechooser~setSelectedFile(.bsf~new("java.io.File", startfilename))
end

rexxfileTypes = .Array~of('rex', 'orx', 'rexx', 'rxj', 'rxo')
finderFilter = .FinderFilter~new(rexxFileTypes, 'Rexx Files')
proxyFinderFilter=BsfCreateRexxProxy(finderFilter, , "javax.swing.filechooser.FileFilter")
filechooser~setFileFilter(proxyFinderFilter)

res = filechooser~showOpenDialog(self)
if res = gui~clsJFileChooser~APPROVE_OPTION then do
  findresult = filechooser~getSelectedFile~getAbsolutePath
  controls[self~EDITREXXFILE]~settext(findresult)
end

call directory curdir


------------------------------------------------------
::method OnOk unguarded
------------------------------------------------------
expose controls okselected

.local~rexxdebugger.rexxfile = controls[self~EDITREXXFILE]~gettext
.local~rexxdebugger.rawargstring = controls[self~EDITARGS]~gettext
.local~rexxdebugger.multipleargs = controls[self~RADIOARGTYPEMULTIPLE]~isselected

okselected = .True
self~dispose

--====================================================
::class FinderFilter
--====================================================

------------------------------------------------------
::method init
------------------------------------------------------
expose fileextensions fileclassname
use arg fileextensions, fileclassname = ''

------------------------------------------------------
::method getDescription
------------------------------------------------------
expose fileextensions fileclassname
description = ''
if fileclassname \= '' then description = fileclassname' ('
do ext over fileextensions~allitems
  description = description||'*.'||ext||','
end
description = description~STRIP('T',',')
if fileclassname \= '' then description = description||')'
return description

------------------------------------------------------
::method accept
------------------------------------------------------
expose fileextensions
use arg fileobject

if fileobject~isDirectory then return .true
name = fileobject~getName
do ext over fileextensions~allitems
  if name~translate~right(ext~length + 1)~caselesscompare('.'||ext) = 0 then return .true
end
return .false


--====================================================
::class DialogControlHelper mixinclass object 
--====================================================

------------------------------------------------------
::method ListSetSelectedIndex
------------------------------------------------------
use arg controls, listid, newindex

controls[listid]~setSelectedIndex(newindex - 1)

------------------------------------------------------
::method ListGetSelectedIndex
------------------------------------------------------
use arg controls,listid
return controls[listId]~getselectedindex + 1

------------------------------------------------------
::method ListGetRowCount
------------------------------------------------------
use arg controls, listid
return controls[listId]~getmodel~getsize

------------------------------------------------------
::method ListGetFirstVisible
------------------------------------------------------
use arg controls, listid

return controls[listId]~getFirstVisibleIndex + 1

------------------------------------------------------
::method ListGetVisibleRowCount
------------------------------------------------------
use arg controls, listid

return controls[listId]~getLastVisibleIndex - controls[listId]~getFirstVisibleIndex

------------------------------------------------------
::method ListSetFirstVisible
------------------------------------------------------
use arg controls, listid, newfirstvisible

originpoint = controls[listid]~indexToLocation(newfirstvisible - 1)
controls[self~ControlsGetPaneLink(listid)]~getViewPort~setViewPosition(originpoint)

------------------------------------------------------
::method ListClearSelection
------------------------------------------------------
use arg controls, listid

controls[listId]~clearselection

------------------------------------------------------
::method ListDeleteAllItems
------------------------------------------------------
use arg controls, listid

listdata = controls[listid]~getModel
listdata~clear

------------------------------------------------------
::method ListAddItem
------------------------------------------------------
use arg controls, listid, text

listdata = controls[listid]~getModel
listdata~addelement(text)

------------------------------------------------------
::method ListGetItem
------------------------------------------------------
use arg controls, listid, itemindex

return controls[listid]~getmodel~get(itemindex - 1)

------------------------------------------------------
::method ListModifyItem
------------------------------------------------------
use arg controls, listid, itemindex, listtext

controls[listid]~getmodel~set(itemindex - 1, listtext)

------------------------------------------------------
::method ControlEnable
------------------------------------------------------
use arg controls, controlid, enable

controls[controlid]~setEnabled(enable)

------------------------------------------------------
::method ControlsInitPaneMap
------------------------------------------------------
expose panelinks
panelinks = .StringTable~new

------------------------------------------------------
::method ControlsSetPaneLink
------------------------------------------------------
expose panelinks
use arg controlid, paneid

panelinks[controlid] = paneid

------------------------------------------------------
::method ControlsGetPaneLink
------------------------------------------------------
expose panelinks
use arg controlid

return panelinks[controlid]


------------------------------------------------------
::method ButtonSetText
------------------------------------------------------
use arg controls, buttonid, text

text=text~changeStr("&", "")
controls[buttonid]~setText(text)

------------------------------------------------------
::method ButtonGetText
------------------------------------------------------
use arg controls, buttonid

return controls[buttonid]~getText


::REQUIRES BSF.CLS      -- get the Java support

--::options TRACE R