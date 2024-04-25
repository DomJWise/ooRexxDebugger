.local~rexxdebugger.deferlaunch = .True

call RexxDebugger

---------------------------------------
::routine LaunchDebugger public
---------------------------------------
use arg parentwindow, offsetdirection
.rexxdebugger.debugger~launch(parentwindow /*Name */, offsetdirection /*UDLR*/)

