SAY 'Welcome to the tutorial! Unless indicated otherwise use the Next button to step forwards'
SAY 'Note the debugger always pauses AFTER executing the line it has stopped on'
SAY 'The options at the end ensure debugging starts straight away and that everything is debugged' 
SAY 'The ::REQUIRES statement also ensures the debugger SAY routine (see later) can be used'
SAY 'By default SAY output appears in the debugger and TRACE output is discarded'
SAY 'The can be changed with the CAPTURE, CAPTUREX and NOCAPTURE debugger commands'
SAY 'CAPTUREX is the current and default mode (capture SAY, discard TRACE)'
SAY 'Enter CAPTURE in the console prompt and press the Exec button to add in TRACE output. Then press Next'
SAY 'The TRACE output and SAY output should now appear in the debugger console'
SAY 'Ensure the console window used to start this session is visible. Output will appear there soon'
SAY 'Enter NOCAPTURE in the console prompt and press the Exec button to stop all capture. Then press Next'
SAY 'The statement which follows uses CALL SAY (a debugger routine) to force the SAY output to the the debugger'
CALL SAY 'Enter CAPTUREX in the console prompt and press the Exec button for normal capture. Then press Next'

SAY 'Double click on line 20 to add a breakpoint then click on the highlighted row in the stack'||.endofline - 
'view to get back to the current line.'
SAY 'Hit Run to progress to the line with the breakpoint '
NOP 
NOP
NOP  -- NOP can be a useful placeholder for breakpoints and when single stepping 
SAY 'Hit Run. Note that the breakpoint on line 25 was already set when debugging started'
NOP
NOP
NOP
/**/ SAY 'An empty comment at the start of a traceable line will cause the debugger to insert a breakpoint'
SAY 'Double clicking on the following line will insert a ? breakpoint marker because the line isn''t traceable' 
/* comment or intruction  Rexx tracing wont stop at */
SAY 'Double click on any breakpoint line above to remove the breakpoint'
NOP
SAY 'Breakpoints can have conditions set on them via a right-click action when they are selected'
SAY 'Click on line 38 then use the right-click action to set the condition i=2 for the breakpoint'
SAY 'With this set the breakpoint will be ignored until the loop variable i has the value 2 so when running'||.endofline -
'you should see 1-2 printed out before the breakpoint is hit, after which it won''t be hit again'
SAY 'Hit the Run button twice to see the conditional breakpoint in action'
SAY 'Running loop from 1 to 4'
do i = 1 to 4
  CALL SAY i
  /**/NOP
end
SAY 'Loop finished'
/**/ SAY 'Conditional breakpoints can be preset using a comment of the form /*WHEN:<cond>*/'
SAY 'Hit the Run button twice to see a preset conditional breakpoint for i = 13 in action'
SAY 'Running loop from 10 to 20'
do i = 10 to 20
  CALL SAY i
  /*WHEN:i=13*/NOP
end
SAY 'Loop finished'
/**/ SAY 'Rexx code can be executed in the context of your program via the input console'
SAY 'Enter "SAY 1+2" into the debugger command prompt below (without the quotes) and hit Next'
SAY 'Press the Enter key on the keyboard or press Exec . When finished press Next to move on'
SAY 'Clear the text in the debugger prompt and hit Enter or press Exec. This is the same as hitting Next'
SAY 'Enter "SAY 2+3" and hit Next'
SAY 'Use the up/down arrow keys to navigate through console input'
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

