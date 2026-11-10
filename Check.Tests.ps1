# Checks RecipeBox.psm1 and your answers, one test per job and per question in README.md.
# Each test points $env:LOCALAPPDATA at a throwaway folder that Pester makes and removes (TestDrive),
# so it starts with an empty recipe box and never touches your own. It puts $env:LOCALAPPDATA and
# your current folder back afterward.
# Run it from this folder with: Invoke-Pester
# You don't need to change this file.

BeforeAll {
    $script:modulePath = Join-Path $PSScriptRoot 'RecipeBox.psm1'
    Import-Module $modulePath -Force

    # A fresh, empty recipe box: its own app-data folder and its own working folder, both new in TestDrive.
    function Use-FreshBox {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N').Substring(0, 8))
        $local = Join-Path $root 'local-app-data'
        $work = Join-Path $root 'work'
        New-Item -ItemType Directory -Force -Path $local, $work | Out-Null
        $env:LOCALAPPDATA = $local
        Set-Location $work
        [pscustomobject]@{ Local = $local; Work = $work }
    }

    function Add-FourRecipes {
        Add-Recipe -Name 'Lemon Garlic Pasta' -Minutes 30 -Category Dinner | Out-Null
        Add-Recipe -Name 'Overnight Oats' -Minutes 10 -Category Breakfast | Out-Null
        Add-Recipe -Name 'Slow Cooker Chili' -Minutes 240 -Category Dinner | Out-Null
        Add-Recipe -Name 'Banana Bread' -Minutes 70 -Category Baking | Out-Null
    }

    # Clicks a button the way Windows Forms does, without showing the window.
    function Invoke-Click($Button) {
        $onClick = [System.Windows.Forms.Button].GetMethod('OnClick', [System.Reflection.BindingFlags]'NonPublic,Instance')
        $onClick.Invoke($Button, @([EventArgs]::Empty)) | Out-Null
    }

    # The answers in answers.txt: the text after "N)", with runs of spaces made single.
    $script:answers = @{}
    foreach ($line in Get-Content (Join-Path $PSScriptRoot 'answers.txt')) {
        if ($line -match '^\s*(\d+)\)\s*(.*)$') {
            $script:answers[[int]$Matches[1]] = ($Matches[2].Trim() -replace '\s+', ' ')
        }
    }
}

