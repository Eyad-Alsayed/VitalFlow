# Security Policy

## Supported Versions

The following versions of the ICU/OR Bed Management System are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of the ICU/OR Bed Management System seriously. If you discover a security vulnerability, please follow these guidelines:

### How to Report

**Please DO NOT create a public GitHub issue for security vulnerabilities.**

Instead, please report security vulnerabilities by:

1. **Email**: Send details to your IT security team
2. **Subject Line**: Use "SECURITY: [Brief Description]"
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact
   - Suggested fix (if any)

### What to Expect

- **Initial Response**: You will receive an acknowledgment within **48 hours** of your report
- **Status Updates**: We will provide updates on the investigation every **5-7 business days**
- **Resolution Timeline**: 
  - Critical vulnerabilities: Patch within **7 days**
  - High-severity issues: Patch within **14 days**
  - Medium/Low severity: Patch within **30 days**

### After Reporting

**If Accepted:**
- We will work on a fix and keep you informed of progress
- You will be credited in the security advisory (unless you prefer to remain anonymous)
- We will coordinate disclosure timing with you
- A security patch will be released as soon as possible

**If Declined:**
- We will provide a detailed explanation of why the issue does not qualify as a security vulnerability
- We may suggest alternative channels if it's a bug rather than a security issue

## Security Best Practices

For users deploying this system:

### Authentication
- **Admin Password**: Change the default admin password immediately after deployment
- **Staff Password**: Regularly update the staff password through the admin dashboard
- **Access Control**: Ensure proper network isolation for the backend API

### Database Security
- Use strong passwords for database access
- Enable SSL/TLS for database connections in production
- Regularly backup the database and test restore procedures
- Restrict database access to application server only
- **Password Hashing**: Staff passwords are hashed using bcrypt before storage

### API Security
- Deploy the backend API behind a reverse proxy (nginx/Apache)
- Use HTTPS/TLS for all API communications in production
- Implement rate limiting to prevent abuse
- Regularly update Python dependencies: `pip install --upgrade -r requirements.txt`

### Environment Security
- Never commit sensitive credentials to version control
- Use environment variables for sensitive configuration
- Keep the backend server updated with security patches
- Monitor application logs for suspicious activity

## Known Security Considerations

### Current Implementation Notes

1. **Simple Authentication**: The current system uses a simplified authentication model with database-backed password storage suitable for internal hospital networks. For internet-facing deployments, implement proper OAuth2/JWT authentication.

2. **Password Storage**: Staff passwords are hashed using bcrypt with salt before storage. Admin password should be configured via environment variables.

3. **CORS**: The backend currently allows CORS for development. Restrict CORS origins in production to your frontend domain only.

4. **Session Management**: Consider implementing session timeouts for idle users in production environments.

## Security Updates

Security patches and updates will be announced through:
- GitHub Security Advisories
- Release notes in the repository
- Email notifications to known deployment sites

## Compliance

This system handles patient data (MRN, names, medical information). Deployers are responsible for ensuring compliance with:
- HIPAA (United States)
- GDPR (European Union)
- Local healthcare data protection regulations

**Important**: Review and adapt this system's security measures to meet your organization's specific compliance requirements before production deployment.

## Contact

For security concerns or questions, contact your IT department or system administrator.

---

**Last Updated**: December 2025
