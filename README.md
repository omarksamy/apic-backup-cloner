# IBM API Connect – Products & APIs Backup Cloner

**A simple Bash script that**
- Authenticates to IBM API Connect **API Manager** via the APIC CLI  
- Iterates over organizations  
- Fetches all **Products** and **APIs** in each org  
- Saves them locally in a **structured, migration-ready backup**

**What you get**
- **Timestamped backup folders**: `Backup N - YYYY-MM-DD_HH-MM-SS`
- **Per-org export** of draft Products and APIs
- **Logs** per run: `success.log` and `error.log` inside each export folder

**Prerequisites**
- **IBM APIC CLI (Toolkit)**
- **Bash** (macOS, Linux, or Git Bash on Windows)
- Sufficient permissions to list/get draft Products & APIs in API Manager

**Configuration**

Edit the variables at the top of `CloneAPIs.bash`:
```
# Path to your IBM API Connect Toolkit installation
TOOLKIT_DIR=""

# Folder where you want backups to be saved
BASE_OUTPUT_DIR=""

# Prefix for backup folder names
BACKUP_PREFIX=""

# Full path to the APIC CLI binary
APIC_CLI="$TOOLKIT_DIR/apic"

# Login to API Manager
"$APIC_CLI" login \
  --username {YOUR_USERNAME} \
  --password {YOUR_PASSWORD} \
  --server {YOUR_APIC_SERVER} \
  --realm {YOUR_REALM} \
  --mode apim
```

**Output structure**
```
  Backup 3 - 2025-07-21_13-30-55/
  ├── <org-name>/
  │   ├── products/
  │   │   ├── <product-name>-<version>/
  │   │   ├── success.log
  │   │   └── error.log
  │   ├── apis/
  │   │   ├── <api-name>-<version>/
  │   │   ├── success.log
  │   │   └── error.log
  │ 
  └── ...
