CALL SAY 'Unless indicated otherwise use the Next button to step through this demo/tutorial'
CALL SAY 'The options at the end ensure debugging starts at the top and that everything is debugged' 
CALL SAY 'The debugger pauses AFTER executing the line it has stopped on'
CALL SAY 'Note that CALL SAY will show up in the debugger but by default SAY goes to your application'
SAY 'i.e. This text should appear in your command prompt window (more on this later!)'
CALL SAY 'Double click on line 11 to add a breakpoint then click on the highlighted row '||.endofline - 
'in the stack window to get back to the current line.'
CALL SAY 'Hit Next once, then Run'
NOP 
NOP
NOP  -- NOP can be a useful placeholder for breakpoints and when single stepping 
CALL SAY 'Hit Run. Note that the breakpoint on line 16 was already set when debugging started'
NOP
NOP
NOP
/**/ SAY 'An empty comment at the start of a traceable line will cause the debugger to insert a breakpoint'
CALL SAY 'Double clicking on the following line  will insert a ? breakpoint marker because the line isn''t traceable' 
/* comment or intruction  Rexx tracing wont stop at */
CALL SAY 'Double click on any breakpoint line above to remove the breakpoint'
NOP
CALL SAY 'Enter "SAY 1+2" into the debugger command prompt below (without the quotes) and hit Execute or Next'
CALL SAY 'Enter "CAPTURE" into the debugger prompt and hit Execute. Trace and SAY output will be moved here'
SAY 'Try hitting NEXT with "CAPTURE" still in the debugger prompt. Debugger commands can''t be present when using Next'
SAY 'Enter "SAY 2+3"  into the debugger prompt and hit Execute or Next'
SAY 'Type "CAPTUREX" into the debugger prompt and hit Execute. Then clear the prompt and hit Next'
SAY 'Trace output should no longer appear anywhere, unless there is an error, but SAY output will'
SAY 'Type "SAY 3+4" into the debugger prompt and hit Execute or Next'
SAY 'Press the Enter key on the keyboard. With text in the debug command prompt this is the same as hitting Exec'
SAY 'Clear the text in the debugger prompt and press Enter again. This is the same as hitting Next'
SAY 'Play around with the up/down arrow keys to see previous commands'
NOP
x = 12
SAY 'Click the Vars button then hit Next'
SAY 'Note that .Environment and .Local are collections available to all Rexx programs'
Y = 13
SAY 'Enter "y=y+1" in the debugger prompt and hit Next a couple of times, with an eye on the Watch window'
SAY y
SAY y
SAY 'Note that with Next your Rexx is executed AFTER the next statement has run'
SAY ''
stemvar.1 = "Hello"
stemvar.2 = "World"
SAY 'In the Watch window, double click on "STEMVAR"'
SAY 'A + sign at the start of a watch variable means it can be expanded.'
SAY 'Try this with either .Local or .Environment'
SAY 'Click Run if you want here to skip array set up'
multidimarray = .Array~new(2,2)
do i = 1 to 2
  do j = 1 to 2
    multidimarray[i,j] = (i-1)*2+j
  end  
end
/**/SAY ' In the Watch window, double click on "MULTIDIMARRAY"'
dir = .Directory~new
dir["StringThing"] = "String Value"
subarray = .array~of("Item1", "Item2", "Item3")
dir["ArrayThing"] = subarray
SAY 'In the Watch window, double click on "DIR"'
SAY 'Recursive watch drilldown is possible for some collection types'
SAY 'In the newly added watch window for DIR, double click on "ArrayThing"'
SAY
SAY 'METHODS and ROUTINES have their own variables. Now a ROUTINE will be called'
SAY 'Note that with a CALL statement Rexx breaks AFTER the call has completed.'
CALL TestRoutine
SAY 'The same will be true for calls to code blocks which use PROCEDURE'
SAY ''
SAY 'At the end of the program:'
SAY ' When programs launched from rexxdebugger end there is an Open button you can use to start another debug session'
SAY ' In other scenarios there is no Open button and while the debugger can''t tell when the program has finished the open windows will stay grey'
SAY ''
SAY 'That''s all for this tutorial'
SAY 'For more information hit the Help button'

exit

::ROUTINE TestRoutine
SAY 'I have my own variables and invalid watch windows will have turned grey (until return)'
x = 5
y = 49
SAY 'You can see where this was called from by selecting a row in the stack view'
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

