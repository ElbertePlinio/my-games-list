# Privacy Policy

NOTICE — The Brazilian Portuguese version is the legally authoritative text; this English version is provided for convenience.

Version: 2026-06-22

Effective date: June 22, 2026

This Privacy Policy describes how Picklog ("the app", "the service", "we", "us") collects, uses, shares, and protects your personal data, in accordance with Brazilian Law No. 13.709/2018 (the General Data Protection Law, "LGPD"). By creating an account and using the service, you acknowledge the practices described here.

## 1. Who is the data controller

The controller of the personal data processed in Picklog is **Elberte Plínio**, an individual. Picklog is maintained by a natural person, not by a company; the LGPD (Art. 5, VI) expressly allows the controller to be an individual.

The controller is the party responsible for the decisions regarding the processing of your personal data.

## 2. Data Protection Officer (DPO)

To exercise your rights or to ask questions about the processing of your personal data, contact the Data Protection Officer (Encarregado):

- Data Protection Officer (DPO): **Elberte Plínio** — **games@elberte.com**

The DPO is the point of contact between you, the controller, and the Brazilian National Data Protection Authority (ANPD).

## 3. What personal data we collect

We collect only the data needed to operate the service. We do not sell your personal data.

Identification and account data:

- Email address.
- Username.
- Social authentication provider identifier (firebase_uid) and the provider used (email, Google, or Apple), when you choose social login.

Authentication and session data:

- Password, stored only as a cryptographic hash (bcrypt); we never store your password in plain text.
- Session tokens, stored as a hash (SHA-256), with creation, last-access, and expiration timestamps.

Consent data:

- The version of the legal documents you accepted (consent_version) and the date and time you accepted them (consent_accepted_at).

Notification data:

- Push notification token (fcm_token), when you enable notifications on your device.

Your game library data (behavioral data):

- Games added to your library and the status assigned to each (planned, playing, on hold, finished, dropped).
- Score or rating assigned to a game.
- Recorded playtime.
- Start and end dates.
- Stated difficulty, favorite flag, and free-text personal notes.

We do not intentionally collect sensitive personal data (such as racial origin, religious belief, political opinion, health data, or biometrics). Please do not include such information in your free-text notes.

## 4. Why we use your data and on what legal basis

We process your personal data for the purposes below, always under a legal basis of the LGPD (Art. 7):

- To create, authenticate, and secure your account. Legal basis: performance of a contract (Art. 7, V).
- To store and display your game library and your ratings. Legal basis: performance of a contract (Art. 7, V).
- To record and prove the consent you gave to the legal documents. Legal basis: compliance with a legal and regulatory obligation (Art. 7, II).
- To send service-related push notifications when you enable them. Legal basis: consent (Art. 7, I), which can be withdrawn at any time.
- To ensure security, prevent fraud and abuse, and operate the infrastructure. Legal basis: legitimate interest (Art. 7, IX).
- To diagnose errors and service stability through technical reports. Legal basis: consent (Art. 7, I). These reports are sent to Firebase Crashlytics only with your explicit consent and may contain technical context about the failure (such as error messages, stack traces, device model, and app version). You can decline or withdraw this at any time in the consent settings.

## 5. Sharing and processors

We do not sell your personal data. We share data only with processors that handle it on our behalf and to the extent necessary for the service to work:

- Google and Firebase: used for authentication (social login with Google and Apple) and for sending push notifications (Firebase Cloud Messaging). When you use social login, we receive from the provider the identifier, email, and name associated with the account.
- IGDB (Internet Game Database): used as the source of the game catalogue (names, covers, release dates, and platforms). Queries to IGDB concern catalogue games; we do not send your personal data or your library data to IGDB.
- Firebase Crashlytics (Google): used, only with your explicit consent, to record app crashes and errors in order to diagnose service stability. These reports may contain technical context about the failure.

## 6. International data transfer

Some processors (such as Google, Firebase, and IGDB) may process data on servers located outside Brazil. In such cases, the international transfer takes place in accordance with Art. 33 of the LGPD, under adequate data protection safeguards and limited to the purposes described in this Policy.

## 7. How long we keep your data

- Account, consent, and library data: kept while your account is active.
- Sessions: kept until the token expires, until logout, or until account deletion.
- Push notification token: kept until updated, removed by you, or until account deletion.

When you delete your account, the associated data (account, sessions, and library) is permanently and cascadingly erased. We may retain records strictly necessary to comply with a legal obligation or to exercise rights, for the period required by law.

## 8. Your rights as a data subject

Under the LGPD (Art. 18), you have the right to:

- Confirmation that processing exists and access to your data.
- Portability and export of your data, available in the app under Settings (a complete export of your account and library in a machine-readable format).
- Correction of incomplete, inaccurate, or outdated data.
- Erasure of your data and deletion of your account, available in the app under Settings (permanent, cascading deletion).
- Withdrawal of consent. You can disable push notifications at any time. Because the record of consent to the legal documents is tied to the existence of your account, the way to broadly withdraw that consent is to delete your account.
- Log out at any time. When you log out, we remove your credentials from this device (we delete the stored token and clear the authentication header); the access token expires on the server after its validity period.
- Information about the entities with which we share data, as described in this Policy.

To exercise any right that is not available directly in the app, contact the DPO listed in section 2.

## 9. How we protect your data

We adopt technical and administrative measures to protect your data, including:

- Traffic protected by TLS (HTTPS) in production.
- Passwords stored only as a bcrypt hash.
- Session tokens stored only as a SHA-256 hash; the original token is never written to our servers.
- Signed access tokens (JWT) with expiration and session validation.
- HTTP security headers, request rate limiting, and request timeouts.
- Database connection protected by TLS in production.

No system is completely immune to risk; we work continuously to mitigate it.

## 10. Cookies and identifiers

The app does not use advertising cookies or third-party trackers. We use strictly technical and necessary identifiers, such as authentication tokens and the push notification token, to operate the service.

## 11. Children's data

The service is not intended for anyone under 18 without the consent and supervision of a parent or legal guardian. We do not intentionally collect children's data. If we learn that we have collected data from a child without proper authorization, we will delete that information. If you are a guardian of a minor and believe they provided us with data, contact the DPO.

## 12. Changes to this Policy

We may update this Privacy Policy to reflect changes to the service or to the law. When a change is material, we will update the version and effective date shown above and ask for a new acceptance in the app, recording the accepted version. We recommend reviewing this document periodically.

## 13. Contact

For questions, requests, or complaints about the processing of your personal data, contact the DPO listed in section 2. You also have the right to lodge a complaint with the Brazilian National Data Protection Authority (ANPD).
