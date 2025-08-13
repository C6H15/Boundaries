import { defineConfig } from 'vitepress'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Boundaries",
  description: "Dynamic spatial boundaries for Roblox using BVH with Morton codes for efficient collision detection.",
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Examples', link: '/markdown-examples' }
    ],

    sidebar: [
      {
        text: 'Examples',
        items: [
          { text: 'Markdown Examples', link: '/markdown-examples' },
          { text: 'Runtime API Examples', link: '/api-examples' }
        ]
      }
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/C6H15/Boundaries' }
    ],

    footer: {
      message: `Released under the <a href="https://github.com/C6H15/Boundaries/blob/main/LICENSE">MIT License</a>.
      Inspired by <a href="https://github.com/unityjaeger">@unityjaeger</a>.`,
      copyright: `Copyright © 2025 <a href="https://github.com/C6H15">C6H15</a>`
    },
  }
})
