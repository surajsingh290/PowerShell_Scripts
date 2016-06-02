Param(
  [string]$vcoHost="localhost",
  [string]$vcoPort="8281",
  [string]$user="vcoadmin",
  [string]$pass="vcoadmin",
  [Parameter(Mandatory=$true)]
  [string]$workflowId='ed960237-725e-473d-8d6e-29f3f61cb61a',
  [string]$fileName=$wid + ".workflow"
)

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$vcoUrl = "https://$($vcoHost):$($vcoPort)/vco/api";

# Authentication token
$token = ConvertTo-Base64("$($user):$($pass)");
$auth = "Basic $($token)";

$headers = @{"Authorization"= $auth;'Accept'='Application/zip'; 'Accept-Encoding'='gzip, deflate'; };
$expWorkflowURI = "https://$($vcoHost):$($vcoPort)/vco/api/workflows/$($workflowId)";
$ret = Invoke-WebRequest -uri $expWorkflowURI -Headers $headers -ContentType "application/xml;charset=utf-8" -Method Get

$ret.Content | Set-Content -Path  $fileName -Encoding Byte

write-host "";
write-host "$expWorkflowURI";
write-host "Exported  to: $fileName";