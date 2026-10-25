$ErrorActionPreference = 'Stop'
$word = New-Object -ComObject Word.Application
try {
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $doc = $word.Documents.Open('C:\flutter_projects\romance_club\.coursework\edited.docx')
    # Refresh the existing contents rather than replacing the author's document.
    foreach ($toc in $doc.TablesOfContents) { $toc.Update() }
    $doc.Fields.Update() | Out-Null
    foreach ($sec in $doc.Sections) {
        foreach ($foot in $sec.Footers) {
            $foot.Range.Font.Name = 'Times New Roman'
            $foot.Range.Font.Size = 14
            $foot.Range.ParagraphFormat.Alignment = 1
            $foot.Range.Fields.Update() | Out-Null
        }
    }
    # Keep generated contents readable and consistent with the source regulation.
    foreach ($name in @(-20,-21,-22)) {
        try {
            $sty = $doc.Styles.Item($name)
            $sty.Font.Name = 'Times New Roman'
            $sty.Font.Size = 14
            $sty.Font.Color = 0
            $sty.ParagraphFormat.SpaceBefore = 0
            $sty.ParagraphFormat.SpaceAfter = 0
            $sty.ParagraphFormat.LineSpacingRule = 0
        } catch { }
    }
    foreach ($toc in $doc.TablesOfContents) {
        $toc.Range.Font.Name = 'Times New Roman'
        $toc.Range.Font.Size = 14
        $toc.Range.ParagraphFormat.SpaceBefore = 0
        $toc.Range.ParagraphFormat.SpaceAfter = 0
        $toc.Range.ParagraphFormat.LineSpacingRule = 0
        $toc.Range.ParagraphFormat.KeepWithNext = 0
        $toc.Range.ParagraphFormat.Alignment = 0
    }
    $doc.Repaginate()
    foreach ($toc in $doc.TablesOfContents) { $toc.UpdatePageNumbers() }
    $doc.Save()
    $doc.ExportAsFixedFormat('C:\flutter_projects\romance_club\.coursework\edited.pdf',17)
    Write-Output ('Pages: ' + $doc.ComputeStatistics(2))
    $doc.Close(0)
} finally { $word.Quit() }
