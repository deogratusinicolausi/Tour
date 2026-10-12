// ⭐ Conditional import — inachagua file kulingana na platform
export 'web_tts_stub.dart'
if (dart.library.js_interop) 'web_tts.dart';