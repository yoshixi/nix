# Pull requests

## Title

One line, simple enough to scan at a glance. Format:

```
[{service-name}] {what changed}
```

## Description

Include:

- Context — why this change happened.
- What changed — the externally observable behavior (new endpoints,
  params, responses, errors).

Leave out:

- Implementation details — internal code organization, refactors, which
  files/functions changed. Test: if a caller of the change can't tell the
  difference from your sentence, it's implementation detail — even without
  naming files or functions. That's what the diff is for.
