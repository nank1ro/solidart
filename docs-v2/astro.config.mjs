import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
  site: 'https://solidart.mariuti.com',
  integrations: [
    starlight({
      title: 'solidart docs',
      favicon: '/favicon.svg',
      social: {
        github: 'https://github.com/nank1ro/solidart',
        twitter: 'https://twitter.com/nank1ro',
      },
      sidebar: [
        {
          label: 'mariuti.com',
          link: 'https://mariuti.com',
          badge: { text: 'Author', variant: 'tip' },
          attrs: { target: '_blank' },
        },
        {
          label: 'flutter_solidart',
          link: 'https://pub.dev/packages/flutter_solidart',
          badge: { text: 'pub.dev', variant: 'note' },
          attrs: { target: '_blank', rel: 'noopener noreferrer' },
        },
        {
          label: 'solidart',
          link: 'https://pub.dev/packages/solidart',
          badge: { text: 'pub.dev', variant: 'note' },
          attrs: { target: '_blank', rel: 'noopener noreferrer' },
        },
        {
          label: 'solidart_lint',
          link: 'https://pub.dev/packages/solidart_lint',
          badge: { text: 'pub.dev', variant: 'note' },
          attrs: { target: '_blank', rel: 'noopener noreferrer' },
        },
        {
          label: 'Getting started',
          items: [
            {
              label: 'Overview',
              link: '',
            },
            {
              label: 'Setup',
              link: '/getting-started/setup',
            },
          ],
        },
        {
          label: 'Learning',
          autogenerate: { directory: 'learning' },
        },
        {
          label: 'Flutter',
          autogenerate: { directory: 'flutter' },
        },
        {
          label: 'Advanced',
          autogenerate: { directory: 'advanced' },
        },
        {
          label: 'Examples',
          link: '/examples',
        }
      ],
    }),
  ],
});
