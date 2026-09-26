# Little Light — launch preparation: accounts, website and payments

This is the checklist of things to prepare outside the game itself before Little Light can be sold.
It complements [marketing-and-launch-plan.md](marketing-and-launch-plan.md), which covers the
audience, promotion and the week-by-week plan, and
[five-journey-roadmap.md](five-journey-roadmap.md), which covers the release gate.

Fees, forms and store rules change. Every number below must be checked against the official page
immediately before it is acted on.

## Decisions this plan is built on

| Question | Decision | Why |
|---|---|---|
| What is sold first? | One upfront purchase containing all five journeys | No payment code in the game, simplest store review for a kids' app, most trusted by parents |
| Ages | **5–8 (Band A)** for Volume 1 | Band B (ages 9–12) is not decided or built (`chapter-2-concept.md`). Do not advertise 9–12 until it exists |
| Subscription? | **No** for Volume 1 | A subscription needs a dependable schedule of new content, adds cancellation and trust problems for parents, and is harder to justify for a finished 45–60 minute volume. Revisit only with 10+ journeys and a monthly release rhythm |
| Free version? | Free browser preview (Journey 1) for research and promotion only | A free store app plus an unlock stays a later option if the paid listing converts poorly |
| Ads in the game? | Never | Core product promise and a Kids-category requirement in practice |

### Why a paid-upfront app needs no payment code

When the app itself has a price, Apple and Google charge the parent, handle refunds, collect and pay
sales tax/VAT in most countries, and pay you monthly. The game never sees a card number and needs no
purchase screen. The only work is on the store side: agreements, tax forms and a bank account.

A free app with an unlock would need store billing inside the game (in Godot: the Google Play
Billing plugin on Android and a StoreKit plugin on iOS), a parental gate in front of the purchase,
a **Restore purchases** button, and testing with sandbox accounts. That work is not required for the
first release.

## Step 1 — identity and business basics (do first, takes weeks)

- [ ] **Decide the seller name.** Store listings show the developer's legal name. As an individual,
      that is your personal name. To show a studio name, register a business (a sole
      proprietorship/trade name or a company, depending on your country).
- [ ] **If selling as an organisation:** get a free **D-U-N-S number** (Dun & Bradstreet). Apple
      requires one for organisation accounts and Google requires one for organisation accounts. It
      can take several days to a few weeks.
- [ ] **Open a separate bank account** for store income. It keeps tax records simple.
- [ ] **Find out your local tax obligations** for app income (income tax, and whether you must
      register for VAT/GST yourself). The stores usually collect consumer sales tax, but your own
      income tax is still yours. A one-hour session with a local accountant is worth it.
- [ ] **Check the name "Little Light"** in app stores, trademark databases and domain availability
      before you spend on branding. Have a fallback such as "Little Light: Bible Journeys".
- [ ] **Create a dedicated email address** for the developer accounts and support, for example
      `hello@<your-domain>`.

## Step 2 — developer accounts

### Google Play (launch first)

- [ ] Create a Google Play Console account (one-time registration fee, currently US$25).
- [ ] Complete identity verification.
- [ ] **Closed-testing rule for new personal accounts:** new personal developer accounts must run a
      closed test with a minimum number of opted-in testers for a continuous period (at the time of
      writing, 12 testers for 14 days) before they can publish to production. Your 10–20 pilot
      families are that test group. Plan for them to install it on Android.
- [ ] Set up a **payments profile / merchant account** in Play Console so you can sell a paid app.
- [ ] Complete the **tax information** in the payments profile.
- [ ] Enrol in the **15% service-fee tier** for the first US$1M of earnings each year.

### Apple App Store (launch second)

- [ ] Enrol in the Apple Developer Program (currently US$99 per year).
- [ ] You need a Mac with Xcode to build and upload the iOS export from Godot. A borrowed or cloud Mac
      works if you don't own one.
- [ ] In App Store Connect → **Agreements, Tax, and Banking**: accept the **Paid Apps Agreement**,
      add the bank account, and complete the tax forms. Non-US developers usually submit a
      **W-8BEN** (individual) or **W-8BEN-E** (company) to claim treaty rates.
- [ ] Apply for the **App Store Small Business Program** (15% commission instead of 30%).

Both stores pay out monthly, typically about 30–45 days after the end of the month of sale, once
earnings pass a minimum threshold.

### Optional: itch.io (desktop and web sales)

- [ ] itch.io is free to join. It hosts the free browser preview now, and can later sell a Windows,
      macOS or Linux build with a "pay what you want" minimum. Payouts go through PayPal or Stripe,
      and you choose itch.io's revenue share (default 10%).

## Step 3 — website: yes, build a small one

You do need a website, but a small one. Both stores require a **privacy policy URL**, and Apple
requires a **support URL**. It is also where the trailer, email list and church/homeschool
information live. You do not need a web shop, user accounts or a blog.

**Recommended setup, about US$10–20 per year in total:**

