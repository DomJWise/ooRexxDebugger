# ooRexxDebugger

A basic interactive dialog based ooRexx debugger for use on Windows.

It is written in ooRexx (version 4.2) and uses the ooDialog framework for its user interface.

It's still in active development so you may well find bugs but features include:

- A main window with:
-  Source code for the running program
-  Stack trace that allows switching between active source locations and files
-  An entry field for executing Rexx statements or debugger commands while tracing is waiting for feedback
-  A console window to display basic help information, status and (optionally) program and debugger output 
-  Single step or run to breakpoints (*)
-  Break for running code or (useful for event driven based programs) when the next line of traceable code is hit 
-  Toggling of breakpoints in an active session
- Watch windows for display of simple variables and drilldown into many collection types
- Presetting of breakpoints in the Rexx source by adding  empty comments (/**/)

(*) Note that this is built around the interactive trace framework included with ooRexx so can only pause
where that framework would pause. Some statements are never hit at all, other statements only once, 
and if you have ROUTINE calls, METHOD calls or calls to external programs you may need to add additional 
TRACE statements and/or use global TRACE options to ensure single stepping and breakpoints work as expected.

To  use the debugger RexxDebugger.rex (and DeferRexxDebuggerLaunch.rex if used) need to be in your path or the local directory.

There are various ways to control the startup depending on your requirements.

Note that global TRACE options are generally a good idea if your program includes METHOD or ROUTINE
sections so you dont want to add TRACE statements to them manually

Common  usage scenarios are as follows:

1. There are global TRACE options but debugger placement and start point of debugging don't matter

At the end of the file with the TRACE option add:

  ::REQUIRES RexxDebugger.rex

With this option the debugger will break at the beginning of the program

2. There are no global TRACE options but debugger placement and/or start point of debugging matter.

Before the first line of code to debug add:
  
  Call RexxDebugger [parentwindowname, offsetdirection-LRUD]  
  TRACE ?R

With this option the debugger will break after the TRACE ?R statement
  
3. There are global TRACE options and debugger placement and/or start point of debugging matter.

Before the first line to debug add:

  CALL LaunchDebugger [parentWindowName, offsetdirection-LRUD]

At the end of the program add

  ::REQUIRES DeferRexxDebuggerLaunch.rex

With this option the debugger will trace from the start of the program but wont break until the LaunchDebugger call
