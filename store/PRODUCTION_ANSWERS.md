# Google Play production access form: answers for Jigsaw by Pagouro

Drafted 2026-10-12 from Testers Community's two reports (`docs/jigsaw_feedback.pdf`, `docs/jigsaw_production.pdf`)
and the build log. Their template answers claim things that did not happen ("surveys and usability sessions",
"10k-100k installs", "Rate and Share in Settings" when the form was written); these answers say only what did, and
name the builds. Testers Community advises 250-300+ characters per answer. Fill the blanks marked ✱ before pasting.

Builds in the closed test: it opened with 0.2.6 (17) on 2026-10-05, then four updates: 0.2.7 (18), 0.2.9 (20),
0.3.1 (22) and 0.3.2 (23). 0.3.2 carries the changes from Testers Community's report and is on the closed test
(uploaded 2026-10-12), so answer 8 is true of a build Google can see.

**1. How did you recruit users for your closed test?**

> Two ways. We used a paid testing provider, Testers Community, whose group of about 15 testers used the app on
> their own Android phones for the full 14 days and sent a written report. We also gave the app to family members
> who are the audience we built it for, casual players who like a quiet puzzle, and they reported back as they played.

**2. How easy was it to recruit testers?** Easy.

**3. Describe the engagement you received from testers.**

> Testers played the daily puzzle and the other pictures through the test period and sent feedback through two
> channels: Testers Community's written report, and direct messages from family testers while they played. The family
> testers played most days and told us exactly where they got stuck, which is how we found the problems below:
> a clock that counted time spent in other apps, a snap that was not generous enough, and zoom that nobody found.

**4. Summary of the feedback and how you collected it.**

> Family testers (direct messages): the finish time was too long because the clock kept running in the background;
> pieces needed to snap more easily; they did not know they could pinch to zoom; they wanted a pause and a way to
> share their result with family. Testers Community (written report): no crashes or bugs found on their devices;
> suggested a first-run walkthrough, a way to rate the app, a way to share the app, and better store screenshots.

**5. Who is the intended audience?**

> Adults who enjoy jigsaw puzzles and want a calm one: no ads, no account, nothing to buy, and it works offline. Many
> of our testers are older casual players, so the game uses large type, generous snapping and a tray of pieces
> sized for a phone. The pictures are Belle Époque posters: Paris, gardens, dancers, castles and more.

**6. How does your app provide value to users?**

> A free, quiet jigsaw puzzle with no ads at all and nothing locked: 382 pictures, a new daily puzzle for everyone,
> and five sizes from 12 to 156 pieces. It collects no data and needs no account or connection. The clock counts
> only time spent playing, and there is no score, so it stays relaxing.

**7. Expected installs in the first year.** Eric's call. Honest guess: the lowest range that is not zero; the
template's 10K-100K assumes marketing we are not doing.

**8. What changes did you make based on the closed test?**

> 0.2.7: a Share button that copies a result (date, pieces, time) to paste in a family chat. 0.2.9: the clock counts
> only active play; pieces in the tray glide into place. 0.3.1: a more generous snap and 382 pictures with a
> seasonal calendar. 0.3.2: a Pause button, a one-card welcome on first launch (drag, zoom, Help, Pause), help
> notes on zoom and Pause, Tell a friend and Rate in the menu, and a link in the shared result.

**9. How did you decide the app is ready for production?**

> No crashes were reported by any tester (✱ add "or in the pre-launch report" only if the Console shows none), and every problem testers
> raised during the test was fixed in a build they then played. Each build passes an automated self-test that solves
> puzzles, checks the clock, saving and restoring, snapping and the tray, so changes do not break what works.

**10. What did you do differently this time?** This is our first app on Google Play, so there is no earlier attempt;
say so plainly:

> This is our first app, so there was no earlier attempt. What we did on purpose was ship small updates during the
> test: four updates in its first week (0.2.7, 0.2.9, 0.3.1 and 0.3.2), each answering something testers told us,
> rather than one large update at the end.

## Not taken from the report, and why

- **Community forum:** a group needs someone to moderate it; revisit if players ask (decided with Eric 2026-10-11).
- **"Regular content updates / seasonal themes":** already there: 382 pictures on a year-long seasonal calendar.
- **Store screenshots:** worth doing before launch: feature captions over the five phone shots (drag and snap,
  daily, sizes, Help card, no ads). Not done yet.
- **Accessibility:** large type and generous snap are in; no screen-reader work planned (a picture puzzle is visual).
