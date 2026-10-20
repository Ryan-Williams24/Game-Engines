# Game Engines

Course projects for Game Engines, Fall 2026.

[Open the project website for games, downloads, and recordings](https://ryan-williams24.github.io/Game-Engines/).

## Maintaining the website

- `index.md` is the visitor homepage; edit its project descriptions and download links there.
- This README documents the repository and publishing steps.
- Each engine folder has an `index.md` for its website page. Project READMEs contain editor instructions and development notes.

The website uses the Jekyll workflow in `.github/workflows/jekyll-gh-pages.yml`. In the repository's **Settings → Pages**, set **Source** to **GitHub Actions**.

Commit and push changes to `main` to publish. The workflow packages the current Meadow Hop source into `GodotProjects/MeadowHop.zip`, builds the Markdown pages, and deploys the site.

To create or refresh the Godot download locally, run:

```sh
python3 tools/package_downloads.py
```

The generated ZIP is ignored by Git because the workflow recreates it on every deployment. GameMaker's project ZIP and recording are stored in `GameMakerProjects/`; replace those files when updating their downloads.
