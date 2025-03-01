#Add-Type -Path "C:\InnovatorCE2025\Innovator\Server\bin\IOM.dll"
Add-Type -Path "C:\Repos\SECE\tools\ConsoleUpgrade\IOM.dll"

$conn =[Aras.IOM.IomFactory]::CreateHttpServerConnection( `
   "http://localhost/SECE/Server/InnovatorServer.aspx", `
   "SECE", `
   "root" ,`
    "innovator")
   $res = $conn.Login()
if ($res.isError()) 
{
   $res.dom.DocumentElement.OuterXml
   "Script cannot continue and will exit."
   exit 
}
$res.dom.DocumentElement.OuterXml
$conn


