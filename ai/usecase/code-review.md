# Code review

Check the diff against `~/.ai/coding.md` and the matching `~/.ai/lang/` doc.

Report findings back in chat. Don't post them to the PR (`gh pr comment`,
`gh pr review`, etc.) unless the user explicitly asks for that.

## Report format

1. Start with a one-line verdict (approve / approve with notes / request changes)
   and say whether anything blocks the merge.

2. "What I checked": short bullets of what you checked and found fine,
   so the user knows what was covered.

3. "Tests": which tests you ran, which passed, and which you could not run and why.

4. Findings, numbered, most important first. For each finding:
   - A short bold title.
   - The file path, then a code block copied from the file with the real
     line numbers at the start of each line. Show only the lines that matter;
     use "..." to skip lines in between. If the problem involves code in
     another file (for example, a function it calls), show that code too.
   - A short plain-English explanation: what goes wrong, a concrete example
     if possible, and how often it can happen.
   - A suggested fix, or say that it is fine to leave as is.
   - Say if it is optional or matches an existing pattern in the codebase.

5. End by saying nothing was posted to the PR, and ask if the user wants any
   findings posted as PR comments.

Use simple English. Don't use line references alone ("node.go:175");
always show the code.