Describe 'Exercise: A Recipe Box Module' {

    BeforeEach {
        $script:savedAppData = $env:LOCALAPPDATA
        Push-Location
    }

    AfterEach {
        $env:LOCALAPPDATA = $script:savedAppData
        Pop-Location
    }

    It 'RecipeBox.psm1 is here and loads' {
        Test-Path -LiteralPath $modulePath -PathType Leaf | Should -BeTrue -Because 'the module lives in RecipeBox.psm1, in this folder. Did it get moved or renamed?'
        Get-Command Add-Recipe, Get-Recipe, Show-Recipe, New-RecipeWindow -ErrorAction SilentlyContinue | Should -HaveCount 4 -Because 'the module should load with Import-Module and give you Add-Recipe, Get-Recipe, Show-Recipe and New-RecipeWindow'
    }

    It '1) Get-Recipe hands back objects with Name, Minutes and Category' {
        $null = Use-FreshBox
        Add-FourRecipes
        $recipes = @(Get-Recipe)
        $recipes | Should -HaveCount 4 -Because 'the box has four recipes, so Get-Recipe should hand back four objects'
        $recipes[0] | Should -Not -BeOfType [string] -Because 'each recipe should be an object made with [PSCustomObject]@{ }, not a line of text'
        @($recipes[0].PSObject.Properties.Name) | Should -Be @('Name', 'Minutes', 'Category') -Because 'each object should have the properties Name, Minutes and Category, in that order'
        $recipes[0].Name | Should -Be 'Lemon Garlic Pasta' -Because 'Name should hold the recipe''s name and nothing else'
    }

    It '1) the recipes sort and filter by their minutes and category' {
        $null = Use-FreshBox
        Add-FourRecipes
        @(Get-Recipe | Sort-Object Minutes | ForEach-Object Name) | Should -Be @('Overnight Oats', 'Lemon Garlic Pasta', 'Banana Bread', 'Slow Cooker Chili') -Because 'Sort-Object Minutes should put the quickest first, which needs Minutes to be a number'
        @(Get-Recipe | Where-Object Minutes -le 30 | ForEach-Object Name) | Should -Be @('Lemon Garlic Pasta', 'Overnight Oats') -Because 'Where-Object Minutes -le 30 should find the two recipes of 30 minutes or less'
        @(Get-Recipe -Category Dinner | ForEach-Object Name) | Should -Be @('Lemon Garlic Pasta', 'Slow Cooker Chili') -Because 'Get-Recipe -Category Dinner should hand back only the dinners'
    }

    It '1) Add-Recipe hands back the recipe it added, as an object' {
        $null = Use-FreshBox
        $added = Add-Recipe -Name 'Black Bean Tacos' -Minutes 25 -Category Dinner
        $added | Should -HaveCount 1 -Because 'Add-Recipe should hand back one thing: the new recipe'
        $added.Name | Should -Be 'Black Bean Tacos' -Because 'Add-Recipe should hand back the recipe object it saved, not a sentence about it. A message for people goes to Write-Host'
        $added.Minutes | Should -Be 25 -Because 'the recipe it hands back should have its minutes'
    }

    It '2) recipes are saved in a RecipeBox folder under $env:LOCALAPPDATA, made on the first run' {
        $box = Use-FreshBox
        Add-Recipe -Name 'Overnight Oats' -Minutes 10 -Category Breakfast | Out-Null
        $file = Join-Path $box.Local 'RecipeBox' 'recipes.json'
        Test-Path $file | Should -BeTrue -Because "the box should save to RecipeBox\recipes.json under `$env:LOCALAPPDATA, here $file. Build the path with Join-Path in Get-RecipeFile, and make the RecipeBox folder in Save-RecipeFile when it isn't there yet"
        Test-Path (Join-Path $box.Work 'recipes.json') | Should -BeFalse -Because 'nothing should be saved in the folder you happen to be in'
    }

    It '2) Get-RecipeFile gives the path under $env:LOCALAPPDATA' {
        $box = Use-FreshBox
        Get-RecipeFile | Should -Be (Join-Path $box.Local 'RecipeBox' 'recipes.json') -Because 'Get-RecipeFile is the one place the path is decided: $env:LOCALAPPDATA, then RecipeBox, then recipes.json'
    }

    It '2) the saved file is JSON that loads back as the same recipes' {
        $box = Use-FreshBox
        Add-Recipe -Name 'Lemon Garlic Pasta' -Minutes 30 -Category Dinner | Out-Null
        Add-Recipe -Name 'Overnight Oats' -Minutes 10 -Category Breakfast | Out-Null
        $file = Join-Path $box.Local 'RecipeBox' 'recipes.json'
        Test-Path $file | Should -BeTrue -Because 'the box should save to RecipeBox\recipes.json under $env:LOCALAPPDATA'
        $saved = @(Get-Content $file -Raw | ConvertFrom-Json)
        @($saved.Name) | Should -Be @('Lemon Garlic Pasta', 'Overnight Oats') -Because 'the file should hold both recipes as JSON, in the order they were added'
        Set-Location $TestDrive
        @(Get-Recipe | ForEach-Object Name) | Should -Be @('Lemon Garlic Pasta', 'Overnight Oats') -Because 'Get-Recipe should find the same recipes from any folder'
    }

    It '2) an empty box hands back nothing, without an error' {
        $null = Use-FreshBox
        $problems = $null
        $recipes = @(Get-Recipe -ErrorVariable problems)
        $recipes | Should -HaveCount 0 -Because 'a box with no recipes yet should hand back nothing'
        $problems | Should -BeNullOrEmpty -Because 'an empty box is a normal first day, not an error: check with Test-Path before reading the file'
    }

    It '3) the recipes'' names have no color codes in them' {
        $null = Use-FreshBox
        Add-Recipe -Name 'Overnight Oats' -Minutes 10 -Category Breakfast | Out-Null
        $oats = Get-Recipe | Where-Object Name -eq 'Overnight Oats'
        $oats | Should -Not -BeNullOrEmpty -Because 'Get-Recipe | Where-Object Name -eq ''Overnight Oats'' should find the oats. A color code in the name, or a line of text, makes the search miss'
        "$($oats.Name)" | Should -Not -Match "`e" -Because 'colors belong on the screen, in Show-Recipe, never in the objects Get-Recipe hands back'
    }

    It '3) Show-Recipe writes every recipe to the screen and hands nothing on' {
        $null = Use-FreshBox
        Add-FourRecipes
        $all = @(Show-Recipe 6>&1)
        $screen = @($all | Where-Object { $_ -is [System.Management.Automation.InformationRecord] })
        $results = @($all | Where-Object { $_ -isnot [System.Management.Automation.InformationRecord] })
        $screen | Should -HaveCount 4 -Because 'Show-Recipe should write one line per recipe to the screen, with Write-Host'
        $results | Should -HaveCount 0 -Because 'Show-Recipe is the end of the line: it writes with Write-Host and hands nothing down the pipeline'
        foreach ($name in 'Lemon Garlic Pasta', 'Overnight Oats', 'Slow Cooker Chili', 'Banana Bread') {
            @($screen | Where-Object { "$_" -like "*$name*" }) | Should -HaveCount 1 -Because "Show-Recipe should show $name"
        }
    }

    It '3) quick recipes are green on the screen, and the others aren''t' {
        $null = Use-FreshBox
        Add-Recipe -Name 'Overnight Oats' -Minutes 10 -Category Breakfast | Out-Null
        Add-Recipe -Name 'Lemon Garlic Pasta' -Minutes 30 -Category Dinner | Out-Null
        $screen = @(Show-Recipe 6>&1 | Where-Object { $_ -is [System.Management.Automation.InformationRecord] })
        $green = $PSStyle.Foreground.Green
        $isGreen = {
            param($record)
            $message = $record.MessageData
            ("$message".Contains($green)) -or ($message.ForegroundColor -eq [ConsoleColor]::Green)
        }
        $oats = $screen | Where-Object { "$_" -like '*Overnight Oats*' } | Select-Object -First 1
        $pasta = $screen | Where-Object { "$_" -like '*Lemon Garlic Pasta*' } | Select-Object -First 1
        $oats | Should -Not -BeNullOrEmpty -Because 'Show-Recipe should show Overnight Oats'
        & $isGreen $oats | Should -BeTrue -Because 'a recipe of 20 minutes or less should be green: $PSStyle.Foreground.Green before it and $PSStyle.Reset after it'
        $pasta | Should -Not -BeNullOrEmpty -Because 'Show-Recipe should show Lemon Garlic Pasta'
        & $isGreen $pasta | Should -BeFalse -Because 'a 30-minute recipe should be in the normal color. Did a $PSStyle.Reset go missing?'
    }

    It '4) the window''s list shows every recipe''s name' -Skip:(-not $IsWindows) {
        $null = Use-FreshBox
        Add-FourRecipes
        $form = New-RecipeWindow
        try {
            $form.Visible | Should -BeFalse -Because 'New-RecipeWindow builds the window; only Show-RecipeBox shows it'
            $list = $form.Controls | Where-Object { $_ -is [System.Windows.Forms.ListBox] } | Select-Object -First 1
            $list | Should -Not -BeNullOrEmpty -Because 'the window should still have its ListBox'
            @($list.Items) | Should -Be @('Lemon Garlic Pasta', 'Overnight Oats', 'Slow Cooker Chili', 'Banana Bread') -Because 'the list should hold every recipe''s name, from Get-Recipe, in order: add each one with $list.Items.Add()'
        }
        finally { $form.Dispose() }
    }

    It '4) clicking How long? shows the chosen recipe''s minutes' -Skip:(-not $IsWindows) {
        $null = Use-FreshBox
        Add-FourRecipes
        $form = New-RecipeWindow
        try {
            $list = $form.Controls | Where-Object { $_ -is [System.Windows.Forms.ListBox] } | Select-Object -First 1
            $button = $form.Controls | Where-Object { $_ -is [System.Windows.Forms.Button] } | Select-Object -First 1
            $label = $form.Controls | Where-Object { $_ -is [System.Windows.Forms.Label] } | Select-Object -First 1
            $list.Items.Count | Should -BeGreaterThan 1 -Because 'the list needs the recipes in it first (the test before this one)'
            $list.SelectedItem = 'Overnight Oats'
            Invoke-Click $button
            $label.Text | Should -Match '\b10 minutes\b' -Because 'with Overnight Oats picked, a click on How long? should set $label.Text to its minutes, like 10 minutes'
            $list.SelectedItem = 'Slow Cooker Chili'
            Invoke-Click $button
            $label.Text | Should -Match '\b240 minutes\b' -Because 'each click should look up the recipe picked at that moment, here Slow Cooker Chili'
        }
        finally { $form.Dispose() }
    }

    It 'answer 1) the parameter that closes a progress bar' {
        $answers[1] | Should -Not -BeNullOrEmpty -Because 'question 1 has no answer yet'
        $answers[1] | Should -Match '^-?Completed$' -Because 'Write-Progress with -Activity and -Completed closes the bar when the job is done'
    }

    It 'answer 2) the $PSStyle property that ends a color' {
        $answers[2] | Should -Not -BeNullOrEmpty -Because 'question 2 has no answer yet'
        $answers[2] | Should -Match '^(\$PSStyle\.)?Reset$' -Because 'a color goes on until $PSStyle.Reset puts the text back to normal'
    }

    It 'answer 3) the method that shows a window and waits' {
        $answers[3] | Should -Not -BeNullOrEmpty -Because 'question 3 has no answer yet'
        $answers[3] | Should -Match '^(\$form\.)?ShowDialog(\(\))?$' -Because 'ShowDialog() opens the window and waits there until it''s closed; look at Show-RecipeBox'
    }
}
