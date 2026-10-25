$ErrorActionPreference='Stop'
$word=New-Object -ComObject Word.Application
try {
 $word.Visible=$false
 $word.DisplayAlerts=0
 $d=$word.Documents.Open('C:\flutter_projects\romance_club\.coursework\audit_current.docx',$false,$true)
 $d.Repaginate()
 $d.ExportAsFixedFormat('C:\flutter_projects\romance_club\.coursework\audit_current.pdf',17)
 $out=@()
 foreach($p in $d.Paragraphs){
  $t=$p.Range.Text.Trim()
  if($t -match '^(ВВЕДЕНИЕ|ЗАКЛЮЧЕНИЕ|СПИСОК|[123](\.|\s)|Рисунок\s+\d|Таблица\s+\d|ПРИЛОЖЕНИЕ)'){
   $out+=('{0}`t{1}`t{2}`t{3}' -f $p.Range.Information(3),$p.Range.Information(1),$p.Range.Start,$t)
  }
 }
 $out | Set-Content 'C:\flutter_projects\romance_club\.coursework\audit_pages.txt' -Encoding UTF8
 Write-Output ('PAGES '+$d.ComputeStatistics(2)+' TOC '+$d.TablesOfContents.Count)
 $d.Close(0)
} finally {$word.Quit()}
