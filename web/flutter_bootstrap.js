// مُحمِّل مخصَّص: يُحمَّل CanvasKit من داخل الحزمة لا من شبكةٍ خارجيّة،
// فتعمل نسخةُ الويب كاملةً دون إنترنت، موافقةً لمبدأ Offline First.
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
