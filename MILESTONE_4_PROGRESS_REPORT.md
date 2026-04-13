Executive Summary
This progress report describes Milestone 4 of the Sampul Mobile Application which is the last major phase before the app is offered to the public through official app stores. Milestone 4 covers finishing remaining features, checking that the whole system works as one product, and completing store submission. The work includes the Extra Wishes Management Module, an analytics and reporting dashboard, final screen design and user experience improvements, full testing and feedback, joining all parts of the system together, User Acceptance Testing (UAT), a final security check, checks that we meet legal and platform rules, and preparing and publishing to the app stores.
This phase rests on work from earlier milestones: main estate planning journeys, post-loss support, connections to outside services such as identity checks and subscriptions. Milestone 4 makes sure these parts work reliably together, stay secure and compliant, and feel polished and consistent for real users.
When Milestone 4 is finished, Sampul should be ready to launch with solid quality, a practical way to measure usage and improvement after go-live, and alignment with Malaysian requirements and each app store’s rules.

Project Overview
The Sampul Mobile Application helps Malaysians with digital estate planning and support after a loss. Milestone 4 is the final stage of the planned build which focuses on wiring everything together, testing at scale, and getting ready for launch, not on adding large new core planning features from scratch.
During this phase, the team checks that sign-in, payments, documents, data movement, and support features all behave correctly when used in real combinations. We try to fix issues during the UAT testing so the problems found in testing are fixed before we submit to the stores. On-screen text and flows are refined so they stay calm, clear, and respectful for people from different backgrounds, in line with Sampul’s voice.
By the end of Milestone 4, we aim for a release-ready build that has passed agreed tests and reviews, with store listings, graphics, and basic monitoring in place so we can keep improving after launch.

Extra Wishes Management Module
Implementation Status: Complete
The Extra Wishes Management Module lets users record additional wishes and preferences alongside their main will and estate details. Users can enter items such as nazar and an estimated cost, fidyah-related details, whether they wish to pledge organ donation, and amounts linked to waqf and charity organisations chosen from a list. Information is saved to the signed-in user’s account.
The feature uses a dedicated service and Supabase storage so each user’s extra wishes load and save securely. The screen guides users through the fields, checks input where needed, and shows clear success or error messages so the task stays as simple as possible during an already sensitive step.
For users, this lowers the chance that important personal or faith-related wishes are never written down. For the product, it adds a clear place for wishes that do not fit standard asset or beneficiary fields, while staying part of the same app structure as the rest of Sampul.

Figure 1: Extra Wishes Management
The extra wishes screen brings optional fields and choices together in one view. Saving writes data to the user’s record. Picking waqf and charity bodies from a list helps keep entries consistent for later use in document flows.

Analytics and Reporting Dashboard
Implementation Status: Complete (core mobile analytics instrumentation and documentation delivered; future enhancement will focus on more mature dashboards and reporting)
We are putting analytics in place so we can understand, at a practical level, how people use the app: which journeys are working well, where people get stuck or leave, and what we should improve next. This is done with privacy in mind. We focus on product usage and avoid collecting sensitive personal details or the content of any messages.

In simple terms, the app records key moments such as visiting important screens and completing steps in core journeys (for example starting or saving a will, starting or submitting a property trust, and moving through checkout and verification). We use these signals to build clear dashboards that help the team prioritise fixes and improvements after launch.

We chose PostHog, which is a product analytics tool, because it fits these needs well: it is designed for product analytics (so it supports clear funnels and dashboards), it gives us control over what we collect, and it can be run in a way that supports our privacy-first approach. It also keeps the team’s reporting consistent across releases, so we can track changes over time without rebuilding the tooling each time.

Future enhancement for this theme is mainly to mature the reporting: agreeing which dashboards matter most for day-to-day operations and product decisions, building and refining those views, and confirming that our analytics set-up matches our privacy policy and each app store’s expectations.

Figure 2: PostHog Dashboard
The PostHog dashboard brings key usage signals into one view (for example how far people get in important journeys), which helps the team prioritise improvements after launch.
![Figure 2: PostHog Dashboard](docs/images/posthog-dashboard.png)

Final UI/UX Enhancement
Implementation Status: Complete (ongoing enhancements)
Final user interface and experience work focuses on making screens feel consistent, easier to use, and polished. Many screens were built or moved over across earlier milestones; this pass strengthens visual consistency, improves empty states and error messages, adds clearer supporting content (such as dedicated images and module information screens), refines home-screen focus (for example making the trust card more prominent), and clarifies navigation (including making the AI chat entry point more visible in the bottom navigation). We also check how the app feels on common phones in Malaysia.
Priority goes to flows that carry the most emotional weight—will steps, post-loss tools, and booking support—so wording and layout support reassurance and clarity. Changes are checked against platform guidance and Sampul’s tone: short labels, plain explanations where the law matters, and no fear-based messaging.
Users get a smoother, more coherent app. The team carries less design inconsistency forward and has a stronger base for new features.

