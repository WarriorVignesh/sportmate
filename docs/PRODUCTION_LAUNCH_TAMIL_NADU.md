# SportMate production launch plan — Tamil Nadu

## Product focus
Launch Android first. Position SportMate as a local sports discovery and participation app: find players, create or join teams, discover games, and register for amateur tournaments. Pilot with a limited set of sports and communities before broadening the feature set.

## P0 — security and release safety
- [ ] Rotate the Cloudinary API secret previously committed to this repository.
- [ ] Remove exposed credentials from Git history; deleting the current file does not remove old commits.
- [ ] Use restricted unsigned Cloudinary presets for public client uploads, or generate short-lived signed parameters on a trusted backend.
- [ ] Restrict upload formats, file sizes, folders, and transformations.
- [ ] Review Firebase Authentication, Firestore, Storage, and App Check configuration.
- [ ] Add and test least-privilege Firestore and Storage rules for every collection.
- [ ] Use separate Firebase projects for development and production.
- [ ] Configure Android release signing; never ship with the debug key.

## P1 — core product correctness
- [ ] Standardize the event schema across posts and teamPosts.
- [ ] Store creator UID, sport, start/end timestamps, venue, and validated coordinates.
- [ ] Make event registration idempotent: one registration per user per event, with transaction/backend enforcement.
- [ ] Ensure registration and notifications work for both personal and team events.
- [ ] Implement team follow/unfollow and join requests with server-enforced authorization.
- [ ] Request location only when needed; handle denied permissions gracefully.
- [ ] Add pagination and query limits to feeds, teams, and marketplace.
- [ ] Validate media type and size before upload; handle failures and cleanup.

## P2 — Tamil Nadu MVP
- [ ] Onboarding: sports, district/city, preferred playing radius, and availability.
- [ ] Nearby discovery: sport, distance, date, and event-type filters.
- [ ] Team profiles: captain, roster, joining requests, and privacy controls.
- [ ] Events: create game, invite players, capacity, registration deadline, cancellation.
- [ ] Tournament basics: organizer, participants, fixtures, results, and reporting.
- [ ] Notifications: invitations, join requests, registration confirmations, and event changes.
- [ ] Tamil and English localization; expand languages after validating the initial experience.

## P3 — trust, operations, growth
- [ ] Report/block users and content; moderation queue and admin tools.
- [ ] Privacy policy, terms, community guidelines, account deletion, and data retention process.
- [ ] Firebase Analytics, Crashlytics, performance monitoring, and budget alerts.
- [ ] Play Store listing, data safety declaration, support contact, and closed testing.
- [ ] Pilot in one or two Tamil Nadu communities; measure weekly active players, registrations, repeat participation, and organizer retention.

## Production-ready exit criteria
A release candidate is ready only when a clean release build succeeds; no privileged client secrets remain; Firestore/Storage rules pass emulator tests; auth and account deletion work; event creation and registration are tested across both post collections; location denial does not break the app; upload limits are enforced; and crash reporting plus moderation/support processes are active.

## Audit boundary
This plan follows source-code inspection only. The Firebase project, Cloudinary account settings, security rules, Android release build, and Play Console configuration have not been independently tested.
