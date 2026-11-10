# Exercise: A Recipe Box Module

Exercise code for the lesson **Exercise: A Recipe Box Module** in PowerShell in Depth on [ask-codey.com](https://www.ask-codey.com).

`RecipeBox.psm1` is a recipe box: `Add-Recipe` saves a recipe, `Get-Recipe` hands them back, and `Show-RecipeBox` opens a small window for people who would rather click. It runs, but it isn't a real tool yet. It hands back lines of text that can't be sorted, saves its recipes in whatever folder you happen to be in, bakes colors into the recipes' names, and its window shows an empty list. Finish four jobs to make it a tool you'd hand to a friend, answer three questions, and a Pester check tries it on a recipe box of its own and tells you what's done.

## What's here

- `RecipeBox.psm1`: the recipe box's commands. `Read-RecipeFile`, `Show-RecipeBox` and the parameters of `Add-Recipe` and `Get-Recipe` are ready to use; four jobs are for you to finish.
- `answers.txt`: three questions, each with a numbered line for your answer. For you to finish.
- `Check.Tests.ps1`: the check. You don't need to change it.

## What to do

A `.psm1` file is a **module**: a script file of commands that `Import-Module` loads into your window, where they work like any other command until you close it. Open PowerShell in this folder (the one with `answers.txt` in it), open the module in VS Code (`code .`) or with `edit .\RecipeBox.psm1`, and try it as it is:

```powershell
Import-Module .\RecipeBox.psm1 -Force
Add-Recipe -Name 'Lemon Garlic Pasta' -Minutes 30 -Category Dinner
Add-Recipe -Name 'Overnight Oats' -Minutes 10 -Category Breakfast
Get-Recipe
Get-Recipe | Sort-Object Minutes
```

Each recipe comes back as a sentence or a line of text, the sort changes nothing, and a `recipes.json` has appeared in this folder. Run `Import-Module .\RecipeBox.psm1 -Force` again after every change you save: `-Force` loads the new version. Then, one job at a time:

1. **Objects, not text.** In `Get-Recipe`, hand back one `[PSCustomObject]` per recipe, with the properties `Name`, `Minutes` and `Category`, in that order, and `Minutes` as a whole number (`[int]$saved.Minutes`). In `Add-Recipe`, hand back the recipe it added, `$recipe`, instead of the sentence. Try `Get-Recipe | Sort-Object Minutes` and `Get-Recipe -Category Dinner`.
2. **One place for the data.** In `Get-RecipeFile`, build the path with `Join-Path`: the folder in `$env:LOCALAPPDATA`, then `RecipeBox`, then `recipes.json`. On a Mac or Linux, `$env:LOCALAPPDATA` is empty, so fall back to `[Environment]::GetFolderPath('LocalApplicationData')`. In `Save-RecipeFile`, make the `RecipeBox` folder on the first run, when it isn't there yet. Then the box finds its recipes from any folder. The starter's `recipes.json` in this folder isn't needed anymore: `Remove-Item .\recipes.json` deletes that one file.
3. **Colors on the screen only.** Take the color out of `Get-Recipe`, so every name is plain. Then write `Show-Recipe`: for each recipe, one line with `Write-Host`, like `Overnight Oats, 10 min, Breakfast`, with every recipe of 20 minutes or less in green (`$PSStyle.Foreground.Green` before the line, `$PSStyle.Reset` after it).
4. **A window for people who would rather click** (Windows). In `New-RecipeWindow`, add every recipe's name to `$list`. In the click block, find the recipe chosen in the list (`$list.SelectedItem`) and set `$label.Text` to its minutes, like `10 minutes`, or to `Pick a recipe first.` when nothing is chosen. Try it with `Show-RecipeBox`: the script waits until you close the window. On a Mac or Linux, skip this job: Windows Forms is Windows only, and the check skips its tests there.

Then answer the three questions in `answers.txt`, and save it.

## Check your work

The check needs Pester 5 or newer. Install it once, if you haven't already:

```powershell
Install-PSResource Pester
```

Then, from this folder:

```powershell
Invoke-Pester
```

At first most tests fail: that is expected. Each job you finish turns its tests green. A failing test's message says what to look at. Each test points `$env:LOCALAPPDATA` at a throwaway folder that Pester makes and removes, so it starts with an empty box and never touches your own recipes; it puts `$env:LOCALAPPDATA` and your current folder back afterward.

If PowerShell says the check *cannot be loaded* because it *is not digitally signed*, or because *running scripts is disabled*, the folder came from a download that Windows marked as from the internet. Unblock its files once with `Get-ChildItem -Recurse | Unblock-File`, from this folder, and run `Invoke-Pester` again.

## The rules

- Keep the file's name, `RecipeBox.psm1`, and the commands' names and parameters.
- `Get-Recipe` and `Add-Recipe` hand back objects with `Name`, `Minutes` and `Category`, and nothing else: no sentences, no colors.
- `Show-Recipe` writes to the screen with `Write-Host` and hands nothing on.
- The data file is `RecipeBox\recipes.json` under `$env:LOCALAPPDATA`.
- Write each answer on its numbered line, after the `)`, like the example: `0) ConvertTo-Json`.

## Tips

- Text has one property, its `Length`. That's why the starter's `Get-Recipe | Sort-Object Minutes` changes nothing.
- `Split-Path $file` gives the folder a file is in; `Test-Path` says whether it's there; `New-Item -ItemType Directory` makes it.
- A color code in a name is part of the name: `Where-Object Name -eq 'Overnight Oats'` can't find `"$($PSStyle.Foreground.Green)Overnight Oats"`.
- `[void]$list.Items.Add($recipe.Name)` adds a name without printing its position.
- The click block can call `Get-Recipe` and use `Where-Object Name -eq $list.SelectedItem`. Leave `.GetNewClosure()` where it is: it keeps `$list` and `$label` for the click.

## Your own recipe box

When you use the finished module, your recipes are saved in `RecipeBox\recipes.json` under `$env:LOCALAPPDATA`, the same file from any folder. To empty the box, look first with `Remove-Item (Split-Path (Get-RecipeFile)) -Recurse -WhatIf`; the same line without `-WhatIf` deletes the `RecipeBox` folder and every recipe in it.

## Hand it in

When it works, push your solution to a public repo of your own on GitHub, then paste that repo's address into **Submit your exercise** on the lesson page at [ask-codey.com](https://www.ask-codey.com). That's what completes the lesson. The lesson page shows the Git commands, step by step.
