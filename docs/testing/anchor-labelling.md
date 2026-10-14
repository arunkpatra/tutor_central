# Labelling the language anchors (D110)

The parents' messages (the weekly note, can-now-do, test tomorrow, not on track) are written by the AI service in the
parent's language with English beside them. Free checks hold the script, the numbers, the sign-off and the tutor's own
words; whether a message reads as a parent of that class would want it read needs a native speaker. These anchor sets are
what that speaker reads.

## What is labelled

- `api/evals/anchors/hi/cases.json`: eight messages in Hindi.
- `api/evals/anchors/kn/cases.json`: eight messages in Kannada.

Each set holds four weekly notes, two can-now-do notes, one test tomorrow and one not-on-track message. The names are the
local seed's (`supabase/seed.sql`); the weeks are invented. No real student, parent, phone number or school is in them, and
none is ever added.

## Who

One native speaker of Hindi and one of Kannada, each a parent or a teacher of school-age children, arranged by the owner.
They need no account and no app: they read a file and write one back.

## How the speaker gets the messages

1. The session runs `bun evals --kinds anchor_hi,anchor_kn` on the real models; `api/evals/output/results.json` then holds
   each case's message and English.
2. The session prints one plain sheet per language (`anchor-hi.txt`, `anchor-kn.txt`): for each case, its id, the facts the
   message was written from (in English) and the message itself. The English beside the message is left out, so the speaker
   reads the message as a parent would.
3. The owner sends the sheet to the speaker.

## What the speaker does, for each message

Read it as the parent of that class would, then answer five things:

| Label | Values | What it means |
|---|---|---|
| `script` | 0, 1 or 2 | 2: all in the language's own script as a parent writes it; 1: a few words in another script that read oddly; 0: much of it in another script |
| `code_mixing` | 0, 1 or 2 | 0: no English words; 1: a word or two of English a parent expects ("unit test", "homework"); 2: more English than a parent would use |
| `meaning_kept` | yes or no | Does it say what the facts say, and nothing they do not? |
| `natural` | 1 to 5 | 5: as a good tutor from that place would write it; 1: plainly machine-made |
| `corrected` | text | The message as the speaker would have written it (the same facts, nothing added) |

## Where the answers go

The speaker sends the answers back in any form; the session writes them to `api/evals/anchors/<lang>/labels.json`, one
object per case id:

```json
{
  "anchor-hi-week-equations": { "script": 2, "code_mixing": 1, "meaning_kept": true, "natural": 4, "corrected": "…" }
}
```

## What the labels become

- A case's `corrected` text gives its `contains` words (the phrases a parent expects) in `cases.json`.
- Labels of 0 for `script`, 2 for `code_mixing`, `meaning_kept: false` or `natural` below 3 become lines of the four
  kinds' rubrics, with the corrected version as the example the checker and the graders read.
- From then the anchors are graded like any golden set (D101, D103).

## When

During Phase 21's build, before the nightly's kinds are set by schedule (the plan's Task 11). The build does not wait for
the labels: until they come the anchors run under the free checks alone.
