/// Rakshak Connect – All app-wide string constants
class AppStrings {
  AppStrings._();

  // ── App ───────────────────────────────────────────
  static const String appName = 'Rakshak Connect';
  static const String tagline = 'Smart Emergency Response System';
  static const String taglineSub = 'One Tap for Your Safety';

  // ── Auth ──────────────────────────────────────────
  static const String login = 'Login';
  static const String register = 'Sign Up';
  static const String logout = 'Logout';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phoneNumber = 'Phone Number';
  static const String welcomeBack = 'Welcome Back!';
  static const String loginSubtitle = 'Login to your account';
  static const String createAccount = 'Create Account';
  static const String registerSubtitle = 'Sign up to get started';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String agreeTerms = 'I agree to Terms & Conditions';
  static const String resetEmailSent = 'Password reset email sent! Check your inbox.';

  // ── Home ──────────────────────────────────────────
  static const String hello = 'Hello';
  static const String staySafe = 'Stay safe, stay connected';
  static const String sosButton = 'SOS';
  static const String tapToAlert = 'TAP TO ALERT';
  static const String myContacts = 'My Contacts';
  static const String liveLocation = 'Live Location';
  static const String emergencyCall = 'Emergency Call';
  static const String alertHistory = 'Alert History';

  // ── Navigation ────────────────────────────────────
  static const String home = 'Home';
  static const String contacts = 'Contacts';
  static const String govServices = 'Services';
  static const String history = 'History';
  static const String profile = 'Profile';

  // ── SOS ───────────────────────────────────────────
  static const String sendEmergencyAlert = 'Send Emergency Alert';
  static const String sosConfirmTitle = 'Send SOS Alert?';
  static const String sosConfirmMessage =
      'This will send your location to all emergency contacts and alert authorities.';
  static const String sosConfirm = 'Yes, Send Alert';
  static const String sosCancel = 'Cancel';
  static const String sosSending = 'Sending Alert...';
  static const String sosSuccess = 'Alert Sent Successfully!';
  static const String sosFailed = 'Alert Failed. Please try again.';
  static const String cancelAlert = 'CANCEL ALERT';
  static const String alertWillBeSentTo = 'Alert will be sent to';
  static const String contacts3 = '3 Contacts';

  // ── Contacts ──────────────────────────────────────
  static const String addContact = 'Add Contact';
  static const String editContact = 'Edit Contact';
  static const String deleteContact = 'Delete Contact';
  static const String contactName = 'Contact Name';
  static const String relationship = 'Relationship';
  static const String saveContact = 'SAVE CONTACT';
  static const String addNewContact = '+ Add New Contact';
  static const String noContacts = 'No emergency contacts yet';
  static const String noContactsSubtitle = 'Add contacts to notify in emergencies';
  static const String searchContacts = 'Search contacts...';
  static const String deleteConfirm = 'Are you sure you want to delete this contact?';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';

  // ── Location ──────────────────────────────────────
  static const String yourCurrentLocation = 'Your Current Location';
  static const String latitude = 'Latitude';
  static const String longitude = 'Longitude';
  static const String shareLocation = 'SHARE LOCATION';
  static const String fetchingLocation = 'Fetching location...';
  static const String locationPermissionDenied = 'Location permission denied';

  // ── Government Services ───────────────────────────
  static const String governmentServices = 'Government Services';
  static const String govServicesSubtitle = 'Quick-access to Government Emergency Services';
  static const String tapToCall = 'Tap on any service to call';
  static const String call = 'CALL';

  // ── Emergency Services Data ───────────────────────
  static const String police = 'Police';
  static const String policeNumber = '112';
  static const String policeDesc = '24x7 Police Help';

  static const String ambulance = 'Ambulance';
  static const String ambulanceNumber = '108';
  static const String ambulanceDesc = 'Medical Emergency';

  static const String fireBrigade = 'Fire Service';
  static const String fireBrigadeNumber = '101';
  static const String fireBrigadeDesc = 'Fire Emergency';

  static const String womenHelpline = 'Women Helpline';
  static const String womenHelplineNumber = '1091';
  static const String womenHelplineDesc = 'Women Safety';

  static const String childHelpline = 'Child Helpline';
  static const String childHelplineNumber = '1098';
  static const String childHelplineDesc = 'Child Safety';

  static const String disasterMgmt = 'Disaster Management';
  static const String disasterMgmtNumber = '1078';
  static const String disasterMgmtDesc = 'Disaster Help';

  // ── Emergency Call ────────────────────────────────
  static const String calling = 'Calling...';
  static const String endCall = 'End Call';

  // ── History ───────────────────────────────────────
  static const String emergencyAlert = 'Emergency Alert';
  static const String sentToContacts = 'Sent to contacts';
  static const String success = 'Success';
  static const String failed = 'Failed';
  static const String noHistory = 'No alert history';
  static const String noHistorySubtitle = 'Your SOS alerts will appear here';

  // ── Profile ───────────────────────────────────────
  static const String editProfile = 'Edit Profile';
  static const String changePassword = 'Change Password';
  static const String appSettings = 'App Settings';
  static const String helpSupport = 'Help & Support';
  static const String aboutUs = 'About Us';
  static const String personalInformation = 'Personal Information';

  // ── Settings ──────────────────────────────────────
  static const String settings = 'Settings';
  static const String darkMode = 'Dark Mode';
  static const String language = 'Language';
  static const String notifications = 'Notifications';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsConditions = 'Terms & Conditions';
  static const String aboutApp = 'About App';
  static const String version = 'Version 1.0.0';

  // ── Tips ──────────────────────────────────────────
  static const String emergencyTips = 'Emergency Tips';
  static const String firstAid = 'First Aid';
  static const String fireSafety = 'Fire Safety';
  static const String disasterGuidance = 'Disaster Guidance';

  // ── Errors ────────────────────────────────────────
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Enter a valid email address';
  static const String passwordTooShort = 'Password must be at least 6 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String invalidPhone = 'Enter a valid 10-digit phone number';
  static const String somethingWentWrong = 'Something went wrong. Please try again.';
  static const String noInternet = 'No internet connection';
}
