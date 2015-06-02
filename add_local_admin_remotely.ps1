$computer = Read-Host -Prompt "Remote computer name"
$username = Read-Host -Prompt "Remote account name (new or existing)"

Do {
    $password = Read-Host -Prompt "New password for remote account" -AsSecureString
    $password_confirm = Read-Host -Prompt "Confirm new password" -AsSecureString
    $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    $pass_confirm = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password_confirm))
} Until ($pass -ceq $pass_confirm)

Try {
    $user_exists = [ADSI]::Exists("WinNT://$computer/$username,User")
} Catch {
    $user_exists = $false
}

If ($user_exists) {
    Out-Host -InputObject "The user $computer\$username already exists."
    $user = [ADSI]"WinNT://$computer/$username,User"
} Else {
    Out-Host -InputObject "The user $computer\$username does not exist."
    $prov = [ADSI]"WinNT://$computer"
    Out-Host -InputObject "Creating user account."
    $user = $prov.Create("User", $username)
}

Out-Host -InputObject "Setting password."
$user.SetPassword($pass)
Out-Host -InputObject "Disabling password expiration."
$user.Put("userFlags", ($user.userFlags.Value -bor 65536))
Out-Host -InputObject "Saving account information."
$user.SetInfo()

$administrators = [ADSI]"WinNT://$computer/Administrators,Group"
Out-Host -InputObject "Adding $computer\$username to $computer\Administrators."
Try {
    $administrators.Add($user.Path)
} Catch {
    Out-Host -InputObject $_.Exception.InnerException.Message
}

Out-Host -InputObject "Press any key to quit"
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
