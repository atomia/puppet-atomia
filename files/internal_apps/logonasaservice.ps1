function Grant-LogOnAsService{
param(
    [string[]] $users
    )


    #Get list of currently used SIDs
    secedit /export /cfg tempexport.inf
    $curSIDs = Select-String .\tempexport.inf -Pattern "SeServiceLogonRight"
    $Sids = $curSIDs.line
    $sidstring = ""
    foreach($user in $users){
        try{
            $objUser = New-Object System.Security.Principal.NTAccount("$user") 
            $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        }
        catch{
            Write-Host "User ""$user"" can not be found !!!" -foregroundcolor red
            break
        }
        if(!$Sids.Contains($strSID) -and !$sids.Contains($user)){
        	$sidstring += ",*$strSID"
        }
    }
    if($sidstring){
        $newSids = $sids + $sidstring
        Write-Host "New Sids: $newSids"
        $tempinf = Get-Content tempexport.inf
        $tempinf = $tempinf.Replace($Sids,$newSids)
        Add-Content -Path tempimport.inf -Value $tempinf
        secedit /import /db secedit.sdb /cfg ".\tempimport.inf"
        secedit /configure /db secedit.sdb

        gpupdate /force
    }
    else{
        Write-Host "No new sids"
    }



    del ".\tempimport.inf" -force -ErrorAction SilentlyContinue
    del ".\secedit.sdb" -force -ErrorAction SilentlyContinue
    del ".\tempexport.inf" -force

}

Grant-LogOnAsService "apppooluser"

New-Item -ItemType directory -Path C:\install\logonasaservice
