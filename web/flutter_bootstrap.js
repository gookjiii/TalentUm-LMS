{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      renderer: "html",
    });
    await appRunner.runApp();
    // Flutter HTML renderer injects user-scalable=no which fails accessibility audit.
    // Patch it out after runApp so Flutter's layout engine has already initialized.
    var flutterViewport = document.querySelector('meta[flt-viewport]');
    if (flutterViewport) {
      flutterViewport.setAttribute('content', 'width=device-width, initial-scale=1.0');
    }
  },
});
