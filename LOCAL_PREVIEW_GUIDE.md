# Local Preview Guide: LWC, Multi-Framework and HXL

How to preview the three kinds of UI in this project inside VS Code, without deploying to the org.

| What | Where in this project | Right-click menu item |
|---|---|---|
| Lightning Web Component (LWC) | `force-app/main/default/lwc/<component>/` | **SFDX: Open in Lightning Preview** |
| Multi-Framework UI Bundle (React) | `force-app/main/default/uiBundles/<bundle>/` | **SFDX: Open in Live Preview** |
| HXL Widget | `force-app/main/default/uiWidgets/<widget>/` | **SFDX: Open in Widget Preview** |

All three come from the **Salesforce Live Preview** extension (`salesforce.salesforcedx-vscode-ui-preview`).

---

## 0. One-time setup

1. Install these VS Code extensions:
   - **Salesforce Extension Pack**
   - **Salesforce Live Preview**
2. Install the Salesforce CLI plugins:
   ```bash
   sf plugins install @salesforce/plugin-lightning-dev   # LWC preview
   sf plugins install @salesforce/plugin-ui-bundle-dev   # UI bundle preview
   ```
3. Make sure the default org is logged in:
   ```bash
   sf org display --target-org ashish-rk
   ```
   The output should say `Connected`. If it doesn't, run `sf org login web --alias ashish-rk --set-default`.
4. Install each UI bundle's packages once:
   ```bash
   cd force-app/main/default/uiBundles/reactinternal && npm install
   cd ../ReactInternalAK && npm install
   ```

---

## 1. LWC: Lightning Preview

**Example:** `lwc/templateExpressionsDemo`

1. In the Explorer, open `force-app/main/default/lwc/templateExpressionsDemo/`.
2. Right-click the **component folder**, or its `.html`, `.js` or `.css` file.
3. Choose **SFDX: Open in Lightning Preview**.
4. The **Lightning Preview** pane opens beside the editor. The first start can take a few seconds while the local server (port `8081`) starts.

You can also open it from the Command Palette (`⇧⌘P`): run **SFDX: Open in Lightning Preview** and pick the component.

**Using the pane**
- **Save** a file and the preview updates by itself.
- **↻ Refresh**: reload the preview.
- **📌 Pin**: keep showing this component while you edit other files. Unpinned, the pane follows the file you have open.
- **⧉ Open in browser**: open the same preview in your browser.

**Data:** the component runs against your org, so Apex methods, `@wire` adapters and `@salesforce/*` imports return real data.

> ⚠️ **Template expressions (`{a ? b : c}`, `?.`, `??`, `.filter()` and so on)**
> These are GA in Winter '27 for components at API 66.0 or higher, and they deploy fine. However, `plugin-lightning-dev` 6.2.19 doesn't turn them on for local preview, so the pane stays **blank** without showing any error.
> This machine has a local patch that fixes it, in:
> every copy of `lexBundler.js` in `~/.local/share/sf/node_modules/@salesforce/plugin-lightning-dev/` (one per API version; API 68.0 uses the top-level `@lwc/lwc-dev-server`). Originals are saved next to each as `lexBundler.js.orig`.
> **Permanent since 2026-10-14:** `~/.config/sf-lwc-preview-fix/fix-lwc-preview.sh` applies it to all copies, and LaunchAgent `com.rohit.sf-lwc-preview-fix` re-applies it automatically after `sf plugins update`, at login, and hourly. See `~/.config/sf-lwc-preview-fix/README.md`. Status: `tail ~/.config/sf-lwc-preview-fix/fix.log`.

---

## 2. Multi-Framework: UI Bundle (Live Preview)

**Bundles in this project:** `uiBundles/reactinternal` and `uiBundles/ReactInternalAK`

