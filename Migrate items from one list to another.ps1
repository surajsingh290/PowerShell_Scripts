$siteUrl="https://dupont.sharepoint.com/teams/teams_ODSA_Japan"
$srcListTitle="ShaberibaTest"
$destListTitle="ShaberibaTest2"


$ErrorActionPreference = "Stop"

If ($siteUrl -eq $null)
{
  Write-Host "Example)"
  Write-Host ">.\MigrateDiscussionBoard.ps1 -siteUrl https://dupont.sharepoint.com/teams/teams_ODSA_Japan -srcListTitle ShaberibaTest -destListTitle ShaberibaTest2"
  return
}

# Load the required assembly
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

# Connect to SharePoint Online
$context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)

Write-Host ""

# Prompt user to input username
Write-Host "Please input user name : "
$username = read-host

# Prompt user to input password
Write-Host "Please input password : "
$password = read-host -assecurestring

Write-Host ""

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $password) 

$context.Credentials = $credentials
$srclist = $context.Web.Lists.GetByTitle($srcListTitle)
$destlist = $context.Web.Lists.GetByTitle($destListTitle)
$context.Load($srclist)
$context.Load($destlist)
$context.ExecuteQuery()
$camlquery = New-Object Microsoft.SharePoint.Client.CamlQuery
$items = $srclist.GetItems($camlquery)


$context.Load($items)
$context.ExecuteQuery()

foreach ($item in $items)
{
  $context.Load($item)
  $context.ExecuteQuery()

  $discussionitem = [Microsoft.SharePoint.Client.Utilities.Utility]::CreateNewDiscussion($context, $destlist, $item.Item("Title"))
  $discussionitem.Update()
  $context.ExecuteQuery()

  $messagecamlquery = New-Object Microsoft.SharePoint.Client.CamlQuery
  $messagecamlquery.ViewXml = "<View Scope='Recursive'><Query><Where><Eq><FieldRef Name='ParentFolderId'/><Value Type='Integer'>" + $item.Id + "</Value></Eq></Where></Query></View>"
  $messageitems = $srclist.GetItems($messagecamlquery)
  $context.Load($messageitems)
  $context.ExecuteQuery()

  foreach ($messageitem in $messageitems)
  {
    $replyitem = [Microsoft.SharePoint.Client.Utilities.Utility]::CreateNewDiscussionReply($context, $discussionitem)
    $replyitem.Item("Body") = $messageitem.Item("Body")
    $replyitem.Item("Author") = $messageitem.Item("Author")
    $replyitem.Item("Editor") = $messageitem.Item("Editor")
    $replyitem.Item("Created") = $messageitem.Item("Created")
    $replyitem.Item("Modified") = $messageitem.Item("Modified")
    $replyitem.Update()
  }

  $discussionitem.Item("Body") = $item.Item("Body")
  $discussionitem.Item("Author") = $item.Item("Author")
  $discussionitem.Item("Editor") = $item.Item("Editor")
  $discussionitem.Item("Created") = $item.Item("Created")
  $discussionitem.Item("Modified") = $item.Item("Modified")
  $discussionitem.Item("LastReplyBy") = $item.Item("LastReplyBy")
  $discussionitem.Item("BestAnswerId") = $item.Item("BestAnswerId")
  $discussionitem.Item("IsAnswered") = $item.Item("IsAnswered")
  $discussionitem.Update()
  $context.ExecuteQuery()
}

if ($items.Count -gt 0)
{
  Write-Host "Discussion Board List has been successfully migrated."
}
else
{
  Write-Host "Discussion Board List has no data."
}
Write-Host ""

