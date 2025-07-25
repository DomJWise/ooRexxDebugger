# ooRexxDebugger

A dialog-based ooRexx debugger for the Windows, Linux and MacOS desktop (*)

Available for Windows running ooRexx 4.2 or later via a native user interface, with an aternative Java (Swing/AWT) user interface for other platforms running ooRexx 5.0 or later. 

(*) Although testing is limited to Windows, Linux and MacOS, other platforms for which the prerequisites can be met can be reasonably be expected to work.

It's still in active development and you may find bugs but features include:

- A main window with:
  -  Source display of the code being debugged
  -  Stack trace that allows switching between active source locations and files
  -  An entry field for executing Rexx statements or debugger commands while tracing is waiting for feedback
  -  A console window to display basic help information, status and (optionally) program and debugger output 
  -  Breakpoint functionality including the ability to set conditional breakpoints (*)
  -  Single step or run to next breakpoint (or the end of the program)
  -  Break button to interrupt running code or set an automatic breakpoint for when the next line of traceable code is hit 
  -  Toggling of breakpoints in an active session
- Watch windows for display of variables with drilldown into string types and object collections (**)
- Presetting of breakpoints in the Rexx source by adding  empty comments (/**/) at the start of traceable lines.

(*) Note that the debugger is built around the interactive trace framework included with ooRexx so can only pause where that framework would pause. Some statements are hit at all, other statements only once. The Rexx documentation provides information on which instructions will pause during interactive tracing, used to guide the "hit" likelihood indicator when setting breakpoints but this may notalways be 100% accurate.

(**) A relation collection can have the same index linked to different collection items. At present Watch drilldown from a relation collection is only possible for one collection item per group of duplicate indexes. This may be addressed in a future release

The ooRexx tracing framework pauses for feedback after executing an instruction, not before. If you want to see the value of a variable just before a particular line which changes that variable you need to check the value before stepping or running to that line. This behaviour also means that instructions which change the control flow of a program (e.g. call) will not pause on that statement unless and until control is returned there e.g. by a return from a called function

Prerequisites
-------------

For Windows using the native interface ooRexx 4.2 or later must be installed.

For any platform using the Java interface the following are needed:
  - ooRexx 5.0 or later
  - Any Java JRE/JDK with Swing and AWT support
  - bsf4oorexx version 641 or 850


Deployment of the files in this package
---------------------------------------

To use the debugger, RexxDebugger.rex (and DeferRexxDebuggerLaunch.rex if used) need to be in your path or the local directory along with one of the user interface modules below:

   - RexxDebuggerWinUI.rex  - required for the Windows native interface

   - RexxDebuggerBSFUI.rex - required for the Java interface

   On Windows when both modules are available the native interface module will be preferred but this can be overridden if needed. See usage instructions below for further details

On Linux and MacOS the files should all be placed in the same directory (local or in the path) along with the following launcher script, which will need to be set as executable:

   - rexxdebugger 

The package file tutorial.rex is not required but may be helpful for learning how to navigate the various debugger features.

Getting started
---------------

To launch the main debugger window so that you can open a Rexx program for debugging use the following command:

    rexxdebugger

The Open button can then be used on the main dialog to select a program to debug.

By default the debugger will use the preferred interface for the current platform, program output will appear in the debugger console pane, and trace output will be dropped but this can be overridden with the following command-line options:

    /JAVAUI      - Force the Java interface to be used (Windows only)
    /NOCAPTURE   - Send all program and trace output to the console window that launched the debugger
    /SHOWTRACE   - Include trace output in the debugger console pane along with the program output
    /TRACEMODE:x - Set the default trace mode (see below for details)
    /FONTSIZE:n  - Set the font size to be used by the debugger (see below for details)

The /TRACEMODE:x option, where x is any permitted trace mode e.g. I, ?R, can be used to change the default trace mode applied to all code blocks in the main rexx file loaded. The debugger adds ::OPTIONS TRACE x to the end of the program to activate the selected mode. The default is ?A, which traces every statement (A) and has interactive tracing enabled (?).  Unless option R,A or I is used and the ? prefix is also used, any code block requiring single step or breakpoint stops will need to include a suitable TRACE clause e.g CALL TRACE '?A' at the start of the block. Further details of the available tracing modes including how to switch on and off interactive tracing from program code can be found in the ooRexx reference manual

The /FONTSIZE:n argument can be used to set a font size. The valid range for the Windows interface is 8 - 16 and for Java it is 12 - 26. For both interfaces the lower limit is the default. All debugger dialogs will use the font size specified but system dialogs (e.g. the file finder) and message boxes will continue to use the platform defined default font size