1. In the Explorer, open `force-app/main/default/uiBundles/reactinternal/src/`.
2. Right-click a **`.ts`, `.tsx`, `.js` or `.jsx` file**, for example **`app.tsx`**.
   (This menu item doesn't appear on folders or other file types.)
3. Choose **SFDX: Open in Live Preview**.
4. Wait about **5–10 seconds**. Behind the scenes the extension:
   - runs `sf ui-bundle dev` for that bundle with your default org
   - starts the bundle's dev server at `http://localhost:5173`
   - waits for **"✅ Ready for development!"**, then opens the pane
5. Click through the app. For example, **☰ → Accounts** should list Accounts from the org (27 in `ashish-rk`).

**Switching bundles:** right-click a file in the other bundle and choose **SFDX: Open in Live Preview** again. The extension stops the current bundle and starts the new one by itself.

**Stopping:** close the pane, or run **SFDX: Close Live Preview** from the Command Palette.

**Good to know**
- Neither bundle has a `dev` block in `ui-bundle.json`, so the default command is **`npm run dev:design`**, not `npm run dev`. To choose the command, add a `dev` block:
  ```json
  {
    "outputDir": "dist",
    "dev": { "command": "npm run dev" },
    "routing": { "trailingSlash": "never", "fallback": "index.html" }
  }
  ```
  If you start the dev server yourself, use `"dev": { "url": "http://localhost:5173" }` instead.
- These bundles have their own Vite proxy to Salesforce, so the separate proxy on port `4545` is skipped. That's expected.
- In the browser's network panel you may see a few `401` responses from `/services/data/.../graphql` at startup, followed by a `csrf` call and then `200`s. That's the normal sign-in handshake, not an error.

---

## 3. HXL: Widget Preview (Beta)

**Widgets in this project:** `uiWidgets/accountDetailsCard` and `uiWidgets/accountRelatedAccordion`

Each widget folder must contain three files:
- `<name>.uiwidget-meta.xml`
- `<name>.json`
- `schema.json`

1. In the Explorer, open `force-app/main/default/uiWidgets/`.
2. Right-click the **widget folder** (for example `accountDetailsCard`), or one of its three files.
3. Choose **SFDX: Open in Widget Preview**.
4. The pane opens almost immediately, since no dev server is needed. Use the channel options to see how the widget looks in each place it can appear.

**Sample data:** the preview fills `{!$attrs.*}` with sample values built from `schema.json`.
- Both widgets were checked: every `{!$attrs.*}` used in the widget is defined in its `schema.json`. In `accountRelatedAccordion`, `accountCount` is defined but never used, which is harmless.
- `accountDetailsCard` shows different sections depending on `found` and `notFound`. Because the schema has no example values, the generated data can show **both** the "Account not found" warning and the details, or **neither**. To see the normal view, set `found = true` and `notFound = false`.

---

## Troubleshooting

| Symptom | What to do |
|---|---|
| Pane is blank or keeps loading | Click **↻ Refresh**. If that doesn't help, run **Developer: Reload Window** (`⇧⌘P`) and open the preview again. |
| LWC pane blank only for components using template expressions | Run `~/.config/sf-lwc-preview-fix/fix-lwc-preview.sh`, then **SFDX: Close Live Preview** and reopen. Check `fix.log` for `WARN`. Also check the component's `apiVersion` is 66.0+. See the ⚠️ note in section 1. |
| You want to see what went wrong | **View → Output**, then choose **Live Preview** in the dropdown. For more detail, set **Settings → Salesforce Live Preview: Log Level** to `debug`. |
| Log shows `SIGKILL` / "LWC preview server exited with error" right after opening a UI bundle or widget | Normal. The extension stops the LWC server when you switch preview type. |
| "Port already in use" (`8081` or `5173`) | Another preview or dev server is still running. Run **SFDX: Close Live Preview**, or find the process with `lsof -nP -iTCP:5173 -sTCP:LISTEN` and stop it. |
| Org data doesn't load | Check the org connection with `sf org display --target-org ashish-rk`. Log in again if needed. |

---

## Test record (2026-10-08, org `ashish-rk`)

| Preview | Item | Result |
|---|---|---|
| LWC | `templateExpressionsDemo` | ✅ Renders; Log in/Log out toggle works; desktop and mobile widths checked |
| UI Bundle | `reactinternal` | ✅ Ready in about 7 s; Accounts page loaded 27 records from the org |
| UI Bundle | `ReactInternalAK` | ✅ Ready in about 6 s; no errors |
| HXL Widget | `accountDetailsCard` | ✅ Preview running; schema matches widget |
| HXL Widget | `accountRelatedAccordion` | ✅ Preview running; schema matches widget |
