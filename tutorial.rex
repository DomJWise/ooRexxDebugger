CALL SAY 'Unless indicated otherwise use the Next button to step through this demo/tutorial'
CALL SAY 'The options at the end ensure debugging starts at the top and that everything is debugged' 
CALL SAY 'The debugger pauses AFTER executing the line it has stopped on'
CALL SAY 'Note that CALL SAY will show up in the debugger but by default SAY goes to your application'
SAY 'i.e. This text should appear in your command prompt window (more on this later!)'
CALL SAY 'Double click on line 11 to add a breakpoint then click on the highlighted row in the stack'||.endofline - 
'view to get back to the current line.'
CALL SAY 'Hit Next once, then Run'
NOP 
NOP
NOP  -- NOP can be a useful placeholder for breakpoints and when single stepping 
CALL SAY 'Hit Run. Note that the breakpoint on line 16 was already set when debugging started'
NOP
NOP
NOP
/**/ SAY 'An empty comment at the start of a traceable line will cause the debugger to insert a breakpoint'
CALL SAY 'Double clicking on the following line will insert a ? breakpoint marker because the line isn''t traceable' 
/* comment or intruction  Rexx tracing wont stop at */
CALL SAY 'Double click on any breakpoint line above to remove the breakpoint'
NOP
CALL SAY 'Breakpoints can have conditions set on them via a right-click action when they are selected'
CALL SAY 'Click on line 29 then use the right-click action to set the condition i=5 for the breakpoint'
CALL SAY 'With this set the breakpoint will be ignored until the loop variable i has the value 5 so when running'
CALL SAY 'you should see 1-5 printed out before the breakpoint is hit, after which it won''t be hit again'
CALL SAY 'Hit the Run button twice to see the conditional breakpoint in action'
CALL SAY 'Running loop 8 times'
do i = 1 to 8
  CALL SAY i
  /**/ NOP
end
CALL SAY 'Loop finished'

/**/CALL SAY 'Enter "SAY 1+2" into the debugger command prompt below (without the quotes) and hit Execute or Next'
CALL SAY 'The result should appear in your console window'
CALL SAY 'Enter "CAPTURE" into the debugger prompt and hit Execute. Trace and SAY output will be moved here'
SAY 'Enter "SAY 2+3"  into the debugger prompt and hit Execute or Next'
SAY 'Type "CAPTUREX" into the debugger prompt and hit Execute.'
SAY 'Trace output should no longer appear anywhere, unless there is an error, but SAY output will'
SAY 'Type "SAY 3+4" into the debugger prompt and hit Execute or Next'
SAY 'Press the Enter key on the keyboard. With text in the debug command prompt this is the same as hitting Exec'
SAY 'Clear the text in the debugger prompt and press Enter again. This is the same as hitting Next'
SAY 'Play around with the up/down arrow keys to see previous commands'
NOP
x = 12
SAY 'Click the Watch button then hit Next'
Y = 13
SAY 'Enter "y=y+1" in the debugger prompt and hit Next a couple of times, with an eye on the Watch window'
SAY y
SAY y
SAY 'Note that with Next your Rexx is executed AFTER the next statement has run'
SAY ''
z = 'Here is'.endofline'a multiple'.endofline'line string'
SAY 'String variables can be opened in a separate window for multi-line or byte view'
SAY 'Double click on Z to show it in a multi-line view, the default'
SAY 'The bytes which make up the string can be individually viewed as well'
SAY 'Right click in the Z watch window and select "Show bytes in hexadecimal"'
SAY 'This view will show ten bytes per line, with the hexadecimal of each followed by the characters'
SAY 'The start of each line shows the index of the start of that block in the string'
SAY
stemvar.1 = "Hello"
stemvar.2 = "World"
SAY 'A + sign at the start of a watch variable means it is a collection that can be expanded.'
SAY 'In the Watch window, double click on STEMVAR to see its components'
SAY 'Arrays are collections so can be expanded, including multi-dimensional arrays'
SAY 'Click Run if you want to skip array set up'
multidimarray = .Array~new(2,2)
do i = 1 to 2
  do j = 1 to 2
    multidimarray[i,j] = (i-1)*2+j
  end  
end
/**/SAY ' In the Watch window, double click on MULTIDIMARRAY'
dir = .Directory~new
dir["StringThing"] = "String Value"
subarray = .array~of("Item1", "Item2", "Item3")
dir["ArrayThing"] = subarray
SAY 'In the Watch window, double click on "DIR"'
SAY 'Recursive watch drilldown is possible for all collection types'
SAY 'In the newly added watch window for DIR, double click on "ArrayThing"'
SAY
SAY 'The global .Environment and .Local directories can be accessed via a menu action'
SAY 'In the main watch window, right-click and select the menu option "Show global items"'
SAY 'The two directory objects will be added at the bottom of the list of variables'
SAY 'METHODS and ROUTINES have their own variables. Now a ROUTINE will be called'
SAY 'Note that with a CALL statement Rexx breaks AFTER the call has completed.'
CALL TestRoutine
SAY 'The same will be true for calls to code blocks which use PROCEDURE'
SAY ''
SAY 'At the end of the program:'
SAY ' When programs launched from rexxdebugger end there is an Open button you can use to start another debug session'
SAY ' In other scenarios there is no Open button and while the debugger can''t tell when the program has finished the open windows will stay grey'
SAY ''
SAY 'For more information hit the Help button'
SAY 'That''s all for this tutorial'

call RexxDebuggerHandleExit
exit

::ROUTINE TestRoutine
SAY 'This routine has its own variables and invalid watch windows will have turned grey'
x = 5
y = 49
say .array~of('You can see where this was called from by selecting a row in the stack view','Watch windows will update to reflect the selected stack entry')~section(1, 1 + .context~stackframes[1]~hasmethod("context"))~makestring
NOP
return

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

::requires "RexxDebugger.rex"
::options TRACE ?A

