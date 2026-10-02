/* ===========================================================
   ZAYN COFFEE PH — SITE BEHAVIOR
   No dependencies, no build step.
   =========================================================== */

(function () {
  "use strict";

  var root = document.documentElement;

  /* ---- Mobile menu ---- */
  var toggle = document.querySelector(".menu-toggle");
  var mobileMenu = document.getElementById("mobile-menu");
  var pageParts = document.querySelectorAll("main, footer, .skip-link");

  if (toggle && mobileMenu) {
    var isOpen = function () { return toggle.getAttribute("aria-expanded") === "true"; };

    var setMenu = function (open, returnFocus) {
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      toggle.setAttribute("aria-label", open ? "Close menu" : "Open menu");
      mobileMenu.classList.toggle("open", open);
      root.classList.toggle("menu-open", open);
      pageParts.forEach(function (el) {
        if (open) el.setAttribute("inert", ""); else el.removeAttribute("inert");
      });
      if (open) {
        var first = mobileMenu.querySelector("a");
        if (first) first.focus();
      } else if (returnFocus) {
        toggle.focus();
      }
    };

    toggle.addEventListener("click", function () { setMenu(!isOpen(), true); });

    mobileMenu.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () { setMenu(false, false); });
    });

    document.addEventListener("keydown", function (e) {
      if (!isOpen()) return;
      if (e.key === "Escape") { setMenu(false, true); return; }
      if (e.key !== "Tab") return;
      // Keep focus inside the toggle + open menu
      var items = [toggle].concat(Array.prototype.slice.call(mobileMenu.querySelectorAll("a")));
      var firstEl = items[0], lastEl = items[items.length - 1];
      if (e.shiftKey && document.activeElement === firstEl) { e.preventDefault(); lastEl.focus(); }
      else if (!e.shiftKey && document.activeElement === lastEl) { e.preventDefault(); firstEl.focus(); }
    });

    // Close if the viewport grows past the mobile breakpoint
    window.matchMedia("(min-width: 1081px)").addEventListener("change", function (mq) {
      if (mq.matches && isOpen()) setMenu(false, false);
    });
  }

  /* ---- Scroll reveal ---- */
  var revealEls = document.querySelectorAll(".reveal");
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (!("IntersectionObserver" in window) || reduceMotion) {
    revealEls.forEach(function (el) { el.classList.add("is-visible"); });
  } else {
    var revealIO = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          revealIO.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
    revealEls.forEach(function (el) { revealIO.observe(el); });
  }

  /* ---- Scroll spy: highlight the current section / menu category ---- */
  function spy(links, rootMargin) {
    if (!links.length || !("IntersectionObserver" in window)) return;
    var map = {};
    links.forEach(function (a) {
      var target = document.getElementById(a.getAttribute("href").slice(1));
      if (target) map[target.id] = a;
    });
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        links.forEach(function (a) { a.removeAttribute("aria-current"); });
        var active = map[entry.target.id];
        if (active) {
          active.setAttribute("aria-current", "true");
          // Keep the active chip visible in the horizontal jump bar
          var bar = active.closest(".menu-jump ul");
          if (bar) {
            var left = active.offsetLeft - bar.clientWidth / 2 + active.clientWidth / 2;
            bar.scrollTo({ left: left, behavior: reduceMotion ? "auto" : "smooth" });
          }
        }
      });
    }, { rootMargin: rootMargin });
    Object.keys(map).forEach(function (id) { io.observe(document.getElementById(id)); });
  }

  spy(Array.prototype.slice.call(document.querySelectorAll(".nav-links a")), "-45% 0px -50% 0px");
  spy(Array.prototype.slice.call(document.querySelectorAll(".menu-jump a")), "-30% 0px -60% 0px");

  /* ---- Merchandise: variant chips swap the product photo ---- */
  document.querySelectorAll("[data-variants]").forEach(function (feature) {
    var main = feature.querySelector("[data-variant-main]");
    var buttons = feature.querySelectorAll("button[data-img]");
    if (!main || !buttons.length) return;
    buttons.forEach(function (btn) {
      btn.addEventListener("click", function () {
        if (btn.getAttribute("aria-pressed") === "true") return;
        buttons.forEach(function (b) { b.setAttribute("aria-pressed", b === btn ? "true" : "false"); });
        var base = btn.getAttribute("data-img");
        main.classList.add("is-swapping");
        var next = new Image();
        next.onload = next.onerror = function () {
          main.srcset = base + "-480.jpg 480w, " + base + "-960.jpg 960w";
          main.src = base + "-960.jpg";
          main.alt = btn.getAttribute("data-alt");
          main.classList.remove("is-swapping");
        };
        next.src = base + "-960.jpg";
      });
    });
  });

  /* ---- Footer year ---- */
  document.querySelectorAll("[data-year]").forEach(function (el) {
    el.textContent = new Date().getFullYear();
  });
})();
