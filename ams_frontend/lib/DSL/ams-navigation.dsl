[
  BH("Navigation", [
    T("AMS automatically adapts its navigation layout based on the orientation and screen size of your device. On mobile devices held in portrait mode, navigation is handled through a bottom navigation bar at the bottom of the screen. On desktop computers, tablets in landscape orientation, or any screen where the width exceeds the height, the navigation switches to a side rail panel on the left side of the screen. Both layouts provide access to the same pages — only the visual presentation differs. The pages available to you also depend on your role, so not all users will see the same navigation items."),
    H("Mobile Layout", [
      T("On mobile devices in portrait orientation, the bottom navigation bar is the primary way to move between pages in AMS. It appears as a fixed bar at the bottom of the screen and remains visible at all times regardless of which page you are on."),
      I("AMS Mobile Bottom Navigation Bar"),
      SH("Bottom Navigation Bar", [
        T("The bottom navigation bar displays between five and seven items depending on your role. Each item consists of an icon and a label. The currently active page is highlighted with a darker background and a filled icon, while inactive items appear in a lighter gray with an outlined icon. Tapping any item navigates to that page immediately. Students see the Schedule, Members, Logs, Profile, Location, and About items. Supervisors see a different set — they do not have a personal Schedule page but instead see Members, Profile, Location, Office, and About. The Logs page is shown to supervisors and the Schedule page is shown only to students."),
        TBL("Navigation Items by Role", 7, 3,
          "Page", "Student", "Supervisor / Admin",
          "Schedule", "Visible", "Hidden",
          "Members", "Visible", "Visible",
          "Logs", "Hidden", "Visible",
          "Profile", "Visible", "Visible",
          "Location", "Visible", "Visible",
          "Office", "Hidden", "Visible",
          "About", "Visible", "Visible"
        )
      ])
    ]),
    H("Desktop and Landscape Layout", [
      T("When AMS is opened on a desktop computer or when a mobile device is rotated to landscape orientation, the bottom navigation bar is replaced by a side rail panel fixed to the left side of the screen. The main content area expands to fill the remaining space to the right of the rail. This layout is optimized for wider screens and provides a more spacious view of each page's content."),
      I("AMS Desktop Side Rail Navigation"),
      SH("Side Rail Navigation", [
        T("The side rail panel is divided into three sections. At the top is the branding area, which displays the CCC logo, the institution name, the office name, and the school year badge or dropdown depending on your role. Below the branding area is the navigation section labeled NAVIGATION, which lists all available pages as full-width items with an icon and label. The active page is highlighted with a subtle white overlay and a small blue dot indicator on the right side of the item. At the bottom of the rail are the action buttons — supervisors and admins with school year advancement permission will see an Advance SY button here, and all users will see a Logout button styled in red."),
        I("AMS Side Rail — Branding and Navigation Sections"),
        I("AMS Side Rail — Bottom Action Buttons")
      ])
    ]),
    H("School Year Switcher", [
      T("Supervisors, admins, and the Super Admin have access to a school year switcher that appears in the navigation area. For supervisors and admins on mobile, it appears in the app bar at the top of the screen. On desktop, it appears in both the top bar and the side rail branding section. Students see a static school year badge that displays their enrolled school year and cannot switch between years."),
      I("AMS School Year Switcher Dropdown"),
      T("Tapping or clicking the school year badge opens a dropdown menu listing all available school year iterations from the earliest to the most recent. Each entry in the dropdown shows the school year label and a status badge — the current active school year is marked with a green ACTIVE badge, while past iterations are marked with a gray PAST badge. Selecting a past school year switches the Members and Schedule views to show data from that year without affecting any live records. A yellow highlight on the badge indicates you are currently viewing a past school year rather than the active one. Switching back to the active year restores the live view."),
      TBL("School Year Badge States", 3, 2,
        "Badge Appearance", "Meaning",
        "Standard color, labeled with current SY", "You are viewing the active school year",
        "Yellow / amber color, labeled with a past SY", "You are viewing a past school year in read-only mode"
      )
    ]),
    H("Advance School Year", [
      T("The Advance School Year function is available to supervisors and admins. It permanently moves the system forward to the next school year iteration, archiving all current student records and resetting the active roster. This action cannot be undone and should only be performed at the end of an OJT cycle when all student records for the current year have been finalized. The button appears as an upward arrow icon in the app bar on mobile and as an Advance SY button at the bottom of the side rail on desktop."),
      SH("Warning Steps", [
        T("To prevent accidental advancement, AMS requires confirmation through a three-step warning dialog before the action is carried out. Each step must be explicitly accepted before the next one appears. The first step presents a general warning showing the current school year and the school year it will be advanced to, and asks for initial confirmation to continue. The second step is a final warning in red that emphasizes the action cannot be undone and that all students on the current school year will be marked inactive — this step requires a second explicit confirmation. The third step confirms that a backup will be downloaded to your device before the advancement proceeds."),
        I("AMS Advance School Year — Step 1: Initial Warning"),
        I("AMS Advance School Year — Step 2: Final Warning"),
        I("AMS Advance School Year — Step 3: Backup Confirmation")
      ]),
      SH("Backup Before Advancing", [
        T("After all three warning steps are accepted, AMS automatically requests a full backup of your office data from the server before performing the advancement. This backup includes all users, schedules, records, and settings associated with your office. The backup is saved as a JSON file to your device. On Android, it is saved to external storage. On Windows and Web, a save dialog will appear allowing you to choose where to store the file. The advancement will only proceed if the backup is saved successfully — if the save is cancelled or fails, the process is aborted and no changes are made to the system. Once the backup is confirmed, the school year is advanced, the page refreshes automatically, and a success message confirms the new active school year.")
      ])
    ])
  ])
]
