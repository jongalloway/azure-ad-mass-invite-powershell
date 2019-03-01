# Bulk Azure AD Invites with Group Add and Pretty E-Mails

This is a script I used to bulk invite from a CSV list, adding each person to an Azure AD Group, and sending pretty e-mails.

Big caveat is that it doesn't work with [Modern Authentication (MFA)](https://docs.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/enable-or-disable-modern-authentication-in-exchange-online)
since it uses send-mailmessage, which is a pretty big showstopper. Possible workarounds:
* User an app password
* Send e-mail using the Graph API

Main references: 
* https://www.adamfowlerit.com/2017/03/azure-ad-b2b-powershell-invites/
* https://github.com/leemunroe/responsive-html-email-template
