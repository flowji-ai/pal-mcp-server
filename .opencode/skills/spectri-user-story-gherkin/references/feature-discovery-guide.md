# Feature Discovery Guide

A step-by-step playbook for conducting feature discovery before user story generation. The goal is to elicit sufficient context so that stories reflect what the user actually needs — not what the agent invented to fill gaps.

---

## Step 1: Narrative Opening

Ask one of these based on whether the feature already exists:

> "Walk me through what happens when you use this feature. Start from the beginning — what triggers it, what happens next, and how does it end?"

Or if it doesn't exist yet:

> "Walk me through how you do this today without the feature. What's the manual process?"

**STOP AND WAIT** for user response before continuing.

After the user responds, update `feature-discovery.md` with what you've captured before moving to Step 2.

---

## Step 2: Gap-Filling Questions

Identify which of the 11 elements are MISSING from the narrative. Ask ONLY about missing ones — skip anything the user already described. Ask conversationally as natural follow-ups, not as a list dump. STOP AND WAIT after each question.

| Element | Ask only if absent |
|---------|-------------------|
| **Invocation mechanism** | "How does someone start this? A CLI command, a UI element, an API call, a hook, or a scheduled job?" |
| **Trigger** | "What kicks this off? What event, condition, or decision prompts this?" |
| **Interaction flow** | "Does the system ask you anything along the way? In what order?" |
| **Decision points** | "Are there any forks — places where you choose between options?" |
| **Output** | "What's the end result? A file, a message, a state change? Where does it go?" |
| **Output structure** | "What should that output look like inside? Any specific structure, headings, or fields?" |
| **Lifecycle** | "Does this thing have stages over time? Create, update, archive, resolve?" |
| **Actors** | "Who's involved? Just you, or does an agent do things too?" |
| **Variants** | "Are there shortcuts or alternative ways to do this?" |
| **Root purpose** | "Why do you need this? What's painful today without it, and what's the most frustrating part of the current experience?" |
| **Exceptions** | "What if [X] fails or isn't available?" |

After each answer, update `feature-discovery.md` before asking the next question.

**Sparse input fallback**: If fewer than 5 of the 11 elements have been collected after Steps 1+2, do NOT proceed to synthesis:
> "I don't have enough detail yet to generate good stories. Can we cover [list missing required elements] before I proceed?"

Continue until invocation mechanism, trigger, flow/decisions, output, and actors are all confirmed.

---

## Step 3: "What About" Probing

Skip this step entirely for simple features with no branching.

For each identified decision point or output, probe for alternatives:
- "What about if [alternative scenario at this step]?"
- "Could there be a shortcut for [identified step]?"

Probe decision points and outputs only. Skip purely mechanical steps ("then it saves the file"). STOP AND WAIT after each probe. Update `feature-discovery.md` with any new information before continuing.

---

## Step 4: Synthesis and Confirmation

Read back your full understanding in the user's own language:

> "So [invocation mechanism → trigger → interaction sequence → decision points → output → lifecycle → actors]. Is that right?"

**STOP AND WAIT.** Story generation begins ONLY after user confirms.

If user corrects: update your understanding, update `feature-discovery.md`, and re-synthesise. Repeat until confirmed.

---

## Step 5: Metaquestion Closer

> "Is there anything I should be asking about that I haven't covered?"

**STOP AND WAIT.** If user raises a new topic, incorporate it into `feature-discovery.md` and return to Step 4 to re-synthesise. After confirmation, the synthesised understanding in `feature-discovery.md` becomes the enriched context for story generation.

---

## Recording Findings

Write to `feature-discovery.md` **after each step** — not at the end. Do not wait for the full walkthrough to complete before saving. Context window compression is a real risk during long discovery sessions: if compression occurs before findings are written, the context is lost and recovery is not possible.

The document must be complete and all required fields populated before the `spec.specify` command will proceed to story generation. The validation script will block progression if any placeholder fields remain.
