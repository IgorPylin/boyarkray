(function () {
  "use strict";

  var PHONE = "+79031220036";
  var PHONE_DISPLAY = "+7 903 122-00-36";
  var ROUTE_URL =
    "https://yandex.ru/maps/?text=" +
    encodeURIComponent("Химки, Калинина, 7");

  /* Replace with your Yandex Metrika counter ID before publishing */
  var YANDEX_METRIKA_ID = null;

  function trackEvent(eventName) {
    if (typeof ym === "function" && YANDEX_METRIKA_ID) {
      ym(YANDEX_METRIKA_ID, "reachGoal", eventName);
    }
    if (typeof gtag === "function") {
      gtag("event", eventName);
    }
  }

  function initMobileMenu() {
    var menuBtn = document.getElementById("menu-btn");
    var mobileNav = document.getElementById("mobile-nav");
    if (!menuBtn || !mobileNav) return;

    menuBtn.addEventListener("click", function () {
      var isOpen = mobileNav.classList.toggle("is-open");
      menuBtn.setAttribute("aria-expanded", String(isOpen));
    });

    mobileNav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", function () {
        mobileNav.classList.remove("is-open");
        menuBtn.setAttribute("aria-expanded", "false");
      });
    });
  }

  function initAnalytics() {
    document.querySelectorAll("[data-event]").forEach(function (el) {
      el.addEventListener("click", function () {
        var eventName = el.getAttribute("data-event");
        if (eventName) trackEvent(eventName);
      });
    });

    var contactsSection = document.getElementById("contacts");
    if (contactsSection && "IntersectionObserver" in window) {
      var observed = false;
      var observer = new IntersectionObserver(
        function (entries) {
          entries.forEach(function (entry) {
            if (entry.isIntersecting && !observed) {
              observed = true;
              trackEvent("scroll_contacts");
              observer.disconnect();
            }
          });
        },
        { threshold: 0.3 }
      );
      observer.observe(contactsSection);
    }
  }

  function initReveal() {
    var els = document.querySelectorAll(".reveal");
    if (!els.length) return;

    var reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    if (reduce || !("IntersectionObserver" in window)) {
      els.forEach(function (el) {
        el.classList.add("is-visible");
      });
      return;
    }

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -8% 0px" }
    );

    els.forEach(function (el) {
      observer.observe(el);
    });
  }

  function initHeaderShadow() {
    var header = document.getElementById("header");
    if (!header) return;
    var onScroll = function () {
      header.classList.toggle("is-scrolled", window.scrollY > 8);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }

  function initMobileBar() {
    var bar = document.getElementById("mobile-bar");
    var hero = document.getElementById("hero");
    if (!bar || !hero || !("IntersectionObserver" in window)) return;

    var observer = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          bar.classList.toggle("is-visible", !entry.isIntersecting);
        });
      },
      { threshold: 0 }
    );
    observer.observe(hero);
  }

  function initYandexMetrika() {
    if (!YANDEX_METRIKA_ID) return;

    (function (m, e, t, r, i, k, a) {
      m[i] =
        m[i] ||
        function () {
          (m[i].a = m[i].a || []).push(arguments);
        };
      m[i].l = 1 * new Date();
      for (var j = 0; j < document.scripts.length; j++) {
        if (document.scripts[j].src === r) return;
      }
      k = e.createElement(t);
      a = e.getElementsByTagName(t)[0];
      k.async = 1;
      k.src = r;
      a.parentNode.insertBefore(k, a);
    })(
      window,
      document,
      "script",
      "https://mc.yandex.ru/metrika/tag.js",
      "ym"
    );

    ym(YANDEX_METRIKA_ID, "init", {
      clickmap: true,
      trackLinks: true,
      accurateTrackBounce: true,
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    initMobileMenu();
    initAnalytics();
    initReveal();
    initHeaderShadow();
    initMobileBar();
    initYandexMetrika();
  });

  window.BoyarskyKray = {
    PHONE: PHONE,
    PHONE_DISPLAY: PHONE_DISPLAY,
    ROUTE_URL: ROUTE_URL,
  };
})();
