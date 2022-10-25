[cmdletbinding()]
param(
    $subscriptionId
)

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
$connection = Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
Set-AzContext -Subscription $subscriptionId


# This will only get resource groups with an ExpirationDate tag. Very possibly would want to list those that don't have an expiration date...
$rgs = Get-AzResourceGroup | Select -Property ResourceGroupName, @{n="ExpirationDate";e={$_.Tags.ExpirationDate}} | where ExpirationDate -NotLike ""

write-output "Here are the expired RGs:"
write-output $rgs
write-output "`n"

foreach ($rg in $rgs) {
    try {
        $rg_name = $rg.ResourceGroupName
        Write-Output "Preparing to work through $rg_name"
        $expDate = [datetime]::parseexact($rg.ExpirationDate,'O',$null)
        write-output "$rg_name will expire on $expDate"

        if ((Get-Date) -gt $expDate) {
            write-output "Checking to see if $rg_name has a longLived tag" # I would also highly recommend resource locks on critical infra :)

            # This will find a resource group that starts with MC (i.e., the Kubernetes Managed Cluster RG)
            # We skip going through the delete process for this because it will be deleted when the cluster resource is deleted.
            # Other services may have the same design, so recommend expanding before using in production.
			if ($rg_name.StartsWith('MC')) {
				write-output "$rg_name is a Kubernetes managed resource group"
			} else {
				if (!(Get-AzResourceGroup -name $rg_name | select @{n="LongLived";e={$_.Tags.longLived}} | select -ExpandProperty LongLived)) {
					write-output "$rg_name is expired, deleting..."
					Remove-AzResourceGroup -Name $rg_name -Force
					Write-Output "Deleted resource group $rg_name"
				} else {
					write-output "$rg_name is set to be longLived"
				}
			}
        } else {
            write-output "$rg_name is not expired"
        }
    } catch {
        write-output "had an issue with $rg"
    }
    write-output "`n"
}