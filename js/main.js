/* ===========================================================
   ZAYN COFFEE PH — SITE BEHAVIOR
   No dependencies, no build step.
   =========================================================== */

(function () {
  "use strict";

  /* ---- Mobile menu ---- */
  var toggle = document.querySelector(".menu-toggle");
  var mobileMenu = document.querySelector(".mobile-menu");
  if (toggle && mobileMenu) {
    var setMenu = function (open) {
      toggle.classList.toggle("open", open);
      mobileMenu.classList.toggle("open", open);
      document.body.style.overflow = open ? "hidden" : "";
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
    };
    toggle.addEventListener("click", function () {
      setMenu(!toggle.classList.contains("open"));
    });
    mobileMenu.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () { setMenu(false); });
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && toggle.classList.contains("open")) setMenu(false);
    });
  }

  /* ---- Scroll reveal ---- */
  function initReveal() {
    var revealEls = document.querySelectorAll(".reveal, .mask-reveal");
    if (!revealEls.length) return;

    document.querySelectorAll(".reveal-stagger").forEach(function (group) {
      Array.prototype.forEach.call(group.children, function (child, i) {
        child.style.setProperty("--i", i);
      });
    });

    if (!("IntersectionObserver" in window)) {
      revealEls.forEach(function (el) { el.classList.add("is-visible"); });
      return;
    }

    var io = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            io.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15, rootMargin: "0px 0px -60px 0px" }
    );
    revealEls.forEach(function (el) { io.observe(el); });
  }
  initReveal();

  /* ---- Footer year ---- */
  document.querySelectorAll("[data-year]").forEach(function (el) {
    el.textContent = new Date().getFullYear();
  });
})();
