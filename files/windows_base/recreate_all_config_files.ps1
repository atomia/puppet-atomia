$items = Get-ChildItem -Path "C:\Program Files (x86)\Atomia\" -Filter "Recreate config files.lnk" -Recurse
foreach($item in $items)
{
	Start-Process $item.FullName
}

