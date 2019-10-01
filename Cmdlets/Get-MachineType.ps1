Function Get-MachineType
{ 
<# 
.Synopsis 
   A quick function to determine if a computer is VM or physical box. 
.DESCRIPTION 
   This function is designed to quickly determine if a local or remote 
   computer is a physical machine or a virtual machine. 
.NOTES 
   Created by: Jason Wasser 
   Modified: 9/11/2015 04:12:51 PM   
 
   Changelog:  
    * added credential support 
 
   To Do: 
    * Find the Model information for other hypervisor VM's like Xen and KVM. 
.EXAMPLE 
   Get-MachineType 
   Query if the local machine is a physical or virtual machine. 
.EXAMPLE 
   Get-MachineType -ComputerName SERVER01  
   Query if SERVER01 is a physical or virtual machine. 
.EXAMPLE 
   Get-MachineType -ComputerName (Get-Content c:\temp\computerlist.txt) 
   Query if a list of computers are physical or virtual machines. 
.LINK 
   https://gallery.technet.microsoft.com/scriptcenter/Get-MachineType-VM-or-ff43f3a9 
#>
    [CmdletBinding()] 
    [OutputType([int])] 
    Param 
    ( 
        # ComputerName 
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)] 
        [string[]]$ComputerName=$env:COMPUTERNAME, 
        $Credential = [System.Management.Automation.PSCredential]::Empty 
    ) 
 
    Begin 
    { 
    } 
    Process 
    { 
        foreach ($Computer in $ComputerName) { 
            Write-Verbose "Checking $Computer" 
            try { 
                $hostdns = [System.Net.DNS]::GetHostEntry($Computer) 
                $ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer -ErrorAction Stop -Credential $Credential 
                 
                switch ($ComputerSystemInfo.Model) { 
                     
                    # Check for Hyper-V Machine Type 
                    "Virtual Machine" { 
                        $MachineType="VM" 
                        } 
 
                    # Check for VMware Machine Type 
                    "VMware Virtual Platform" { 
                        $MachineType="VM" 
                        } 
 
                    # Check for Oracle VM Machine Type 
                    "VirtualBox" { 
                        $MachineType="VM" 
                        } 
 
                    # Check for Xen 
                    # I need the values for the Model for which to check. 
 
                    # Check for KVM 
                    # I need the values for the Model for which to check. 
 
                    # Otherwise it is a physical Box 
                    default { 
                        $MachineType="Physical" 
                        } 
                    } 
                 
                # Building MachineTypeInfo Object 
                $MachineTypeInfo = New-Object -TypeName PSObject -Property ([ordered]@{ 
                    ComputerName=$ComputerSystemInfo.PSComputername 
                    Type=$MachineType 
                    Manufacturer=$ComputerSystemInfo.Manufacturer 
                    Model=$ComputerSystemInfo.Model 
                    }) 
                $MachineTypeInfo 
                } 
            catch [Exception] { 
                Write-Output "$Computer`: $($_.Exception.Message)" 
                } 
            } 
    } 
    End 
    { 
 
    } 
}