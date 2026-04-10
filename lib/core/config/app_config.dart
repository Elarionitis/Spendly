/// Global configuration flag.
///
/// Build with:
/// - Demo mode: `--dart-define=SPENDLY_MODE=demo`
/// - Firebase mode (default): `--dart-define=SPENDLY_MODE=firebase`
const String appMode = String.fromEnvironment(
	'SPENDLY_MODE',
	defaultValue: 'firebase',
);

/// True when repositories run fully in-memory with seeded demo data.
const bool useDemoMode = appMode == 'demo';

/// True when Firebase/Firestore/Auth/Storage backed repositories are enabled.
const bool useFirebaseMode = !useDemoMode;
