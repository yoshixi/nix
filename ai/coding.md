# Coding

Applies to every language. Language-specific docs live in `~/.ai/lang/`.

## Comments

Comments carry why and why-not. The code already states what it does, so a
comment that paraphrases it is noise — delete it rather than keep it in sync.

Worth a comment: the reason behind a non-obvious choice, a constraint that
forced it, an alternative that was rejected and why, a bug the line prevents.

Not worth one: restating the call below, narrating control flow, labelling
sections of an obvious sequence, or noting that code was changed.

## I/O boundaries

Keep business logic free of I/O — no database, HTTP, filesystem, clock or
randomness inside it. Take data in, return data out.

Push I/O into thin adapters at the edge. They fetch, hand off and persist; they
hold no business rules.

Pass time, IDs and randomness in as arguments rather than reading them from
inside the logic.

Test the core by calling it with plain values. Needing a mock to test a business
rule means the rule and its I/O are still tangled — separate them instead of
reaching for the mock.

## Test style

Tests should be DAMP — "Descriptive And Meaningful Phrases" — rather than DRY,
so the spec reads straight off the test. See
[Unit Testing](https://abseil.io/resources/swe-book/html/ch12.html) in the
Google SWE book: some duplication is fine when it makes a case clearer.

Parameterise repetitive cases where it helps, but readability wins — keep a case
separate if folding it in would obscure what is being asserted.
