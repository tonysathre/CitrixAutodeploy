Get-ADComputer -Identity $NewBrokerMachine.MachineName.Split('\')[1] | Move-ADObject -TargetPath "OU=VDI,DC=domain,DC=com"