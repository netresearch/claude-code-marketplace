# TYPO3 Core Contribution Account Setup Guide

Complete guide for setting up all required accounts for TYPO3 Core contributions.

## Overview

Three accounts are required for TYPO3 Core contribution:
1. **TYPO3.org Account** - Central authentication for all TYPO3 services
2. **Gerrit Account with SSH** - Code review and patch submission
3. **Slack Access** - Community communication and support

## 1. TYPO3.org Account

### Registration

1. Visit the signup page: https://my.typo3.org/index.php?id=2

2. Fill in the registration form:
   - **Username**: Choose alphanumeric identifier (avoid special characters like `@` or `!`)
   - **Email Address**: Use email for Forge and Gerrit notifications
   - **Full Name**: Use real name (community values genuine identification)
   - **Password**: Create strong password (use password manager recommended)

3. Submit the form

4. Check your email for verification message

5. Click verification link to activate account

### What This Account Provides

- Access to Forge issue tracker
- Authentication for Gerrit code review
- Access to my.typo3.org profile management
- Community member identification

### Important Notes

- Username cannot be changed after registration
- Consider using personal email (not corporate) if contributing independently
- This account will be visible in git commits and Gerrit reviews

## 2. Gerrit Account Setup

### Prerequisites

- Active TYPO3.org account
- SSH key pair (will create if needed)

### Step 1: Sign In to Gerrit

1. Visit https://review.typo3.org
2. Click **Sign In** button (top right)
3. Authenticate with your TYPO3.org credentials
4. You'll be redirected back to Gerrit

### Step 2: Generate SSH Key Pair

SSH keys are required for pushing patches to Gerrit.

#### Linux / macOS

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.org"

# Default location: ~/.ssh/id_ed25519
# Press Enter to accept default location
# Optionally set a passphrase for additional security

# View your public key
cat ~/.ssh/id_ed25519.pub
```

#### Windows

**Option A: Git Bash (Recommended)**
```bash
# Same commands as Linux/macOS above
ssh-keygen -t ed25519 -C "your-email@example.org"
```

**Option B: PuTTYgen**
1. Download and install PuTTY: https://www.putty.org/
2. Run PuTTYgen
3. Click "Generate" and move mouse randomly
4. Save private key (*.ppk file)
5. Copy public key from text area

### Step 3: Add Public Key to Gerrit

1. Click your profile icon (top right in Gerrit)
2. Select **Settings** from dropdown
3. Click **SSH Keys** in left sidebar
4. Paste your **public key** content (entire content of `id_ed25519.pub` or `id_rsa.pub`)
5. Click **Add New SSH Key**

**Important**: Only add the PUBLIC key, never the private key!

### Step 4: Test SSH Connection

```bash
# Test connection to Gerrit
ssh -p 29418 <YOUR_USERNAME>@review.typo3.org

