{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  onEntrypointLoaded: async function (initializer) {
    const runner = await initializer.initializeEngine();
    await runner.runApp();
    document.getElementById('boot-status')?.remove();
  }
}).catch(() => {
  const status = document.getElementById('boot-status');
  if (status) status.textContent = 'AnkiDSA could not load. Check your connection and refresh this page.';
});
