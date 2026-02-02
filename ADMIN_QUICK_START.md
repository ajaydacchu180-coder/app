# Quick Start Guide: Employee Login Creation

## For Administrators

### Accessing the Admin Panel

1. **Login** to the app with your admin credentials
2. On the **Home Screen**, locate the **Admin Panel** card (purple-colored, bottom of the grid)
3. **Tap** on the Admin Panel card

### Creating an Employee Login

#### Step 1: Fill Employee Information
Navigate to the "Create Employee" tab and fill in the following required fields:

- **Full Name**: Employee's complete name (e.g., "John Doe")
- **Employee ID**: Unique identifier (e.g., "EMP001", "EMP002")
- **Email Address**: Company email (e.g., "john.doe@company.com")
- **Department**: Employee's department (e.g., "Engineering", "HR", "Sales")
- **Initial Password**: Secure password (minimum 8 characters)

💡 **Tip**: Use strong passwords with uppercase, lowercase, numbers, and special characters for better security.

#### Step 2: Create the Employee
1. Tap the blue **"Create Employee"** button
2. Wait for the API call to complete (you'll see a loading indicator)

#### Step 3: Save the Credentials
After successful creation, a dialog will appear showing:

✅ **Success message** with green checkmark
⚠️ **Important warning**: "Save these credentials now. They will not be shown again!"

The dialog displays:
- Employee Name
- Department
- **Employee ID** (with copy button)
- **Email** (with copy button)
- **Password** (with copy button)

**Actions available:**
- Tap individual **copy icons** to copy specific credentials
- Tap **"Copy All & Close"** to copy all credentials in formatted text
- Tap **"Close"** to dismiss the dialog

#### Step 4: Share Credentials with Employee
After copying the credentials:

1. **Send to employee** via secure channel (in-person, encrypted email, or secure messaging)
2. **Inform employee** they must change their password on first login
3. **Delete the credentials** from clipboard/temporary storage after sending

### Viewing Audit Logs

1. Navigate to the **"Audit Log"** tab
2. View the complete history of employee creations
3. **Expand** any entry to see detailed information:
   - Timestamp
   - Action type
   - Employee details
   - Created by (admin name)
   - Password strength
   - Success/failure status

### Security Best Practices

✅ **DO:**
- Use unique Employee IDs for each employee
- Create strong passwords (12+ characters with mixed case, numbers, symbols)
- Save credentials immediately when the dialog appears
- Share credentials through secure channels only
- Inform employees to change password on first login
- Review audit logs regularly

❌ **DON'T:**
- Reuse Employee IDs
- Use simple or common passwords
- Share credentials via unsecured channels (SMS, public chat, plain email)
- Keep credentials in plain text files
- Allow employees to keep initial passwords

## For Employees

### First Time Login

1. **Receive credentials** from your administrator:
   - Employee ID
   - Email
   - Initial Password

2. **Login** to the app:
   - Enter your Employee ID or Email
   - Enter your initial password
   - Select "Employee" role

3. **Change password** immediately:
   - You'll be prompted to change your password on first login
   - Create a strong, unique password
   - Don't share your password with anyone

4. **Confirm** the password change and complete your first login

## Troubleshooting

### Employee Creation Failed

**Problem**: Error message appears when trying to create employee

**Solutions**:
1. Check that all fields are filled correctly
2. Ensure Employee ID is unique (not already used)
3. Verify email address format is correct
4. Check that password meets minimum requirements (8+ characters)
5. Verify your admin authentication is still valid
6. Check network connection

### Can't Copy Credentials

**Problem**: Copy buttons not working

**Solutions**:
1. Ensure you have permission to access clipboard
2. Try tapping "Copy All & Close" instead
3. Manually note down credentials if copy fails

### Credentials Dialog Won't Appear

**Problem**: Employee created but no dialog shown

**Solutions**:
1. Check the Audit Log tab to confirm creation was successful
2. Employee ID and details can be retrieved from audit logs
3. Note: Password cannot be retrieved after dialog closes
4. Solution: Create a new password reset request

### Can't Access Admin Panel

**Problem**: Admin Panel card not visible on home screen

**Solutions**:
1. Verify you're logged in with an **Admin** account (not Employee or Manager)
2. Check with system administrator about your role permissions
3. Try logging out and logging back in

## Quick Reference

| Task | Action |
|------|--------|
| Access Admin Panel | Home → Admin Panel (purple card) |
| Create Employee | Fill form → Create Employee button |
| Copy Single Credential | Tap copy icon next to field |
| Copy All Credentials | Tap "Copy All & Close" |
| View History | Navigate to "Audit Log" tab |
| Check Creation Status | Expand audit log entry |

## Support

For additional help or technical issues:
- Contact your IT administrator
- Refer to the full documentation: `EMPLOYEE_LOGIN_FEATURE.md`
- Check audit logs for error details

---

**Last Updated**: 2026-01-30  
**Version**: 1.0.0
