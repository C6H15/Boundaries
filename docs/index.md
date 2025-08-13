---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: Boundaries
  text: Spatial boundaries for Roblox using BVH with Morton codes.
  actions:
    - theme: brand
      text: Get Started →
      link: /markdown-examples
    - theme: alt
      text: GitHub
      link: https://github.com/C6H15/Boundaries

features:
  - title: Dynamic Boundaries
    details: Create boundaries using existing parts or custom shapes, with support for both complex geometries and simple shapes such as blocks.
  - title: Boundary Groups
    details: Set each boundary to only track specific groups, allowing control over which parts trigger collision callbacks.
  - title: Part Groups
    details: Organize parts into groups with entered/exited callbacks that receive custom data for flexible collision handling.
  - title: Budgeted Processing
    details: Frame-budgeted processing with BVH and Morton codes to maintain consistent performance.
---