Figure 3: UI/UX Polish (Before and After)
The before-and-after screenshots show the same screen before final polish and after a broader set of improvements (visual consistency, clearer supporting content, and navigation refinements).
![Figure 3a: Before UI/UX Polish](docs/images/uiux-before.png)
![Figure 3b: After UI/UX Polish](docs/images/uiux-after.png)

Final Testing and Feedback
Implementation Status: Planned
Final testing and feedback means running structured tests (new features, regression, and exploratory passes) and collecting input from inside the team and, where useful, from external testers. Plans focus on the paths that matter most: sign-in, profile and verification, subscriptions and billing, the will journey and related areas (including extra wishes), post-loss and support features, and links to third-party services.

We capture feedback in two ways. First, testers record findings during planned sessions (what was expected versus what happened, and how often it occurs). Second, the app includes a “Send feedback” option in Settings so testers can report bugs or request features directly from within the app, while the experience is still fresh.

Issues are then grouped and prioritised by user impact and release risk. Where needed, problems are reproduced and written up clearly so fixes are targeted. Fixes are retested before release so we do not reintroduce earlier issues while addressing new ones. The goal is real fixes and clear severity—not paperwork alone.
This step lowers the risk that serious bugs reach users and makes sure late findings are handled in an orderly way.

Figure 4: In-app Feedback Entry Point (Settings)
The Settings screen includes a “Send feedback” option, which makes it easier for testers to report bugs or request features during UAT and final testing.
![Figure 4: Send feedback in Settings](docs/images/settings-send-feedback.png)

Final System Integration
Implementation Status: Complete (ongoing enhancements)
Final system integration checks that the mobile app, Supabase backend, edge functions, webhooks, and external services behave as one system under realistic use. Tests include full journeys that cross several parts of the system—for example, whether identity verification status correctly affects what a user can do, or whether subscription updates from webhooks show up correctly in the app.

This work also covers newer end-to-end areas that need to feel seamless. For OneSignal push notifications, we have implemented in-app handling for notification receive and open events, and we store a simple in-app notification history. As part of final system integration, we will validate delivery and behaviour across common scenarios (for example when the app is closed, in the background, or already open), and confirm that opening a notification takes users to the right place when notification data is present. We will also confirm that any tracking stays at a high level and does not capture sensitive notification content.

We also include the Learning Resources module as a new part of the app experience in this milestone. It is a dedicated place where users can view Sampul’s uploaded content—videos, podcasts, short clips, and articles. This helps users stay engaged with the app while we steadily build awareness and understanding around Hibah, trust, and wills, using the same content we share on channels such as YouTube.

As part of integration, we will validate that this content is easy to find and view in the app, and that administrators can manage and update it from the app settings with the latest videos and articles for users.

Figure 5: Learning Resources
The Learning Resources page brings Sampul videos, podcasts, short clips, and articles into one place in the app.
![Figure 5: Learning Resources](docs/images/learning-resources.png)


User Acceptance Testing (UAT)
Implementation Status: Ongoing Testing
Milestone 4 includes a structured User Acceptance Testing (UAT) phase using a standard test script and workflow. The purpose is to confirm that Sampul meets agreed “done” expectations in everyday use: features behave correctly, the experience feels consistent, and the app is ready to move from internal testing into store submission.

Over the past week, we have completed an initial round of internal UAT with our team. Findings from this internal testing have been used to make targeted improvements across the app, focusing on usability, flow clarity, and stability.

Once the internal fixes are fully applied and verified, we will open UAT to external testers (stakeholders) to validate the app in broader real-world conditions. After external testing is completed, we will address any remaining changes and retest as needed. Only after this internal + external UAT cycle is complete will we proceed to publish the app to the public.

UAT is executed in a controlled testing environment with assigned test accounts and real devices. Testers follow each test case step-by-step, then compare the actual outcome against the expected outcome. Every case is recorded as **Pass** or **Fail**. If a test cannot be completed, it is recorded as **KIV** (Keep In View) so it remains visible and can be completed later. Any failed cases are documented with a clear reason and supporting screenshots so issues can be prioritised and reproduced quickly.

Testing may begin once entry criteria are met: testers can log in successfully, have valid credentials, the app is installed and running on a real device (not just a simulator), and internet connectivity is available. UAT is considered complete when all test cases have been executed and recorded (Pass/Fail/KIV), all issues have been documented with screenshots where relevant, and the UAT report has been submitted.

