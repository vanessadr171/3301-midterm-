# ECE 3301 — Practical Midterm (individual repository)

This repository is **yours alone**. It holds `PracticalMidterm.X`:
"Write Your Own BIOS" for the PIC18F46K22, in pure assembly. Everyone
starts from this same starter code.

| | |
|---|---|
| Opens | Tuesday, September 29, 2026 |
| Due | **Monday, October 5, 2026, 11:59 PM PT** |
| Theory Exam (separate, on Gradescope) | opens Sept 29, due Thursday, October 1, 11:59 PM PT |

You have about one week. The practical is deliberately more involved
than a weekly lab. Start early so hardware, toolchain, dependency and
debugging problems do not eat your last two days.

## Workflow

1. Clone this repo and open `PracticalMidterm.X` in MPLAB X.
2. Complete every `TODO` in `bios.S`. The comments walk you through the
   steps; the midterm handout has the details and the rubric.
3. Commit and push to `main` as you work:

   ```bash
   git add PracticalMidterm.X
   git commit -m "POST: RAM test passes"
   git push
   ```

4. Every push is compiled automatically — check the **Actions** tab. A
   green check means it assembles and produces firmware. A red X links
   to the assembler errors. **Green is required but is not the grade.**
   Behavior is graded from your video; code is graded from this repo.

## What must be in the repository

- `PracticalMidterm.X/bios.S` — your firmware.
- `PracticalMidterm.X/WRITEUP.md` — your write-up, in your own words,
  quoting your own code. A commit without `WRITEUP.md` scores 0 on the
  written part. It must contain these sections, in this order:

  1. **Answers** to the questions in the handout.
  2. **AI usage acknowledgment** (see below).
  3. **Status** (see "If it is not finished" below). If everything
     works, one line saying so.

## AI usage acknowledgment

Include a brief AI usage acknowledgment in `WRITEUP.md`.

If you used AI tools at any point, state briefly how, for example:
debugging assistance, explaining an error message, clarifying a
microcontroller concept, checking syntax, helping interpret
documentation. Your final implementation must still be your own work,
and you must be able to explain every line you submit.

If you did not use AI tools, write: *No AI tools were used.*

## If it is not finished

An honest, specific account of unfinished work earns partial credit. A
video of something that does not work, with no explanation, does not.
If any part is incomplete or misbehaving at the deadline, add to the
**Status** section of `WRITEUP.md`:

- **What works and what does not.** Name the exact stage or scenario
  (e.g. "RAM test passes; the INT0 handler fires but RD7 never blinks").
- **Why you think it fails.** Your best diagnosis, with the evidence:
  what you observed, what you measured, what the assembler or the board
  told you.
- **What you tried.** The things you changed and what happened.
- **Plan to fix it.** The concrete next steps you would take with more
  time.

In your demo video, show whatever does work, then show the failing
behavior and say what you have written in Status. Do not skip the
failing part.

## Grading

Two grades, 100 points each. **The full grading sheet is posted with
the exam on Gradescope**, so you can see exactly how every point is
awarded before you start.

**Code (100), graded from your last commit on `main` before the deadline:**

| Points | What |
|---:|---|
| 30 | **GitHub Actions green check on that commit.** This is the "assembles" score. A red X on your final commit is 0 here, so check the Actions tab before the deadline. |
| 6 | firmware hex produced by that build |
| 24 | automated static checks (the required structures are present) |
| 30 | `WRITEUP.md` answers to the handout questions |
| 2 | `WRITEUP.md` AI usage acknowledgment |
| 8 | `WRITEUP.md` Status section: what works, what does not, diagnosis with evidence, what you tried, plan to fix. Fully working plus a one-line status is 8/8. |

A missing `WRITEUP.md` scores 0 on all 40 write-up points.

**Demo (100), graded from your video:** each scenario is scored on what
is shown working. A scenario that fails must be shown and narrated as
described in your Status section. A failing scenario that is skipped or
hidden scores 0 for that scenario.

## Submitting

There is nothing to upload for the code. **Push it here.** The last
commit on `main` before the deadline is the one that is graded, straight
from this repository. Make sure it has a green check and that
`WRITEUP.md` is in it.

The demo video is submitted on **Gradescope**, as a link: one
continuous take, five minutes or less, opening on the commit hash of
your final commit on screen, narrated by you. Use a link that the
instructor can open without requesting access (an unlisted YouTube
video, or a Drive link shared with "anyone with the link").

The Gradescope timestamp is the official submission time for the demo;
the commit timestamp on `main` is the official submission time for the
code. Commits pushed after the deadline are not graded.

## Individual work and collaboration policy

The code you submit must be your own implementation. Similarity that
comes from the provided starter code is expected; the code you add,
modify and develop must be yours.

You **may** talk with classmates about: hardware setup and connections;
general design ideas; problems or symptoms you hit while debugging;
troubleshooting strategies; toolchain, compiler, driver or dependency
issues; how a peripheral or microcontroller concept works.

You **may not**: share or copy source code; send code files to another
student; copy another student's implementation; share screenshots
containing substantial portions of your code; write the code together
and then tweak it into separate submissions; share a complete
algorithm, pseudocode or step-by-step solution that hands someone the
implementation; split the exam among several people and combine the
work.

The rule of thumb: you may help someone understand *why* something is
not working or discuss the general engineering approach, but each
person decides independently how to implement it and writes their own
code. Commit histories make copying easy to detect.

## Housekeeping

- Do not modify `.github/workflows/`.
- Do not commit MPLAB `build/`, `dist/` or `debug/` folders (the
  `.gitignore` already prevents this).
