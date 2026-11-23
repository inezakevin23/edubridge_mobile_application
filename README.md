# edubridge_mobile_application

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Demo data

The synthetic Firestore dataset is documented in
[`docs/demo_seed_data.json`](./docs/demo_seed_data.json). It contains 7
profiles, 5 open challenges, 6 submissions, and 3 feedback records. The
documents use `demo-` IDs and were created in the confirmed `edubridge-65fb2`
project without overwriting existing documents.

The seed does not create Firebase Authentication users or demo credentials.
The open challenges can be shown in the challenge browser; company and talent
dashboards require signed-in users whose UIDs match the corresponding seeded
company or talent IDs.
