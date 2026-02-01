# Supabase SMTP Setup Guide

Configure custom SMTP in Supabase so auth emails (magic link, password reset, email confirmation) are sent from your domain (e.g. **support@gamerflick.in**) and have better deliverability.

---

## Where to configure

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → select your project (**dedknavvqlnqzsadlbfp**).
2. Go to **Project Settings** (gear icon) → **Auth**.
3. Scroll to **SMTP Settings**.
4. Enable **Custom SMTP** and fill in the form.

---

## Option A: Gmail / Google Workspace (e.g. support@gamerflick.in)

If you use **Google Workspace** for gamerflick.in:

| Field | Value |
|-------|--------|
| **Sender email** | `support@gamerflick.in` (or noreply@gamerflick.in) |
| **Sender name** | `GamerFlick` |
| **Host** | `smtp.gmail.com` |
| **Port** | `587` (TLS) or `465` (SSL) |
| **Username** | Your full email, e.g. `support@gamerflick.in` |
| **Password** | **App Password** (not your normal password) |

### Gmail App Password

1. Go to [Google Account → Security](https://myaccount.google.com/security).
2. Enable **2-Step Verification** if not already.
3. Go to **App passwords** (search in account settings).
4. Create an app password for “Mail” / “Other (Supabase)”.
5. Copy the 16-character password and paste it in Supabase **Password** field.

Save in Supabase and send a test email (Auth → Users → “Send test email” or trigger a password reset) to verify.

---

## Option B: GoDaddy (if your mail is hosted on GoDaddy)

If you use **GoDaddy Email** or **Workspace Email** for @gamerflick.in:

| Field | Value |
|-------|--------|
| **Sender email** | `support@gamerflick.in` |
| **Sender name** | `GamerFlick` |
| **Host** | `smtpout.secureserver.net` |
| **Port** | `465` (SSL) or `587` (TLS) |
| **Username** | Full email, e.g. `support@gamerflick.in` |
| **Password** | Your GoDaddy email account password |

Confirm exact host/port in [GoDaddy Email Help](https://support.godaddy.com) for your product (e.g. “Email Office” or “Microsoft 365”).

---

## Option C: Resend (recommended for deliverability)

1. Sign up at [resend.com](https://resend.com).
2. Add and verify your domain **gamerflick.in** (DNS records in GoDaddy).
3. Create an API key in Resend dashboard.
4. In Supabase SMTP:

| Field | Value |
|-------|--------|
| **Host** | `smtp.resend.com` |
| **Port** | `465` |
| **Username** | `resend` |
| **Password** | Your Resend API key |
| **Sender email** | e.g. `noreply@gamerflick.in` (must be from verified domain) |

---

## After saving

- **Auth → Email Templates**: Optionally edit “Confirm signup”, “Magic Link”, “Reset password” to use your branding and sender name.
- **Test**: Trigger a password reset or signup confirmation and check that the email arrives from your custom address.

---

## No code changes needed

Your GamerFlick app uses Supabase Auth as-is. Once SMTP is set in the dashboard, Supabase sends all auth emails through your SMTP; no Flutter or environment changes required.
