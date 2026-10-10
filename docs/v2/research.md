# V2 research: the solo home tutor in India

Written 2026-10-10 for the V2 brainstorm, before any spec. Six research threads ran in parallel (the tutor's reality,
curriculum and school supply, competition, AI capability and languages, learning science and measurement, growth and money).
Every claim carries its source; "thin" at the end of each section says what could not be verified. Read with
`docs/spec.md` (V1) and `docs/reference/functional-inventory.md` (the V1 contract).

The customer V2 is for, in the owner's words (2026-10-10): one person who teaches, 10 to 15 school children, often from
different classes (1 to 7, sometimes 8 to 10) in the same evening slot, all subjects for the younger ones. Not a centre.
The product must take the least possible of the tutor's time and headspace, tell them what to do, give them the tools,
and do the hard work with AI under the covers.

## 1. The customer

- **Tuition is normal.** 27% of Indian students take private coaching (urban 31%, rural 26%); household spend ₹3,988 a
  year per urban student ([NSS CMS:E 2025, PTI](https://www.tribuneindia.com/news/india/one-third-school-students-take-private-coaching-trend-more-common-in-urban-areas-centres-survey)).
  Rural paid tuition in classes 1 to 8 rose from 26% (2018) to 31% (2022) ([ASER 2022](https://img.asercentre.org/docs/ASER%202022%20report%20pdfs/aser2022pressrelease_english_january18final_prathamletterhead.pdf)).
  Karnataka's rural tuition is low and falling (6 to 12%); the market there is urban Bengaluru ([ASER 2024 annexure 3](https://asercentre.org/wp-content/uploads/2022/12/Annexure_3.pdf)).
- **How many tutors.** No official count. "Five lakh home tutors" is a 2015 industry guess ([The Week](https://www.theweek.in/theweek/business/great-indian-tuition-boom.html));
  UrbanPro claims 7.5 lakh tutors and institutes ([UrbanPro 2025](https://www.urbanpro.com/urbanpro-in-numbers-2025)).
  Private tutoring market USD 4.4 bn in 2025 ([IMARC](https://www.imarcgroup.com/india-private-tutoring-market)).
- **How they work.** Batches of 5 to 12 for about 90 minutes, two or three batches a day for the experienced
  ([Jobipo 2026](https://jobipo.com/blog/tuition-teacher-kese-bane)). Group fees at the tutor's home, all subjects:
  ₹1,500 to 2,500 a month per child for classes 1 to 8 ([UrbanPro](https://www.urbanpro.com/tuition-fee/how-much-fees-should-i-set-for-teaching-class),
  [Bengaluru](https://www.urbanpro.com/tuition-fee/what-is-the-tuition-fees-like-for-i-v-stds)). So a tutor with 12 children
  earns roughly ₹20,000 to 35,000 a month. The software budget is small; the product sells time, not revenue.
- **Boards in Bengaluru schools:** 61% state board, 17% CBSE, 9% ICSE ([UDISE+ via aggregator](https://getschoolsinfo.com/schools-in-bengaluru)).
  The Karnataka state syllabus is the majority, not an afterthought.
- **Their phones and tools.** 98% of teachers own a smartphone; WhatsApp 71%, YouTube 61%, Google 53%; communication is
  the top use; 45% of EdTech-using teachers already use generative AI ([CSF Bharat Survey for EdTech 2025](https://www.edtechbase.centralsquarefoundation.org/factsheets/Tamil%20Nadu%20Factsheet.pdf));
  70% of 5,000 surveyed educators use AI, mostly for lesson planning ([CENTA via South First, Aug 2025](https://thesouthfirst.com/news-in-brief/70-of-indian-teachers-using-ai-in-classrooms-centa-survey-reveals/)).
  An AI worksheet is therefore expected, not novel.
- **How they get students.** Word of mouth, neighbours, apartment and school WhatsApp groups, a free demo; UrbanPro's
  paid leads are resented ([UrbanPro Q&A](https://www.urbanpro.com/class-ix-x-tuition/how-to-get-students),
  [Coimbatore Junction](https://coimbatorejunction.in/tuition/guides/how-to-get-tuition-students-coimbatore/)).
- **Pains documented in their words:** endless WhatsApp groups ([Hashnode 2025](https://hashnode.com/tag/tuition-centre-parent-app)),
  chasing parents for payment screenshots ([Simtrain](https://blog.simtrainsystem.com/)), parents judging by marks
  ([Yale Globalist](https://globalist.yale.edu/?p=1020)), fees rising before exams. The owner's list (material across
  grades, weak in a higher-grade subject, not knowing the school's exams, parents not forwarding, explaining hard
  concepts) found no written source: Reddit and Quora blocked fetching. It stands on the owner's observation and
  should be confirmed with the Phase 9 tutors.

Thin: tutor headcount, Bengaluru tuition incidence, mixed-grade practice, churn, iPhone share among tutors.

## 2. What the schools and boards supply

- **Textbooks are free to read, not free to ship.** NCERT textbooks are CC BY-NC-ND on DIKSHA ([DIKSHA](https://diksha.gov.in/about-us/)):
  no commercial use, no derivatives. NCERT's 2024 advisory threatens Copyright Act action for commercial publication
  ([Careers360](https://news.careers360.com/ncert-warns-publishers-against-copyright-infringement-of-school-textbooks-educational-materials/amp)),
  and its online-textbook notice forbids use in "digital content packages or software" (quoted by search; the page itself
  could not be fetched). Karnataka's textbooks are PDFs at [textbooks.karnataka.gov.in](https://textbooks.karnataka.gov.in/)
  for LKG to 10 in six media, with no licence shown, so all rights reserved. ICSE prescribes no textbooks; schools pick
  Selina or Frank, fully copyrighted. NCERT Exemplar and CBSE sample papers carry the same copyright.
- **What is safe:** syllabus facts. Chapter names, topics, learning outcomes and exam blueprints are not copyrightable.
  V2 keeps its own structured chapter list per board, class, subject and edition, built from the PDFs, and generates
  original material against it. No textbook text is stored, cached or embedded.
- **Edition matters.** NCF-2023 books: classes 1 to 8 new; class 9 new from 2026-27; classes 10 and 11 old in 2026-27, new
  in 2027-28 ([Deccan Herald](https://deccanherald.com/education/new-ncert-books-for-class-9-from-this-year-classes-10-11-to-follow-soon-3935977)).
  Every chapter list carries its edition year.
- **Two calendars.** CBSE and ICSE run April to March; class 10 CBSE now sits two board exams, February (mandatory) and May
  (optional) ([The Week](https://www.theweek.in/wire-updates/national/2025/06/25/del73-cbse-board-exams.html)).
  Karnataka 2026-27 opened 29 May, Dasara 3 to 21 October, term 2 to 10 April ([Asianet](https://newsable.asianetnews.com/karnataka-news/karnataka-schools-to-reopen-on-may-29-for-2026-27-session-government-releases-academic-calendar-articleshow-7vcgryv));
  FA1 July, FA2 August, SA1 September (board-set papers for 8 to 10), FA3 November, FA4 January, SA2 March
  ([a school calendar](https://rvghs.edu.in/academic_calendar/)); SSLC in March and May.
- **Exam dates below class 10 come from the school, not the board.** No common date sheet exists for periodic tests.
  WhatsApp class groups are the default channel; diaries and circulars the older layer ([Softwarewale 2026](https://www.softwarewale.in/blogs/indian-schools-whatsapp-groups-cost-school-management-app)).
  The tutor's input is a forwarded message or a photo of a timetable or portions. "Paste or photograph what the school
  sent" is the capture, not a board feed.
- **Languages.** Hinglish dominates Hindi speakers online; 58% prefer Hindi in Latin script, 13% Devanagari
  ([Milestone survey](https://www.milestoneloc.com/hinglish-report-pr/)). Karnataka is adding English-medium sections to
  4,134 government primaries because parents leave for lack of English ([Careers360](https://news.careers360.com/karnataka-decides-start-english-medium-classes-in-4134-government-primary-schools/amp)).
  Safe defaults for parent messages: English and Hinglish, Kannada offered in Karnataka.

Thin: the exact NCERT notice text, Karnataka Textbook Society terms, FA/SA weights, school-app market share, direct
evidence of parents forwarding timetables to tutors.

## 3. What AI can honestly do

- **Explanations and practice:** good in English and Hindi, with the tutor reading before use. Indic benchmarks put every
  Indian language well behind English; on IndicParam (late 2025) Gemini 2.5 scored 55%, GPT-5 45%, Claude 4.5 42%
  ([arXiv 2512.00333](https://arxiv.org/pdf/2512.00333)). Kannada, Tamil and Telugu are good enough for a parent
  message, less certain for a child's lesson. Romanised Hindi needs an explicit instruction; models drift to Devanagari
  ([arXiv 2601.07153](https://arxiv.org/pdf/2601.07153)).
- **Visual explainers:** free-form generated pictures and animations fail on labels and silent geometry
  ([Math-Vision Diagrams 2026](https://arxiv.org/pdf/2608.08964), [ManiBench](https://arxiv.org/html/2603.13251v1));
  diffusion images misspell labels, which teaches a child something false ([CAGE 2026](https://arxiv.org/pdf/2604.09691)).
  What works: templates per concept type (number line, fraction bar, unit circle, labelled cell), SVG from computed
  coordinates with programmatic checks, a vision pass over the render, and vetted simulations over generation.
- **Free resources we may use:** PhET simulations, CC BY 4.0 with an exact attribution line, commercial use allowed for
  sims published before 2026-03-29 ([PhET licensing](https://phet.colorado.edu/en/licensing/html)); Wikimedia Commons
  diagrams per file licence. Not usable in a paid app without an agreement: GeoGebra ([licence](https://www.geogebra.org/license)),
  Desmos ([terms](https://desmos.com/terms)), Khan Academy videos (CC BY-NC-SA; linking is fine), CK-12. YouTube only
  through its own player in a web view ([YouTube terms](https://developers.google.com/youtube/terms/required-minimum-functionality)).
- **Marking from a photo:** 2026 vision models reach about 98% on handwritten exam answers when the reference solution
  is supplied ([arXiv 2606.11477](https://arxiv.org/pdf/2606.11477)). A draft the tutor confirms, with the key given.
- **Claude in 2026:** Sonnet 5.5 $2/$10, Opus 5.5 $4/$20, Haiku 5.5 $0.10/$0.50 per million tokens; cache reads $0.20;
  PDFs to 600 pages; structured outputs; one-hour cache fits a per-chapter context. Apple's on-device models: English
  only, no Indian language in iOS 26 or 27 ([Apple](https://support.apple.com/en-in/121115)).
- **Speech:** Google Cloud has 46 Hindi and 38 Kannada voices; Sarvam Bulbul covers 11 languages; Apple's Kannada voice
  is unconfirmed.

Thin: PhET's Hindi and Kannada sim counts and its post-March-2026 terms, a 2026 Claude Indic benchmark, Bhashini's terms.

## 4. What moves learning, and how to measure it cheaply

- **Tutoring works when structured and frequent.** Pooled effect 0.29 to 0.37 SD, larger for early grades and three or
  more sessions a week ([Nickow, Oreopoulos, Quan](https://www.nber.org/papers/w27476)); Bloom's two sigma is an outlier
  ([Education Next](https://www.educationnext.org/two-sigma-tutoring-separating-science-fiction-from-science-fact/)).
  Loose, low-dose tutoring at scale yields little ([UK NTP](https://nfer.ac.uk/publications/independent-evaluation-of-the-national-tutoring-programme-year-2-impact-evaluation)).
  Effectiveness drops above six or seven per group ([EEF](https://dera.ioe.ac.uk/id/eprint/40911/1/Tutoring_Guide_2022_V1.2.pdf)):
  a 12-child mixed batch must run as two or three level groups.
- **Group by level, not age.** Teaching at the Right Level: 0.70 SD in UP camps ([Banerjee et al.](https://www.nber.org/papers/w22746)).
  Mindspark's Delhi sample was 2.5 grades behind in class 6, 4.5 in class 9, with a five-grade spread inside one class;
  adaptivity at the child's level gave 0.36 SD in maths in four and a half months ([NBER w22923](https://www.nber.org/papers/w22923)).
- **Practices that fit 90 minutes:** spacing (g 0.74), worked examples (0.48, novices), interleaving (0.42), feedback
  (0.48), mastery units under 12 weeks (0.52), retrieval practice (consistent). Homework: 0.15 in primary, 0.64 in
  secondary ([Hattie via teacherhead](https://teacherhead.com/2012/10/21/homework-what-does-the-hattie-research-actually-say/)).
  So: homework light for classes 1 to 5, substantive for 6 to 10; class time is retrieval, worked examples, feedback.
- **AI in the loop works when scaffolded and supervised:** 0.63 SD with pre-written solutions and per-question prompts
  ([Harvard, Sci Rep 2025](https://pmc.ncbi.nlm.nih.gov/articles/PMC12179260/)); 0.31 SD teacher-supervised in Nigeria
  ([World Bank](https://openknowledge.worldbank.org/entities/publication/15e1ff08-15ae-4f7a-b2a8-d146e6c113ee));
  unguided chatbot use is null; Khanmigo saw two to five minutes a week of use.
- **Parents.** Child-specific effort messages move outcomes: course failures down 39%, attendance up 17%
  ([Bergman & Chan](https://www.povertyactionlab.org/print/pdf/node/2353?lang=en)); three a week beats one and five;
  weekends help less-educated parents; personalised beats generic ([World Bank](https://blogs.worldbank.org/impactevaluations/some-evidence-based-practical-tips-designing-text-based-parenting-programs)).
  Generic nudges backfire ([Ghana](https://diposit.ub.edu/dspace/bitstream/2445/205763/1/E24-461-Aurino%2BWolf.pdf));
  SMS alone was null in Botswana, SMS plus a short weekly call gave 0.12 SD. The tutor is the human touch; the app drafts.
- **Measuring with taps, not typing.** A placement ladder on joining (ASER-style reading and arithmetic for classes 1 to
  5 ([ASER tasks](https://asercentre.org/wp-content/uploads/2022/12/ASER-2024-assessment-tasks.pdf)); NCERT learning
  outcomes per class for 6 to 10 ([NCERT 2017](https://cprindia.org/wp-content/uploads/2023/04/Learning-Outcomes-at-the-Elementary-Stage-2017.pdf)));
  a mastery grid per skill; a three-question exit check per child per session (one from today, two spaced), tapped right
  or wrong; attendance and homework as pills; school marks from a photo of the report. The app computes the gap in
  grade levels, the accuracy trend, absences over four weeks, homework streaks, and says "not on track" with the next
  move: re-teach with a worked example, drop to the prerequisite, add to the spaced queue.
- **An honest promise.** The evidence supports "measurable progress you can show the parent" and "a tenth of the
  preparation time". It does not support "ten times better marks". The product should claim the first two.

Thin: no RCT on mixed-grade groups of 10 to 15; Karnataka FA/SA weights; Mindspark's scale-up results.

## 5. The market

| Who | For | Price | AI | Where it leaves the solo tutor |
|---|---|---|---|---|
| Classplus | Institutes wanting a branded app | about ₹20,000 to 32,000 a year (aggregator) | None found | Built for institutes; complaints of hidden add-ons ([Voxya](https://voxya.com/company/classplus-complaints/1248572)) |
| Teachmint | K-12 schools since 2023 | from $5 a user a year | EduAI: quiz, homework, recap | Discontinued its tutor products ([Entrackr](https://entrackr.com/?p=166343)) |
| Tuition Plus, Tufee, TutorPe | Home tutors | Free | None | Tiny, Android-first, no traction |
| MagicSchool | Teachers (US) | Free; Plus $12.99 a month | 80+ generators | A menu; most used are rewriter, quiz, worksheet ([MagicSchool](https://www.magicschool.ai/blog-posts/most-used-classroom-ai-tools-2025)) |
| Brisk, Diffit, Eduaide | Teachers (US) | $50 to 150 a year | Generators in Docs | US standards first |
| Khanmigo for Teachers | Teachers, free in India in Hindi and English | Free | Activities | No roster, no India boards; students US only |
| Gemini for Education | Google Workspace schools | Free | Quizzes, JEE mocks | Institutional; India leads its education use |
| PhysicsWallah, Doubtnut, Filo | Students | Free to paid | Doubt engines | Student-facing, not tutor-aware |
| UrbanPro, Superprof | Tutors seeking students | ₹799 to 6,900 coins and passes | None | Paid leads, resented |

The India App Store Education chart on 2026-10-10 is spoken-English AI apps and institute white-labels; no tutor-side
product appears above position 15 ([Apple](https://apps.apple.com/in/charts/iphone/education-apps/6017)).

**White space, from the map:** nothing watches a tutor's own roster and says what to do next with the artefact ready;
every AI tool is a blank-prompt generator; none is board-specific for Indian school children in Indian languages; none
closes the loop to the parent; the moat is workflow and the tutor's data, not the model, since Khanmigo and Gemini are
free in India.

Thin: Classplus's current price, Winuall's status, the paid chart.

## 6. Growth and money

- **iPhone only is a sliver.** Apple shipped 14 million phones in India in 2025, 9% of units, 28% of value
  ([TechCrunch](https://techcrunch.com/2026/01/23/apple-iphone-just-had-its-best-year-in-india-as-the-smartphone-market-stays-broadly-flat));
  iOS is 6 to 7% of mobile web traffic ([StatCounter](https://gs.statcounter.com/os-market-share/mobile/india)).
  No survey of teachers' or tutors' phones exists. iPhones are 65% of refurbished sales and iPhone 11 and later run iOS 26
  ([Business Today](https://www.businesstoday.in/technology/news/story/indians-are-buying-pricier-refurbished-phones-iphones-are-leading-the-trend-552697-2026-09-02)),
  so the reachable tutor is urban, English-comfortable, and able to pay. That fits a sharp wedge and pricing power; it
  does not fit "many solo tutors". Android is a when. Every parent-facing surface should be a WhatsApp message, a link or
  a PDF, which is platform-neutral already.
- **How tutor apps grew.** Teachmint reached 120,000 tutors in five months on negligible marketing: teachers heard from
  friends and shared classroom links on WhatsApp ([YourStory](https://yourstory.com/2020/10/teachmint-funding-lightspeed-ventures-better-capital-titan-edtech/amp)).
  Classplus's outbound sales model did not survive at tutor price points ([Inc42](https://inc42.com/features/classplus-flips-its-edtech-playbook/)).
  The loop for V2: every sheet, note and report a parent receives carries the tutor's name and "Made with Tutor Central".
- **Price.** ChatGPT Go is ₹399 a month in India, Plus ₹1,999; Canva Pro about ₹4,000 a year; MagicSchool Plus $8.33 a
  month annual. Apple In-App Purchase in India takes UPI Autopay; a subscription for software must go through IAP
  (guideline 3.1.1; no India external-link entitlement) at 15% under the Small Business Program. A sketch: free tier with a
  small monthly allowance; ₹499 a month or ₹3,999 a year.
- **AI cost per tutor.** For 15 children with a weekly homework sheet, practice set, parent note and three explanations
  each: all Opus about ₹770 a month (unsellable); all Sonnet with caching about ₹300; Haiku for routine sheets and notes
  with Sonnet for exam prep and explanations, cached and capped, about ₹110, which holds a 70% margin at ₹499.
  Per-child batching (one call makes the sheet, the set and the note) cuts input by about a third.
- **Children's data.** DPDP Act 2023 section 9: verifiable parental consent for under-18s, no tracking or behavioural
  monitoring of children; rules notified 2025-11-14, the children's duties start 2027-05-14
  ([AMSS](https://www.amsshardul.com/insight/enforcement-of-the-dpdp-act-and-notification-of-the-dpdp-rules/)).
  Whether a solo tutor is an exempt "educational institution" is unsettled. Practical: the app records a parent's consent
  per child (phone, time), keeps names and marks only for teaching, runs no analytics on children, exports and deletes
  on request. 77% of surveyed parents prefer a one-time consent flow. Apple: not the Kids category; guideline 5.1.4(b)
  still applies.

Thin: Apple's INR tiers, Teachmint's current tutor price, token estimates per artefact, the Fourth Schedule question.

## 7. What this means for V2

1. **The product is the plan, not a menu of tools.** The home screen is tonight's batch: which children, in which level
   groups, what each does, with the sheet, the worked example and the explainer already made. Tools are pulled by the plan,
   never browsed.
2. **The tutor never types.** Inputs are forwards (the school's WhatsApp message), photos (a timetable, a diary page, a
   marked paper, a report card) and taps (came, right or wrong, homework given). One question a day at most.
3. **The record is the asset.** Per child: board, school, class, edition, chapters taught, skills secure, exit-check
   trend, marks, absences, homework. Everything AI makes is made against it. This is the moat the free models cannot
   copy.
4. **Group by level.** The app proposes the two or three groups for the batch from the record, across grades.
5. **Explain it, honestly.** Worked examples and a tutor's five-minute brief on a chapter they are weak in; visuals from
   templates and computed SVG with checks; PhET sims with attribution; nothing free-form, nothing that can mislabel a
   diagram.
6. **The parent hears child-specific facts, at most three times a week, in their language, after the tutor reads it.**
   Hinglish and English first, Kannada in Karnataka. Every message is forwardable and carries the tutor's name.
7. **Measure with taps.** Placement on joining, exit checks, marks from photos. "On track" or "not on track" with the
   reason and the next move. Claim measurable progress and a tenth of the preparation time, never ten-times marks.
8. **Own the syllabus facts, not the books.** Chapter lists per board, class, subject and edition, built by hand from
   the PDFs: Karnataka state first for Bengaluru, then CBSE, then ICSE by publisher. No textbook text stored.
9. **Exam prep runs from the school's own dates.** Two target dates for class 10. A revision plan, daily sets, a mock in
   the school's pattern, marking from a photo, a gap report.
10. **V1 stays as the spine:** students, attendance (now the session's trigger), fees (the sharpest documented admin
    pain), WhatsApp links, the API and consent. The admin surface recedes behind the plan.
11. **Price flat and visible, through IAP, around ₹499 a month;** AI routed by job (Haiku routine, Sonnet for exam prep
    and explanations); a monthly cap.
12. **iPhone first is a wedge, not the market.** Decide Android at a number of paying tutors; keep every parent surface
    platform-neutral until then.
13. **Consent per child from the first version,** ahead of May 2027.

## 8. To confirm with the Phase 9 tutors

The owner's list of pains (material across grades, weak subjects, school exam visibility, parents not forwarding,
explaining hard concepts) found no written source. Six questions to ask them, on WhatsApp, before the spec is final:
how many classes and boards are in one batch; how they learn a school test is coming; how long they spend preparing a
week; which chapter they dread; what they send parents today and in which language; what they would pay a month.
