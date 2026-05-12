# How to get Confluence credentials for Copy2Conf

## What you need

| Field | Example |
|-------|---------|
| Base URL | `https://yourcompany.atlassian.net` |
| Email | `you@company.com` |
| API Token | (generated below) |
| Page ID | `3746627623` (from the Confluence page URL) |

---

## Step 1 — Get an API Token

1. Go to **id.atlassian.com**
   - If it redirects to `home.atlassian.com`, click your profile avatar (top-right) → **Account settings**
   - Or go directly: `https://id.atlassian.com/manage-profile/security/api-tokens`
2. Click **Security** in the left sidebar
3. Click **API tokens**
4. Click **Create API token**
5. Give it a label (e.g. `md-copy2conf`) and click **Create**
6. Copy the token immediately — it is only shown once

> **Note:** `id.atlassian.com` may redirect to `home.atlassian.com`. If so, use the direct URL above.

---

## Step 2 — Find your Page ID

Open the Confluence page you want to paste into. The Page ID is the number in the URL:

```
https://yourcompany.atlassian.net/wiki/spaces/IW/pages/3746627623/Page+Title
                                                              ^^^^^^^^^^
                                                              This is the Page ID
```

---

## Step 3 — Enter settings in md.htm

1. Click the **⚙** (gear) button next to Copy2Conf in md.htm
2. Fill in:
   - **Base URL**: `https://yourcompany.atlassian.net` (no trailing slash)
   - **Email**: your Atlassian account email
   - **API Token**: the token from Step 1
   - **Page ID**: the number from Step 2
3. Click **Save & Copy**

Settings are saved in `localStorage` (browser, per-site) — you only need to do this once per browser.

---

## Notes

- The API token authenticates as your user account — it has the same permissions as you.
- You need **Edit** permission on the Confluence page to upload attachments.
- The Page ID changes if you move the page to a different space. Update it if images stop uploading.
