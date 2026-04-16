* [](../md.htm) should have code handling the [](./analyer.md/#key-words)
* ~~Investigate why [img](./imgs/go-not-working.png) does not show Go button~~ — fixed: changed `indexOf` exact match to `includes` so labels like "Source local 1/2", "C# Source folder", "Git folder" now match

## key-words

Table cell labels (case-insensitive) that trigger a "Go" folder button in [md.htm](../md.htm):

* `source folder`
* `source` (also matches "C# Source folder", "Source local 1", etc. via includes)
* `local folder`
* `folder`
* `local`

# Buttons order

* The Go button order should be same as `<td>` order in `<tr>`
