[
  BH("Supervisor Features", [
    T("This section covers all features available to supervisors and admins in AMS. Supervisors are the primary managers of their office and are responsible for overseeing student members, reviewing and managing attendance records, configuring office settings, and maintaining office data. Admins share all supervisor capabilities with the addition of elevated member status management authority. Unless explicitly noted, everything described in this section applies equally to both supervisors and admins."),
    H("Members Page", [
      T("The Members page is the central hub for supervisors and admins to view and manage all accounts registered under their office. It lists every student and supervisor account in the office and provides tools to search, filter, and add new members. The page is accessible from the navigation bar on both mobile and desktop layouts."),
      I("AMS Members Page — Supervisor View"),
      SH("Viewing Members", [
        T("Each member in the list is displayed as a card containing the member's profile photo or initials avatar, full name, office ID, course, and a progress bar showing their OJT completion percentage. Supervisor and admin accounts are displayed with a distinct badge and a different card border style to differentiate them from student entries. Members flagged for pending deletion are shown with an amber warning strip at the top of their card and a hourglass badge. Tapping any member card opens the Member Detail Screen for that member.")
      ]),
      SH("Searching and Filtering Members", [
        T("A search field at the top of the Members page filters the list in real time as you type. The search matches against the member's full name, CCC ID, and email address. Below the search field are two rows of filter chips. The first row filters by role — All, Supervisor, or Student. The second row filters by progress status — All Progress, Completed, or In Progress. Completed shows only students who have reached their target hours. In Progress shows students who have not yet completed their target hours. On desktop, the role filter chips appear in the top toolbar alongside the search field."),
        TBL("Member Filter Options", 6, 2,
          "Filter", "Behavior",
          "All (Role)", "Shows all members regardless of role",
          "Supervisor", "Shows only supervisor and admin accounts",
          "Student", "Shows only student accounts",
          "All Progress", "Shows all students regardless of completion status",
          "Completed", "Shows only students who have reached their target OJT hours",
          "In Progress", "Shows only students who have not yet reached their target OJT hours"
        )
      ]),
      SH("Adding a Student Account", [
        T("To add a new student account, tap the Add Member button. On mobile, this appears as a floating action button at the bottom right of the screen. On desktop, it appears as a button in the top toolbar. A form sheet or dialog will open depending on your device orientation."),
        I("AMS Add Student Form"),
        SH("Personal Information", [
          T("The first section of the form collects the student's personal information. First name and last name are required and accept letters only including Filipino characters such as ñ. Middle name is optional. All name fields enforce a minimum length of two characters and reject numeric or special character input.")
        ]),
        SH("Account Information", [
          T("The second section collects the student's account credentials and identifiers. The CCC ID is the institution-assigned identifier and must be at least three characters. The Custom ID is a secondary identifier such as a student number and must be at least two characters. The email field must be a valid email address format. The course is selected from a dropdown list containing all recognized degree programs offered at City College of Calamba. The target hours field accepts a number between 400 and 800 representing the student's required OJT hours.")
        ]),
        SH("Course and Target Hours", [
          T("The course dropdown contains a comprehensive list of all bachelor's, associate, and professional degree programs. Scroll through the list or use the dropdown search to locate the correct program. The target hours field only accepts numeric input and enforces a minimum of 400 hours and a maximum of 800 hours. Entering a value outside this range will display a validation error and prevent the form from being submitted.")
        ]),
        SH("Password Options", [
          T("The password section offers two options: auto-generate or custom. By default, auto-generate is selected. When auto-generate is active, the system creates a password from the student's initials and CCC ID following the format: first name initial, middle name initial if provided, full last name, and CCC ID joined without spaces. An info banner below the toggle shows the exact formula so the supervisor knows what password will be assigned. To set a custom password instead, toggle the switch to Custom Password and enter a password of at least six characters in the field that appears. The custom password must be communicated to the student separately as it is not displayed again after the account is created.")
        ])
      ]),
      SH("Adding a Supervisor Account", [
        T("To add a new supervisor account, tap the Add Supervisor button. On mobile, this appears as a separate floating action button above the Add Member button. On desktop, it appears as a teal-colored button in the top toolbar. The form for adding a supervisor is similar to the student form but does not include a course or target hours field. The same personal information, account information, and password options apply. Supervisor accounts created this way are assigned the standard supervisor role — they do not have admin privileges. Admin privileges can only be granted through the initial Admin registration process using a special key.")
      ]),
      SH("Member Card Overview", [
        T("Each member card in the list provides a quick summary of the member's status and progress without needing to open the detail screen."),
        SH("Progress Bar", [
          T("For student members, a progress bar is displayed at the bottom of the card showing the percentage of target hours completed. The bar color changes based on completion level — red for below 40 percent, amber for 40 to 70 percent, blue for 70 to 99 percent, and green for 100 percent or above. The hours label and percentage are shown alongside the bar.")
        ]),
        SH("Status Badges", [
          T("Status badges appear on the right side of the member's name row. A Completed badge in green appears when the student has reached their target hours. An Admin badge in purple appears for admin accounts. A Supervisor badge in navy appears for supervisor accounts. A Pending Delete badge in amber appears for members whose accounts have been flagged for deletion. Members with a Pending Delete badge also display a warning strip at the top of their card.")
        ])
      ])
    ]),
    H("Member Detail Screen", [
      T("Tapping any member card opens the Member Detail Screen. This screen provides a full view of the selected member's profile information and, for student members, their complete attendance record list. Supervisors can perform all record management actions from this screen. The app bar at the top of the screen displays the member's name and contains action buttons relevant to the member's role and status."),
      I("AMS Member Detail Screen — Student"),
      SH("Student Info Panel", [
        T("On desktop, the left side of the Member Detail Screen contains a fixed info panel displaying the student's profile photo or initials, full name, school year badge, role badge, office ID, email, course, and a progress bar with hours breakdown. An Edit Member button at the bottom of the panel opens the member edit dialog. On mobile, this information is displayed as a collapsible card at the top of the screen that can be expanded or collapsed using the chevron button to save vertical space.")
      ]),
      SH("Schedule List", [
        T("The right side of the Member Detail Screen on desktop, or the main scrollable area on mobile, displays the student's attendance records. The list supports the same search, filter, and sort options available on the student's own Schedule page. Each record card shows the date, time-in, time-out, hours, record type, and any proof image buttons. A three-dot menu on the right side of each record card provides access to record management actions."),
        I("AMS Member Detail — Schedule Record Card with Menu"),
        SH("Viewing Proof Images", [
          T("If a record has a proof photo attached for time-in or time-out, small labeled buttons appear at the bottom of the record card — a Time In button and a Time Out button. Tapping either button opens the proof image viewer in a dialog. The viewer supports pinch-to-zoom on mobile and scroll-to-zoom on desktop, as well as drag-to-pan. The image can be downloaded from the viewer using the download button.")
        ]),
        SH("Viewing AR Folder", [
          T("Tapping the View AR option in the three-dot menu of a record card opens the Activity Report page for that specific record. Supervisors can view all AR images and the daily summary for the selected record. Supervisors viewing a past school year's records will see a read-only banner and will not be able to add or delete AR content. On the active school year, supervisors have the same AR modification permissions as the student.")
        ]),
        SH("Adding a Schedule", [
          T("Supervisors can manually add an attendance record for a student by tapping the Add button in the app bar of the Member Detail Screen. This opens the Add Schedule dialog. The dialog allows the supervisor to select any date using a date picker, set a time-in and optionally a time-out using time pickers, and configure additional flags for the record."),
          I("AMS Add Schedule Dialog"),
          TBL("Add Schedule Dialog Options", 5, 2,
            "Option", "Description",
            "Date", "The date of the attendance record — can be any date selected from the calendar picker",
            "Time In", "The time-in for the record — selected using the system time picker",
            "Time Out", "Optional — the time-out for the record — if not set, the record remains open",
            "Work From Home toggle", "Marks the record as a WFH entry — when enabled, an Accept WFH toggle appears",
            "Accept WFH toggle", "When enabled alongside the WFH toggle, the WFH record is pre-approved and counted immediately"
          ),
          T("If the time-in entered is before 8:00 AM, a warning banner appears in the dialog and an Accept Early Time-In toggle becomes available. Enabling this toggle means the early time-in will be accepted as-is and the full early hours will be counted. Leaving it disabled means the time-in will be adjusted to 8:00 AM for hour calculation purposes even though the actual recorded time is preserved.")
        ]),
        SH("Editing a Schedule", [
          T("To edit an existing record, tap the three-dot menu on the record card and select Edit. The Edit Schedule dialog opens with all current values pre-filled. The supervisor can modify the date, time-in, time-out, WFH status, WFH acceptance, early time-in acceptance, and time-out cap acceptance. Changes are saved to the server immediately upon confirmation.")
        ]),
        SH("Deleting a Schedule", [
          T("To delete a record, tap the three-dot menu on the record card and select Delete. A confirmation dialog will appear asking the supervisor to confirm the deletion. Once confirmed, the record is permanently removed from the student's attendance history and their hour total is recalculated automatically. This action cannot be undone.")
        ])
      ]),
      SH("Managing Member Status", [
        T("Member status management controls appear in the app bar of the Member Detail Screen. The buttons shown depend on the current status of the member and the role of the logged-in user. Regular supervisors can only mark active members for deletion. Admins have access to all three status actions."),
        I("AMS Member Detail — Status Action Buttons in App Bar"),
        SH("Mark for Deletion", [
          T("Tapping the Mark for Deletion button opens a confirmation dialog describing the action. Confirming marks the member's account with a pending deletion status. The member will still appear in the Members list with a Pending Delete badge and warning strip, but their account is flagged for review. The member can still log in and use the system while in this state. This action is available to both supervisors and admins.")
        ]),
        SH("Permanently Delete", [
          T("The Permanently Delete button is only available to admins and only appears when a member is already in the pending deletion state. Tapping it opens a confirmation dialog with a strong warning about the irreversible nature of the action. Once confirmed, the member's account is marked as deleted. Their records are hidden from the active view but are not erased from the database. After deletion, the Member Detail Screen closes automatically and the member is removed from the Members list. This action cannot be undone through the app.")
        ]),
        SH("Restore Account", [
          T("The Restore Account button appears when a member is in either the pending deletion or deleted state and is only available to admins. Tapping it opens a confirmation dialog. Once confirmed, the member's status is restored to active, all their records become visible again, and they regain full access to the system. The Pending Delete badge and warning strip are removed from their card in the Members list.")
        ])
      ]),
      SH("Exporting a Member's Records", [
        T("The Export button in the app bar of the Member Detail Screen generates an Excel export for the selected student. Tapping it opens the Export to Excel dialog pre-configured for that student's CCC ID. The same export options available on the student's own Schedule page apply here — all records or a custom date range. The generated file is identical in format to the student's own export and is saved to the supervisor's device.")
      ])
    ]),
    H("Logs Page", [
      T("The Logs page is accessible only to supervisors and admins. It displays a chronological record of all system events associated with the office, including time-in and time-out actions, record creation and updates, deletions, synchronization events, errors, and informational messages. Logs are useful for auditing attendance activity and identifying any unusual patterns or issues."),
      I("AMS Logs Page"),
      SH("Log Types", [
        T("Each log entry is categorized by type and displayed with a corresponding color-coded icon to make scanning the list easier."),
        TBL("Log Type Reference", 9, 3,
          "Type", "Color", "Description",
          "Time In", "Green", "A student logged a time-in record",
          "Time Out", "Orange", "A student logged a time-out record",
          "Create", "Blue", "A new record or account was created",
          "Update", "Indigo", "An existing record was modified",
          "Delete", "Red", "A record or account was deleted",
          "Sync", "Purple", "A data synchronization event occurred",
          "Error", "Dark Red", "An error was encountered during an operation",
          "Info", "Gray", "A general informational system event"
        )
      ]),
      SH("Searching and Filtering Logs", [
        T("A search field at the top of the Logs page filters entries by message content in real time. Type any keyword to narrow the list to entries whose message contains that text. Below the search field is a row of filter chips for each log type plus an All chip to reset the filter. Only one type filter can be active at a time. The count of currently visible log entries is displayed below the filter bar.")
      ]),
      SH("Sort Options", [
        T("Four sort options are available as filter chips alongside the type filters: Newest, Oldest, Type A-Z, and Type Z-A. Newest sorts entries from the most recent timestamp to the oldest. Oldest reverses this. Type A-Z sorts entries alphabetically by log type name. Type Z-A reverses the alphabetical order. The selected sort option is highlighted and can be changed at any time without resetting other active filters.")
      ])
    ]),
    H("Office Page", [
      T("The Office page displays the configuration settings for the supervisor's office. It shows the office identity, schedule time windows, GPS location coordinates, academic year policy, and data management tools. Supervisors and admins can edit most of these settings directly from this page. Students also have access to a read-only version of the Office page that shows the same information without edit controls."),
      I("AMS Office Page — Supervisor View"),
      SH("Viewing Office Settings", [
        T("The Office page is organized into cards. The Office Identity card shows the office name, supervisor's CCC ID, supervisor's full name, and email. The Schedule Settings card shows all time windows and the weekend policy. The Office Location card shows the registered GPS coordinates and check-in radius. The Academic Year and Policy card shows the current active school year and iteration number. All values are displayed in a label-value format and are read-only until editing mode is activated.")
      ]),
      SH("Editing Office Settings", [
        T("Supervisors and admins can edit office settings by tapping the Edit Settings button in the top bar of the Office page. This activates editing mode, which replaces the read-only display with interactive input fields and toggles. An editing mode banner appears at the top of the content area reminding the user that changes must be saved before leaving the page. Two buttons replace the Edit Settings button in the top bar — Cancel and Save Changes."),
        I("AMS Office Page — Editing Mode"),
        SH("Office Name", [
          T("The office name field accepts free-form text. This name is displayed throughout the app in the navigation header and top bar for all members under the office. Changing the office name takes effect immediately after saving and is visible to all members on their next page load.")
        ]),
        SH("Time-In Start (Office)", [
          T("This setting defines the earliest time a student can log a time-in record when they are physically present at the office within the 40-meter GPS radius. Tapping the field opens a time picker. Set this to the earliest reasonable start time for in-office attendance at your location.")
        ]),
        SH("Time-In Start (WFH)", [
          T("This setting defines the earliest time a student can log a time-in record when they are outside the office radius and the entry is flagged as Work From Home. This value is typically set later than the in-office start time. Tapping the field opens a time picker.")
        ]),
        SH("Time-In End", [
          T("This setting defines the latest time a student is allowed to log a time-in record for either in-office or WFH attendance. Any attempt to add a time-in after this time will be rejected by the system with a warning message. Tapping the field opens a time picker.")
        ]),
        SH("Time-Out Cap", [
          T("This setting defines the maximum time that can be recorded as a time-out. If a student submits a time-out after this cap, their recorded time-out will be automatically adjusted to the cap value. This prevents excessively late time-outs from inflating hour calculations. Tapping the field opens a time picker.")
        ]),
        SH("Allow Weekend Toggle", [
          T("This toggle controls whether students under this office are permitted to log attendance records on Saturdays and Sundays. When disabled, any attempt to add a record on a weekend will be blocked. When enabled, weekend records are treated the same as weekday records. Toggle this setting based on your office's OJT schedule policy.")
        ])
      ]),
      SH("Data Management", [
        T("The Data Management card is visible only to supervisors and admins. It provides two actions for protecting and recovering office data. An info banner at the top of the card reminds the user that a backup includes all users, schedules, and records, and that a restore will overwrite all current office data."),
        SH("Backup Office Data", [
          T("Tapping the Backup Office Data button initiates a full backup of the office. AMS requests the complete office dataset from the server including all member accounts, attendance records, AR images references, and office settings. The data is compiled into a JSON file and saved to the device. On Android, the file is saved to external storage automatically. On Windows and Web, a save dialog appears allowing the supervisor to choose the save location and filename. A loading indicator is shown while the backup is being prepared. A success message confirms when the file has been saved.")
        ]),
        SH("Restore from Backup", [
          T("Tapping the Restore from Backup button opens a file picker dialog where the supervisor selects a previously saved JSON backup file. After selecting the file, a confirmation dialog appears displaying the filename and a strong warning that restoring will permanently overwrite all current office data. Confirming the restore uploads the backup file to the server, which replaces all current data with the backup contents. After a successful restore, the app logs out automatically because the restored data may differ significantly from the current session state. The supervisor must log in again for the restored data to take effect.")
        ])
      ])
    ]),
    H("Profile Page", [
      T("The supervisor's Profile page displays their personal account information and provides the same account management actions available to students. The layout on desktop shows the profile hero card on the left and the account settings card on the right. On mobile, the cards are stacked vertically. Supervisors do not have an OJT progress section, statistics, or academic information — those are student-specific elements."),
      I("AMS Profile Page — Supervisor View"),
      SH("Account Settings", [
        T("The Account Settings card provides four actions: Change Profile Information, Change Profile Picture, Change Password, and Logout. These work identically to the student account settings described in the Student Features section. Changes to profile information and the profile picture are reflected immediately throughout the app for all users who can view the supervisor's profile.")
      ])
    ]),
    H("Location Page", [
      T("The Location page displays real-time GPS information for the supervisor and the office. It shows the supervisor's current coordinates, the office's registered coordinates, the distance between the two points, and the current in-office or out-of-office status. Supervisors also have the ability to update the office's GPS coordinates from this page."),
      I("AMS Location Page — Supervisor View"),
      SH("Viewing Current Location", [
        T("The Your Location card displays the supervisor's current latitude, longitude, and GPS accuracy in meters. These values update in real time as the device's position changes. The accuracy value indicates how precise the GPS reading is — a lower number means a more accurate reading. If the device does not yet have a GPS fix, the card will show a waiting message until coordinates become available.")
      ]),
      SH("Viewing Office Location", [
        T("The Office Location card displays the currently registered GPS coordinates for the office and the check-in radius, which is fixed at 40 meters for all offices. These are the coordinates that AMS uses to determine whether a student is in-office or outside when logging attendance. The coordinates shown here match the values stored in the office settings.")
      ]),
      SH("Distance to Office", [
        T("The Distance to Office card displays the calculated straight-line distance between the supervisor's current position and the office coordinates. The distance is displayed in meters for values below one kilometer and in kilometers for larger distances. This value updates in real time as the supervisor moves. The status hero card at the top of the page also reflects the current in-office state with a green background when within 40 meters and a red background when outside.")
      ]),
      SH("Setting Office Location", [
        T("To update the office's GPS coordinates, tap the Set Office Location button in the top bar of the Location page. This button is only visible to supervisors and admins. Tapping it activates the Set Location banner which appears at the top of the content area. The banner displays a preview of the new coordinates that will be saved — these are the supervisor's current GPS coordinates at the moment the banner is active. The accuracy of the current GPS reading is also shown. If GPS is not yet available, a waiting message is displayed and the confirm button remains disabled."),
        I("AMS Set Office Location Banner"),
        T("To confirm the location update, tap the Confirm Set Location button in the banner. AMS sends the current coordinates to the server and updates the office record. The new coordinates take effect immediately — the Office Location card updates and all future student attendance checks will use the new coordinates. Tap Cancel to exit the set location mode without making any changes.")
      ])
    ])
  ])
]
