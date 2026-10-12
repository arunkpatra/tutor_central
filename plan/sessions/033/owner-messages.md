# Session 33: the owner's messages, word for word

## Message 1 (the resume prompt)

`plan/resume/031-v3-interview-and-spec.md`, pasted whole.

## Message 2 (the answer to Q1, the owner's own review)

> The phone initiating tasks in general (e.g. AI work) which is long running is not the correct architecture. Long running
> tasks (which will potentially become even longer due to increasing sophistication, agentic processes, multi-round
> conversations etc. in teh futire) should be independently done and managed by a persistence backed process with valid
> states. UI (i.e iOS app) should interface with the system using APIs. The iOS app is just a presentation layer and that is
> what it should be .
>
> There is no tracking of cost incurred, activities being done by the user (tutor) - on their account. Admin app (next.js web
> app) is needed for full visibility.
>
> All limits etc should be managed properly. Backend is the "platform", iOS is just the UI layer just like a UI app pulling
> data from backend via API.
>
> How is the notifications are being even created? where? what is teh robust bessed Apple way? what is teh APNS thing. How
> can system/backend decide if neeeded when to push notifications and send. The platform MUST NOT depend on compute happening
> or being orchestrated by teh iOS app at all - think, suggest, push back if needed.
>
> For now one env is ok. We will stand up staging environment later on.
>
> In admin app (admin portal) and admin user (internal admin personnel of TutorCentral company) should be able to see
> everything about cost consumptions, analytics, metrics of teh user (tutor and their account).
>
> The AI generations seem to be very naive. The content is coming back very crude with no mathemical equations in proper
> format/rendering - its just some text format etc.
>
> ALso AI layer needs complete overhaul - proper agentic system design which we should eb able to systematically grow. Each
> specific work should be specialized AI agent which does teh job. Basically we absolutely want th best possible quality of
> teh outputs and not naive ai generated content.

## Message 3 (Q4, the team)

> Me alone with Claude for now. Exactly as how it has happend till now. `Claude code ` codes . why are you even asking this
> question?

## Message 4 (Q5, the budget)

> Paid plans are fine now - whatever is needed, be judicious

## Message 5 (after dismissing Q6)

> for now, we will not go overobard like sentry , helpdesk etc...... we just want our platform architecture in order and teh
> admin portal so that we have teh data the analytics and teh eyes on what's happening so taht we can debug easily and monitor
> easily

## Message 6 (Q6 asked again, answered: the recommended option)

> ask the last question again

(Then the dialog's answer: "Same Supabase Auth + TOTP + server-side service role (Recommended)".)

## Message 7 (while Q7 was being written)

> don't ask me superfluous questions that you are capable of answering/deciding yourself

## Message 8 (enough; the spec)

> yes, write the spec

## Message 9 (while reviewing the spec)

> I'm reviewing. Tell me what product/functional/feature-dev work is pending in V2

## Message 10 (approval)

> Ok, spec approved. We should not call it "tutor round" - I got confused. I think it's the external testing round is what you
> were saying
