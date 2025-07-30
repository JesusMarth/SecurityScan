# 🔒 Web Security Scanner with OWASP ZAP

A personal project as a junior that automates security scanning of vulnerable web applications using **OWASP ZAP** and **Docker**. Perfect for learning about web vulnerabilities and DevSecOps practices.

## What This Project Does

This tool automatically:
- Spins up a vulnerable web app (OWASP Juice Shop) using Docker
- Runs comprehensive security scans with OWASP ZAP
- Generates detailed security reports in multiple formats
- Works on both Windows (PowerShell) and Linux/macOS (Bash)

## Quick Start

### Prerequisites
- Docker and Docker Compose
- OWASP ZAP (will be installed automatically)
- PowerShell (Windows) or Bash (Linux/macOS)

### Setup
```bash
# Clone this repository
git clone <your-repo-url>
cd security-scanner

# Run the setup script
.\scripts\setup.ps1  # Windows
./scripts/setup.sh   # Linux/macOS
```

### Run a Security Scan
```bash
# Full security scan
.\scripts\security_scan.ps1  # Windows
./scripts/security_scan.sh   # Linux/macOS

# Quick test to verify everything works
.\scripts\quick_test.ps1     # Windows
./scripts/quick_test.sh      # Linux/macOS
```

## What You'll Get

After running the scan, you'll find in the `reports/` folder:
- **`zap-report.html`** - Detailed visual report
- **`zap-report.json`** - Structured data for analysis
- **`zap-report.xml`** - Standard format for integration

## Vulnerabilities Detected

OWASP ZAP will find common web vulnerabilities like:
- SQL Injection
- Cross-Site Scripting (XSS)
- Cross-Site Request Forgery (CSRF)
- Information disclosure
- Insecure configurations
- Authentication vulnerabilities

## Understanding the Results

### Risk Levels
- **🔴 Critical/High** - Immediate attention required
- **🟡 Medium** - Should be fixed soon
- **🟢 Low** - Recommended improvement
- **🔵 Informational** - For awareness

### Example Output
```
[INFO] Vulnerability summary:
[INFO]   - Critical: 5
[INFO]   - Medium: 12
[INFO]   - Low: 8
```

## Project Structure

```
security-scanner/
├── docker-compose.yml          # Juice Shop configuration
├── scripts/
│   ├── security_scan.ps1       # Main scan script (Windows)
│   ├── security_scan.sh        # Main scan script (Linux/macOS)
│   ├── setup.ps1               # Initial setup (Windows)
│   ├── setup.sh                # Initial setup (Linux/macOS)
│   ├── quick_test.ps1          # Quick environment test
│   └── quick_test.sh           # Quick environment test
├── reports/                    # Generated reports
├── logs/                       # System logs
└── README.md                   # This file
```

## Customization

### Environment Variables
You can modify these variables in the scripts:

```powershell
# Application configuration
$AppUrl = "http://localhost:3000"
$AppName = "OWASP Juice Shop"

# ZAP configuration
$ZapHost = "localhost"
$ZapPort = 8080
```

### Scan Types
To modify the scan type, edit the `Invoke-ZapScan()` function:

```powershell
# Basic scan (current)
zap-baseline.py -t "$AppUrl" -J "$ZapReportJson" -r "$ZapReportHtml" -x "$ZapReportXml" --auto

# Full scan (slower but more thorough)
zap-full-scan.py -t "$AppUrl" -J "$ZapReportJson" -r "$ZapReportHtml" -x "$ZapReportXml" --auto
```

## Troubleshooting

### Common Issues

1. **Port 3000 is busy**
   ```bash
   # Check what's using the port
   lsof -i :3000
   
   # Stop if needed
   docker-compose down
   ```

2. **ZAP won't start**
   ```bash
   # Check installation
   zap.sh -version
   
   # Reinstall if needed
   .\scripts\setup.ps1
   ```

3. **Docker issues**
   ```bash
   # Check Docker
   docker --version
   docker-compose --version
   ```

### Detailed Logs
For more information about errors:

```bash
# View script logs
tail -f logs/security-scan.log

# View ZAP logs
tail -f logs/zap.log

# View Docker logs
docker-compose logs juice-shop
```

## Learning Resources

- [OWASP ZAP Documentation](https://www.zaproxy.org/docs/)
- [OWASP Juice Shop](https://owasp.org/www-project-juice-shop/)
- [Docker Documentation](https://docs.docker.com/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Important Disclaimer

**⚠️ IMPORTANT**: This project is for educational and testing purposes only. Only use these tools on applications you own or have explicit permission to test. Unauthorized use of security tools may be illegal.

---

**Built with ❤️ for learning about cybersecurity and DevSecOps** 