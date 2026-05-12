# inputSearch Triggers

## Summary

The `inputSearch` text box (`<input id="inputSearch">`) in `md.htm` is a search/filter box.
Only two markdown files are intended to use its filtering behaviour:

| File | Role |
|------|------|
| `_work-index.md` | Root index page (`isRootPage = true`) |
| `_LoadingDocuments/bauSensei.md` | BAU issue log — also an index-style list page |

Both are covered by `isSearchPage` in `md.htm`.

---

## Who listens to inputSearch changes?

### 1. keyup event — `md.htm` line ~893
```js
inputSearch.addEventListener("keyup", function() {
    if (isSearchPage) searchText();
});
```
Fires `searchText()` on every keystroke, but **only when `isSearchPage` is true**.

### 2. Page load restore — `md.htm` line ~1067
```js
if (isSearchPage) {
    inputSearch.value = localStorage.getItem(_searchText);
    searchText();
} else {
    inputSearch.value = '';
}
```
Restores saved search text from `localStorage` and applies the filter **only on search pages**.
Non-search pages get an empty search box.

### 3. resetText() — `md.htm`
```js
function resetText() {
    inputSearch.value = "";
    searchText();
}
```
Called when the Reset button is clicked. Clears the box and re-runs the filter.
(Runs on all pages but harmless — clears the box and filters nothing.)

### 4. Collapse button inside searchText() — `md.htm`
```js
// Collapse button clicked
searchText();
```
Called when an Expand/Collapse button in the content is collapsed.
Re-applies the current filter to restore hidden items.

---

## isSearchPage definition

```js
var isSearchPage = isRootPage || app.src.toLowerCase().includes('bausensei.md');
```

`isRootPage` is true when `app.src` matches `_work-index.md`.

---

## Bug: spurious search trigger on non-search pages

**Symptom**: When viewing any other markdown file and returning from another window,
the search box would run `searchText()` and hide content unexpectedly.

**Root cause**:
- `inputSearch.value` was set from `localStorage` for **all** pages on load.
- `inputSearch.addEventListener("keyup", searchText)` was bound for **all** pages.
- Returning from another window can restore focus to `inputSearch`, and any subsequent
  keyboard event (or browser-synthesised event) would fire `searchText()`, filtering
  content on pages that should not be filtered.

**Fix applied** (`md.htm`):
- `keyup` handler now guards with `if (isSearchPage)`.
- `inputSearch.value` is only restored from localStorage on search pages.
- Non-search pages get `inputSearch.value = ''` on load, preventing stale text.
