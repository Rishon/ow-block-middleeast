# ow-block-middleeast

Keeps Overwatch off Middle East game servers with a single Windows Firewall rule.

## Run

Right-click `firewall-block.ps1`, choose **Run with PowerShell**, and accept the admin prompt. Then:

1. Type **B** to block or **U** to unblock.
2. When blocking, enter the path to `Overwatch.exe` (its folder also works), or press Enter to use the suggested path.
3. Restart Overwatch.

Run it again any time to refresh the server list or remove the block.

## How it works

- The Middle East IP ranges are downloaded fresh on every run from the official [AWS](https://ip-ranges.amazonaws.com/ip-ranges.json) and [Google Cloud](https://www.gstatic.com/ipranges/cloud.json) lists.
- One outbound rule blocks UDP ports 6250 and 12000-64000 to those ranges, for `Overwatch.exe` only. Other apps are unaffected.
- The rule shows up as **Overwatch - block Middle East servers** in Windows Defender Firewall's outbound rules.
