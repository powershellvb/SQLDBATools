Function Get-ClusterInfo
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('MachineName','ComputerName')]
        [String]$ServerName
    )

    if ([String]::IsNullOrEmpty($ServerName) -or (Test-Connection -ComputerName $ServerName -Count 1 -Quiet) -eq $false)
    {
        Write-Host "Supplied value of '$ServerName' for ServerName parameter is invalid, or server is not accessible." -ForegroundColor Red;
        if($LogErrorToInventoryTable) {
            Add-CollectionError -ComputerName $ServerName -Cmdlet 'Get-ClusterInfo' -CommandText "Get-ClusterInfo -ServerName '$ServerName'" -ErrorText "Supplied value of '$ServerName' for Server parameter is invalid, or server is not accessible." -Remark $null;
        }
        return;
    }

    try { # Trying to find ClusterInfo
        Write-Verbose "Trying to connect to [$ServerName] using Invoke-Command.";
        $ClusterService = $null;
        $ClusterService = Invoke-Command -ComputerName $ServerName -ScriptBlock { $ClsSvc = $null; $ClsSvc = Get-Service | Where-Object {$_.Name -eq 'ClusSvc' -and $_.Status -eq 'Running'}; Write-Output $ClsSvc;} -ErrorAction Stop ;
    }
    catch {
        $formatstring = "{0} : {1}`n{2}`n" +
                    "    + CategoryInfo          : {3}`n" +
                    "    + FullyQualifiedErrorId : {4}`n"
        $fields = $_.InvocationInfo.MyCommand.Name,
                  $_.ErrorDetails.Message,
                  $_.InvocationInfo.PositionMessage,
                  $_.CategoryInfo.ToString(),
                  $_.FullyQualifiedErrorId

        $returnMessage = $formatstring -f $fields;
        Write-Verbose "Get-ClusterInfo => Error Occurred while executing Invoke-Command against server [$ServerName]";
        if($LogErrorToInventoryTable) {
            Add-CollectionError -ComputerName $ServerName -Cmdlet 'Get-ClusterInfo' -CommandText "Get-ClusterInfo -ServerName '$ServerName'" `
                                -ErrorText "$returnMessage" `
                                -Remark "Invoke-Command";
        } 
        elseif( $PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent ) { 
            Write-Host "Error Occurred";
            Write-Host $returnMessage -ForegroundColor Red;
        }
        
        Write-Output $null;
        return;
    }
    
    if($ClusterService)
    {
        $ClusterInfo = $null;
        # Check if server is part of Failover Cluster
        $command = {
            $ClusterNodes = Get-ClusterNode;
            $ClusterGroupResources = Get-ClusterGroup -Cluster $ClusterNodes[0].Cluster | Where-Object {$_.IsCoreGroup -eq $false} | Get-ClusterResource;
            #$ClusterGroupResources | Select-Object Cluster, ResourceType, Name | Write-Host
            $SqlClusterNetworkName = $null;
            $AgNetworkName = $null;
            $SqlClusterRG = $ClusterGroupResources | Where-Object {$_.ResourceType -eq 'SQL Server'};
            $AgRG = $ClusterGroupResources | Where-Object {$_.ResourceType -eq 'SQL Server Availability Group'};
            if(![string]::IsNullOrEmpty($SqlClusterRG)) {
                Write-Verbose "Extracting SqlCluster Listener Name";
                $SqlClusterNetworkName = ($ClusterGroupResources | Where-Object {$_.ResourceType -eq 'Network Name'}).Name; 
            }
            if(![string]::IsNullOrEmpty($AgRG)) {
                Write-Verbose "Extracting AG Listener Name";
                $Ag = $ClusterGroupResources | Where-Object {$_.ResourceType -eq 'Network Name'};
                $Name = $Ag.Name;
                $OwnerGroup = ($Ag.OwnerGroup).Name;
                $AgNetworkName = $Name.replace($OwnerGroup+'_','');
                #Write-Host "Listener Name is $AgNetworkName";
            
            }

            $ClusterInfo = @();

            # Get SqlClusterSPN/AgSPN
            if(![string]::IsNullOrEmpty($SqlClusterNetworkName))
            {
                $InfoProp = [Ordered]@{
                    'Name' = $SqlClusterNetworkName;
                    'Role' = 'SqlCluster';
                    'OrderId' = 1;
                }
                $InfoPropObj = New-Object -TypeName PSObject -Property $InfoProp;
                $ClusterInfo += $InfoPropObj;
            }
            elseif (![string]::IsNullOrEmpty($AgNetworkName))
            {
                $InfoProp = $null;
                $InfoProp = [Ordered]@{
                    'Name' = $AgNetworkName;
                    'Role' = 'Ag';
                    'OrderId' = 1;
                }
                $InfoPropObj = New-Object -TypeName PSObject -Property $InfoProp;
                $ClusterInfo += $InfoPropObj;
            }

            # Get WSFCSPN
            $InfoProp = [Ordered]@{
                'Name' = $ClusterNodes[0].Cluster;
                'Role' = 'WSFC';
                'OrderId' = 2;
            }
            $InfoPropObj = New-Object -TypeName PSObject -Property $InfoProp;
            $ClusterInfo += $InfoPropObj;

            # Get Nodes
            foreach($node in $ClusterNodes)
            {
                $InfoProp = [Ordered]@{
                    'Name' = $node.NodeName;
                    'Role' = if(![string]::IsNullOrEmpty($SqlClusterNetworkName)){'SqlClusterNode'}else{'AgNode'};
                    'OrderId' = $node.Id+2;
                }
                $InfoPropObj = New-Object -TypeName PSObject -Property $InfoProp;
                $ClusterInfo += $InfoPropObj;
            }

            Write-Output $ClusterInfo;
        }
        $ClusterInfo = Invoke-Command -ComputerName $ServerName -ScriptBlock $command;
        Write-Output ($ClusterInfo | Select-Object Name, Role, OrderId);
    }
    else {
        Write-Verbose "Cluster Service is not running on computer [$ServerName]";
        Write-Output $null;
    }
}


#$ClusterInfo = Get-ClusterInfo -ServerName 'ServerName' -Verbose
#$ClusterInfo | ft -AutoSize
