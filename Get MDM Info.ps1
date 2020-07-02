$AccountId = ""

Try
{
    $AccountKeys = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts  -ErrorAction SilentlyContinue

    foreach( $Account in $AccountKeys )
    {
        $AccountId = $Account.PSChildName

        # Read the Address Info
        $AddrInfo = (Get-ItemProperty ($Account.pspath+"\Protected\AddrInfo") -ErrorAction SilentlyContinue)

    
        # If this is the MSIT Account
        if(($AddrInfo -ne $null) -and ($AddrInfo.Addr.Contains("https://r.manage-beta.microsoft.com")) )
        {
            # Read Connection Info
            $ConnInfo = Get-ItemProperty ($Account.pspath+"\Protected\ConnInfo")

            $ServerLastSuccessTime = $ConnInfo.ServerLastSuccessTime
            $ServerLastFailureTime = $ConnInfo.ServerLastFailureTime
            $LastSessionResult = $ConnInfo.LastSessionResult

            break
        }
    }
}
Catch
{
    return "not enrolled"
}

if( $AccountId -eq "" )
{
    return "not enrolled"
}
else
{
    return (new-object psobject -property  @{Account = $AccountId; ServerLastSuccessTime = $ServerLastSuccessTime; ServerLastFailureTime = $ServerLastFailureTime; LastSessionResult = $LastSessionResult})
}
