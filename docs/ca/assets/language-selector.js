(function () {
  "use strict";

  const storageKey = "aucoop-docs-language";
  const supportedLanguages = new Set(["en", "es", "fr", "ca"]);

  function languageCode(value) {
    return String(value || "").toLowerCase().split("-")[0];
  }

  const alternateUrls = new Map();
  document.querySelectorAll('link[rel="alternate"][hreflang]').forEach(function (link) {
    const language = languageCode(link.getAttribute("hreflang"));
    if (supportedLanguages.has(language)) alternateUrls.set(language, link.href);
  });

  document.querySelectorAll("a[hreflang]").forEach(function (link) {
    link.addEventListener("click", function () {
      const language = languageCode(link.getAttribute("hreflang"));
      if (!supportedLanguages.has(language)) return;
      try {
        localStorage.setItem(storageKey, language);
      } catch (_error) {}
    });
  });

  if (languageCode(document.documentElement.lang) !== "en") return;
  const englishHome = alternateUrls.get("en");
  if (!englishHome) return;

  function normalizedPath(pathname) {
    return pathname.replace(/index\.html$/, "").replace(/\/*$/, "/");
  }

  const currentUrl = new URL(window.location.href);
  const englishHomeUrl = new URL(englishHome, currentUrl);
  if (normalizedPath(currentUrl.pathname) !== normalizedPath(englishHomeUrl.pathname)) return;

  let preferredLanguage = "";
  try {
    const savedLanguage = languageCode(localStorage.getItem(storageKey));
    if (supportedLanguages.has(savedLanguage)) preferredLanguage = savedLanguage;
  } catch (_error) {}

  if (!preferredLanguage) {
    const browserLanguages = navigator.languages && navigator.languages.length
      ? navigator.languages
      : [navigator.language];
    preferredLanguage = browserLanguages.map(languageCode).find(function (language) {
      return supportedLanguages.has(language);
    }) || "";
  }

  if (!preferredLanguage || preferredLanguage === "en") return;
  const destination = alternateUrls.get(preferredLanguage);
  if (destination) window.location.replace(destination);
})();
