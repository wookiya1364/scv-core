# choices — how SCV asks the user to choose

This file is the only place this rule is written (`scv/SCV.md` Top-level rules, clause 4). Protocols,
hooks and the rewrite principle point here instead of restating it.

## When the host names a choice tool

The wrapper's host profile may name the host's tool that shows the user selectable options
(`SCV_CHOICE_TOOL`, `contracts/host-profile.md`). When it does, every decision SCV puts to the
user goes through that tool — in any turn, inside or outside an action, automatic-notification
turns included:

1. One decision is one question. The recommended option comes first and is marked as recommended.
2. Each option's description says what choosing it does, including how it avoids the problems it
   would cause. Problems are not listed on their own — the options carry their fixes.
3. More questions than the tool takes in one call (four today): ask in consecutive calls, the most
   important first.
4. More options than one question takes (four today): ask in two steps — first a group, then a
   choice inside it — so that every option stays reachable.
5. A free answer, such as a name or a title: offer one or two recommended values as options; the user
   types anything else in the tool's own free-text choice.
6. Cancelled or unanswered: do not go ahead on the recommendation. Say so in one line and stop,
   without ending on a question.
7. Never end a turn by asking in text. An offer of more detail is a decision too — ask it with the
   tool, or state it without a question. The stop hook blocks a final message that asks the user
   something or asks for an answer by number — once per turn; when the host reports that it is
   already continuing, it leaves a warning for the next turn instead.

Information is not a decision. Tables that report — the unit table of the rewrite principle, result
tables, the help item table — stay as text.

## When the host names none

Nothing changes: a decision is asked as before — a numbered table with a recommendation on every row,
answered by number.

## What this rule replaces

The help answer shape states this rule in its Decisions slot (`protocols/help.md`, "Answer shape",
slot 6 — the section's lock was renewed with that wording on 2026-10-01). Where the host names a choice
tool, this rule also replaces the numbered Decisions table echoed in `protocols/help/full.md`, the one
decisions table of regression triage (`protocols/regression.md`, Step 2), the question form of the offer
in the plain-language section's example, and the text rendering of every `Question: … options:` block in
the protocols. It is the narrower rule — it applies only when the host has the tool, and only to
decisions — and it declares here that it supersedes those texts (Top-level rules, resolution order 2
and 4).
