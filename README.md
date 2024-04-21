# ooRexxDebugger

An interactive dialog based ooRexx debugger for use on Windows.

It is written in ooRexx (version 4.2) and uses the ooDialog framework for its user interface.

It's a bit rough around the edges (still) and pretty basic but features include:

- Display of active source code
- A stack listing to allow switching between active locations and source files
- An entry field for executing Rexx statements when tracing is waiting for feedback
- A console window to display basic help information and (optionally) program and debugger output 
- Single step or run to breakpoints (*)
- Toggling of breakpoints in an active session
- Presetting of breakpoints in the Rexx source by adding  empty comments (/**/)
- Watch windows, for display of simple variables with drilldown into many collection types
- A deferred launch option enabling positioning relative to a specific window

(*) Note that this is built around the interactive trace framework included with ooRexx so can only pause
where that framework would pause. Some statements are never hit at all, other statements only once, 
and if you have ROUTINE calls, METHOD calls or calls to external programs you may need to add additional 
TRACE statements and/or use global TRACE options to ensure single stepping and breakpoints work as expected.

To  activate the debugger you need to download and put RexxDebugger.rex somewhere in your path
and modify your source code as follows:

Before the first line of code to debug (if not using a global TRACE option) add:
  
TRACE ?R
  
At the end of the file add:
::REQUIRES RexxDebugger.rex
  
For deferrered launching with optional positioning you also need to you need to download and put
DeferRexxDebuggerLaunch.rex in your path and make a couple of additional source code changes:

Insert the following above the TRACE ?R line:

CALL LaunchDebugger [<parentWindowName>, '<offset directorion L,R,U or D>']

Before the ::REQUIRES RexxDebugger.rex insert:

::REQUIRES DeferRexxDebuggerLaunch.rex