Specifying a program to debug
-----------------------------

A Rexx program can be specified for debugging on the rexxdebugger command line. The program name and any parameters must come after any of the debugger specific parameters described above.

For a standalone program where a single argument string is passed unaltered to the program you would use:

    rexxdebugger [/showtrace | /nocapture] [/javaui] myprogram.rex [{argstring}]

For a 'routine' program that expects multiple ARG(n) arguments you would use:

    rexxdebugger [/showtrace | /nocapture] [/javaui] CALL myroutine.rex [{arg1}] ... [{argn}]

Multi-word aruments need to be surrounded by double quotes and (at present) double quotes cannot be included within an argument

Embedded Rexx programs / special requirements
---------------------------------------------

Starting debug sessions with the rexxdebugger command facilitates debugging for a huge range of scenarios but there are situations where it either cannot be used or where finer controls over some aspects of debugging are needed. So long as the Rexx source can be modified many of these scenarios can also be handled using certain Rexx directives and statements.

  ### Embedded Rexx programs
  --------------------------
 
  If you have an application in which a Rexx interpreter is embedded, a Rexx program run within that environment cannot be debugged using the rexxdebugger command, but so long as the embedding application does not itself capture trace input you will very likely be able to debug the script when it is run by the application.
  
  For this to work you will need modify the Rexx program to load the debugger and activate tracing, either with a TRACE statement or ::OPTIONS TRACE if you have methods and routines that should be debuggable. You may also want to have the debugger open relative to a specific window e.g. to the right of the application window. Following are 3 example scenarios 
  
  (1) There are global TRACE options but debugger window placement and start point of debugging don't matter

  At the end of the code along with the TRACE option (::OPTIONS TRACE ?A is recommended) add:

    ::REQUIRES "RexxDebugger.rex"

  Note that double quotes will not generally be required on Windows but may be needed on operating systems that use a case-sensitive filesystem

  With this option the debugger will launch and break at the start of the Rexx program

  (2) There are no global TRACE options but debugger window placement and/or start point of debugging matter (*)

  Before the first line of code to debug add:
  
    CALL RexxDebugger [parentwindowname, offsetdirection-LRUD]  
    TRACE ?A

  With this option the debugger will launch during the CALL statement and break after the TRACE ?A statement
  
  (3) There are global TRACE options (::OPTIONS TRACE ?A is recommended) and debugger window placement and/or start point of debugging matter (*)

  Before the first line to debug add:

    CALL LaunchDebugger [parentWindowName, offsetdirection-LRUD]

  At the end of the code, you should not add a requires statement for RexxDebugger.rex, but along with the TRACE option you should add 

    ::REQUIRES "DeferRexxDebuggerLaunch.rex"

  With this option the debugger will show trace output from the start of the program but wont break until the LaunchDebugger call

  (*) Debugger window placement is only supported by the Windows native interface


  ### Direct launch of a Rexx program 
  -----------------------------------
  
  The code modification examples above can also be used for debugging Rexx programs that you launch directly instead of via the rexxdebugger command. Sometimes you may just do this for convenience or for additional control but it's possible you may find specific situations where launching a program from rexxdebugger does not work as expected. In these situations modifying the program and using direct launch is an alternative that may be successful.
  
  In term of directly launching a Rexx program, in Windows you can do this just by specifying its name but on other platforms you will generally need to precede the program name with a launcher command
  
  On Linux:

    rexx <program> <arguments>
	
  On MacOS running bsf4oorexx 641

    rexxj.sh <program> <arguments>
  
  On MacOS running bsf4oorexx 850
  
    rexxjh.sh <program> <arguments>
  
  Note that when a debug session launched this way on MacOS reaches the end of the program or aborts due to an unhandled error the debugger window will disappear unless the utility functions described later on in the document are added to the program

  ###  Embedded / direct launch alternatives for rexxdebugger command line switches ###
  
  The rexxdebugger command line switches cannot be used for embedded or direct launch so a number of additional modules have been provided that can be included in the program source to bring about the same behaviours. 

