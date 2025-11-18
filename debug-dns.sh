#!/usr/bin/env bash
# Debug script to troubleshoot DNS sync issues

echo "=== WSL VPN DNS Debug Script ==="
echo ""

echo "1. Testing PowerShell access..."
powershell.exe -Command "Write-Output 'PowerShell works!'" 2>&1
echo ""

echo "2. Checking Windows DNS (method 1)..."
powershell.exe -Command "Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object {\$_.ServerAddresses} | ForEach-Object {\$_.ServerAddresses}" 2>&1 | tr -d '\r'
echo ""

echo "3. Checking Windows DNS (method 2)..."
powershell.exe -Command "Get-NetIPConfiguration | Where-Object {\$_.DNSServer -ne \$null} | ForEach-Object {\$_.DNSServer.ServerAddresses}" 2>&1 | tr -d '\r'
echo ""

echo "4. Checking Windows network adapters..."
powershell.exe -Command "Get-NetAdapter | Where-Object {\$_.Status -eq 'Up'} | Select-Object Name, Status, InterfaceDescription" 2>&1 | tr -d '\r'
echo ""

echo "5. Checking WSL network..."
echo "Default gateway: $(ip route show | grep -i default | awk '{print $3}')"
echo "Can ping gateway?"
ping -c 2 $(ip route show | grep -i default | awk '{print $3}')
echo ""

echo "6. Testing DNS resolution..."
echo "Can reach 1.1.1.1?"
ping -c 2 1.1.1.1
echo ""

echo "7. Current /etc/resolv.conf:"
cat /etc/resolv.conf
