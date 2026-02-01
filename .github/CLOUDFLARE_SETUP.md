# Cloudflare Pages Setup Guide

This guide explains how to set up Cloudflare Pages deployment for GamerFlick.

## Prerequisites

1. Cloudflare account (free tier works)
2. GitHub repository
3. Domain (optional, Cloudflare provides free subdomain)

## Step 1: Create Cloudflare Account

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Sign up or log in
3. Note your **Account ID** (found in the right sidebar of any page)

## Step 2: Create API Token

1. Go to [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token**
3. Use the **Edit Cloudflare Workers** template or create custom:

### Custom Token Permissions:
| Permission | Access |
|------------|--------|
| Account - Cloudflare Pages | Edit |
| Account - Account Settings | Read |
| Zone - Zone | Read (if using custom domain) |
| Zone - Cache Purge | Purge (if using custom domain) |

4. Set **Account Resources** to your account
5. Set **Zone Resources** to your zone (if applicable)
6. Click **Continue to summary** → **Create Token**
7. **Copy the token immediately** (shown only once)

## Step 3: Create Cloudflare Pages Project

### Option A: Via Dashboard (First Time)
1. Go to **Workers & Pages** → **Create application** → **Pages**
2. Click **Connect to Git**
3. Select your GitHub repository
4. Configure build settings:
   - **Project name:** `gamerflick`
   - **Production branch:** `main`
   - **Build command:** `flutter build web --release`
   - **Build output directory:** `build/web`
5. Click **Save and Deploy**

### Option B: Via Wrangler CLI
```bash
# Install Wrangler
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Create project
wrangler pages project create gamerflick

# Deploy (for testing)
cd /path/to/gamerflick
flutter build web --release
wrangler pages deploy build/web --project-name=gamerflick
```

## Step 4: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

### Required Secrets:

| Secret Name | Description | Where to Find |
|-------------|-------------|---------------|
| `CLOUDFLARE_API_TOKEN` | API token from Step 2 | Cloudflare Dashboard → API Tokens |
| `CLOUDFLARE_ACCOUNT_ID` | Your account ID | Cloudflare Dashboard → Right sidebar |

### Optional Secrets (for custom domain):

| Secret Name | Description | Where to Find |
|-------------|-------------|---------------|
| `CLOUDFLARE_ZONE_ID` | Zone ID for cache purging | Cloudflare Dashboard → Your domain → Overview → Right sidebar |

## Step 5: Set Up Custom Domain (Optional)

### Add Domain to Cloudflare Pages:
1. Go to **Workers & Pages** → **gamerflick** → **Custom domains**
2. Click **Set up a custom domain**
3. Enter your domain (e.g., `app.gamerflick.com`)
4. Cloudflare will automatically configure DNS

### DNS Configuration:
If domain is already on Cloudflare:
- Automatic CNAME record is created

If domain is elsewhere:
- Add CNAME record pointing to `gamerflick.pages.dev`

## Step 6: Test Deployment

### Automatic Deployment:
Push to any branch to trigger deployment:
```bash
git add .
git commit -m "Test Cloudflare deployment"
git push origin main
```

### Manual Deployment:
1. Go to **Actions** → **Deploy to Cloudflare Pages**
2. Click **Run workflow**
3. Select branch and environment

## Workflow Features

### Triggers
- Push to `main`, `production`, or `develop` branches
- Pull requests to `main` or `production`
- Manual workflow dispatch

### Deployment Environments

| Branch | Environment | URL |
|--------|-------------|-----|
| `main` | Production | `gamerflick.pages.dev` |
| `production` | Production | Custom domain |
| `develop` | Preview | `develop.gamerflick.pages.dev` |
| PR branches | Preview | `<hash>.gamerflick.pages.dev` |

### Features
- ✅ Automatic preview deployments for PRs
- ✅ PR comments with preview URLs
- ✅ Lighthouse performance audits
- ✅ Cache headers configuration
- ✅ SPA routing support
- ✅ Security headers
- ✅ Cache purging on production deploy

## Configuration Files

### `_headers` (Auto-generated)
Controls HTTP headers for security and caching:
```
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff

/assets/*
  Cache-Control: public, max-age=31536000, immutable
```

### `_redirects` (Auto-generated)
Enables SPA routing:
```
/*    /index.html   200
```

## Cloudflare Pages Limits (Free Tier)

| Resource | Limit |
|----------|-------|
| Builds per month | 500 |
| Concurrent builds | 1 |
| Max file size | 25 MB |
| Max files per deployment | 20,000 |
| Bandwidth | Unlimited |
| Requests | Unlimited |

## Performance Features

### Automatic Optimizations
- Global CDN (275+ locations)
- Automatic HTTPS
- HTTP/2 and HTTP/3
- Brotli compression
- Early hints
- Smart caching

### Flutter Web Optimizations
The workflow configures:
- Long cache for static assets (1 year)
- No cache for HTML and service worker
- CanvasKit renderer for better performance

## Workflow Failure Guide

### Why workflows fail (common causes)

| Workflow | Failure point | Fix |
|----------|----------------|-----|
| **Deploy to Cloudflare Pages** | **Deploy** job fails with "Secret not found" or empty token | Add repo secrets: `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` (see Step 4 above). |
| **Deploy to Cloudflare Pages** | **Build** job fails at `flutter pub get` | Dependency resolution error: run `flutter pub get` locally, fix `pubspec.yaml` or version constraints. |
| **Deploy to Cloudflare Pages** | **Build** job fails at `flutter build web` | Ensure `lib/config/environment.dart` has `defaultValue` for all `String.fromEnvironment()` (CI doesn't pass secrets to dart-define). |
| **Deploy to Cloudflare Pages** | **Build** job fails at `flutter test` | Tests are `continue-on-error: true` so they don't fail the job; fix tests locally with `flutter test`. |
| **CodeQL Advanced** | "We were unable to automatically build your code" | This repo uses Flutter (no standard root build). CodeQL workflow uses `build-mode: none` for c-cpp, java-kotlin, swift to avoid autobuild. |
| **Lighthouse** (on PRs) | Fails or empty URL | Runs after deploy; needs `needs.deploy.outputs.deployment-url`. If deploy was skipped or failed, Lighthouse is skipped. |
| **Claude Code Review** | Job fails with auth error | Add repo secret `ANTHROPIC_API_KEY` (get key from [console.anthropic.com](https://console.anthropic.com)). |

### Required secrets (all workflows)

**Cloudflare Pages:**
- `CLOUDFLARE_API_TOKEN` – **required** for deploy; without it the **deploy** step fails.
- `CLOUDFLARE_ACCOUNT_ID` – **required** for deploy.
- `CLOUDFLARE_ZONE_ID` – **optional**; only for purge-cache (production).

**Claude Code Review** (`.github/workflows/claude-code-review.yml`):
- `ANTHROPIC_API_KEY` – **required** for automated PR code review; create at [console.anthropic.com](https://console.anthropic.com).

## Troubleshooting

### Build Fails
```bash
# Check Flutter version
flutter --version

# Ensure dependencies are up to date
flutter pub get

# Test local build
flutter build web --release
```

### Deployment Fails
- Verify `CLOUDFLARE_API_TOKEN` is correct
- Check token permissions include Pages Edit
- Verify `CLOUDFLARE_ACCOUNT_ID` is correct

### 404 on Routes
Ensure `_redirects` file is in `build/web`:
```
/*    /index.html   200
```

### Assets Not Loading
Check `_headers` file for correct cache settings

### Custom Domain Not Working
1. Verify DNS propagation: `dig your-domain.com`
2. Check SSL certificate status in Cloudflare dashboard
3. Wait up to 24 hours for DNS propagation

## Rollback Deployment

1. Go to **Workers & Pages** → **gamerflick** → **Deployments**
2. Find the previous working deployment
3. Click **...** → **Rollback to this deployment**

## Monitoring

### View Analytics
- Go to **Workers & Pages** → **gamerflick** → **Analytics**
- View requests, bandwidth, and errors

### View Logs
- Real-time logs available in dashboard
- Filter by status code, path, etc.

## Cost

Cloudflare Pages is **free** for:
- Unlimited sites
- Unlimited bandwidth
- Unlimited requests
- 500 builds/month

Paid plans available for:
- More concurrent builds
- Web Analytics
- Additional features