# Expected output:
#   ****    Welcome to Gerrit Code Review    ****
#   Hi <Your Name>, you have successfully connected over SSH.
```

If you see the welcome message, SSH is configured correctly!

### Multiple Devices

If you work on multiple computers:

**Option 1: Copy Private Key**
- Copy `~/.ssh/id_ed25519` (private key) to other machines
- Set proper permissions: `chmod 600 ~/.ssh/id_ed25519`
- Not recommended for security reasons

**Option 2: Generate Separate Keys (Recommended)**
- Generate new key pair on each device
- Add all public keys to Gerrit settings
- Gerrit supports multiple SSH keys per account
- More secure: compromised device doesn't affect others

### Troubleshooting

**"Permission denied (publickey)"**
- Verify key is added to Gerrit: Settings → SSH Keys
- Check key permissions: `chmod 600 ~/.ssh/id_ed25519`
- Test with verbose: `ssh -vvv -p 29418 <username>@review.typo3.org`

**"Connection refused"**
- Check firewall settings
- Verify port 29418 is accessible
- Try from different network

**"Host key verification failed"**
- Accept host key: `ssh-keyscan -p 29418 review.typo3.org >> ~/.ssh/known_hosts`

## 3. TYPO3 Slack Workspace

### Joining Slack

1. Visit https://typo3.slack.com

2. Click **Create an account** or **Sign in**

3. Use same email as TYPO3.org account (recommended for consistency)

4. Complete Slack registration

5. You'll receive invitation to TYPO3 workspace

### Required Channels

**#typo3-cms-coredev** (Essential)
- Core development discussions
- Patch review requests
- Technical questions
- Get help from core team

### Recommended Channels

**#typo3-cms**
- General TYPO3 CMS discussions
- User questions
- Extension development

**#random**
- Off-topic chat
- Community social

**#announce**
- Official announcements
- Release notifications

### Using Slack Effectively

**Asking for Reviews**:
```
I've submitted a patch for issue #105737 (indexed search crash).
Would appreciate reviews: https://review.typo3.org/c/Packages/TYPO3.CMS/+/12345
```

**Asking Questions**:
```
Working on #105737, need clarification on preg_replace error handling.
Should I use fallback or throw exception? Context: [brief explanation]
```

**Best Practices**:
- Search before asking (knowledge base exists)
- Provide context and Forge/Gerrit links
- Be patient (volunteers respond when available)
- Use threads for discussions
- Thank people who help!

### Slack Etiquette

- **Don't** @here or @channel unless critical
- **Do** use threads to keep discussions organized
- **Don't** DM core team members without asking first
- **Do** share knowledge when you can help others
- **Don't** expect immediate responses (volunteers have lives!)

## Verification Checklist

Before proceeding with development, verify:

- [ ] TYPO3.org account created and email verified
- [ ] Can sign in to https://forge.typo3.org
- [ ] Can sign in to https://review.typo3.org
- [ ] SSH key added to Gerrit
- [ ] SSH connection to Gerrit successful: `ssh -p 29418 <user>@review.typo3.org`
- [ ] Joined TYPO3 Slack workspace
- [ ] Member of #typo3-cms-coredev channel

Run `scripts/verify-prerequisites.sh` to automatically check most of these!

## Security Best Practices

### SSH Key Security

- **Never share private keys** - TYPO3 team will never ask for them
- **Use strong passphrase** - Protects key if device is compromised
- **Rotate keys periodically** - Generate new keys annually
- **Delete old keys** - Remove unused keys from Gerrit settings

### Account Security

- **Use unique strong password** - Use password manager
- **Enable 2FA if available** - Additional security layer
- **Log out on shared devices** - Don't stay signed in
- **Review SSH keys regularly** - Remove keys from old devices

### Privacy Considerations

- Your name and email will be visible in:
  - Git commit history
  - Gerrit reviews
  - Forge issue comments
- Consider using professional email if contributing as individual
- Company contributions may require corporate email

## Next Steps

After completing account setup:

1. Proceed to **Environment Setup** (Phase 2 in main workflow)
2. Configure Git for TYPO3 contributions
3. Clone TYPO3 repository
4. Install Git hooks
5. Start contributing!

## Support Resources

- **Forge Account Issues**: https://forge.typo3.org/projects/typo3cms-core
- **Gerrit SSH Help**: https://review.typo3.org/Documentation/user-upload.html
- **Slack Support**: Ask in #typo3-cms-coredev
- **Documentation**: https://docs.typo3.org/m/typo3/guide-contributionworkflow/

## Quick Reference

| Service | URL | Purpose |
|---------|-----|---------|
| TYPO3.org Registration | https://my.typo3.org/index.php?id=2 | Create account |
| TYPO3.org Profile | https://my.typo3.org | Manage profile |
| Forge | https://forge.typo3.org | Issue tracking |
| Gerrit | https://review.typo3.org | Code review |
| Gerrit SSH Test | `ssh -p 29418 <user>@review.typo3.org` | Verify connection |
| Slack | https://typo3.slack.com | Community chat |
| Documentation | https://docs.typo3.org/m/typo3/guide-contributionworkflow/ | Full guide |
