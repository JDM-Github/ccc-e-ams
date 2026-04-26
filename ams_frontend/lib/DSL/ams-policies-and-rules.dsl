[
  BH("Policies and Rules", [
    T("This section documents the rules and policies that AMS enforces automatically during normal use. These are not optional guidelines — they are hard constraints built into the system that govern when records can be created, how hours are calculated, and what conditions must be met for attendance data to be counted toward a student's OJT completion. Understanding these rules helps students avoid rejected records and helps supervisors configure their office settings correctly."),
    H("GPS Attendance Policy", [
      T("AMS uses the device's GPS to determine a student's physical location at the time of logging a time-in record. The system compares the student's current coordinates against the office's registered GPS coordinates using the Haversine formula, which calculates the straight-line distance between two points on the earth's surface. This distance is evaluated against a fixed check-in radius of 40 meters that applies uniformly to all offices and cannot be changed by supervisors."),
      TBL("GPS Attendance Outcomes", 3, 2,
        "Student's GPS Position", "Result",
        "Within 40 meters of office coordinates", "Record is marked as In Office — hours are counted normally upon completion",
        "Beyond 40 meters of office coordinates", "Record is marked as Work From Home — subject to supervisor approval before hours are counted"
      ),
      T("GPS location is requested when the Schedule and Location pages are first opened. The student must grant location permission to the app for attendance logging to function. If permission is denied, AMS will display an error message and the student will be unable to add records until permission is granted through the device settings. On Android, location services must also be enabled at the system level. AMS uses high-accuracy GPS mode and listens for position updates continuously while the Schedule page is open, updating the in-office status indicator in real time as the student's position changes.")
    ]),
    H("Work From Home Policy", [
      T("Work From Home records are created automatically when a student attempts to log a time-in while outside the 40-meter office radius. The student does not manually choose to submit a WFH record — the system determines this based on GPS position. WFH records follow a different approval workflow compared to standard in-office records."),
      T("A WFH record that has not been approved by a supervisor or admin is considered pending and its hours are excluded from all calculations. The record appears in the student's list with a WFH Pending badge and a red border. A warning message is shown inside the record card explaining that the hours will not be counted until approval. The student's OJT progress bar and total hours display also exclude pending WFH records, and an orange info banner appears on the Profile and Schedule pages indicating how many WFH records are currently pending."),
      T("Supervisors and admins can approve a WFH record by opening the Member Detail Screen for the student, locating the record, and editing it to enable the Accept Work From Home toggle. Once approved, the record's badge changes to WFH Approved, the red border is removed, and the hours are immediately included in the student's total. Supervisors can also pre-approve WFH records when adding them manually through the Add Schedule dialog by enabling both the Work From Home toggle and the Accept WFH toggle at the time of creation."),
      TBL("WFH Record States", 4, 2,
        "State", "Description",
        "WFH Pending", "Record submitted outside office radius — hours excluded from total — awaiting supervisor approval",
        "WFH Approved", "Record reviewed and accepted by supervisor or admin — hours included in total",
        "Pre-approved WFH", "Record manually added by supervisor with both WFH and Accept WFH enabled — counted immediately",
        "In Office", "Record submitted within 40-meter radius — approved automatically — hours counted normally"
      )
    ]),
    H("Early Time-In Policy", [
      T("AMS defines early time-in as any time-in recorded before 8:00 AM. The system detects this automatically by checking the hour component of the recorded time-in. When a time-in is flagged as early, its handling depends on whether a supervisor has accepted it or not."),
      T("If an early time-in is not accepted, AMS adjusts the effective time-in to 8:00 AM for all hour calculation purposes. The actual recorded time-in value is preserved in the database and remains visible on the record card with an Early Adjusted badge, but the hours counted from that record begin at 8:00 AM rather than the actual earlier time. This prevents students from accumulating hours before the standard working day begins."),
      T("If a supervisor accepts the early time-in — either by editing the record and enabling the Accept Early Time-In toggle, or by enabling it at the time of manual record creation — the actual recorded time-in is used for hour calculation as-is. The record displays an Early badge instead of Early Adjusted to indicate that the early hours have been approved and are being counted."),
      TBL("Early Time-In States", 3, 2,
        "State", "Hour Calculation Behavior",
        "Early (Accepted)", "Hours are counted from the actual recorded time-in even if it is before 8:00 AM",
        "Early Adjusted (Not Accepted)", "Hours are counted from 8:00 AM regardless of the actual recorded time-in"
      )
    ]),
    H("Time-Out Cap Policy", [
      T("Each office defines a Time-Out Cap — the latest time that can be recorded as a time-out for any attendance record. This setting is configured by the supervisor in the Office page and applies to all students under that office. The cap is enforced automatically by AMS at the moment a student submits their time-out."),
      T("When a student submits a time-out that is later than the office's Time-Out Cap, AMS silently adjusts the recorded time-out to the cap value before saving the record. The student is notified of this adjustment through a warning snackbar message that appears after the record is saved. The message confirms that the time-out was capped and states the cap time so the student is aware of the adjustment. The actual submission time is not stored — only the capped value is recorded in the system."),
      T("This policy exists to prevent inflated hour counts from very late time-outs and to align all records with the office's defined working day boundaries. Supervisors can override the cap for individual records by editing the record in the Member Detail Screen and enabling the Accept Time-Out Cap Override toggle if one is available, or by manually setting a specific time-out value through the edit dialog.")
    ]),
    H("Weekend Attendance Policy", [
      T("By default, AMS does not allow students to log attendance records on Saturdays or Sundays. This restriction is enforced at the office level through the Allow Weekend setting in the Office page. When the setting is disabled — which is the default — any attempt by a student to add a record on a weekend day will be rejected with a warning message."),
      T("When the Allow Weekend setting is enabled by the supervisor, weekend records are treated identically to weekday records. The same GPS check, time-in window enforcement, proof photo requirement, and time-out cap policy all apply on weekends when the setting is active. Supervisors should enable this setting only for offices where OJT duties are genuinely expected to be performed on weekends."),
      TBL("Weekend Attendance Behavior", 3, 2,
        "Allow Weekend Setting", "Behavior on Saturday or Sunday",
        "Disabled (default)", "Students cannot add records — a warning message is shown and the action is blocked",
        "Enabled", "Students can add records normally — all standard policies apply"
      )
    ]),
    H("Hour Calculation Rules", [
      T("OJT hours in AMS are not simply the difference between time-in and time-out. The system applies several rules and deductions when calculating the hours contributed by each attendance record. These rules ensure that only legitimate working hours are counted toward the student's OJT completion."),
      SH("Lunch Break Deduction", [
        T("AMS automatically deducts one hour for lunch break from any record whose time span overlaps with the lunch period defined as 12:00 PM to 1:00 PM. The deduction is proportional — only the portion of the lunch period that falls within the record's time span is deducted. For example, if a student times in at 11:30 AM and times out at 1:30 PM, the two-hour span is reduced by the full one-hour lunch overlap, resulting in one counted hour. If a student times in at 12:30 PM and times out at 2:00 PM, only thirty minutes of the lunch period overlap, so only thirty minutes are deducted from the total."),
        TBL("Lunch Deduction Examples", 5, 3,
          "Time In", "Time Out", "Hours Counted",
          "8:00 AM", "5:00 PM", "8.0 hours (1 hour lunch deducted from 9-hour span)",
          "11:30 AM", "1:30 PM", "1.0 hour (full lunch deducted from 2-hour span)",
          "12:30 PM", "2:00 PM", "1.0 hour (30-minute lunch deducted from 1.5-hour span)",
          "1:00 PM", "5:00 PM", "4.0 hours (no lunch overlap — full span counted)"
        )
      ]),
      SH("Auto Time-Out for Past Records", [
        T("If a student logged a time-in record on a past date but did not submit a time-out before the day ended, AMS automatically treats 5:00 PM as the effective time-out for that record when calculating hours. This auto time-out is applied only for display and calculation purposes — the record in the database still shows no time-out, and the record card displays 5:00 PM with a tooltip icon indicating that the value was automatically assigned. The lunch break deduction still applies to the auto time-out calculation. This rule prevents past records without time-outs from being permanently excluded from the student's progress total.")
      ]),
      SH("WFH Pending Exclusion", [
        T("Work From Home records that have not been approved by a supervisor are completely excluded from all hour calculations. They do not contribute to the student's completed hours total, are not counted in the progress bar calculation, and are not included in the statistics shown on the Profile page. Only after a supervisor approves a WFH record does it begin contributing to the student's total. This exclusion is applied consistently across the Schedule page, Profile page, Members page progress bars, and the Member Detail Screen info panel.")
      ]),
      T("The following table summarizes all conditions that affect whether a record's hours are counted and how the effective time values are determined before calculation."),
      TBL("Hour Calculation Conditions Summary", 7, 3,
        "Condition", "Effective Time-In", "Hours Counted",
        "Standard in-office record with time-out", "Recorded time-in", "Yes — lunch deducted if applicable",
        "Early time-in accepted", "Recorded time-in (before 8:00 AM)", "Yes — lunch deducted if applicable",
        "Early time-in not accepted", "Adjusted to 8:00 AM", "Yes — from 8:00 AM — lunch deducted if applicable",
        "Past record with no time-out", "Recorded time-in", "Yes — time-out treated as 5:00 PM — lunch deducted if applicable",
        "WFH record approved", "Recorded time-in", "Yes — lunch deducted if applicable",
        "WFH record pending", "Recorded time-in", "No — excluded entirely until approved"
      )
    ])
  ])
]
