[
  BH("Getting Started", [
    T("This section walks you through everything you need to know before using AMS for the first time. It covers the different account types available in the system, how to log in, how to recover a forgotten password, and how to register a new Admin account. Understanding your role in the system before proceeding is important — different roles have access to different features, and some actions are permanently restricted based on your account type."),
    H("Account Types and Roles", [
      T("AMS uses a role-based access model. Every account in the system is assigned one of four roles: Super Admin, Admin, Supervisor, or Student. Your role determines which pages you can access, what actions you can perform, and how the navigation is structured when you log in. Roles are assigned at the time of account creation and cannot be changed by the user themselves."),
      SH("Super Admin", [
        T("The Super Admin is the highest-level account in AMS and operates outside of any specific office. There is only one Super Admin in the system. This account has access to a dedicated Super Admin Panel that is completely separate from the main application interface seen by all other users. From this panel, the Super Admin can view and manage all registered offices across the platform, perform office-level data backups and restorations, deactivate or reactivate offices, and generate special registration keys required to create new Admin accounts. The Super Admin account cannot access individual student schedules or office-level settings — its scope is platform-wide management only."),
        I("AMS Super Admin Panel")
      ]),
      SH("Admin", [
        T("The Admin role shares the same interface and features as the Supervisor role but carries additional authority over member account management. An Admin can mark members for deletion, permanently delete members, and restore deleted accounts — actions that a regular Supervisor cannot perform on their own. Admin accounts are created through the standard registration process using a special key provided by the Super Admin. Each office can have one or more Admin accounts alongside its regular Supervisors.")
      ]),
      SH("Supervisor", [
        T("The Supervisor role is the primary management role within an office. Supervisors can view and manage all student members registered under their office, add new student and supervisor accounts, manually add or edit student schedule records, configure office settings such as time windows and GPS coordinates, manage office data backups, and advance the school year. Supervisors see a different set of navigation pages compared to students — they do not have a personal Schedule page but instead have access to the Members, Logs, Office, and Location pages.")
      ]),
      SH("Student", [
        T("The Student role is the standard user role in AMS. Students can log their own daily attendance by adding time-in and time-out records, submit proof photos for each record, manage their Activity Report images and daily summaries, monitor their OJT progress against their target hours, and export their records to Excel. Students only see their own data and cannot access other members' records or any office management settings.")
      ])
    ]),
    H("Logging In", [
      T("The login screen is the first screen displayed when AMS is opened and no active session is found. It contains two tabs — Sign In and Register. On initial use, you will always start from the Sign In tab."),
      I("AMS Login Screen"),
      SH("Login Fields", [
        T("The Sign In form contains two input fields. The first field accepts either your CCC ID or your registered email address — both are valid identifiers and either can be used to log in. The second field accepts your password. Passwords are case-sensitive and must be at least six characters long. If you are logging in for the first time as a student, your default password is generated from your name and CCC ID following the format: first initial, middle initial if available, full last name, and CCC ID joined together without spaces. Your supervisor or admin will inform you of your exact default password upon account creation."),
        TBL("Login Field Reference", 3, 2,
          "Field", "Accepted Input",
          "CCC ID or Email", "Your assigned CCC ID (e.g. CCC-2024-001) or your registered email address",
          "Password", "Your account password — minimum 6 characters, case-sensitive"
        )
      ]),
      SH("Remember Me Option", [
        T("Below the password field is a Remember Me checkbox. When this is enabled before logging in, AMS will store your session locally on the device so that you remain logged in the next time the app is opened — even after closing it. This is useful on personal devices where you are the only user. On shared or public devices, it is strongly recommended to leave this option unchecked and to always log out after each session.")
      ]),
      SH("Forgot Password", [
        T("If you cannot remember your password, tap the Forgot Password link on the login screen. This will open a three-step password reset dialog. In the first step, you must enter your CCC ID and your registered email address so the system can verify your identity. In the second step, a six-digit one-time code will be sent to your registered email — enter this code in the provided boxes to confirm ownership of the account. In the third step, you can set a new password. Your new password must be at least eight characters long and must be entered twice to confirm. Once submitted, your password is updated immediately and you can use it to log in."),
        I("AMS Forgot Password Dialog — Step 1: Verify Identity"),
        I("AMS Forgot Password Dialog — Step 2: Email OTP"),
        I("AMS Forgot Password Dialog — Step 3: New Password")
      ])
    ]),
    H("Registering an Admin Account", [
      T("AMS does not allow open self-registration. The only account type that can be self-registered is the Admin account, and it requires a special key that must be obtained from the Super Admin beforehand. Student and Supervisor accounts are created internally by a Supervisor or Admin from within the Members page — those users do not register themselves. If you are a student or supervisor, your account will be created for you and your credentials will be provided by your office admin."),
      I("AMS Register Tab"),
      SH("Registration Form", [
        T("To register a new Admin account, switch to the Register tab on the login screen. The form requires the following information: your first name, middle name if applicable, last name, CCC ID, a custom ID assigned by your institution, your office name, your email address, and a password with confirmation. The office name entered here will become the name of the new office that is automatically created alongside your Admin account — choose it carefully as it will be visible to all members under your office. All name fields accept letters only including Filipino characters. The email field must be a valid address as it will be used for OTP verification."),
        TBL("Registration Form Fields", 9, 2,
          "Field", "Description",
          "First Name", "Your legal first name — letters only",
          "Middle Name", "Optional — letters only",
          "Last Name", "Your legal last name — letters only",
          "CCC ID", "Your institution-assigned CCC ID",
          "Custom ID", "A secondary identifier assigned by your institution — minimum 2 characters",
          "Office Name", "The name of the office this account will manage — this creates a new office in the system",
          "Email Address", "A valid email address — used for OTP verification during registration",
          "Password", "Minimum 6 characters",
          "Creator Password", "A special key obtained from the Super Admin — required to complete registration"
        )
      ]),
      SH("Email OTP Verification", [
        T("After filling out and submitting the registration form, AMS will send a six-digit verification code to the email address you provided. A new screen will appear showing six individual input boxes. Enter the code digit by digit — the cursor will advance automatically as you type. If you did not receive the code, use the Resend Code link to request a new one. The code is valid for the duration of the current session. Once the correct code is entered, the system will proceed to create your account and your office."),
        I("AMS Email OTP Verification Screen")
      ]),
      SH("Creator Password Requirement", [
        T("The creator password field at the bottom of the registration form is not your account password — it is a separate special key that must be provided by the Super Admin. This key acts as an authorization gate to prevent unauthorized office creation in the system. Each key is time-limited and single-use. If the key you enter is expired or invalid, the registration will be rejected and you will need to request a new key from the Super Admin. Once a valid key is used successfully, it is consumed and cannot be reused.")
      ])
    ])
  ])
]
