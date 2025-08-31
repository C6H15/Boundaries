<script setup>
import { VPTeamMembers } from 'vitepress/theme'

const members = [
  {
    avatar: 'https://github.com/C6H15.png',
    name: 'C6H15',
    links: [
      { icon: 'github', link: 'https://github.com/C6H15' },
    ]
  },
  {
    // Empty
  },
]

</script>

# Introduction {#1}
Boundaries is a Roblox module for efficient 3D collision detection and spatial boundary management. It uses [Bounding Volume Hierarchy (BVH)](https://en.wikipedia.org/wiki/Bounding_volume_hierarchy) and [Morton codes](https://en.wikipedia.org/wiki/Z-order_curve) to provide fast and reliable detection, allowing you to create spatial areas in your Roblox experience to track parts within boundaries.

> [!NOTE] Project Inspiration
> This project was inspired by [QuickBounds](https://github.com/unityjaeger/QuickBounds) by [@unityjaeger](https://github.com/unityjaeger). This project was created from scratch to address limitations in their project's design, improve performance, and reduce memory usage. If you're interested in the benchmarks, head to [Performance](/resources/performance) under Resources.

## Use Cases
- **Player Interactions**:<br>
PvP and PvE areas, safe zones, motion sensors, and NPC dialogue triggers.
- **Game Mechanics**:<br>
Quest checkpoints, item drop-off and pickup areas, and cutscene triggers.
- **World Systems**:<br>
Weather and lighting transitions, ambient SFX and VFX, and environmental triggers.

<div class="tip custom-block" style="padding-top: 8px;">

Want to see a basic implementation? Move on to the [Tutorial](./tutorial).

</div>

---

<VPTeamMembers size="small" :members />