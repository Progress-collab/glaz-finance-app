# 🚀 Webhook Deployment Setup

## Overview
This setup replaces the slow GitHub Actions deployment with instant webhook-based deployment. When you push to GitHub, the server immediately pulls changes and restarts the application - no more waiting!

## 🎯 Benefits
- ⚡ **Instant deployment** (seconds vs minutes)
- 💰 **No GitHub Actions usage** (saves compute time)
- 🔄 **Automatic restart** on every push
- 🛡️ **Runs as Windows service** (starts with server)
- 📊 **Detailed logging** for debugging

## 📋 Quick Setup

### 1. Install Webhook Service
On Windows Server (as Administrator):
```powershell
cd C:\glaz-finance-app
powershell -ExecutionPolicy Bypass -File scripts\install-webhook-service.ps1
```

### 2. Configure GitHub Webhook
1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. **Payload URL**: `http://195.133.47.134:9000/webhook`
4. **Content type**: `application/json`
5. **Events**: Just the push event
6. **Active**: ✅ checked

### 3. Test the System
```powershell
cd C:\glaz-finance-app
powershell -ExecutionPolicy Bypass -File scripts\test-webhook.ps1
```

## 🔧 How It Works

1. **You push to GitHub** → GitHub sends webhook to server
2. **Webhook server receives notification** → Validates signature
3. **Server pulls latest changes** → `git reset --hard origin/main`
4. **Server restarts application** → PM2 restart with new code
5. **Deployment complete** → Takes 5-10 seconds total!

## 📁 Files Created

- `scripts/webhook-server.ps1` - Main webhook listener
- `scripts/start-webhook-server.ps1` - Manual start script
- `scripts/install-webhook-service.ps1` - Windows service installer
- `scripts/test-webhook.ps1` - System test script
- `scripts/webhook-service-wrapper.ps1` - Service wrapper (auto-created)

## 🛠️ Service Management

```powershell
# Check service status
Get-Service -Name GlazFinanceWebhook

# Start/Stop/Restart service
Start-Service -Name GlazFinanceWebhook
Stop-Service -Name GlazFinanceWebhook
Restart-Service -Name GlazFinanceWebhook

# View logs
Get-Content C:\glaz-finance-app\logs\webhook-service.log -Tail 20
```

## 🔍 Monitoring

### Health Check
- **Webhook Server**: http://195.133.47.134:9000/
- **Application**: http://195.133.47.134:3000/

### Log Files
- **Service Logs**: `C:\glaz-finance-app\logs\webhook-service.log`
- **PM2 Logs**: `pm2 logs`

## 🚨 Troubleshooting

### Webhook Server Not Responding
```powershell
# Check if service is running
Get-Service -Name GlazFinanceWebhook

# Restart service
Restart-Service -Name GlazFinanceWebhook

# Check logs
Get-Content C:\glaz-finance-app\logs\webhook-service.log -Tail 20
```

### Application Not Updating
```powershell
# Test webhook manually
cd C:\glaz-finance-app
powershell -ExecutionPolicy Bypass -File scripts\test-webhook.ps1

# Check PM2 status
pm2 list
pm2 logs
```

### GitHub Webhook Issues
1. Check webhook URL in GitHub settings
2. Verify server is accessible: http://195.133.47.134:9000/
3. Check GitHub webhook delivery logs

## 🔄 Migration from GitHub Actions

### Old Way (GitHub Actions)
1. Push to GitHub
2. GitHub Actions starts (30-60 seconds)
3. SSH connection to server
4. Pull changes, install dependencies
5. Restart application
6. **Total time**: 3-5 minutes

### New Way (Webhook)
1. Push to GitHub
2. GitHub sends webhook (instant)
3. Server receives webhook (instant)
4. Pull changes, restart application
5. **Total time**: 5-10 seconds

## 🎉 Success!

Once setup is complete:
- Push any change to `main` branch
- Watch your application update in seconds
- No more waiting for GitHub Actions
- Automatic deployment on every push

## 📞 Support

If you encounter issues:
1. Run the test script: `scripts\test-webhook.ps1`
2. Check service logs: `C:\glaz-finance-app\logs\webhook-service.log`
3. Verify GitHub webhook configuration
4. Check Windows service status

---

**🎯 Result**: Your application now deploys instantly on every push! 🚀
