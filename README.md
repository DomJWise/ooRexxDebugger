# ooRexxDebugger

A cross platform dialog based ooRexx debugger

Written in ooRexx with support from version 4.2 on Windows where ooDialog is used for the user interface, 
and on platforms with Java and bsf4ooRexx (minimum tested versions bsf4ooRexx 850 + ooRexx 5.0) where the 
Swing/AWT libraries are used. The JRE/JDK version should not matter unless it is especially ancient or
specifically excludes Swing and/or AWT.

Validation testing for the  Swing/AWT version is limited to  Windows, Mac OS and Ubuntu 24.04 at this time.

It's still in active development so you will likely find bugs but features include:

- A main window with:
  -  Source display of the code being debugged
  -  Stack trace that allows switching between active source locations and files
  -  An entry field for executing Rexx statements or debugger commands while tracing is waiting for feedback
  -  A console window to display basic help information, status and (optionally) code and debugger output 
  -  Single step or run to breakpoints (*)
  -  Break button to interrupt running code or (useful for event driven based code) break when the next line of traceable code is hit 
  -  Toggling of breakpoints in an active session
- Watch windows for display of simple variables and drilldown into many collection types
- Presetting of breakpoints in the Rexx source by adding  empty comments (/**/) at the start of traceable lines.

(*) Note that this is built around the interactive trace framework included with ooRexx so can only pause
where that framework would pause. Some statements are never hit at all, other statements only once. 
Note also that global TRACE options are generally a good idea if your code includes METHOD or ROUTINE
sections so you dont have to add TRACE statements to them manually. TRACE ?R is a good tracing option for 
keeping the trace output low and minimizing the overhead of processing the trace text, though in many cases the 
CAPTUREX debugger command can be used to discard all TRACE output and speed things up considerably.

To  use the debugger, RexxDebugger.rex (and DeferRexxDebuggerLaunch.rex if used) need to be in your path or the local directory, along with one of the user interface modules below:

   - RexxDebuggerWinUI.rex is required for the Windows ooDialog version

   - RexxDebuggerBSFUI.rex in required for the Swing/AWT version

On Windows when both modules are available the native ooDialog module will be preferred but this can be overridden by including ::REQUIRES RexxDebuggerBSFUI.rex in your source. If the source also includes ::REQUIRES RexxDebugger.rex the latter must appear later on in the source for this override to work. Alternatively if launching via RexxDebugger you can specify the /javaui command line option (see below)

On Unix platforms the (bash) script rexxdebugger can be copied into the path e.g. /usr/local/bin and marked executable. This will
invoke RexxDebugger.rex from the rexx executable passing all your arguments, saving you from having to type e.g. rexx RexxDebugger .... 

Standalone programs or programs called as a single routine with multiple arguments can be debugged without modification via command line options available to RexxDebugger.rex

For a standalone program  where a single argument string is passed unaltered to the program you would use:

rexxdebugger [/showtrace | /nocapture] [/javaui] myprogram.rex [{argstring}]

For a 'routine' program that expects multiple ARG(n) arguments you would use:

rexxdebugger [/showtrace | /nocapture] [/javaui] CALL myroutine.rex [{arg1}] ... [{argn}]

Multi-word aruments need to be surrounded by double quotes and (at present) double quotes cannot be included within an argument

For both of the above the default is to capture all program output in the debugger console with trace output discarded to improve performance and reduce "noise". 

If /showtrace is specified the trace output is also captured in the debugger console.

If /nocapture option is specified nothing will be captured.

The ability to control what is captured to the console is available in any debug session using the CAPTURE/CAPTUREX/NOCAPTURE commands. Note that some embedded environments will not allow redirection of output in which case these commands will have no effect.

NB: On Mac OS it may be that the rexxdebugger script cannot be used and so to run either of the above you will need to use the Rexx+Java launcher script and the full name of the debugger rexx file

e.g. rexxjh.sh RexxDebugger.rex [/showtrace | /nocpature] myprogram.rex [{argstring}]

The /javaui option can be used on Windows with ooRexx 5.0 or later to run the debugger with the Swing/AWT (Java) interface

If more fine-grained control over debugging is needed or when your Rexx code is embedded and run from within another application, source code modification is required and there are various options depending on your requirements.

If not using RexxDebugger to launch a program i.e. if running it directly or if it is embedded in another application some modifications to the code will be required and some example usage scenarios are as follows:

(1) There are global TRACE options but debugger window placement and start point of debugging don't matter

At the end of the code along with the TRACE option (::OPTIONS TRACE ?R is recommended) add:

  ::REQUIRES RexxDebugger.rex

With this option the debugger will break at the start of the code

(2) There are no global TRACE options but debugger window placement and/or start point of debugging matter (*)

Before the first line of code to debug add:
  
  Call RexxDebugger [parentwindowname, offsetdirection-LRUD]  
  TRACE ?R

With this option the debugger will break after the TRACE ?R statement
  
(3) There are global TRACE options (::OPTIONS TRACE ?R is recommended) and debugger window placement and/or start point of debugging matter (*)

Before the first line to debug add:

  CALL LaunchDebugger [parentWindowName, offsetdirection-LRUD]

At the end of the code along with the TRACE option add:

  ::REQUIRES DeferRexxDebuggerLaunch.rex

With this option the debugger will trace from the start of the code  but wont break until the LaunchDebugger call

(*) Debugger window placement is only supported on the Windows ooDialog version

THe Help button will send more information about the various options to the debugger console window and is worth checking out at least once, even though it's not very structured or pretty.

For an interactive walkthrough of many of the features run tutorial.rex, ideally from a command prompt / terminal, and follow the instructions.
