(() => {
  const body = document.body;
  if (!body) return;

  // Remove the splash state after a short intro sequence.
  window.requestAnimationFrame(() => {
    window.setTimeout(() => {
      body.classList.add("is-ready");
    }, 900);
  });
})();
