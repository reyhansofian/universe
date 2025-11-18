# WSL2 VPN Connectivity Fix

## Problem
WSL2 uses a virtualized Hyper-V network adapter with NAT, which creates a separate network namespace from Windows. When you connect to OpenVPN on Windows, the VPN tunnel is established on Windows but WSL2 traffic doesn't automatically route through it.

## Root Causes
1. **Network Isolation**: WSL2 doesn't share the Windows network stack directly
2. **DNS Issues**: WSL2's auto-generated DNS doesn't update when VPN connects
3. **Routing**: WSL2 traffic goes through NAT, bypassing the VPN tunnel

## Solutions Implemented

### 1. NixOS Configuration Changes
The following changes have been made to `/hosts/nixos/wsl.nix`:

- **Disabled automatic DNS generation**: `generateResolvConf = false` allows manual DNS management
- **Added fallback DNS servers**: Google DNS (8.8.8.8, 8.8.4.4) as fallback
- **Created `wsl-vpn-sync` script**: Syncs Windows DNS to WSL when VPN connects

### 2. Windows .wslconfig (Recommended)

Create or edit `C:\Users\<YourUsername>\.wslconfig` with the following content:

```ini
[wsl2]
# Network mirroring mode (Windows 11 22H2+ only)
# This makes WSL2 use the same network interface as Windows
networkingMode=mirrored

# DNS tunneling - helps with VPN DNS resolution
dnsTunneling=true

# Localhost forwarding
localhostForwarding=true

# Auto proxy (helps with corporate proxies/VPNs)
autoProxy=true
```

**Note**: `networkingMode=mirrored` requires Windows 11 22H2 (build 22621) or later. If you're on Windows 10 or older Windows 11, remove this line.

After creating/editing `.wslconfig`, restart WSL:
```powershell
wsl --shutdown
```

## Usage Instructions

### Method 1: Automatic DNS Sync (Recommended)

1. **Rebuild NixOS configuration**:
   ```bash
   sudo nixos-rebuild switch
   ```

2. **After connecting to VPN on Windows**, run in WSL:
   ```bash
   wsl-vpn-sync
   ```

3. **Test connectivity**:
   ```bash
   ping google.com
   nslookup your-vpn-resource.example.com
   ```

### Method 2: Manual DNS Configuration

If the script doesn't work, manually edit `/etc/resolv.conf`:

1. **Find Windows DNS servers** (in PowerShell on Windows):
   ```powershell
   Get-DnsClientServerAddress -AddressFamily IPv4
   ```

2. **Edit resolv.conf in WSL**:
   ```bash
   sudo nano /etc/resolv.conf
   ```

3. **Add nameservers**:
   ```
   nameserver <VPN_DNS_1>
   nameserver <VPN_DNS_2>
   nameserver 8.8.8.8
   ```

### Method 3: Automatic DNS Sync on Shell Start (Optional)

Add to your shell RC file (`~/.zshrc` or `~/.bashrc`):

```bash
# Auto-sync DNS when VPN might be active
if command -v wsl-vpn-sync &> /dev/null; then
  # Only run if resolv.conf is older than 1 hour
  if [ -f /etc/resolv.conf ]; then
    if [ $(find /etc/resolv.conf -mmin +60 2>/dev/null) ]; then
      echo "DNS might be stale, syncing..."
      wsl-vpn-sync
    fi
  fi
fi
```

## Verification

### Check DNS Resolution
```bash
# Should show VPN DNS servers
cat /etc/resolv.conf

# Test DNS lookup
nslookup google.com

# If you have a VPN-only resource, test it
nslookup internal.company.com
```

### Check Routing
```bash
# Check default route (requires iproute2 package)
ip route show

# Test connectivity
ping 8.8.8.8
ping google.com
```

### Test VPN Resources
Try accessing resources that are only available through VPN:
```bash
curl https://internal.company.com
ssh user@internal-server
```

## Troubleshooting

### Issue: DNS not updating
- **Solution**: Run `wsl-vpn-sync` manually after connecting to VPN
- **Alternative**: Add the script to your shell RC file

### Issue: Still can't reach VPN resources
- **Check**: Verify VPN is connected on Windows
- **Check**: Run `wsl-vpn-sync` and verify DNS servers are from VPN
- **Try**: Restart WSL completely: `wsl --shutdown` (in PowerShell)

### Issue: Network mirroring not working
- **Requirement**: Windows 11 22H2+ (build 22621 or later)
- **Check Windows version**: Run `winver` in Windows
- **If older**: Remove `networkingMode=mirrored` from `.wslconfig`

### Issue: Permission denied when running wsl-vpn-sync
- **Solution**: The script uses `sudo` internally, you may need to enter your password

## Alternative: VPN Client in WSL

If the above solutions don't work, consider installing OpenVPN client directly in WSL:

```nix
# Add to wsl.nix
environment.systemPackages = with pkgs; [
  openvpn
  # ... other packages
];
```

Then run OpenVPN directly in WSL with your VPN config file.

## References
- [WSL2 Networking Documentation](https://learn.microsoft.com/en-us/windows/wsl/networking)
- [WSL2 Advanced Settings (.wslconfig)](https://learn.microsoft.com/en-us/windows/wsl/wsl-config#wslconfig)
- [NixOS WSL Module](https://github.com/nix-community/NixOS-WSL)
