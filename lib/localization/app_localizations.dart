import 'package:flutter/material.dart';

/// Supported application language model
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

/// Comprehensive Localization system supporting 7 Indian languages
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'en', name: 'English', nativeName: 'English', flag: '🇮🇳'),
    AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    AppLanguage(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', flag: '🇮🇳'),
    AppLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी', flag: '🇮🇳'),
    AppLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🇮🇳'),
    AppLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '🇮🇳'),
    AppLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🇮🇳'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    // ── English ─────────────────────────────────────────
    'en': {
      'appName': 'Rakshak Connect',
      'tagline': 'Smart Emergency Response System',
      'staySafe': 'Stay safe, stay connected',
      'sosButton': 'SOS',
      'tapToAlert': 'TAP TO ALERT',
      'myContacts': 'My Contacts',
      'liveLocation': 'Live Location',
      'emergencyCall': 'Emergency Call',
      'alertHistory': 'Alert History',
      'fakeCall': 'Fake Call',
      'safetyTips': 'Safety Tips',
      'panicSiren': 'Panic Siren',
      'medicalId': 'Medical ID & ICE',
      'home': 'Home',
      'contacts': 'Contacts',
      'govServices': 'Services',
      'history': 'History',
      'profile': 'Profile',
      'settings': 'Settings',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'sendEmergencyAlert': 'Send Emergency Alert',
      'sosConfirm': 'Yes, Send Alert',
      'sosCancel': 'Cancel',
      'sosSending': 'Sending Alert...',
      'sosSuccess': 'Alert Sent Successfully!',
      'sosFailed': 'Alert Failed. Please try again.',
      'police': 'Police',
      'ambulance': 'Ambulance',
      'fireService': 'Fire Service',
      'womenHelpline': 'Women Helpline',
      'childHelpline': 'Child Helpline',
      'disasterMgmt': 'Disaster Management',
      'addContact': 'Add Contact',
      'save': 'Save',
      'logout': 'Logout',
    },

    // ── Hindi (हिन्दी) ───────────────────────────────────
    'hi': {
      'appName': 'रक्षक कनेक्ट',
      'tagline': 'स्मार्ट आपातकालीन प्रतिक्रिया प्रणाली',
      'staySafe': 'सुरक्षित रहें, जुड़े रहें',
      'sosButton': 'आपातकाल',
      'tapToAlert': 'अलर्ट भेजने के लिए दबाएं',
      'myContacts': 'मेरे संपर्क',
      'liveLocation': 'लाइव लोकेशन',
      'emergencyCall': 'आपातकालीन कॉल',
      'alertHistory': 'अलर्ट इतिहास',
      'fakeCall': 'फेक कॉल',
      'safetyTips': 'सुरक्षा सुझाव',
      'panicSiren': 'पैनिक सायरन',
      'medicalId': 'मेडिकल आईडी (ICE)',
      'home': 'होम',
      'contacts': 'संपर्क',
      'govServices': 'सेवाएं',
      'history': 'इतिहास',
      'profile': 'प्रोफ़ाइल',
      'settings': 'सेटिंग्स',
      'language': 'भाषा (Language)',
      'darkMode': 'डार्क मोड',
      'sendEmergencyAlert': 'आपातकालीन अलर्ट भेजें',
      'sosConfirm': 'हाँ, अलर्ट भेजें',
      'sosCancel': 'रद्द करें',
      'sosSending': 'अलर्ट भेजा जा रहा है...',
      'sosSuccess': 'अलर्ट सफलतापूर्वक भेजा गया!',
      'sosFailed': 'अलर्ट विफल हुआ। कृपया पुनः प्रयास करें।',
      'police': 'पुलिस (112)',
      'ambulance': 'एम्बुलेंस (108)',
      'fireService': 'दमकल सेवा (101)',
      'womenHelpline': 'महिला हेल्पलाइन (1091)',
      'childHelpline': 'चाइल्ड हेल्पलाइन (1098)',
      'disasterMgmt': 'आपदा प्रबंधन (1078)',
      'addContact': 'नया संपर्क जोड़ें',
      'save': 'सहेजें',
      'logout': 'लॉग आउट',
    },

    // ── Gujarati (ગુજરાતી) ──────────────────────────────
    'gu': {
      'appName': 'રક્ષક કનેક્ટ',
      'tagline': 'સ્માર્ટ કટોકટી પ્રતિસાદ સિસ્ટમ',
      'staySafe': 'સુરક્ષિત રહો, જોડાયેલા રહો',
      'sosButton': 'કટોકટી SOS',
      'tapToAlert': 'ચેતવણી આપવા માટે દબાવો',
      'myContacts': 'મારા સંપર્કો',
      'liveLocation': 'લાઇવ લોકેશન',
      'emergencyCall': 'ઇમરજન્સી કૉલ',
      'alertHistory': 'ચેતવણી ઇતિહાસ',
      'fakeCall': 'ફેક કૉલ',
      'safetyTips': 'સુરક્ષા ટિપ્સ',
      'panicSiren': 'પેનિક સાયરન',
      'medicalId': 'મેડિકલ ID (ICE)',
      'home': 'હોમ',
      'contacts': 'સંપર્કો',
      'govServices': 'સેવાઓ',
      'history': 'ઇતિહાસ',
      'profile': 'પ્રોફાઇલ',
      'settings': 'સેટિંગ્સ',
      'language': 'ભાષા',
      'darkMode': 'ડાર્ક મોડ',
      'sendEmergencyAlert': 'કટોકટી ચેતવણી મોકલો',
      'sosConfirm': 'હા, ચેતવણી મોકલો',
      'sosCancel': 'રદ કરો',
      'sosSending': 'ચેતવણી મોકલી રહ્યું છે...',
      'sosSuccess': 'ચેતવણી સફળતાપૂર્વક મોકલાઈ!',
      'sosFailed': 'ચેતવણી નિષ્ફળ થઈ. ફરી પ્રયાસ કરો.',
      'police': 'પોલીસ (112)',
      'ambulance': 'એમ્બ્યુલન્સ (108)',
      'fireService': 'ફાયર સર્વિસ (101)',
      'womenHelpline': 'મહિલા હેલ્પલાઇન (1091)',
      'childHelpline': 'ચાઇલ્ડ હેલ્પલાઇન (1098)',
      'disasterMgmt': 'આપત્તિ વ્યવસ્થાપન',
      'addContact': 'સંપર્ક ઉમેરો',
      'save': 'સાચવો',
      'logout': 'લૉગ આઉટ',
    },

    // ── Marathi (मराठी) ──────────────────────────────────
    'mr': {
      'appName': 'रक्षक कनेक्ट',
      'tagline': 'स्मार्ट आणीबाणी प्रतिसाद प्रणाली',
      'staySafe': 'सुरक्षित रहा, कनेक्टेड रहा',
      'sosButton': 'आणीबाणी SOS',
      'tapToAlert': 'अलर्ट देण्यासाठी टॅप करा',
      'myContacts': 'माझे संपर्क',
      'liveLocation': 'थेट स्थान (Live Location)',
      'emergencyCall': 'आणीबाणी कॉल',
      'alertHistory': 'अलर्ट इतिहास',
      'fakeCall': 'बनावट कॉल',
      'safetyTips': 'सुरक्षा टिपा',
      'panicSiren': 'पॅनिक सायरन',
      'medicalId': 'वैद्यकीय आयडी (ICE)',
      'home': 'मुख्यपृष्ठ',
      'contacts': 'संपर्क',
      'govServices': 'सेवा',
      'history': 'इतिहास',
      'profile': 'प्रोफाइल',
      'settings': 'सेटिंग्ज',
      'language': 'भाषा',
      'darkMode': 'डार्क मोड',
      'sendEmergencyAlert': 'आणीबाणी अलर्ट पाठवा',
      'sosConfirm': 'होय, अलर्ट पाठवा',
      'sosCancel': 'रद्द करा',
      'sosSending': 'अलर्ट पाठवत आहे...',
      'sosSuccess': 'अलर्ट यशस्वीरित्या पाठवला!',
      'sosFailed': 'अलर्ट अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
      'police': 'पोलीस (112)',
      'ambulance': 'रुग्णवाहिका (108)',
      'fireService': 'अग्निशामक दल (101)',
      'womenHelpline': 'महिला हेल्पलाइन (1091)',
      'childHelpline': 'चाइल्ड हेल्पलाइन (1098)',
      'disasterMgmt': 'आपत्ती व्यवस्थापन',
      'addContact': 'संपर्क जोडा',
      'save': 'जतन करा',
      'logout': 'लॉग आउट',
    },

    // ── Tamil (தமிழ்) ────────────────────────────────────
    'ta': {
      'appName': 'ரக்ஷக் கனெக்ட்',
      'tagline': 'ஸ்மார்ட் அவசரக்கால உதவி அமைப்பு',
      'staySafe': 'பாதுகாப்பாக இருங்கள்',
      'sosButton': 'அவசர SOS',
      'tapToAlert': 'எச்சரிக்க தட்டவும்',
      'myContacts': 'என் தொடர்புகள்',
      'liveLocation': 'நேரலை இருப்பிடம்',
      'emergencyCall': 'அவசர அழைப்பு',
      'alertHistory': 'எச்சரிக்கை வரலாறு',
      'fakeCall': 'போலி அழைப்பு',
      'safetyTips': 'பாதுகாப்பு குறிப்புகள்',
      'panicSiren': 'சைரன் ஒலி',
      'medicalId': 'மருத்துவ அட்டை (ICE)',
      'home': 'முகப்பு',
      'contacts': 'தொடர்புகள்',
      'govServices': 'சேவைகள்',
      'history': 'வரலாறு',
      'profile': 'சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'language': 'மொழி',
      'darkMode': 'டார்க் பயன்முறை',
      'sendEmergencyAlert': 'அவசர எச்சரிக்கை அனுப்பு',
      'sosConfirm': 'ஆம், எச்சரிக்கை அனுப்பு',
      'sosCancel': 'ரத்து செய்',
      'sosSending': 'எச்சரிக்கை அனுப்பப்படுகிறது...',
      'sosSuccess': 'எச்சரிக்கை வெற்றிகரமாக அனுப்பப்பட்டது!',
      'sosFailed': 'தோல்வி. மீண்டும் முயற்சிக்கவும்.',
      'police': 'காவல்துறை (112)',
      'ambulance': 'ஆம்புலன்ஸ் (108)',
      'fireService': 'தீயணைப்பு (101)',
      'womenHelpline': 'பெண்கள் உதவி (1091)',
      'childHelpline': 'குழந்தைகள் உதவி (1098)',
      'disasterMgmt': 'பேரிடர் மேலாண்மை',
      'addContact': 'தொடர்பைச் சேர்',
      'save': 'சேமி',
      'logout': 'வெளியேறு',
    },

    // ── Telugu (తెలుగు) ──────────────────────────────────
    'te': {
      'appName': 'రక్షక్ కనెక్ట్',
      'tagline': 'స్మార్ట్ అత్యవసర ప్రతిస్పందన వ్యవస్థ',
      'staySafe': 'సురక్షితంగా ఉండండి',
      'sosButton': 'అత్యవసర SOS',
      'tapToAlert': 'అలర్ట్ చేయడానికి నొక్కండి',
      'myContacts': 'నా పరిచయాలు',
      'liveLocation': 'లైవ్ లొకేషన్',
      'emergencyCall': 'అత్యవసర కాల్',
      'alertHistory': 'అలర్ట్ చరిత్ర',
      'fakeCall': 'ఫేక్ కాల్',
      'safetyTips': 'భద్రతా చిట్కాలు',
      'panicSiren': 'సైరన్ మోగించు',
      'medicalId': 'మెడికల్ ఐడీ (ICE)',
      'home': 'హోమ్',
      'contacts': 'పరిచయాలు',
      'govServices': 'సేవలు',
      'history': 'చరిత్ర',
      'profile': 'ప్రొఫైల్',
      'settings': 'సెట్టింగ్‌లు',
      'language': 'భాష',
      'darkMode': 'డార్క్ మోడ్',
      'sendEmergencyAlert': 'అత్యవసర హెచ్చరిక పంపండి',
      'sosConfirm': 'అవును, హెచ్చరిక పంపు',
      'sosCancel': 'రద్దు చేయి',
      'sosSending': 'హెచ్చరిక పంపబడుతోంది...',
      'sosSuccess': 'హెచ్చరిక విజయవంతంగా పంపబడింది!',
      'sosFailed': 'విఫలమైంది. దయచేసి మళ్లీ ప్రయత్నించండి.',
      'police': 'పోలీస్ (112)',
      'ambulance': 'అంబులెన్స్ (108)',
      'fireService': 'ఫైర్ సర్వీస్ (101)',
      'womenHelpline': 'మహిళా హెల్ప్‌లైన్ (1091)',
      'childHelpline': 'చైల్డ్ హెల్ప్‌లైన్ (1098)',
      'disasterMgmt': 'విపత్తు నిర్వహణ',
      'addContact': 'పరిచయాన్ని జోడించు',
      'save': 'సేవ్ చేయి',
      'logout': 'లాగ్ అవుట్',
    },

    // ── Bengali (বাংলা) ───────────────────────────────────
    'bn': {
      'appName': 'রক্ষক কানেক্ট',
      'tagline': 'স্মার্ট জরুরি প্রতিক্রিয়া ব্যবস্থা',
      'staySafe': 'নিরাপদ থাকুন, সাথে থাকুন',
      'sosButton': 'জরুরি SOS',
      'tapToAlert': 'সতর্ক করতে ট্যাপ করুন',
      'myContacts': 'আমার পরিচিতি',
      'liveLocation': 'লাইভ অবস্থান',
      'emergencyCall': 'জরুরি কল',
      'alertHistory': 'সতর্কতার ইতিহাস',
      'fakeCall': 'ফেক কল',
      'safetyTips': 'নিরাপত্তা টিপস',
      'panicSiren': 'প্যানিক সাইরেন',
      'medicalId': 'মেডিকেল আইডি (ICE)',
      'home': 'হোম',
      'contacts': 'পরিচিতি',
      'govServices': 'সেবাসমূহ',
      'history': 'ইতিহাস',
      'profile': 'প্রোফাইল',
      'settings': 'সেটিংস',
      'language': 'ভাষা',
      'darkMode': 'ডার্ক মোড',
      'sendEmergencyAlert': 'জরুরি সতর্কতা পাঠান',
      'sosConfirm': 'হ্যাঁ, সতর্কতা পাঠান',
      'sosCancel': 'বাতিল করুন',
      'sosSending': 'সতর্কতা পাঠানো হচ্ছে...',
      'sosSuccess': 'সতর্কতা সফলভাবে পাঠানো হয়েছে!',
      'sosFailed': 'ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
      'police': 'পুলিশ (112)',
      'ambulance': 'অ্যাম্বুলেন্স (108)',
      'fireService': 'দমকল পরিষেবা (101)',
      'womenHelpline': 'মহিলা হেল্পলাইন (1091)',
      'childHelpline': 'চাইল্ড হেল্পলাইন (1098)',
      'disasterMgmt': 'দুর্যোগ ব্যবস্থাপনা',
      'addContact': 'পরিচিতি যোগ করুন',
      'save': 'সংরক্ষণ করুন',
      'logout': 'লগ আউট',
    },
  };

  /// Translate a given key to active language
  String t(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => [
        'en',
        'hi',
        'gu',
        'mr',
        'ta',
        'te',
        'bn',
      ].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
