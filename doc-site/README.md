# KDK documentation

KDK documentation can be built by using the Hugo static site generator and the [Geekdoc Hugo theme](https://geekdocs.de). When changes a pushed to the `main` branch, configuration
in this directory is used to build and deploy the KDK documentation to <https://khulnasoft-lab.github.io/khulnasoft-development-kit/>.

## Set up local preview

To retrieve and build the theme assets required for Geekdoc:

```bash
git submodule update --init --recursive
cd doc-site/themes/hugo-geekdoc
npm install
npm run build
cd ../..
```

To start the development server:

```bash
hugo server -D
```

By default, the development server will start on port 1313. To specify a different port, use:

```bash
hugo server -D --port <PORT>
```

## Add new documentation pages

To be published, all documentation must be placed in the `docs/` directory.

Each new page should include the following front matter:

```markdown
---
title: "Page Title"
weight: 10
description: "Brief description of this page"
---

Content starts here
```

To create a new section, create a directory with an `_index.md` file.
To include a table of contents on a page, use the `{{ < toc > }}` shortcode.

## Troubleshooting

If navigation links aren't working properly:

- Make sure all pages have a proper weight defined in front matter.
- Check that all sections have an `_index.md` file.
- If you've updated the theme. rebuild the theme assets.