| Part | Recommended | Cost |
|---|---|---|
| Domain | e.g. `littlelightgame.com` from any registrar (Cloudflare, Porkbun, Namecheap) | about US$10–15/year |
| Hosting | **GitHub Pages** from a separate repository, or **Cloudflare Pages**. Both are free static hosting | Free |
| Simpler no-code alternative | Carrd (single page) | Free–about US$19/year |
| Email list | MailerLite or Kit (ConvertKit) free tier; use their embedded signup form | Free up to their free-tier limits |
| Support email | Email forwarding from the domain registrar to your inbox | Free |
| Page analytics | A cookie-free option such as Cloudflare Web Analytics, on the **website only**, never in the game | Free |

**Pages to create:**

1. **Home:** the 15–30 second trailer, the one-line promise ("A gentle, ad-free Bible adventure
   children can play and hear at their own pace"), three trust points (no ads, read aloud, nothing
   leaves the device), the five-journey map, **Play the free preview** and **Join the launch list**.
   After launch the buttons become App Store and Google Play badges.
2. **Privacy policy:** plain language. The game collects no personal data, has no accounts, no
   network access, no ads and no analytics, and child profiles stay on the device. The website's
   email list is for adults only and has its own section. Keep it accurate if anything changes.
3. **Support / FAQ:** contact email, supported devices, how to reset progress, how refunds work
   (through Apple or Google), and which Bible translation is used.
4. **For churches and homeschool groups:** how to use the game with a class, and how to buy several
   copies (see Step 5).
5. **Press kit:** fact sheet, logo, six screenshots, trailer download, short and long descriptions,
   and a contact email.

The website needs a real parent-facing trailer, so build it after the first gameplay capture
(see `promo-production-checklist.md`). A one-page version with the email form can go up earlier.

## Step 4 — store listing assets and declarations

- [ ] App icon at every required size, derived from `icon.svg`.
- [ ] Screenshots for phone and tablet on both stores, from real gameplay.
- [ ] App preview video (Apple) and promo video (Google, a YouTube link).
- [ ] Short and long descriptions, keywords/subtitle, and category (Education or Games → Family).
- [ ] **Google Play:** Families policy declarations, target age group, content rating
      questionnaire (IARC), Data safety form ("no data collected").
- [ ] **Apple:** Kids Category with the age band "5 and under" or "6–8" chosen from playtest results,
      age rating questionnaire, App Privacy details ("Data Not Collected").
- [ ] **Parental gate** in front of any external link (website, support email, store rating) inside
      the grown-ups area. Required for kids' apps on both stores.
- [ ] Signed Android App Bundle (`.aab`) with the upload key backed up in two safe places. **Losing
      the key blocks future updates.**
- [ ] iOS build uploaded through Xcode, tested with TestFlight.

## Step 5 — rights and licences check

Before charging money, confirm you are allowed to sell everything in the build:

- [ ] **Bible text:** the World English Bible (WEB) is public domain. Keep using it or another public
      domain translation unless you license one.
- [ ] **Voices:** the voice clips were generated with a text-to-speech service (`voice-over.md`).
      Confirm that the account plan used allows **commercial use in a sold product**, and keep a
      screenshot of those terms.
- [ ] **Sound effects:** CC0 sources are logged in `assets/audio/CREDITS.md`. Keep logging every new
      clip.
- [ ] **3D models, textures and promotional video:** confirm commercial rights for every AI-generated
      or downloaded asset (models, Higgsfield clips, music).
- [ ] **Godot engine:** MIT licence. Include its licence text in the credits screen or grown-ups
      area.

## Step 6 — pricing and selling to groups

- Test US$4.99 / 6.99 / 7.99 with parents after they watch their child play (see the marketing
  plan). Pick one price and let the stores localise it.
- A **launch discount** (for example 30% off for the first week) gives the email list a reason to buy
  on day one, which helps ranking and early reviews. Both stores support temporary price changes.
- **Churches, schools and homeschool co-ops:** Apple's volume purchasing (through Apple School
  Manager or Apple Business Manager) lets organisations buy many copies of a paid app, often with an
  education discount if enabled. For Android, point groups to a copy per device. Do not sell
  licences or take payment through the website for the store versions. For a desktop classroom
  build, itch.io can sell group copies directly.
- Never direct families from inside the app to pay somewhere else.

## Step 7 — later, only if the data asks for it

| Signal after launch | Option |
|---|---|
| Many store page views, few purchases | Free Journey 1 plus one parent-gated **Full Journey** in-app purchase |
| Families finish and ask for more | Volume 2 as a separate paid app or a bundle, not a subscription |
| Strong demand for older children | Band B (ages 9–12) as a free update or part of Volume 2 |
| 10+ journeys and a reliable monthly release rhythm | Only then evaluate a subscription or "family pass" |

## Official references

- [Google Play Console registration](https://support.google.com/googleplay/android-developer/answer/6112435)
- [Google Play testing requirements for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Google Play payments profile and merchant account](https://support.google.com/googleplay/android-developer/answer/7161426)
- [Google Play Families policies](https://support.google.com/googleplay/android-developer/answer/9893335)
- [Apple Developer Program enrolment](https://developer.apple.com/programs/enroll/)
- [Apple App Store Small Business Program](https://developer.apple.com/app-store/small-business-program/)
- [Apple Kids Category and parental gates](https://developer.apple.com/kids/)
- [Apple volume purchasing](https://support.apple.com/guide/apple-business-manager/intro-to-apps-and-books-axmb19317543/web)
- [Godot: exporting for Android](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
  and [iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
