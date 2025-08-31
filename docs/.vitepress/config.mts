import { defineConfig } from 'vitepress'
import { tabsMarkdownPlugin } from 'vitepress-plugin-tabs'

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "Boundaries",
  description: "Dynamic spatial boundaries for Roblox using BVH with Morton codes for efficient collision detection.",
  base: "/Boundaries/",
  lastUpdated: true,
  cleanUrls: true,

  head: [["link", { rel: "icon", href: "/Boundaries/" }]], // /Boundaries/favicon.ico

  markdown: {
    lineNumbers: true,
    config(md) {
      md.use(tabsMarkdownPlugin)
    }
  },

  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      { text: "Home", link: "/" },
      { text: "Guide", link: "/guide/introduction", activeMatch: "/guide/" },
      { text: "API", link: "/api/types", activeMatch: "/api/" },
      {
        text: "Resources",
        items: [
          { text: "Troubleshooting", link: "/resources/troubleshooting" },
          { text: "Performance", link: "/resources/performance" },
        ]
      }
    ],

    sidebar: {
      "/guide/": [
        {
          text: "Guide",
          items: [
            { text: "Introduction", link: "/guide/introduction" },
            { text: "Installation", link: "/guide/installation" },
            { text: "Tutorial", link: "/guide/tutorial" },
          ]
        }
      ],
      "/api/": [
        {
          text: "API",
          items: [
            { text: "Types", link: "/api/types" },
            { text: "Functions", link: "/api/functions" },
          ]
        }
      ],
      "/resources/": [
        {
          text: "Resources",
          items: [
            { text: "Troubleshooting", link: "/resources/troubleshooting" },
            { text: "Performance", link: "/resources/performance" },
          ]
        }
      ],
    },

    socialLinks: [
      { icon: "github", link: `https://github.com/C6H15/Boundaries` }
    ],

    lightModeSwitchTitle: "Light Mode",
    darkModeSwitchTitle: "Dark Mode",

    footer: {
      message: `Inspired by <a href="https://github.com/unityjaeger">@unityjaeger</a><br>
      Released under the <a href="https://github.com/C6H15/Boundaries/blob/main/LICENSE">MIT License</a>`,
      copyright: `Copyright © 2025 <a href="https://github.com/C6H15">C6H15</a>`
    },

    search: {
      provider: "local"
    },

    outline: {
      level: [2, 3],
      label: "Page Outline:"
    },
  }
})
