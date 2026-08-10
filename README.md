# SurveyAI website

Jekyll source for the SurveyAI project site (DARIAH-FI-SurveyAI, University
of Helsinki). This is the starting point: a single homepage that can be
expanded with more pages later.

## How to publish it on GitHub Pages

1. Upload all of these files to the root of the `surveyai-site` repository
   (drag-and-drop through the GitHub web interface works fine, or use
   `git add` / `git commit` / `git push` if you're working locally).
2. In the repository, go to **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to "Deploy from a branch".
4. Set **Branch** to `main` and folder to `/ (root)`, then **Save**.
5. GitHub will build the site automatically. It usually takes 1-2 minutes.
   The URL will be shown at the top of the Pages settings page — it should
   match the `url` + `baseurl` set in `_config.yml`
   (`https://dariah-fi-surveyai.github.io/surveyai-site`).

## Logo

`assets/images/logo.png` is the current SurveyAI hexagon logo. Replace this
file (keeping the same name) if you want to swap in a new version, or
update the `src` in the header block of `index.html` if you rename it.
The unused `assets/images/logo-placeholder.svg` can be deleted.

## File structure

```
_config.yml           site settings (title, description, url)
_layouts/default.html base HTML wrapper (head, fonts, css include)
index.html             homepage content
assets/css/style.css   all styling
assets/images/         logo and future images
```

## Adding more pages later

Create a new `.html` or `.md` file in the repo root with front matter like:

```
---
layout: default
title: About
---
```

Then add a link to it in the `<nav class="site-nav">` block in `index.html`.
