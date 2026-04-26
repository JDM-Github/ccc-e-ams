[
  BH("About the App", [
    T("This section provides general information about the AMS application itself — its version, the institution it was built for, and the vision and mission that guide the college it serves. This information is also accessible directly within the app through the About page, which is available to all users regardless of role."),
    H("Version and Build Information", [
      T("The current release of AMS is version 1.0.0 with a build number of 2026.03. The version number follows a standard major.minor.patch format. The build number reflects the year and month of the build, providing a quick reference for identifying when a particular release was compiled. These values are displayed on the About page of the app under the App Information card and can be used when reporting issues or verifying that a device is running the latest release."),
      TBL("App Information", 4, 2,
        "Field", "Value",
        "Application Name", "CCC Attendance Monitoring System",
        "Version", "1.0.0",
        "Build", "2026.03",
        "Institution", "City College of Calamba"
      )
    ]),
    H("Institution", [
      T("AMS was developed exclusively for City College of Calamba, a local university in the Philippines committed to producing future-ready professionals through quality education and community engagement. The system is purpose-built around the OJT coordination needs of the college and is not intended for general use outside of that institutional context. All office configurations, GPS policies, school year structures, and account management workflows in AMS are designed to align with the college's OJT program requirements.")
    ]),
    H("Vision and Mission", [
      T("The About page of AMS displays the official vision and mission statements of City College of Calamba. These are presented as a reference for all users of the system and reflect the institutional values that the AMS platform was built to support."),
      SH("Vision", [
        T("City College of Calamba envisions itself as a reputable and internationally engaged local university that produces future-ready global professionals by 2035. This vision drives the college's commitment to equipping students with the skills, discipline, and professional formation needed to succeed in a competitive global environment — values that the OJT program, and by extension AMS, directly supports by instilling accountability and professionalism in students during their internship period.")
      ]),
      SH("Mission", [
        T("The mission of City College of Calamba is to cultivate future-ready global professionals through inclusive education, a research-oriented culture, and collaborative partnerships. AMS contributes to this mission by providing a transparent, accurate, and accountable platform for managing the practical component of students' academic journey — ensuring that OJT hours are properly documented, verified, and recognized.")
      ])
    ]),
    H("Key Features Summary", [
      T("The following is a consolidated summary of all major features available in AMS across all platforms and roles. This summary is also displayed on the About page within the app under the Key Features card."),
      TBL("AMS Key Features", 9, 2,
        "Feature", "Description",
        "GPS-Based Attendance", "Validates in-office presence using real-time GPS coordinates within a fixed 40-meter radius — students outside the radius are automatically flagged as Work From Home",
        "Work From Home Support", "Allows students to log attendance records from outside the office, with hours counted only after supervisor approval",
        "Proof Photo Capture", "Requires a photo to be attached for every time-in and time-out record — supports device camera and gallery on all platforms including Windows and Web via webcam",
        "Daily Summaries and Activity Reports", "Students can document daily accomplishments through free-form text summaries and multiple photo attachments organized per attendance record",
        "Excel Export", "Generates formatted Excel reports of attendance records with options for full history or custom date range export — includes hours, summaries, and AR photo counts per record",
        "Member Management", "Supervisors can view, add, edit, and manage all student and supervisor accounts registered under their office including manual schedule entry and member status control",
        "Multi-School Year Support", "Supports multiple academic iterations with a controlled school year advancement process that includes mandatory backup, three-step confirmation, and historical record preservation",
        "Data Backup and Restore", "Supervisors and the Super Admin can export full office data snapshots as JSON files and restore them when needed — includes all users, schedules, and records",
        "Cross-Platform", "Runs natively on Android, iOS, Windows, and Web from a single Flutter codebase with adaptive layouts for both portrait mobile and landscape desktop views"
      )
    ])
  ])
]