They need to be included above the call / require for RexxDebugger in order to be effective except in the case where RexxDebugger is included with a CALL and the  module is added via a require

  If you want the debugger windows to use a different font size (/FONTSIZE:n option) you can call / require one of the RexxDebuggerFont[n].rex modules. There is one module for each permitted font size (8-26)

    CALL RexxDebuggerFont16

    or 

    ::REQUIRES "RexxDebuggerFont16.rex"

 If you want the debugger to use one of the custom capture options /SHOWTRACE or /NOCAPTURE you can call / require one of the following modules
 
    RexxDebuggerShowTrace.rex
    RexxDebuggerNoCapture.rex
 
  
  If you are running on Windows but wish to use the Java interface (/JAVAUI option) you need to add the following line before any other ::requires statements for the debugging modules to activate this. You can still use 'call RexxDebugger' if you want but this particular override **must** be included in the form of a ::requires statement
  
    ::REQUIRES "RexxDebuggerBSFUI.rex"



### Utility functions for embedded / direct launch debugging
--------------------------------------------------------

When debugging embedded code or using direct launch there are two utility functions that can be used to provide more control over how the program terminates, making the behaviour similar to that when debugging from rexxdebugger. These can be especially useful on MacOS to prevent the debugger closing immediately at program exit or if a runtime error occurs

RexxDebuggerHandleExit can be called at the very end of the program or immediately before any statement (e.g. exit or return) that would cause it to exit. When called it reports that the program has ended then waits for the debugger window to be closed

```
x = 1 
say x

CALL RexxDebuggerHandleExit
exit

::REQUIRES RexxDebugger.rex
::OPTIONS ?A
```

RexxDebuggerHandleError can be called from a syntax or other signal handler and needs to be passed the .context special symbol as an argument. It will report the error and abnormal program termination then wait for the debugger window to be closed


```
signal on syntax

x = 1 
y = x /0

exit

syntax:
call RexxDebuggerHandleError(.context)
exit

::REQUIRES RexxDebugger.rex
::OPTIONS TRACE ?A
```

Control of program / trace output and possible limitations
----------------------------------------------------------

When launching a debug session via rexxdebugger there are command line options (see above) for controlling where these types of ouput go but there are additional debugger commands (CAPTURE/CAPTUREX/NOCAPTURE) that can be used to make changes during any active debug session. Further details on what they do can can found in the Help text, but it is important to note that some embedded environments may take full control of program and trace output. For these environments you may not be able to redirect ouput to the debug console window and will be limited to  whatever output is generated by the embedding application.

Multiple debug runs in the same rexxdebugger session
----------------------------------------------------

If you have run a debug session using rexxdebugger to completion, the Open button will become available and you can launch a new debug session. However, you will be running with the same Rexx interpreter instance as previously so you should ensure that any files or other resources have been released by the code in your previous debug session or you may see unexpected behaviour in the new debug session. Furthermore, modules included in your program via a ::REQUIRES statement may not be reloaded on subsequent debug runs so changes you make to these modules may not be picked up when you reuse a debug session

Closing the rexxdebugger window and launching a new one for the next debug session will ensure that you are using a new Rexx interpreter each time and will avoid these issue.


Showing object detail in Watch windows - the makeDebuggerString method
----------------------------------------------------------------------

Apart from string and collection classes most object types show only the class name in Watch windows. This means that if you have a variable called pt holding an instance of a user-defined Point class you would just see something like the following:

pt = a Point

This does not give you any indication as to what is in the object, and while you can use the command console to call methods which return object information for display this can be cumbersome.

To facilitate greater visibilty into user-defined classes when debugging a special method can be defined for the class to format and return a descriptive string for each object. The value returned is included alongside the object description in any Watch windows. 

Defining this method for the Point class mentioned above with object variables x and y (the co-ordinates of the point) would enable these co-ordinates to be shown in the Watch windows for each instance of this class

The method to be defined is: makeDebuggerString

This method must be unguarded, as must any method it calls. Failing to meet this requirement will likely cause the debugger to hang.

Please note that interactive tracing of the method is only possible when your code calls it and not when it is called by the debugger. If the method throws an error when called by the debugger the name returned will be \*ERROR\* and information about the error will be added to the console log

A simple Point class below shows how this can be used

```
::class Point

::method init
expose x y
use arg x,y

::atribute  x get
::attribute y get

::method makedebuggerstring unguarded     -- must be unguarded
expose x y
return 'x='||x||',y='y

... other methods

```

In a Watch window the return value will be appended to the display line in square brackets so for a Point at (0,0) called 'origin' you would see:

origin = a Point [x=0,y=0]


Final notes and further information
-----------------------------------
The Help button will send output information about the various options to the debugger console window and is worth checking out at least once, even though it's not very structured or pretty.

For an interactive walkthrough of many of the features run tutorial.rex, ideally from a command prompt / terminal using direct launch, and follow the instructions.
