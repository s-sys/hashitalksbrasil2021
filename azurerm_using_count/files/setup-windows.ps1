#ps1
# Create directory
New-Item -Path "c:\" -Name "temp-salt" -ItemType "directory"

# Download salt-minion
$source = 'https://repo.saltproject.io/windows/Salt-Minion-3004-Py3-AMD64.msi'
$destination = 'c:\temp-salt\Salt-Minion-3004-Py3-AMD64.msi'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $source -OutFile $destination

# Install salt-minion
Start-Process msiexec.exe -Wait -NoNewWindow -ArgumentList '/I C:\temp-salt\Salt-Minion-3004-Py3-AMD64.msi /quiet /norestart'

# Remove temp folder
Remove-Item –path c:\temp-salt –recurse 
