# OneSend product site

Source for [onesend.01mvp.com](https://onesend.01mvp.com), the public product
page and privacy notice for OneSend · 扫传.

## Development

Requires Node.js 22.13 or newer.

```bash
npm install
npm run dev
```

Run the production build, rendered-page checks, and lint before deployment:

```bash
npm test
npm run lint
```

The page links to the stable filenames in the latest GitHub Release and to the
public TestFlight group. Apple enables joining through that link after the
submitted external beta build passes Beta App Review.

## Hosting

The site is deployed with OpenAI Sites. `.openai/hosting.json` stores only the
public project identifier; credentials and generated deployment output are not
committed.

OneSend and this website are released under the repository's MIT license.
