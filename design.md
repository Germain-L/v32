Plan
- Provide a single reusable prompt template for Stitch targeting the Today screen.
- Provide five filled-in prompt variants (one per design direction) that follow the template.
- Keep each prompt concise, with layout + typography + color + components + mood.
- Include explicit "one screen only" instruction to avoid multi-screen output.
- Provide a reusable negative prompt line and alternates.

Single prompt template (Today screen)
```
Design a single mobile app screen (Today) for a diet/meal tracker. Show 4 fixed meal slots (Breakfast, Lunch, Afternoon Snack, Dinner), each with a photo placeholder/capture button, optional short note field, and a “saved” state indicator for completed slots. Include a top date header and a small daily summary footer. Use the following visual direction:
- Typography:
- Color palette:
- Layout style:
- Component styling:
- Mood keywords:
Keep it minimal, fast to scan, and do not include other screens.
```

Five one-screen prompts (Today)

1) Editorial Minimal (Swiss-style)
```
Design a single mobile app screen (Today) for a diet/meal tracker. Show 4 fixed meal slots (Breakfast, Lunch, Afternoon Snack, Dinner), each with a photo placeholder/capture button, optional short note field, and a “saved” state indicator for completed slots. Include a top date header and a small daily summary footer. Use the following visual direction:
- Typography: high-contrast serif headings (Fraunces), neutral grotesk body (Work Sans).
- Color palette: paper white background, near-black text, muted sage accent.
- Layout style: strict grid, generous whitespace, crisp thin dividers.
- Component styling: flat cards, sharp corners, edge-to-edge images.
- Mood keywords: editorial, premium, calm, journal.
Keep it minimal, fast to scan, and do not include other screens.
```

2) Soft Tactile (Neo-analog)
```
Design a single mobile app screen (Today) for a diet/meal tracker. Show 4 fixed meal slots (Breakfast, Lunch, Afternoon Snack, Dinner), each with a photo placeholder/capture button, optional short note field, and a “saved” state indicator for completed slots. Include a top date header and a small daily summary footer. Use the following visual direction:
- Typography: rounded sans (DM Sans) with friendly weights.
- Color palette: warm neutrals with soft peach and sand accents.
- Layout style: airy spacing, large touch targets, pill shapes.
- Component styling: subtle inner shadows, soft borders, gentle depth.
- Mood keywords: cozy, approachable, soft, tactile.
Keep it minimal, fast to scan, and do not include other screens.
```

3) Bento Photo-First
```
Design a single mobile app screen (Today) for a diet/meal tracker. Show 4 fixed meal slots (Breakfast, Lunch, Afternoon Snack, Dinner), each with a photo placeholder/capture button, optional short note field, and a “saved” state indicator for completed slots. Include a top date header and a small daily summary footer. Use the following visual direction:
- Typography: clean modern sans (Space Grotesk).
- Color palette: monochrome UI, photos provide color.
- Layout style: bento grid with image-dominant tiles.
- Component styling: high-radius tiles, minimal chrome, icon-only actions.
- Mood keywords: modern, visual-first, gallery, bold.
Keep it minimal, fast to scan, and do not include other screens.
```

4) Monochrome Utility
```
Design a single mobile app screen (Today) for a diet/meal tracker. Show 4 fixed meal slots (Breakfast, Lunch, Afternoon Snack, Dinner), each with a photo placeholder/capture button, optional short note field, and a “saved” state indicator for completed slots. Include a top date header and a small daily summary footer. Use the following visual direction:
- Typography: monospace headers (IBM Plex Mono) + humanist body (IBM Plex Sans).
- Color palette: grayscale with a single amber accent for status.
- Layout style: compact list, strong alignment, no fluff.
- Component styling: strong outlines, squared corners, dense info.
- Mood keywords: efficient, pro tool, utilitarian.
Keep it minimal, fast to scan, and do not include other screens.
```

5) Organic Nutrition (Naturalist)
```
Design a single mobile app screen (Today) for a diet/meal tracker. Show 4 fixed meal slots (Breakfast, Lunch, Afternoon Snack, Dinner), each with a photo placeholder/capture button, optional short note field, and a “saved” state indicator for completed slots. Include a top date header and a small daily summary footer. Use the following visual direction:
- Typography: soft serif headings + light sans body.
- Color palette: earthy olive, sand, clay, charcoal.
- Layout style: gentle curves, subtle paper/fiber texture.
- Component styling: rounded rectangles, tinted chips, soft shadows.
- Mood keywords: wholesome, grounded, natural.
Keep it minimal, fast to scan, and do not include other screens.
```

Negative prompt (default)
- Avoid Material Design, no floating action button, no Android system chrome, no gradients unless specified, no card elevation, no purple accents, no neumorphism unless specified.

Negative prompt alternates
1) Avoid Material Design; no FAB; no bottom navigation; no elevation or drop shadows; no purple; no glassmorphism.
2) Avoid Material and iOS chrome; no default system fonts; no cards with shadows; no gradient backgrounds; no pill toggles.
3) Avoid Material UI patterns; no FAB; no M3 typography; no elevation; no purple; no neon colors.
