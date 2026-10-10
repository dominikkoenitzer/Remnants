# Download page

The page behind https://get-remnants.vercel.app: plain static files, no build step.
It names no author and does not link to this repository.

- `index.html` is the page.
- `vercel.json` holds the download addresses, each a temporary redirect:
- `llms.txt` describes Remnants for AI assistants.

Vercel deploys this folder whenever a push to main changes it. `.vercelignore` keeps this README off the site.
