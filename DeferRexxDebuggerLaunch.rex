if .local~rexxdebugger.deferlaunch = .False then  SAY 'Order of debugger ::requires statements needs to be swapped for deferred launching to work.'
else  .local~rexxdebugger.deferlaunch = .True

---------------------------------------
::routine LaunchDebugger public
---------------------------------------
use arg parentwindow, offsetdirection
.rexxdebugger.debugger~launch(parentwindow, offsetdirection)

::requires ooDialog.cls