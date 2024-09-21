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
  -  Single step or run to breakpoints (*)
  -  Break button to interrupt running code or set an automatic breakpoint for when the next line of traceable code is hit 
  -  Toggling of breakpoints in an active session
- Watch windows for display of simple variables and drilldown into many collection types
- Presetting of breakpoints in the Rexx source by adding  empty comments (/**/) at the start of traceable lines.

(*) Note that this is built around the interactive trace framework included with ooRexx so can only pause where that framework would pause. Some statements are never hit at all, other statements only once. The Rexx documentation provides information on which instructions will pause during interactive tracing, used to guide the "hit" likelihood indicator when setting breakpoints but this may not always be 100% accurate.

Prerequisites
-------------

For Windows using the native interface ooRexx 4.2 or later must be installed.

For any platform using the Java interface the following are needed:
  - ooRexx 5.0 (recommended) or later (*)
  - Any Java JRE/JDK with Swing and AWT support
  - bsf4oorexx version 641 or 850

(*) The debugger can be used with the ooRexx 5.1 beta release but at time of writing there are some stability issues with tracing in this version which may result in hangs or crashes when using the debugger.

Deployment of the files in this package
---------------------------------------

To use the debugger, RexxDebugger.rex (and DeferRexxDebuggerLaunch.rex if used) need to be in your path or the local directory along with one of the user interface modules below:

   - RexxDebuggerWinUI.rex  - required for the Windows native interface

   - RexxDebuggerBSFUI.rex - required for the Java interface

   On Windows when both modules are available the native interface module will be preferred but this can be overridden if needed. See usage instructions below for further details

On Linux and MacOS the following launcher script should be copied into the path or local directory and set as executable:

   - rexxdebugger 

The package file tutorial.rex is not required but may be helpful for learning how to navigate the various debugger features.

Getting started
---------------

To launch the main debugger window so that you can open a Rexx program for debugging use the following command:

    rexxdebugger

The Open button can then be used on the main dialog to select a program to debug.

By default the debugger will use the preferred interface for the current platform, program output will appear in the debugger console pane, and trace output will be dropped but this can be overridden with the following command-line options:

    /JAVAUI    - Force the Java interface to be used (Windows only)
    /NOCAPTURE - Send all program and trace output to the console window that launched the debugger
    /SHOWTRACE - Include trace output in the debugger console pane along with the program output

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

  At the end of the code along with the TRACE option (::OPTIONS TRACE ?R is recommended) add:

    ::REQUIRES "RexxDebugger.rex"

  Note that double quotes will not generally be required on Windows but may be needed on operating systems that use a case-sensitive filesystem

  With this option the debugger will launch and break at the start of the Rexx program

  (2) There are no global TRACE options but debugger window placement and/or start point of debugging matter (*)

  Before the first line of code to debug add:
  
    CALL RexxDebugger [parentwindowname, offsetdirection-LRUD]  
    TRACE ?R

  With this option the debugger will launch during the CALL statement and break after the TRACE ?R statement
  
  (3) There are global TRACE options (::OPTIONS TRACE ?R is recommended) and debugger window placement and/or start point of debugging matter (*)

  Before the first line to debug add:

    CALL LaunchDebugger [parentWindowName, offsetdirection-LRUD]

  At the end of the code, you should not add a requires statement for RexxDebugger.rex, but along with the TRACE option you should add 

    ::REQUIRES "DeferRexxDebuggerLaunch.rex"

  With this option the debugger will show trace output from the start of the program but wont break until the LaunchDebugger call
  
  Note that if you are running on Windows but wish to use the Java interface you can include the following line before any other ::requires statements for the debugging modules to activate this.
  
    ::REQUIRES "RexxDebuggerBSFUI.rex"

  (*) Debugger window placement is only supported by the Windows native interface


  ### Direct launch of a Rexx program (and known limitations of rexxdebugger launching)
  -------------------------------------------------------------------------------------
  
  The code modification examples above can also be used for debugging Rexx programs that you launch directly instead of via the rexxdebugger command. Sometimes you may just do this for convenience or for additional control, and you may also need to modify programs called by your top-level program to activate tracing in those, but there is at least one known scenario where using rexxdebugger to launch a program will fail and code modification must be used.
  
  When you have classes in your top level program which include a class init or activate method and module level tracing is activated, these methods will be traced before the debugger library is properly initialised causing unpredictable behaviour when such programs are invoked via rexxdebugger
  
  You can either:
  
  Modify your program to activate tracing but create a wrapper program which calls this program and which can safely be launched from rexxdebugger
  
  or
  
  Use direct launch with your program and include code to activate tracing but place any ::REQUIRES "RexxDebugger.Rex" line earlier in your code than the definition of the first class which includes such method calls

  In term of directly launching a Rexx program, in Windows you can do this just by specifying its name but on other platforms you will generally need to precede the program name with a launcher command
  
  On Linux:

    rexx <program> <arguments>
	
  On MacOS running bsf4oorexx 641

    rexxj.sh <program> <arguments>
  
  On MacOS running bsf4oorexx 850
  
    rexxjh.sh <program> <arguments>
  
  Note that when a debug session launched this way on MacOS reaches the end of the program or aborts due to an unhandled error the debugger window will disappear. Possible ways of avoiding this will be investigated for future releases.
 
Control of program / trace output and possible limitations
----------------------------------------------------------

When launching a debug session via rexxdebugger there are command line options (see above) for controlling where these types of ouput go but there are additional debugger commands (CAPTURE/CAPTUREX/NOCAPTURE) that can be used to make changes during any active debug session. Further details on what they do can can found in the Help text, but it is important to note that some embedded environments may take full control of program and trace output. For these environments you may not be able to redirect ouput to the debug console window and will be limited to  whatever output is generated by the embedding application.

Multiple debug runs in the same rexxdebugger session
----------------------------------------------------

If you have run a debug session using rexxdebugger to completion, the Open button will become available and you can launch a new debug session. However, you will be running with the same Rexx interpreter instance as previously so you should ensure that any files or other resources have been released by the code in your previous debug session or you may see unexpected behaviour in the new debug session. 

Closing the rexxdebugger window and launching a new one for the next debug session will ensure that you are using a new Rexx interpreter each time and will avoid this issue.

Final notes and further information
-----------------------------------
The Help button will send output information about the various options to the debugger console window and is worth checking out at least once, even though it's not very structured or pretty.

For an interactive walkthrough of many of the features run tutorial.rex, ideally from a command prompt / terminal using direct launch, and follow the instructions.