In this phase, detailed step-by-step test cases are executed and recorded via a shared UAT Google Sheet template. Testers create their own copy and complete one row per test performed (including actual result, Pass/Fail, and tester comments). This keeps results consistent across testers and makes it easier to consolidate findings.

Figure 6: UAT Results Template (Google Sheets)
The UAT template is used to record each test case outcome (Pass/Fail/KIV), actual results, and tester comments in a consistent format across internal and external testers.
![Figure 6: UAT Results Template (Google Sheets)](docs/images/uat-google-sheet-template.png)

Scope and traceability are defined through a module-based test matrix. The current UAT scope covers **12 modules** and **41 test cases** (TC-01.01 to TC-12.08):
Authentication, Home, Assets, Family, Will, Trust, Hibah, Checklist, Executors, AI Chat, Aftercare, and Settings. This provides coverage across the main user journeys and key supporting features required for launch readiness.

The expected deliverables from UAT are:
- A completed UAT results sheet with outcomes and tester comments for every executed test case
- A module-level summary of outcomes (Passed / Failed / KIV)
- A consolidated list of issues and remarks, with screenshots attached for failures
- Tester and device information (for example device model, OS version, and connectivity) to support reproducibility

UAT outcomes will be reviewed alongside final system integration results, security review findings, and compliance verification to support a clear go/no-go decision for app store submission.

Final Security Review
Implementation Status: Complete (enhancements ongoing)
The final security review focuses on confirming that the app is configured safely for release and that sensitive keys are handled properly. In the current build, external service credentials are loaded through environment configuration (for example Supabase, Stripe, PostHog, and OneSignal), and the app can skip optional integrations when configuration is not present.

On the backend, Supabase Row Level Security (RLS) is used on key tables to help enforce access rules at the database layer. For example, the Learning Resources table uses RLS policies to allow public read access to published items, while restricting create/update/delete actions to admin users.

The review also checks that sign-in and account access behave as expected using Supabase authentication, and that app features which touch payments use the Stripe SDK and the configured checkout/portal flows. Any issues found during this review are recorded and addressed before store submission.

Regulatory Compliance Verification
Implementation Status: Complete (verification completed and documented)
Regulatory compliance verification means checking that the product, how we handle data, and what we tell users on screen match Malaysian requirements and each app store’s policies. This includes privacy notices, consent where needed, how long we keep data and who can access it, and features that involve payments or identity checks.

For will-writing specifically, we are aligning the app experience with Malaysian practice by generating different will document content for Muslim and non-Muslim users. In the current build, the will document output adapts based on the user profile (for example “WASIAT” content for users marked as Muslim, and an English will format for non-Muslim users).

We also verify execution requirements around witnessing and signatures. In the current build, the generated will document includes signature sections and witness sections (including space for witness details and signing). During compliance verification, we confirm that the wording shown in-app and in the document stays clear and accurate—for example the guidance that users should print and sign where needed for physical safekeeping.

For platform compliance, we also align authentication with Apple’s App Store requirements. Because Sampul supports third-party sign-in options, we integrate “Sign in with Apple” so iOS users have Apple’s privacy-focused option available, in line with Apple’s guidelines for apps that offer other third-party login methods. We verify that the Apple sign-in button, user consent flows, and account linking behaviour follow Apple’s Human Interface and review requirements, so submission risk is reduced.

