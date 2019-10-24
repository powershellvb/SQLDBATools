function Add-SqlAgentOperator {
<#
.SYNOPSIS
This function creates SQL Agent operator
.DESCRIPTION
This function creates SQL Agent Operator with specified Name & EmailID
.PARAMETER SqlInstance
Sql Server Instance against which Operator is to be created
.PARAMETER OperatorName
Name of the Operator to create
.PARAMETER EmailId
Email id of the Operator to create
.EXAMPLE OperatorName
Add-SqlAgentOperator -SqlInstance 'testvm' -OperatorName 'DBAGroup' -EmailId 'DBAGroup@Contso.com'
The command creates SQL Agent operator DBAGroup on sql instance testvm.
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('Instance')]
        [String]$SqlInstance,

        [Parameter(Mandatory=$true)]
        [Alias('Name')]
        [String]$OperatorName,

        [Parameter(Mandatory=$true)]
        [Alias('OperatorEmailID')]
        [String]$EmailId
    )

    $conn = Connect-DbaInstance -SqlInstance $SqlInstance;

    $tsqlCreateOperator = @"
IF NOT EXISTS(SELECT * FROM msdb..sysoperators o where o.name = '$OperatorName')
BEGIN
    EXEC msdb.dbo.sp_add_operator @name=N'$OperatorName', 
		    @enabled=1, 
		    @pager_days=0, 
		    @email_address=N'$EmailId'
END
"@;

    if($PSCmdlet.ShouldProcess($SqlInstance)) {
        Invoke-DbaQuery -SqlInstance $conn -Query $tsqlCreateOperator -ErrorAction Continue -WarningAction SilentlyContinue;
        Write-Verbose "Opeartor $OperatorName created.";
        return 0;
    }
}