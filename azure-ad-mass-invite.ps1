# Pull in defaults from config
. .\config.ps1

function readValue([string]$item, [string]$prompt) {
    if($item) {return $item}
    return read-host $prompt
}

$cred = Get-Credential
$cred.Password.MakeReadOnly()
Connect-AzureAD -Credential $cred

$groupname =            readValue $groupname        'Group to add members to'
$inviteCsv =            readValue $inviteCsv        'CSV file path'
$inviteRedirectUrl =    readValue $inviteRedirectUrl 'URL to redirect to after member added'
$emailFrom =            readValue $emailFrom        'Email from address'
$emailSubject =         readValue $emailSubject     'Email subject'

$group = get-azureadgroup -SearchString $groupname
if ($group.count -ne 1) {Write-Output "Not Exactly One Group Found"; break}

$existingUsers = Get-AzureAdUser
$existingMembers = Get-AzureADGroupMember -ObjectId $group.objectid
$invitations = import-csv -LiteralPath $inviteCsv
$emailtemplate = Get-Content -path .\email-template.html -Raw

foreach ($email in $invitations) {
    $existinguser = $existingUsers | Where-Object {$_.OtherMails -eq $email.InvitedUserEmailAddress} | Select-Object -First 1
    if ($existinguser.count -eq 0) {

        $result = New-AzureADMSInvitation `
            -InvitedUserEmailAddress $email.InvitedUserEmailAddress `
            -InvitedUserDisplayName $email.Name `
            -SendInvitationMessage $false `
            -InviteRedirectUrl $inviteRedirectUrl 

        $inviteurl = $result.InviteRedeemUrl
        $userid = $result.InvitedUser.Id

        #automatically add the new user to Security Group
        Add-AzureADGroupMember `
            -objectid $group.objectid `
            -RefObjectId $userid
    }
    else {
        if ($existingMembers -notcontains $existinguser) {
            #User exists in AAD but is not in group. Invite URL goes directly to site rather than redeem URL.
            Add-AzureADGroupMember `
                -objectid $group.objectid `
                -RefObjectId $existinguser.objectid

            $inviteurl = $inviteRedirectUrl
        } else {
            #Already in group. Could send notification e-mail?
            Write-Output "User $($email.InvitedUserEmailAddress) already in group"
            continue
        }
    }

    #customize and send invitiation e-mail
    $emailbody = $emailtemplate `
        -replace "{{name}}", $email.Name `
        -replace "{{action}}", $inviteurl
  
    Send-MailMessage `
        -Attachments .\header.png, .\footer.png `
        -Body $emailbody `
        -BodyAsHtml `
        -Subject $emailSubject `
        -From $emailFrom `
        -To $email.InvitedUserEmailAddress `
        -SmtpServer 'smtp.office365.com' `
        -Port 587 `
        -Credential $cred  `
        -UseSsl
}