To support store review and user transparency, the Settings screen includes entries for Terms of Service and Privacy Policy that open our policy page, where we explain how Sampul uses and protects data ([Privacy Policy](https://sampul.co/policy)).

Legal or compliance advisors are involved as needed. We keep checklists and evidence on file. Any required wording or flow changes are implemented and checked again.
Clear compliance supports user trust and lowers legal and reputational risk at launch.

App Store Preparation and Deployment
Implementation Status: Complete (iOS TestFlight internal testing live; App Store submission in progress)
We have submitted the iOS build through App Store Connect and enabled TestFlight for internal testing. This puts Sampul into a controlled “release candidate” phase: the build is distributed to approved internal testers through Apple’s official channel, and feedback is gathered while the app stays close to what will be reviewed and released publicly.

Figure 6: TestFlight Builds (App Store Connect)
The TestFlight section in App Store Connect shows multiple builds released for testing. This helps us validate fixes iteratively and ensure each new build is available to internal testers before we expand testing to external stakeholders.
![Figure 6: TestFlight Builds in App Store Connect](docs/images/appstoreconnect-testflight-builds.png)

Internal TestFlight testing is being used to validate real-world readiness on common iPhone devices and iOS versions, not just simulator behaviour. This includes:
- sign-in and account access (email/password and any supported social sign-in),
- onboarding and navigation across the main tabs,
- key document journeys (creating, saving, and editing flows where applicable),
- billing and subscription flows (including any paywall states and post-payment return paths),
- push notification behaviour (receive/open and correct in-app routing),
- performance and stability (cold start, screen load times, crash-free usage),
- accessibility and content clarity (labels, empty states, and error messages staying calm and understandable).

During this phase, we treat internal testing as the final gate before public release. Issues are triaged by impact:
- critical blockers (crashes, login failures, payment failures, data not saving) are fixed immediately and retested,
- high-impact UX issues (confusing steps, unclear messaging, wrong navigation outcomes) are refined so the app feels consistent and safe to use,
- low-risk polish items are recorded for a later patch release if they do not affect launch readiness.

With the submission pipeline in place, the remaining work is focused on completing the App Store review and launch process: ensuring the store listing is complete and accurate (screenshots, description, keywords, categories, and support contact), completing required privacy disclosures, confirming reviewer information (including any demo account details if needed), responding quickly to any review feedback, and choosing a release approach (immediate or scheduled release). This keeps the path to launch practical: test thoroughly, fix what matters, then move forward with confidence.

In parallel, we are preparing for Google Play Store release. This includes getting the Android release build and signing ready for Play Console upload, setting up the right testing track (internal testing first, then closed/open testing if needed), and preparing the Play Store listing details (store description, screenshots, category, and support contact). We are also planning the required Play Console disclosures such as Data Safety and any permissions-related explanations, so the Android release can follow the same controlled, test-first approach as iOS.

Key Achievements (Milestone 4 trajectory)
Milestone 4 is where earlier work is brought together into a release-ready product. The focus has been on completing remaining user-facing modules, tightening the overall experience, and putting the right “launch foundations” in place (testing, feedback capture, analytics, notifications, and store readiness).

One key achievement is the completion of the Extra Wishes Management Module. This gives users a clear place to record wishes that do not naturally fit into assets or beneficiaries, including nazar and estimated costs, fidyah-related information, organ donation preference, and waqf/charity amounts (with organisations chosen from a list to keep entries consistent). It reduces the chance that meaningful personal or faith-related wishes are left unwritten, while keeping the experience structured and calm.

Another major achievement is putting mobile product analytics in place using PostHog. The implementation focuses on practical, privacy-first tracking: capturing high-level usage signals such as important screen visits and step completions across core journeys (for example will, trust, hibah, and checkout/verification), without collecting sensitive personal details or message content. Alongside the instrumentation, documentation has been delivered so tracking remains consistent as the product evolves and so future dashboards and reporting can be matured without rework.

Across the app, UI/UX enhancements have been applied to improve consistency and reduce friction. This includes cleaner navigation, better supporting content, and more consistent screen structure so users can move through emotionally sensitive flows (especially will and aftercare) with less confusion and more reassurance. These improvements are aligned to Sampul’s voice: simple language, clear guidance, and no fear-based messaging.

Milestone 4 also adds “keep users informed and supported” capabilities that matter at launch. Learning Resources has been integrated as a dedicated place to view Sampul content (videos, podcasts, short clips, and articles), helping users build understanding and stay engaged. OneSignal push notification handling has been implemented in-app (receive/open events) and paired with a simple in-app notification history, forming the foundation for reliable notification behaviour and clearer user follow-through in real usage.

To support quality and fast iteration during testing, the Settings screen now includes a “Send feedback” entry point. This makes it easier for testers to report issues while the context is fresh, which improves the usefulness of findings during UAT and final test cycles.

Finally, iOS TestFlight is live and App Store submission is in progress. This means we can test the app on real iPhones and iOS versions, fix any critical issues we find, and confirm the fixes before we launch to the public.

Overall, these achievements strengthen launch readiness by ensuring the app works reliably as one system, feels coherent to users, and has the measurement and feedback loops needed for steady improvement after go-live.

Conclusion
Milestone 4 is the final phase before Sampul is ready for wider release through the app stores. This milestone consolidates key user journeys and adds the practical foundations needed for launch: clearer UX, integrated notifications, learning content, feedback capture, and product analytics instrumentation.

Next, the focus is to complete external UAT, fix and retest the remaining findings, and then complete the final steps of store review and submission.

After go-live, we will keep improving the app step by step. Analytics will show where people move smoothly and where they get stuck. Feedback from users and support will tell us what feels confusing or missing. Together, these will guide the next releases so the app becomes more reliable while staying simple and calm to use.
