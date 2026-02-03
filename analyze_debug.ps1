$content = Get-Content "lib\logic\game_engine.dart"
$count = 0
$lineNum = 0
$classFound = $false

foreach ($line in $content) {
    $lineNum++
    # Skip comments (simple check)
    $cleanLine = $line -replace "//.*", "" 
    $chars = $cleanLine.ToCharArray()
    foreach ($char in $chars) {
        if ($char -eq "{") {
            $count++
            if (!$classFound -and $line -match "class GameEngine") {
                $classFound = $true
                Write-Host "Class starts at line $lineNum"
            }
        } elseif ($char -eq "}") {
            $count--
            if ($classFound -and $count -eq 0) {
                Write-Host "Class closes at line $lineNum"
                exit
            }
        }
    }
}
Write-Host "File ended with count: $count"
