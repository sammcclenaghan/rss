// Mercury Parser HTTP sidecar — the readability engine for the RSS reader,
// modelled on github.com/feedbin/extract. The Rails app fetches each article
// page with its own SSRF-guarded client and POSTs the HTML here; Mercury turns
// it into a clean article body. This service does no fetching of its own when
// `html` is supplied, so it should run on a private network only.

const express = require("express");
const Mercury = require("@jocmp/mercury-parser");

const app = express();
app.use(express.json({ limit: "12mb" }));

const TOKEN = process.env.EXTRACT_TOKEN;
const PORT = process.env.PORT || 3000;

app.get("/up", (_req, res) => res.json({ status: "ok" }));

app.post("/parse", async (req, res) => {
  if (TOKEN && req.get("X-Extract-Token") !== TOKEN) {
    return res.status(401).json({ error: "unauthorized" });
  }

  const { url, html } = req.body || {};
  if (!url) return res.status(400).json({ error: "url required" });

  try {
    // Passing html keeps page fetching on the Rails side (where SSRF is
    // guarded); Mercury just extracts the article from the bytes we vetted.
    const result = await Mercury.parse(url, html ? { html } : undefined);
    res.json(result);
  } catch (err) {
    res.status(502).json({ error: String((err && err.message) || err) });
  }
});

app.listen(PORT, () => console.log(`extract service listening on ${PORT}`));
