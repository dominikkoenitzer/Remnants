# Download page

The page behind https://get-remnants.vercel.app: static files, no build step on the server.
It names no author and does not link to this repository.

- `page.json` holds every word on the page and which screenshots it shows.
- `build.py` turns `page.json` into `index.html`. The same `build.py` sits in every app's
  `site/` folder, so all the download pages share one design. After an edit:

  ```
  python build.py
  ```

- `img/` holds real screenshots of the app as WebP, `-light` and `-dark` where the app has both
  looks. Never put a mock-up or an edited screenshot there.
- `jakarta.woff2` is the Plus Jakarta Sans typeface, served from the page itself;
  `jakarta-OFL.txt` is its licence.
- `vercel.json` holds the download addresses, each a temporary redirect:
  - `/download/windows`
  - `/download/windows-arm`
  - `/download/mac`
  - `/download/mac-intel`
  - `/download/linux`
  - `/download/deb`
  - `/download/rpm`
  - `/download/pkgbuild`
  - `/download/checksums`
  - `/latest`
  - `/issues`
  - `/issues/new`
  - `/releases/download/([^/]+?)/([^/]+?)`
- `llms.txt` describes the app for AI assistants.
- Some addresses in `vercel.json` name a version: update them with every release.

Vercel deploys this folder whenever a push to main changes it. `.vercelignore` keeps this README,
`build.py` and `page.json` off the site.
