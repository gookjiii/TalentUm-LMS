# Design System: TalentUm (Elite Digital Campus)

## 1. Visual Theme & Atmosphere
A high-clarity, ultra-modern educational workspace defined by sophisticated Glassmorphism and fluid spring-based micro-interactions. The interface feels weightless yet tactile, using translucent layers and precise shadows to establish hierarchy. The mood is **"Elite Digital Campus"** — professional, clean, and deeply structured, yet alive with motion.

- **Density:** 6/10 (Balanced Workspace) — Functional density for dashboard operations with generous breathable margins.
- **Variance:** 6/10 (Structured Asymmetry) — Confident use of white space and offset layouts to avoid generic 3-column grids.
- **Motion:** 7/10 (Fluid Spring) — Hardware-accelerated transforms and spring-based interactions (`stiffness: 100, damping: 20`).

## 2. Color Palette & Roles
- **Canvas Frost** (#F9FAFC) — Primary background surface.
- **Glass Surface** (#FFFFFF) — Card fill with 80-95% opacity for Glassmorphism effects.
- **Ink Navy** (#0F172A) — Primary text, deep Zinc-950 equivalent for high contrast.
- **Slate Secondary** (#475569) — Secondary text, labels, and metadata.
- **Muted Whisper** (#64748B) — Tertiary text, placeholder, and disabled states.
- **Frost Border** (#ECEBF3) — Card borders, 1px structural lines.
- **Vibrant Amethyst** (#7C3AED) — Primary brand accent for CTAs, active states, and focus rings.
- **Emerald Growth** (#059669) — Success states, grade improvements, and positive progress.

*(Max 1 primary accent. Saturation < 80%. No neon glows or AI-purple gradients.)*

## 3. Typography Rules
- **Display:** **Inter** (Weight: 900) — Track-tight (-0.3px), controlled scale. Used for App Bar titles and section headers.
- **Headlines:** **Inter** (Weight: 700-800) — Weight-driven hierarchy. Never screaming; size is secondary to weight.
- **Body:** **Inter** (Weight: 500) — Relaxed leading (1.55), 65ch max-width for readability.
- **Mono:** **JetBrains Mono** — For student codes, file sizes, and high-density statistical numbers.
- **Banned:** Generic system fonts (Arial, Helvetica), all serif fonts (dashboards/software UI constraint), and emojis in labels.

## 4. Component Stylings
* **Buttons:** Tactile "push" feedback (-1px Y-translate on active). Vibrant Amethyst (#7C3AED) fill for primary, Frost Border (#ECEBF3) outline for secondary. Border radius: **14px**.
* **Cards:** Generously rounded corners (**20px**). Multi-layered "Glass" effect: 1.2px border (#ECEBF3) + subtle glass shadow (`blur: 40, opacity: 0.04`).
* **Inputs:** Filled style (#F8FAFC). Label above, error below. Focus ring uses Vibrant Amethyst (#7C3AED) with 1.5px thickness. Border radius: **14px**.
* **Loaders:** Custom skeletal shimmer matching exact layout dimensions. No generic circular spinners.
* **Navigation:** Sidebar using deep Indigo (#1E1B4B) with high-contrast borders (#312E81).
* **Empty States:** Composed architectural compositions illustrating child progress or class activity — never just "No data".

## 5. Layout Principles
- **Grid System:** CSS Grid-first responsive architecture. Max-width containment (**1400px**).
- **Asymmetric Hero:** Split-screen or Left-aligned Hero layouts only. Centered layouts are BANNED.
- **Section Rhythm:** Vertical gaps scale via `clamp(3rem, 8vw, 6rem)`.
- **Glass Stacking:** Use `z-index` and `backdrop-filter: blur(10px)` to communicate modal and overlay depth.
- **No Overlapping:** Every element occupies a clean spatial zone. No absolute-positioned content stacking.

## 6. Motion & Interaction
- **Spring Physics:** Use `stiffness: 100, damping: 20` for all interactive translates and scales.
- **Staggered Entry:** Mount list items (grades, messages, assignments) using a 50ms-increment cascade delay.
- **Perpetual Micro-Interactions:** Active chat search bars and notification bells use subtle infinite float or pulse loops.
- **Hardware Acceleration:** Animate exclusively via `transform` and `opacity`.

## 7. Anti-Patterns (Banned)
- **No Emojis** in UI labels, navigation, or buttons.
- **No Pure Black** (#000000) — use Ink Navy (#0F172A).
- **No Neon Glows** or outer glow shadows on buttons.
- **No 3-column equal card grids** — use asymmetric layouts or horizontal scroll.
- **No AI Copywriting Clichés** ("Seamless", "Elevate", "Unleash").
- **No Filler Text** ("Scroll to explore", "Swipe down").
- **No Generic Placeholder Names** (use "Alex Student", "Dr. Teacher" or specific localized names).
- **No Broken Unsplash links** — use `picsum.photos` or local assets.
