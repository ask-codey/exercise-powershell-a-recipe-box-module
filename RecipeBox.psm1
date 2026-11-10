# RecipeBox.psm1: a recipe box you can use from the prompt, or from a window.
# Load it with: Import-Module .\RecipeBox.psm1 -Force
# (-Force loads it again after you change this file.)

# Job 2: the box's one place for its data. Right now it's recipes.json in whatever
# folder you happen to be in.
function Get-RecipeFile {
    Join-Path (Get-Location) 'recipes.json'
}

# Reads every saved recipe from the file, as it was saved. Ready to use.
function Read-RecipeFile {
    $file = Get-RecipeFile
    if (Test-Path $file) {
        $saved = Get-Content $file -Raw | ConvertFrom-Json
        $saved
    }
}

# Saves a list of recipes to the file.
function Save-RecipeFile {
    param($Recipes)
    $file = Get-RecipeFile
    # Job 2: on the first run, the folder isn't there yet.
    $Recipes | ConvertTo-Json -AsArray | Set-Content $file
}

function Add-Recipe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] [ValidateRange(1, 1440)] [int] $Minutes,
        [Parameter(Mandatory)] [ValidateSet('Breakfast', 'Lunch', 'Dinner', 'Baking', 'Snack')] [string] $Category
    )
    $recipe = [PSCustomObject]@{ Name = $Name; Minutes = $Minutes; Category = $Category }
    Save-RecipeFile -Recipes (@(Read-RecipeFile) + $recipe)
    # Job 1: this hands back a sentence, not the recipe.
    "Added $Name."
}

function Get-Recipe {
    [CmdletBinding()]
    param(
        [ValidateSet('Breakfast', 'Lunch', 'Dinner', 'Baking', 'Snack')] [string] $Category
    )
    foreach ($saved in Read-RecipeFile) {
        if ($Category -and $saved.Category -ne $Category) { continue }
        # Jobs 1 and 3: these lines hand back text, with a color baked into the quick recipes' names.
        $name = $saved.Name
        if ($saved.Minutes -le 20) {
            $name = "$($PSStyle.Foreground.Green)$name$($PSStyle.Reset)"
        }
        "$name - $($saved.Minutes) min - $($saved.Category)"
    }
}

function Show-Recipe {
    [CmdletBinding()]
    param()
    # Job 3: show every recipe on the screen, the quick ones in green.
}

# Builds the Recipe Box window and hands it back, without showing it. Windows only.
function New-RecipeWindow {
    Add-Type -AssemblyName System.Windows.Forms
    $form = [System.Windows.Forms.Form]::new()
    $form.Text = 'Recipe Box'
    $form.ClientSize = [System.Drawing.Size]::new(320, 250)
    $form.StartPosition = 'CenterScreen'

    $list = [System.Windows.Forms.ListBox]::new()
    $list.Location = [System.Drawing.Point]::new(10, 10)
    $list.Size = [System.Drawing.Size]::new(300, 160)
    # Job 4: fill the list.

    $button = [System.Windows.Forms.Button]::new()
    $button.Text = 'How long?'
    $button.Location = [System.Drawing.Point]::new(10, 185)
    $button.Size = [System.Drawing.Size]::new(100, 30)

    $label = [System.Windows.Forms.Label]::new()
    $label.Location = [System.Drawing.Point]::new(120, 192)
    $label.AutoSize = $true

    # GetNewClosure() keeps $list and $label for the click, after this function has ended.
    $button.Add_Click({
        # Job 4: show how long the chosen recipe takes.
    }.GetNewClosure())

    $form.Controls.AddRange(@($list, $button, $label))
    $form
}

# Opens the Recipe Box window and waits until it's closed. Ready to use.
function Show-RecipeBox {
    $form = New-RecipeWindow
    $form.ShowDialog() | Out-Null
    $form.Dispose()
}
