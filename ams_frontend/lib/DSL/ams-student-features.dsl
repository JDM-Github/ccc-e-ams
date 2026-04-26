[
  BH("Student Features", [
    T("This section covers all features available to students in AMS. Students interact primarily with the Schedule page for logging daily attendance, the Activity Report page for documenting work activities, the Profile page for monitoring progress and managing account settings, and the Export feature for downloading records. All student data is scoped to the student's own account — students cannot view or modify other members' records."),
    H("Schedule Page", [
      T("The Schedule page is the most frequently used page for students. It displays all attendance records logged under the student's account and provides the controls needed to add new time-in records and complete existing ones with a time-out. Records are listed in a scrollable list and can be filtered, searched, and sorted to help the student locate specific entries quickly."),
      I("AMS Schedule Page — Student View"),
      SH("Adding a Time-In Record", [
        T("To add a new attendance record for the current day, tap the Add Record button. On mobile, this appears as a floating action button at the bottom right of the screen. On desktop, it appears as a button in the top toolbar. Before the record sheet opens, AMS performs several validation checks automatically. If any check fails, a warning message is displayed and the sheet does not open."),
        I("AMS Add Record Button — Mobile and Desktop"),
        TBL("Time-In Validation Checks", 4, 2,
          "Check", "What Happens if it Fails",
          "Weekend check", "If the office does not allow weekend attendance and today is Saturday or Sunday, the record cannot be added",
          "Duplicate check", "If a record for today already exists, a second record cannot be added for the same day",
          "Time window check", "If the current time is outside the office-defined time-in window, the record cannot be added"
        ),
        T("Once validation passes, the Add Record sheet opens displaying today's date and the current time as the time-in. These values are automatically captured and cannot be manually changed — the system always uses the actual current time at the moment the sheet is opened. The only required action from the student is to attach a proof photo before saving.")
      ]),
      SH("GPS Check", [
        T("When the Schedule page is first loaded, AMS requests access to your device's location. This permission is required for the system to determine whether you are physically present at the office. AMS continuously tracks your position using high-accuracy GPS while the page is open and compares it to the office's registered GPS coordinates. If you are within 40 meters of the office coordinates, your record is marked as In Office. If you are beyond that radius, the record is automatically flagged as a Work From Home entry. The office status indicator in the top bar of the Schedule page shows your current status in real time — a green dot labeled In Office or a gray dot labeled Outside Office."),
        I("AMS GPS Status Indicator — In Office and Outside Office")
      ]),
      SH("Work From Home Time-In", [
        T("If AMS detects that you are outside the 40-meter office radius when you add a record, the time-in sheet will open with a Work From Home label in the title. The record is still created normally and requires a proof photo, but it will be tagged as a WFH entry pending supervisor approval. WFH records are not counted toward your total OJT hours until a supervisor or admin accepts them. A WFH Pending badge will appear on the record card in your list until it is reviewed. Once approved, the badge changes to WFH Approved and the hours are included in your progress calculation.")
      ]),
      SH("Proof Photo Requirement", [
        T("Every time-in record requires a proof photo before it can be saved. The proof photo area in the Add Record sheet displays a placeholder with a camera icon when no image has been selected. Tap the area or the Add button next to the Proof of Time In label to open the image source picker. You can choose to take a photo using your device camera or select an existing image from your gallery. On Windows and Web, the camera option opens an in-app camera preview dialog using your connected webcam, and the gallery option opens a file upload dialog instead. Once an image is selected, it appears as a preview in the sheet. You can remove it using the close button overlay or replace it using the edit button overlay. The Save Record button remains disabled until a proof photo is attached."),
        I("AMS Add Record Sheet — Proof Photo Area Empty"),
        I("AMS Add Record Sheet — Proof Photo Area with Image"),
        I("AMS Image Source Picker")
      ]),
      SH("Time-In Window Enforcement", [
        T("Each office defines a specific time window during which students are allowed to time in. There are two separate windows — one for in-office attendance and one for Work From Home attendance. If you attempt to add a record outside of these windows, AMS will display a warning message specifying the allowed time range and the record will not be created. The time-in window is configured by your supervisor in the Office settings page and may differ between offices. Contact your supervisor if you are unsure of your office's allowed time-in window.")
      ]),
      SH("Adding a Time-Out", [
        T("To complete an attendance record, you need to add a time-out. A time-out can only be added to today's record and only if no time-out has been recorded yet. On the record card, tap the logout icon on the right side of the record to open the Time Out sheet. Similar to the time-in process, the current time is automatically captured as the time-out and cannot be manually adjusted. A proof photo is also required before the time-out can be saved."),
        I("AMS Time Out Sheet")
      ]),
      SH("Proof Photo Requirement", [
        T("The time-out proof photo works the same way as the time-in proof photo. Tap the proof area or the Add button to open the image source picker and attach a photo. The Save Record button will remain disabled until a proof image is selected. Once saved, the time-out is recorded and your hours for that day are calculated automatically.")
      ]),
      SH("Time-Out Cap Policy", [
        T("Each office defines a maximum allowed time-out time called the Time-Out Cap. If the time at which you submit your time-out exceeds this cap, AMS will automatically adjust your recorded time-out to the cap value instead. For example, if the cap is set to 9:00 PM and you submit your time-out at 9:45 PM, your recorded time-out will be saved as 9:00 PM. A warning message will notify you when this adjustment occurs so you are aware that your time-out was capped.")
      ]),
      SH("Viewing and Filtering Records", [
        T("All attendance records are displayed as a list on the Schedule page, sorted from newest to oldest by default. The list can be scrolled vertically to view older records. Above the list is a filter bar containing a search field, status filter chips, and sort options."),
        I("AMS Schedule Page — Filter Bar")
      ]),
      SH("Search by Date", [
        T("The search field accepts date input in the format YYYY-M-D or partial date strings. As you type, the list filters in real time to show only records whose date matches the entered value. For example, typing 2025-3 will show all records from March 2025. Clear the search field to return to the full list.")
      ]),
      SH("Status Filters", [
        T("Three status filter chips are available: All, Completed, and Active. All is selected by default and shows every record. Completed shows only records that have a time-out recorded or belong to a past date. Active shows only records that are still open — meaning today's record with no time-out yet. Only one status filter can be active at a time.")
      ]),
      SH("Sort Options", [
        T("Four sort options are available: Newest, Oldest, Earliest In, and Latest In. Newest sorts records from the most recent date to the oldest. Oldest reverses this order. Earliest In sorts records by time-in from the earliest time of day to the latest. Latest In reverses this, showing the latest time-in first. The selected sort option is highlighted and persists while the page is open."),
        TBL("Sort Options Reference", 5, 2,
          "Sort Option", "Behavior",
          "Newest", "Records sorted from most recent date to oldest",
          "Oldest", "Records sorted from oldest date to most recent",
          "Earliest In", "Records sorted by time-in from earliest to latest time of day",
          "Latest In", "Records sorted by time-in from latest to earliest time of day"
        )
      ]),
      SH("Record Status Indicators", [
        T("Each record card in the list displays one or more status badges that describe the state of that record. These badges appear as small colored labels next to the date and help you quickly identify records that need attention."),
        TBL("Record Status Badges", 7, 2,
          "Badge", "Meaning",
          "Done (green)", "The record has a time-out or belongs to a past date and is considered complete",
          "Active (blue)", "The record is open — today's record with no time-out yet",
          "WFH (blue border)", "The record was submitted as Work From Home and has been approved by the supervisor",
          "WFH Pending (red border)", "The record was submitted as Work From Home but has not yet been approved — hours are not counted",
          "Early (orange)", "The time-in was before 8:00 AM and the supervisor has accepted the early entry",
          "Early Adjusted (amber)", "The time-in was before 8:00 AM and was not accepted — the recorded time-in is adjusted to 8:00 AM for hour calculation",
          "Not Recorded (red)", "The record is a WFH entry that has not been approved — it is excluded from all hour calculations"
        )
      ])
    ]),
    H("Activity Report Page", [
      T("The Activity Report page, referred to as the AR page, is accessible from each individual schedule record card by tapping the folder icon. It serves as a digital logbook for the work activities performed on that specific day. Students can attach multiple photos documenting their tasks and write a daily summary describing what they accomplished. The AR page is date-specific — each record has its own independent set of AR images and summary."),
      I("AMS Activity Report Page"),
      SH("Viewing AR Images", [
        T("All AR images attached to a record are displayed in a grid on the AR page. On mobile, the grid shows three images per row. On desktop in landscape orientation, it shows five per row. Each image card displays a timestamp overlay at the bottom showing when the image was added. Tapping any image opens a full-screen viewer with pinch-to-zoom and drag-to-pan support. From the viewer, the image can also be downloaded to your device.")
      ]),
      SH("Adding AR Images", [
        T("AR images can only be added to today's record while it is still active. If the record belongs to a past date or if the student's account is inactive for the current school year, the add controls will not be shown and a read-only banner will be displayed instead. To add an image, tap the Add Image button in the toolbar on desktop or the camera floating action button on mobile."),
        I("AMS AR Page — Add Image Button"),
        SH("Camera", [
          T("Selecting the Take Photo option opens your device's native camera on Android and iOS. On Windows and Web, an in-app camera preview dialog opens instead, using your connected webcam. Frame your photo and capture it — the image will be uploaded and added to the AR grid automatically after capture.")
        ]),
        SH("Gallery and File Upload", [
          T("Selecting the gallery or upload option opens your device's photo gallery on Android and iOS, allowing you to pick an existing image. On Windows and Web, a standard file picker dialog opens instead where you can select an image file from your computer. Supported formats include standard image files such as JPEG and PNG.")
        ])
      ]),
      SH("Daily Summary", [
        T("Each AR record supports a single daily summary — a free-form text entry where the student can describe the tasks completed, challenges encountered, or accomplishments of that day. The summary appears as a preview card below the AR image header on mobile, and as a truncated text snippet in the toolbar on desktop."),
        I("AMS Daily Summary Preview on Mobile"),
        SH("Adding a Summary", [
          T("To add a daily summary, tap the Summary button in the AR page toolbar. A dialog will open with a multi-line text field. Type your summary describing your activities for the day and tap Save. The summary is saved to the server and will appear in the AR page header the next time the page is viewed. A summary can only be added to today's record while it is active.")
        ]),
        SH("Editing a Summary", [
          T("If a summary already exists for the record, the Summary button label changes to Edit Summary. Tapping it opens the same dialog with the existing text pre-filled. Modify the text as needed and tap Save to update it. The previous summary is replaced with the new content.")
        ]),
        SH("Deleting a Summary", [
          T("To delete an existing summary, open the Edit Summary dialog and tap the red trash icon button on the left side of the action row. The summary will be permanently removed from the record. This action cannot be undone. The delete button is only shown when an existing summary is present and the record is still modifiable.")
        ])
      ]),
      SH("Downloading AR Images as ZIP", [
        T("All AR images for a record can be downloaded at once as a compressed ZIP file. Tap the download icon in the AR page app bar to initiate the download. AMS will collect all images for that record, compress them into a single ZIP file named with the record identifier, and save it to your device. On Android, the file is saved to external storage. On Windows, a save dialog appears. On Web, the file is downloaded through the browser. A loading indicator is shown while the ZIP is being prepared.")
      ])
    ]),
    H("Profile Page", [
      T("The Profile page displays the student's personal information, OJT progress, attendance statistics, and academic details. It also provides access to account management actions such as changing profile information, updating the profile picture, changing the password, and logging out. The layout adapts between mobile and desktop — on desktop, the information is arranged in a multi-column card layout, while on mobile it is presented as a vertical list of cards."),
      I("AMS Profile Page — Student View"),
      SH("OJT Progress", [
        T("The OJT Progress card displays the student's current completed hours against their target hours. The completed hours value is calculated from all approved and counted attendance records — WFH pending records and non-approved records are excluded. A linear progress bar fills from left to right as hours accumulate. The percentage completion is shown as a badge next to the hours display. When the target is reached, the bar turns green and a completion message is shown. If any WFH records are pending approval, an orange info banner appears below the progress bar noting how many records are excluded from the total.")
      ]),
      SH("Statistics Overview", [
        T("The Statistics card displays four numerical values summarizing the student's attendance history."),
        TBL("Statistics Card Values", 5, 2,
          "Statistic", "Description",
          "Total Days", "The total number of attendance records that are counted — excludes unapproved WFH entries",
          "Completed", "The number of records that have a time-out or belong to a past date",
          "Pending", "The number of records that are still open with no time-out on a future or current date",
          "WFH Pending", "The number of WFH records awaiting supervisor approval — only shown when greater than zero"
        )
      ]),
      SH("Academic Information", [
        T("The Academic Information card displays the student's enrolled course and their target OJT hours. These values are set by the supervisor when the student account is created and can be updated through the Change Profile Information dialog.")
      ]),
      SH("Account Settings", [
        T("The Account Settings card provides four actions available to the student at any time."),
        SH("Change Profile Information", [
          T("Tapping Change Profile Information opens an edit dialog pre-filled with the student's current details including name, CCC ID, custom ID, email, course, and target hours. Make the desired changes and confirm to update the profile. Changes are saved to the server and reflected immediately in the app.")
        ]),
        SH("Change Profile Picture", [
          T("Tapping Change Profile Picture opens a dialog that allows the student to upload a new profile photo. The photo can be taken with the camera or selected from the gallery. Once uploaded, the new photo replaces the initials avatar displayed throughout the app wherever the student's profile is shown.")
        ]),
        SH("Change Password", [
          T("Tapping Change Password opens a dialog with three fields: the current password, the new password, and a confirmation of the new password. The current password must be entered correctly before the change is accepted. The new password must be at least six characters long. Once saved, the new password takes effect immediately on the next login.")
        ]),
        SH("Logout", [
          T("Tapping Logout opens a confirmation dialog. Confirming the logout clears the local session, removes any stored credentials, and returns the app to the login screen. If Remember Me was enabled during login, the session data is also cleared and the student will need to log in again manually on the next app launch.")
        ])
      ])
    ]),
    H("Export to Excel", [
      T("Students can export their attendance records to a formatted Excel file at any time from the Schedule page. On mobile, a small green download floating action button appears above the main Add Record button. On desktop, an Export button is available in the top toolbar of the Schedule page. Tapping either opens the Export to Excel dialog."),
      I("AMS Export to Excel Dialog"),
      SH("All Records Export", [
        T("By default, the All Records option is selected in the Export dialog. With this option active, every attendance record associated with the student's account will be included in the export regardless of date. Tap the Export Excel button to generate and download the file.")
      ]),
      SH("Custom Date Range Export", [
        T("To export only records within a specific period, select the Custom Range option. Two date pickers will appear — Start Date and End Date. Tap each picker to open a calendar and select the desired dates. The start date cannot be later than the end date. Once both dates are selected, an info banner at the bottom of the dialog confirms the selected range. Tap Export Excel to generate the file for that range only."),
        I("AMS Export Dialog — Custom Date Range Selected")
      ]),
      T("The exported Excel file is formatted with a header section containing the student's name, CCC ID, course, the name of the person who generated the report, and the generation timestamp. Below the header is a table of all records within the selected range. Each row contains the record number, date, day of the week, time-in, time-out, total hours, record type, status, daily summary text, and the number of AR photos attached. A grand total of all counted hours is displayed at the bottom of the table. On Android, the file is saved directly to external storage and opened automatically. On Windows, a save dialog appears. On Web, the file is downloaded through the browser.")
    ])
  ])
]
