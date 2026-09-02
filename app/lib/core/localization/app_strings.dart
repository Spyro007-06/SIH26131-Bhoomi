/// Multi-language localization dictionary for Bhoomi Farmer App.
/// Supports Marathi (Primary - mr-IN), Hindi (hi-IN), and Indian English (en-IN).

enum AppLanguage {
  marathi('mr', 'मराठी'),
  hindi('hi', 'हिंदी'),
  english('en', 'English');

  final String code;
  final String label;
  const AppLanguage(this.code, this.label);

  String get localeIdentifier => '$code-IN';
  bool get isMarathi => this == AppLanguage.marathi;
  bool get isHindi => this == AppLanguage.hindi;
  bool get isEnglish => this == AppLanguage.english;

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.marathi,
    );
  }
}

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  // App Identity
  String get appName => language == AppLanguage.marathi
      ? 'भूमी'
      : (language == AppLanguage.hindi ? 'भूमी' : 'Bhoomi');

  String get appTagline => language == AppLanguage.marathi
      ? 'तुमचा डिजिटल शेती सहाय्यक'
      : (language == AppLanguage.hindi
          ? 'आपका डिजिटल कृषि सहायक'
          : 'Your digital field assistant');

  String get loading => language == AppLanguage.marathi
      ? 'लोड होत आहे...'
      : (language == AppLanguage.hindi ? 'लोड हो रहा है...' : 'Loading...');

  // Auth - Phone
  String get welcomeTitle => language == AppLanguage.marathi
      ? 'भूमीमध्ये आपले स्वागत आहे'
      : (language == AppLanguage.hindi
          ? 'भूमी में आपका स्वागत है'
          : 'Welcome to Bhoomi');

  String get phoneSubtitle => language == AppLanguage.marathi
      ? 'सुरू करण्यासाठी आपला मोबाईल नंबर प्रविष्ट करा'
      : (language == AppLanguage.hindi
          ? 'शुरू करने के लिए अपना मोबाइल नंबर दर्ज करें'
          : 'Enter your mobile number to get started');

  String get phoneLabel => language == AppLanguage.marathi
      ? 'मोबाईल नंबर'
      : (language == AppLanguage.hindi ? 'मोबाइल नंबर' : 'Mobile Number');

  String get phoneHint => '98765 43210';

  String get sendOtp => language == AppLanguage.marathi
      ? 'OTP पाठवा'
      : (language == AppLanguage.hindi ? 'OTP भेजें' : 'Send OTP');

  String get invalidPhoneError => language == AppLanguage.marathi
      ? 'कृपया योग्य १० अंकी मोबाईल नंबर टाका'
      : (language == AppLanguage.hindi
          ? 'कृपया सही 10 अंकों का मोबाइल नंबर दर्ज करें'
          : 'Please enter a valid 10-digit mobile number');

  // Auth - Demo Mode
  String get tryDemoAccount => language == AppLanguage.marathi
      ? '🌾 डेमो खाते वापरून पहा'
      : (language == AppLanguage.hindi
          ? '🌾 डेमो खाता आज़माएँ'
          : '🌾 Try Demo Account');

  String get demoModalTitle => language == AppLanguage.marathi
      ? '🌾 भूमी डेमो'
      : (language == AppLanguage.hindi ? '🌾 भूमी डेमो' : '🌾 Bhoomi Demo');

  String get demoModalDesc => language == AppLanguage.marathi
      ? 'पूर्व-कॉन्फिगर केलेल्या शेतकरी प्रोफाइलसह भूमी ॲपचा अनुभव घ्या.'
      : (language == AppLanguage.hindi
          ? 'पहले से कॉन्फ़िगर की गई किसान प्रोफ़ाइल के साथ भूमी ऐप का अनुभव करें।'
          : 'Experience the Bhoomi Farmer App using a pre-configured demo farmer.');

  String get demoFarmerNameLabel => language == AppLanguage.marathi
      ? 'शेतकरी: रमेश पाटील'
      : (language == AppLanguage.hindi ? 'किसान: रमेश पाटिल' : 'Farmer: Ramesh Patil');

  String get demoFarmNameLabel => language == AppLanguage.marathi
      ? 'शेत: डेमो भात शेत (Demo Paddy Farm)'
      : (language == AppLanguage.hindi ? 'खेत: डेमो धान खेत (Demo Paddy Farm)' : 'Farm: Demo Paddy Farm');

  String get demoLocationLabel => language == AppLanguage.marathi
      ? 'स्थान: नाशिक, महाराष्ट्र'
      : (language == AppLanguage.hindi ? 'स्थान: नासिक, महाराष्ट्र' : 'Location: Nashik, Maharashtra');

  String get enterDemoButton => language == AppLanguage.marathi
      ? 'डेमो मध्ये प्रवेश करा'
      : (language == AppLanguage.hindi ? 'डेमो में प्रवेश करें' : 'Enter Demo');

  // Auth - OTP
  String get verifyNumberTitle => language == AppLanguage.marathi
      ? 'नंबर पडताळणी करा'
      : (language == AppLanguage.hindi
          ? 'नंबर सत्यापित करें'
          : 'Verify your number');

  String otpSentTo(String phone) => language == AppLanguage.marathi
      ? '$phone वर OTP पाठवला आहे'
      : (language == AppLanguage.hindi
          ? '$phone पर OTP भेजा गया है'
          : 'OTP sent to $phone');

  String get enterOtpHint => language == AppLanguage.marathi
      ? '६ अंकी OTP टाका'
      : (language == AppLanguage.hindi
          ? '6 अंकों का OTP दर्ज करें'
          : 'Enter 6-digit OTP');

  String get verifyOtp => language == AppLanguage.marathi
      ? 'पडताळणी करा'
      : (language == AppLanguage.hindi ? 'सत्यापित करें' : 'Verify OTP');

  String get changeNumber => language == AppLanguage.marathi
      ? 'नंबर बदला'
      : (language == AppLanguage.hindi ? 'नंबर बदलें' : 'Change Number');

  String get didntReceiveOtp => language == AppLanguage.marathi
      ? 'OTP मिळाला नाही का?'
      : (language == AppLanguage.hindi
          ? 'OTP नहीं मिला?'
          : "Didn't receive the OTP?");

  String get resendOtp => language == AppLanguage.marathi
      ? 'पुन्हा OTP पाठवा'
      : (language == AppLanguage.hindi ? 'OTP पुनः भेजें' : 'Resend OTP');

  String resendIn(int seconds) => language == AppLanguage.marathi
      ? '$seconds सेकंदात पुन्हा पाठवा'
      : (language == AppLanguage.hindi
          ? '$seconds सेकंड में पुनः भेजें'
          : 'Resend in ${seconds}s');

  String get invalidOtpLength => language == AppLanguage.marathi
      ? 'कृपया ६ अंकी OTP टाका'
      : (language == AppLanguage.hindi
          ? 'कृपया 6 अंकों का OTP दर्ज करें'
          : 'Please enter 6-digit OTP');

  // Navigation
  String get navHome => language == AppLanguage.marathi
      ? 'मुख्य'
      : (language == AppLanguage.hindi ? 'मुख्य' : 'Home');

  String get navCheckCrop => language == AppLanguage.marathi
      ? 'पीक तपासा'
      : (language == AppLanguage.hindi ? 'फसल जांचें' : 'Check Crop');

  String get navAlerts => language == AppLanguage.marathi
      ? 'सतर्कता'
      : (language == AppLanguage.hindi ? 'सतर्कता' : 'Alerts');

  String get navHistory => language == AppLanguage.marathi
      ? 'इतिहास'
      : (language == AppLanguage.hindi ? 'इतिहास' : 'History');

  String get navMore => language == AppLanguage.marathi
      ? 'अधिक'
      : (language == AppLanguage.hindi ? 'अधिक' : 'More');

  // Home Screen
  String get greetingMorning => language == AppLanguage.marathi
      ? 'शुभ प्रभात'
      : (language == AppLanguage.hindi ? 'शुभ प्रभात' : 'Good Morning');

  String get greetingAfternoon => language == AppLanguage.marathi
      ? 'शुभ दुपार'
      : (language == AppLanguage.hindi ? 'शुभ दोपहर' : 'Good Afternoon');

  String get greetingEvening => language == AppLanguage.marathi
      ? 'शुभ संध्याकाळ'
      : (language == AppLanguage.hindi ? 'शुभ संध्या' : 'Good Evening');

  String get fieldAssistantTitle => language == AppLanguage.marathi
      ? 'तुमचा शेती सल्लागार'
      : (language == AppLanguage.hindi
          ? 'आपका कृषि सलाहकार'
          : 'Your Crop Assistant');

  String get checkCropBannerTitle => language == AppLanguage.marathi
      ? 'पिकावर काही रोग किंवा कीड दिसतेय?'
      : (language == AppLanguage.hindi
          ? 'फसल पर कोई रोग या कीट दिख रहा है?'
          : 'Spot any disease or pest on your crop?');

  String get checkCropBannerAction => language == AppLanguage.marathi
      ? 'आताच फोटो काढून तपासा'
      : (language == AppLanguage.hindi
          ? 'अभी फोटो खींचकर जांचें'
          : 'Take photo to check now');

  String get activeFarmTitle => language == AppLanguage.marathi
      ? 'तुमचे शेत (सक्रिय नोंद)'
      : (language == AppLanguage.hindi
          ? 'आपका खेत (सक्रिय विवरण)'
          : 'Your Active Farm');

  String get noFarmSetupTitle => language == AppLanguage.marathi
      ? 'तुमच्या शेताची नोंदणी करा'
      : (language == AppLanguage.hindi
          ? 'अपने खेत का विवरण जोड़ें'
          : 'Set up your farm profile');

  String get noFarmSetupDesc => language == AppLanguage.marathi
      ? 'अचूक रोग निदान आणि हवामान अलर्ट मिळवण्यासाठी पिकाची माहिती जोडा.'
      : (language == AppLanguage.hindi
          ? 'सटीक रोग निदान और मौसम अलर्ट पाने के लिए फसल की जानकारी जोड़ें।'
          : 'Add your crop and location details for accurate disease diagnosis.');

  String get setupFarmButton => language == AppLanguage.marathi
      ? 'शेत जोडा'
      : (language == AppLanguage.hindi ? 'खेत जोड़ें' : 'Add Farm');

  String get recentAlertsHeader => language == AppLanguage.marathi
      ? 'हवामान व कीड सतर्कता'
      : (language == AppLanguage.hindi
          ? 'मौसम और कीट अलर्ट'
          : 'Weather & Pest Alerts');

  String get noActiveAlerts => language == AppLanguage.marathi
      ? 'सध्या तुमच्या परिसरासाठी कोणतीही गंभीर सतर्कता नाही.'
      : (language == AppLanguage.hindi
          ? 'फिलहाल आपके क्षेत्र के लिए कोई गंभीर अलर्ट नहीं है।'
          : 'No active risk alerts for your region right now.');

  // Low-Literacy Farmer UX Helpers
  String get checkCropHeroTitle => language == AppLanguage.marathi
      ? 'पिकाची तपासणी करा'
      : (language == AppLanguage.hindi ? 'फसल की जांच करें' : 'Check My Crop');

  String get checkCropHeroSubtitle => language == AppLanguage.marathi
      ? 'फोटो काढून रोग ओळखा'
      : (language == AppLanguage.hindi ? 'फोटो खींचकर रोग पहचानें' : 'Take photo to identify issue');

  String get askVoiceQuickAction => language == AppLanguage.marathi
      ? 'बोलून विचारा'
      : (language == AppLanguage.hindi ? 'बोलकर पूछें' : 'Ask by Voice');

  String get historyQuickAction => language == AppLanguage.marathi
      ? 'मागील तपासणी'
      : (language == AppLanguage.hindi ? 'पिछली जांच' : 'Past Checks');

  String get helpQuickAction => language == AppLanguage.marathi
      ? 'शेतकरी मदत'
      : (language == AppLanguage.hindi ? 'किसान मदद' : 'Farmer Help');

  String get simpleConfidenceHigh => language == AppLanguage.marathi
      ? '🟢 जास्त खात्री'
      : (language == AppLanguage.hindi ? '🟢 पूरी खात्री' : '🟢 High Confidence');

  String get simpleConfidenceMedium => language == AppLanguage.marathi
      ? '🟡 थोडी खात्री'
      : (language == AppLanguage.hindi ? '🟡 थोड़ी खात्री' : '🟡 Check more');

  String get simpleConfidenceLow => language == AppLanguage.marathi
      ? '🔴 तज्ञांची मदत'
      : (language == AppLanguage.hindi ? '🔴 विशेषज्ञ मदद' : '🔴 Expert Needed');

  String get followupStatusImproved => language == AppLanguage.marathi
      ? '🙂 सुधारणा झाली'
      : (language == AppLanguage.hindi ? '🙂 सुधार हुआ' : '🙂 Improved');

  String get followupStatusSame => language == AppLanguage.marathi
      ? '😐 जैसे थे'
      : (language == AppLanguage.hindi ? '😐 कोई बदलाव नहीं' : '😐 Same / No change');

  String get followupStatusWorse => language == AppLanguage.marathi
      ? '😟 जास्त खराब'
      : (language == AppLanguage.hindi ? '😟 स्थिति बिगड़ी' : '😟 Worse');

  String get speakAnswer => language == AppLanguage.marathi
      ? 'बोलून सांगा'
      : (language == AppLanguage.hindi ? 'बोलकर बताएं' : 'Speak Answer');

  String get callNowButton => language == AppLanguage.marathi
      ? 'थेट कॉल करा'
      : (language == AppLanguage.hindi ? 'सीधे कॉल करें' : 'Call Now');

  String get listenSpokenAudio => language == AppLanguage.marathi
      ? '🔊 सल्ला ऐका'
      : (language == AppLanguage.hindi ? '🔊 सलाह सुनें' : '🔊 Listen to Advisory');

  String get todayStatusSafe => language == AppLanguage.marathi
      ? 'पीक सुरक्षित आहे'
      : (language == AppLanguage.hindi ? 'फसल सुरक्षित है' : 'Crop looks safe for now');

  String get todayStatusAlert => language == AppLanguage.marathi
      ? 'शेतात धोका आहे'
      : (language == AppLanguage.hindi ? 'खेत में खतरा है' : 'Active field alert');

  String get pendingFollowupsHeader => language == AppLanguage.marathi
      ? 'पुढील तपासणी (फॉलो-अप)'
      : (language == AppLanguage.hindi
          ? 'अगली जांच (फॉलो-अप)'
          : 'Pending Follow-ups');

  String get noPendingFollowups => language == AppLanguage.marathi
      ? 'सध्या कोणतीही तपासणी प्रलंबित नाही.'
      : (language == AppLanguage.hindi
          ? 'फिलहाल कोई जांच लंबित नहीं है।'
          : 'No pending follow-up check-ins at this moment.');

  // Farm Setup Screen
  String get farmSetupTitle => language == AppLanguage.marathi
      ? 'शेताची माहिती नोंदवा'
      : (language == AppLanguage.hindi
          ? 'खेत की जानकारी दर्ज करें'
          : 'Set up Farm Profile');

  String get cropLabel => language == AppLanguage.marathi
      ? 'पीक (Crop)'
      : (language == AppLanguage.hindi ? 'फसल (Crop)' : 'Crop');

  String get cropPaddy => language == AppLanguage.marathi
      ? 'भात / धान (Paddy)'
      : (language == AppLanguage.hindi ? 'धान (Paddy)' : 'Paddy / Rice');

  String get varietyLabel => language == AppLanguage.marathi
      ? 'वाण / प्रकार (Variety)'
      : (language == AppLanguage.hindi ? 'किस्म (Variety)' : 'Variety');

  String get varietyHint => language == AppLanguage.marathi
      ? 'उदा. इंद्रायणी, बासमती, कर्जत'
      : (language == AppLanguage.hindi
          ? 'उदा. बासमती, पूसा'
          : 'e.g. Indrayani, Karjat-4');

  String get growthStageLabel => language == AppLanguage.marathi
      ? 'पिकाची अवस्था (Growth Stage)'
      : (language == AppLanguage.hindi
          ? 'फसल की अवस्था (Growth Stage)'
          : 'Growth Stage');

  String get growthStageNursery => language == AppLanguage.marathi
      ? 'रोपवाटिका (Nursery)'
      : (language == AppLanguage.hindi ? 'नर्सरी (Nursery)' : 'Nursery');

  String get growthStageTillering => language == AppLanguage.marathi
      ? 'फुटवे फुटण्याची अवस्था (Tillering)'
      : (language == AppLanguage.hindi
          ? 'कल्ले निकलने की अवस्था (Tillering)'
          : 'Tillering');

  String get growthStagePanicle => language == AppLanguage.marathi
      ? 'पोटरी / लोंबी निघणे (Panicle Initiation)'
      : (language == AppLanguage.hindi
          ? 'बालियां निकलना (Panicle Initiation)'
          : 'Panicle Initiation');

  String get growthStageFlowering => language == AppLanguage.marathi
      ? 'फुलोरा (Flowering)'
      : (language == AppLanguage.hindi ? 'फूल आना (Flowering)' : 'Flowering');

  String get growthStageGrainFilling => language == AppLanguage.marathi
      ? 'दाणे भरणे / पक्वता (Grain Filling / Maturity)'
      : (language == AppLanguage.hindi
          ? 'दाना भरना / पकना (Grain Filling / Maturity)'
          : 'Grain Filling / Maturity');

  String get regionLabel => language == AppLanguage.marathi
      ? 'जिल्हा / तालुका (Region)'
      : (language == AppLanguage.hindi ? 'जिला (Region)' : 'District / Region');

  String get regionHint => language == AppLanguage.marathi
      ? 'उदा. नाशिक, रायगड, ठाणे'
      : (language == AppLanguage.hindi
          ? 'उदा. नाशिक, पुणे'
          : 'e.g. Nashik, Raigad, Pune');

  String get locationLabel => language == AppLanguage.marathi
      ? 'शेताचे स्थान (GPS Location)'
      : (language == AppLanguage.hindi
          ? 'खेत का स्थान (GPS Location)'
          : 'Farm GPS Location');

  String get locationFetching => language == AppLanguage.marathi
      ? 'स्थान शोधत आहे...'
      : (language == AppLanguage.hindi
          ? 'स्थान खोजा जा रहा है...'
          : 'Detecting GPS location...');

  String get locationSet => language == AppLanguage.marathi
      ? 'स्थान निश्चित केले'
      : (language == AppLanguage.hindi ? 'स्थान तय हुआ' : 'GPS Location Set');

  String get saveFarmButton => language == AppLanguage.marathi
      ? 'शेत जतन करा'
      : (language == AppLanguage.hindi ? 'खेत सहेजें' : 'Save Farm Profile');

  // More Screen
  String get moreTitle => language == AppLanguage.marathi
      ? 'अधिक पर्याय'
      : (language == AppLanguage.hindi ? 'अन्य विकल्प' : 'More Options');

  String get profileSection => language == AppLanguage.marathi
      ? 'शेतकरी प्रोफाइल'
      : (language == AppLanguage.hindi
          ? 'किसान प्रोफ़ाइल'
          : 'Farmer Profile');

  String get selectLanguageTitle => language == AppLanguage.marathi
      ? 'भाषा निवडा / Select Language'
      : (language == AppLanguage.hindi
          ? 'भाषा चुनें / Select Language'
          : 'Select Language / भाषा निवडा');

  String get languageOption => language == AppLanguage.marathi
      ? 'भाषा बदला (Change Language)'
      : (language == AppLanguage.hindi
          ? 'भाषा बदलें (Change Language)'
          : 'Language (भाषा)');

  String get referralsOption => language == AppLanguage.marathi
      ? 'कृषी विज्ञान केंद्र (KVK) व मदत केंद्र'
      : (language == AppLanguage.hindi
          ? 'कृषि विज्ञान केंद्र (KVK) और हेल्पलाइन'
          : 'KVK & Agricultural Helpline');

  String get aboutOption => language == AppLanguage.marathi
      ? 'भूमीबद्दल माहिती'
      : (language == AppLanguage.hindi ? 'भूमी के बारे में' : 'About Bhoomi');

  String get myFarmOption => language == AppLanguage.marathi
      ? 'माझे शेत व पीक माहिती'
      : (language == AppLanguage.hindi ? 'मेरा खेत और फसल' : 'My Farm & Crop Profile');

  String get historyOption => language == AppLanguage.marathi
      ? 'तपासणी व सल्ला इतिहास'
      : (language == AppLanguage.hindi ? 'जांच व सलाह इतिहास' : 'Check & Advisory History');

  String get logoutButton => language == AppLanguage.marathi
      ? 'बाहेर पडा (Log Out)'
      : (language == AppLanguage.hindi
          ? 'लॉग आउट करें (Log Out)'
          : 'Log Out');

  String get logoutConfirmTitle => language == AppLanguage.marathi
      ? 'तुम्हाला बाहेर पडायचे आहे का?'
      : (language == AppLanguage.hindi
          ? 'क्या आप लॉग आउट करना चाहते हैं?'
          : 'Are you sure you want to log out?');

  String get logoutConfirmDesc => language == AppLanguage.marathi
      ? 'तुमची सत्र माहिती या फोनवरून हटवली जाईल.'
      : (language == AppLanguage.hindi
          ? 'आपका सत्र विवरण इस फोन से हटा दिया जाएगा।'
          : 'Your active session will be cleared from this device.');

  String get cancel => language == AppLanguage.marathi
      ? 'रद्द करा'
      : (language == AppLanguage.hindi ? 'रद्द करें' : 'Cancel');

  String get confirmLogout => language == AppLanguage.marathi
      ? 'हो, बाहेर पडा'
      : (language == AppLanguage.hindi ? 'हां, लॉग आउट करें' : 'Yes, Log Out');

  // Error Messages
  String get genericError => language == AppLanguage.marathi
      ? 'काहीतरी त्रुटी आली. कृपया पुन्हा प्रयत्न करा.'
      : (language == AppLanguage.hindi
          ? 'कुछ गड़बड़ हुई। कृपया पुनः प्रयास करें।'
          : 'Something went wrong. Please try again.');

  String get networkError => language == AppLanguage.marathi
      ? 'इंटरनेट कनेक्शन उपलब्ध नाही. कृपया नेटवर्क तपासा.'
      : (language == AppLanguage.hindi
          ? 'इंटरनेट उपलब्ध नहीं है। कृपया नेटवर्क जांचें।'
          : 'Internet connection unavailable. Please check your connection.');

  String get invalidOtpError => language == AppLanguage.marathi
      ? 'दिलेला OTP चुकीचा आहे. कृपया तपासून पुन्हा टाका.'
      : (language == AppLanguage.hindi
          ? 'दर्ज किया गया OTP गलत है। कृपया पुनः प्रयास करें।'
          : 'The OTP is incorrect. Please check the code and try again.');

  // Camera & Image Capture (Step 4)
  String get cameraTitle => language == AppLanguage.marathi
      ? 'पीक तपासा (फोटो घ्या)'
      : (language == AppLanguage.hindi ? 'फसल जांचें (फोटो लें)' : 'Check Crop (Take Photo)');

  String get cameraInstruction => language == AppLanguage.marathi
      ? 'पानावरील किंवा खोडावरील डाग स्पष्ट दिसतील असा फोटो घ्या.'
      : (language == AppLanguage.hindi
          ? 'पत्ती या तने पर लगे धब्बे साफ दिखें, ऐसी फोटो लें।'
          : 'Take a clear photo showing the affected leaf or stem.');

  String get cameraFrameGuide => language == AppLanguage.marathi
      ? 'पाने किंवा बाधित भाग चौकटीत ठेवा'
      : (language == AppLanguage.hindi
          ? 'पत्तियां या प्रभावित हिस्सा फ्रेम में रखें'
          : 'Keep affected leaf/crop inside frame');

  String get captureButton => language == AppLanguage.marathi
      ? 'फोटो काढा'
      : (language == AppLanguage.hindi ? 'फोटो खींचें' : 'Capture Photo');

  String get galleryButton => language == AppLanguage.marathi
      ? 'गॅलरीतून निवडा'
      : (language == AppLanguage.hindi ? 'गैलरी से चुनें' : 'Choose from Gallery');

  String get retakeButton => language == AppLanguage.marathi
      ? 'पुन्हा फोटो घ्या'
      : (language == AppLanguage.hindi ? 'दोबारा फोटो लें' : 'Retake');

  String get usePhotoButton => language == AppLanguage.marathi
      ? 'हा फोटो वापरा (तपासा)'
      : (language == AppLanguage.hindi ? 'यह फोटो उपयोग करें' : 'Use this Photo');

  String get previewTitle => language == AppLanguage.marathi
      ? 'फोटोची खात्री करा'
      : (language == AppLanguage.hindi ? 'फोटो की पुष्टि करें' : 'Confirm Photo');

  String get previewHint => language == AppLanguage.marathi
      ? 'रोग किंवा कीड स्पष्ट दिसत आहे का? नसल्यास पुन्हा फोटो घ्या.'
      : (language == AppLanguage.hindi
          ? 'क्या रोग या कीट साफ दिख रहा है? नहीं तो दोबारा फोटो लें।'
          : 'Is the affected area clearly visible? If not, retake.');

  // Diagnosis Loading (Step 4)
  String get checkingPhotoTitle => language == AppLanguage.marathi
      ? 'फोटो तपासत आहोत...'
      : (language == AppLanguage.hindi ? 'तस्वीर की जाँच हो रही है...' : 'Checking the crop photo...');

  String get checkingPhotoSubtitle => language == AppLanguage.marathi
      ? 'कृपया थोडा वेळ थांबा, लक्षणे ओळखली जात आहेत.'
      : (language == AppLanguage.hindi
          ? 'कृपया थोड़ा इंतज़ार करें, लक्षणों की पहचान की जा रही है।'
          : 'Please wait a moment while symptoms are analyzed.');

  String get uploadingPhoto => language == AppLanguage.marathi
      ? 'फोटो सुरक्षित सर्व्हरवर पाठवत आहोत...'
      : (language == AppLanguage.hindi
          ? 'फोटो सुरक्षित सर्वर पर भेज रहे हैं...'
          : 'Uploading photo securely...');

  // Confidence Gate - Advise Outcome
  String get diagnosisResultTitle => language == AppLanguage.marathi
      ? 'निदान व सल्ला'
      : (language == AppLanguage.hindi ? 'निदान और सलाह' : 'Diagnosis & Advisory');

  String get highConfidence => language == AppLanguage.marathi
      ? 'उच्च अचूकता (High Confidence)'
      : (language == AppLanguage.hindi ? 'उच्च सटीकता (High Confidence)' : 'High Confidence');

  String get moderateConfidence => language == AppLanguage.marathi
      ? 'मध्यम अचूकता (Moderate Confidence)'
      : (language == AppLanguage.hindi ? 'मध्यम सटीकता (Moderate Confidence)' : 'Moderate Confidence');

  String get otherPossibilities => language == AppLanguage.marathi
      ? 'इतर शक्यता (Other Possibilities)'
      : (language == AppLanguage.hindi ? 'अन्य संभावनाएं (Other Possibilities)' : 'Other Possibilities');

  String get whatToAvoidHeader => language == AppLanguage.marathi
      ? 'हे अजिबात करू नका (तातडीचा इशारा)'
      : (language == AppLanguage.hindi ? 'यह बिल्कुल न करें (चेतावनी)' : 'WHAT TO AVOID FIRST (CRITICAL)');

  String get whatToCheckHeader => language == AppLanguage.marathi
      ? 'शेतात काय तपासावे (लक्षणे)'
      : (language == AppLanguage.hindi ? 'खेत में क्या जांचें (लक्षण)' : 'WHAT TO CHECK (SYMPTOMS)');

  String get ipmLadderHeader => language == AppLanguage.marathi
      ? 'उपाययोजना पायऱ्या (IPM Ladder)'
      : (language == AppLanguage.hindi ? 'नियंत्रण के चरण (IPM Ladder)' : 'INTEGRATED PEST MANAGEMENT (IPM)');

  String get culturalTier => language == AppLanguage.marathi
      ? '१. मशागतीय उपाय (Cultural)'
      : (language == AppLanguage.hindi ? '1. सस्यीय उपाय (Cultural)' : '1. Cultural Action');

  String get biologicalTier => language == AppLanguage.marathi
      ? '२. जैविक उपाय (Biological)'
      : (language == AppLanguage.hindi ? '2. जैविक नियंत्रण (Biological)' : '2. Biological Action');

  String get chemicalTier => language == AppLanguage.marathi
      ? '३. रासायनिक उपाय (Chemical)'
      : (language == AppLanguage.hindi ? '3. रासायनिक नियंत्रण (Chemical)' : '3. Chemical Action');

  String get showChemicalDetails => language == AppLanguage.marathi
      ? '+ रासायनिक औषधांचे तपशील पहा'
      : (language == AppLanguage.hindi ? '+ रासायनिक दवाओं का विवरण देखें' : '+ Show chemical details');

  String get hideChemicalDetails => language == AppLanguage.marathi
      ? '- रासायनिक तपशील लपवा'
      : (language == AppLanguage.hindi ? '- रासायनिक विवरण छुपाएं' : '- Hide chemical details');

  String get citationsHeader => language == AppLanguage.marathi
      ? 'सल्ल्याचा अधिकृत संदर्भ (Citations)'
      : (language == AppLanguage.hindi ? 'सलाह का आधिकारिक स्रोत' : 'Why this advice? (Official Sources)');

  String get listenAudio => language == AppLanguage.marathi
      ? 'सल्ला ऐका (Listen)'
      : (language == AppLanguage.hindi ? 'सलाह सुनें (Listen)' : 'Listen to Advisory');

  // Confidence Gate - Doubt Doctor (Clarify Outcome)
  String get doubtDoctorTitle => language == AppLanguage.marathi
      ? 'थोडी अधिक माहिती हवी आहे'
      : (language == AppLanguage.hindi ? 'थोड़ी और जानकारी चाहिए' : "Let's check one more thing");

  String get doubtDoctorSubtitle => language == AppLanguage.marathi
      ? 'अचूक निदानासाठी शेतात प्रत्यक्ष पाहून खालील प्रश्नाचे उत्तर द्या.'
      : (language == AppLanguage.hindi
          ? 'सटीक निदान के लिए खेत में देखकर नीचे दिए गए प्रश्न का उत्तर दें।'
          : 'Check your field observation to confirm the diagnosis.');

  String get answerYes => language == AppLanguage.marathi
      ? 'होय (YES)'
      : (language == AppLanguage.hindi ? 'हाँ (YES)' : 'YES');

  String get answerNo => language == AppLanguage.marathi
      ? 'नाही (NO)'
      : (language == AppLanguage.hindi ? 'नहीं (NO)' : 'NO');

  String get answerUnknown => language == AppLanguage.marathi
      ? 'सांगता येत नाही (CAN\'T TELL)'
      : (language == AppLanguage.hindi ? 'पता नहीं (CAN\'T TELL)' : "CAN'T TELL");

  // Confidence Gate - Escalate Outcome
  String get escalateTitle => language == AppLanguage.marathi
      ? 'तज्ञांकडे वर्ग केले (Escalated)'
      : (language == AppLanguage.hindi ? 'विशेषज्ञ को भेजा गया (Escalated)' : 'Referred to Agricultural Expert');

  String get escalateSubtitle => language == AppLanguage.marathi
      ? 'या समस्येची लक्षणे अस्पष्ट असल्याने आम्ही ही केस स्थानिक कृषी शास्त्रज्ञांकडे पाठवली आहे.'
      : (language == AppLanguage.hindi
          ? 'लक्षण अस्पष्ट होने के कारण यह मामला स्थानीय कृषि वैज्ञानिक को भेजा गया है।'
          : 'Symptoms could not be identified with certainty. An expert is reviewing your case.');

  String get caseIdLabel => language == AppLanguage.marathi
      ? 'केस क्रमांक (Case ID)'
      : (language == AppLanguage.hindi ? 'केस संख्या (Case ID)' : 'Case ID');

  String get assignedToLabel => language == AppLanguage.marathi
      ? 'नियुक्त केंद्र / तज्ञ'
      : (language == AppLanguage.hindi ? 'नियुक्त केंद्र / विशेषज्ञ' : 'Assigned Expert / KVK');

  String get queuePositionLabel => language == AppLanguage.marathi
      ? 'रांगेतील स्थान'
      : (language == AppLanguage.hindi ? 'कतार में स्थान' : 'Queue Position');

  String get etaMinutesLabel => language == AppLanguage.marathi
      ? 'अपेक्षित वेळ'
      : (language == AppLanguage.hindi ? 'अनुमानित समय' : 'Estimated Time');

  String get backToHome => language == AppLanguage.marathi
      ? 'मुख्य पृष्ठावर जा'
      : (language == AppLanguage.hindi ? 'मुख्य पृष्ठ पर जाएं' : 'Back to Home');

  // GPS Location Strings
  String get locationDetecting => language == AppLanguage.marathi
      ? 'GPS स्थान शोधत आहे...'
      : (language == AppLanguage.hindi ? 'GPS स्थान खोजा जा रहा है...' : 'Detecting GPS location...');

  String get locationPermissionRequired => language == AppLanguage.marathi
      ? 'शेताच्या हवामान अलर्ट आणि रोगांच्या अचूक निदानासाठी GPS स्थान आवश्यक आहे.'
      : (language == AppLanguage.hindi
          ? 'सटीक मौसम अलर्ट और रोग निदान के लिए GPS स्थान आवश्यक है।'
          : 'GPS location is required for local disease alerts and KVK routing.');

  String get locationDeniedError => language == AppLanguage.marathi
      ? 'स्थान परवानगी नाकारली. कृपया फोन सेटिंग्जमधून लोकेशन चालू करा.'
      : (language == AppLanguage.hindi
          ? 'स्थान की अनुमति अस्वीकृत। कृपया सेटिंग से लोकेशन चालू करें।'
          : 'Location permission denied. Please enable location services.');

  String get retryLocation => language == AppLanguage.marathi
      ? 'स्थान पुन्हा शोधा'
      : (language == AppLanguage.hindi ? 'स्थान पुनः खोजें' : 'Retry Location');

  // Step 5: Alerts
  String get alertsTitle => language == AppLanguage.marathi
      ? 'कीड व रोग सतर्कता'
      : (language == AppLanguage.hindi ? 'कीट व रोग सतर्कता' : 'Risk Alerts');

  String get alertsSubtitle => language == AppLanguage.marathi
      ? 'स्थानिक हवामान आणि प्रादुर्भावावर आधारित सूचना'
      : (language == AppLanguage.hindi
          ? 'स्थानीय मौसम और प्रकोप पर आधारित अलर्ट'
          : 'Proactive alerts based on local weather and pest surveillance');

  String get illCheckButton => language == AppLanguage.marathi
      ? 'मी शेतात तपासतो (I\'ll Check)'
      : (language == AppLanguage.hindi ? 'मैं खेत में जाँचूँगा (I\'ll Check)' : 'I\'LL CHECK');

  String get alertResponseRecorded => language == AppLanguage.marathi
      ? 'प्रतिसाद नोंदवला गेला आहे. शेताचे निरीक्षण केल्याबद्दल धन्यवाद!'
      : (language == AppLanguage.hindi
          ? 'प्रतिक्रिया दर्ज की गई। निरीक्षण के लिए धन्यवाद!'
          : 'Response recorded. Thank you for checking your field!');

  String get noActiveAlertsTitle => language == AppLanguage.marathi
      ? 'सध्या कोणतीही सतर्कता नाही'
      : (language == AppLanguage.hindi ? 'वर्तमान में कोई अलर्ट नहीं है' : 'No active alerts');

  String get noActiveAlertsMessage => language == AppLanguage.marathi
      ? 'तुमच्या परिसरातील हवामान व पीक परिस्थिती सध्या सामान्य आहे.'
      : (language == AppLanguage.hindi
          ? 'आपके क्षेत्र में मौसम और फसल की स्थिति सामान्य है।'
          : 'Weather conditions and disease risk in your area are currently normal.');

  // Step 5: Follow-ups
  String get followupsTitle => language == AppLanguage.marathi
      ? 'उपाययोजना फॉलो-अप'
      : (language == AppLanguage.hindi ? 'उपाय फॉलो-अप' : 'Pending Follow-Ups');

  String get followupQuestionDefault => language == AppLanguage.marathi
      ? 'उपचारानंतर पिकाची स्थिती कशी आहे?'
      : (language == AppLanguage.hindi
          ? 'उपचार के बाद फसल की स्थिति कैसी है?'
          : 'How is the crop doing after treatment?');

  String get statusImproved => language == AppLanguage.marathi
      ? 'सुधारणा झाली (Improved)'
      : (language == AppLanguage.hindi ? 'सुधार हुआ (Improved)' : 'Improved');

  String get statusNoChange => language == AppLanguage.marathi
      ? 'बदल नाही (No Change)'
      : (language == AppLanguage.hindi ? 'कोई बदलाव नहीं (No Change)' : 'No Change');

  String get statusGotWorse => language == AppLanguage.marathi
      ? 'अधिक बिघडले (Got Worse)'
      : (language == AppLanguage.hindi ? 'और बिगड़ गया (Got Worse)' : 'Got Worse');

  String get followupSuccessMessage => language == AppLanguage.marathi
      ? 'फॉलो-अप प्रतिसाद जतन केला. शेताची सद्यस्थिती अद्यतनित झाली आहे.'
      : (language == AppLanguage.hindi
          ? 'फॉलो-अप सहेजा गया। खेत की स्थिति अद्यतन की गई है।'
          : 'Follow-up response recorded. Farm health status updated.');

  String get noPendingFollowupsTitle => language == AppLanguage.marathi
      ? 'कोणताही प्रलंबित फॉलो-अप नाही'
      : (language == AppLanguage.hindi ? 'कोई लंबित फॉलो-अप नहीं है' : 'No pending follow-ups');

  String get noPendingFollowupsMessage => language == AppLanguage.marathi
      ? 'सर्व उपचार पडताळणी पूर्ण झाली आहे.'
      : (language == AppLanguage.hindi
          ? 'सभी उपचार सत्यापन पूर्ण हो चुके हैं।'
          : 'All treatment check-ins are up to date.');

  // Step 5: Timeline / History
  String get timelineTitle => language == AppLanguage.marathi
      ? 'पीक इतिहास (Timeline)'
      : (language == AppLanguage.hindi ? 'फसल इतिहास (Timeline)' : 'Crop Timeline & History');

  String get noHistoryTitle => language == AppLanguage.marathi
      ? 'अजून कोणताही इतिहास नाही'
      : (language == AppLanguage.hindi ? 'अभी कोई इतिहास नहीं है' : 'No history yet');

  String get noHistoryMessage => language == AppLanguage.marathi
      ? 'निदान, सतर्कता किंवा उपचारानंतरच्या नोंदी येथे दिसतील.'
      : (language == AppLanguage.hindi
          ? 'निदान, अलर्ट या उपचार की प्रविष्टियां यहाँ दिखेंगी।'
          : 'Diagnoses, alerts, and treatment check-ins will appear here.');

  String get eventDiagnosis => language == AppLanguage.marathi
      ? 'रोग निदान'
      : (language == AppLanguage.hindi ? 'रोग निदान' : 'Diagnosis');

  String get eventObservation => language == AppLanguage.marathi
      ? 'प्रत्यक्ष निरीक्षण'
      : (language == AppLanguage.hindi ? 'खेत निरीक्षण' : 'Field Observation');

  String get eventTreatment => language == AppLanguage.marathi
      ? 'उपाययोजना'
      : (language == AppLanguage.hindi ? 'उपाययोजना' : 'Treatment');

  String get eventAlert => language == AppLanguage.marathi
      ? 'हवामान सतर्कता'
      : (language == AppLanguage.hindi ? 'मौसम अलर्ट' : 'Weather Alert');

  String get eventFollowup => language == AppLanguage.marathi
      ? 'फॉलो-अप तपासणी'
      : (language == AppLanguage.hindi ? 'फॉलो-अप जाँच' : 'Follow-up Check');

  // Step 5: Problem Detail
  String get problemDetailTitle => language == AppLanguage.marathi
      ? 'समस्या सविस्तर माहिती'
      : (language == AppLanguage.hindi ? 'समस्या का विवरण' : 'Problem Details');

  String get statusOpen => language == AppLanguage.marathi
      ? 'सक्रिय (Open)'
      : (language == AppLanguage.hindi ? 'सक्रिय (Open)' : 'Open');

  String get statusResolved => language == AppLanguage.marathi
      ? 'निवारण झाले (Resolved)'
      : (language == AppLanguage.hindi ? 'समाधान हुआ (Resolved)' : 'Resolved');

  String get openedOnLabel => language == AppLanguage.marathi
      ? 'नोंदणी दिनांक'
      : (language == AppLanguage.hindi ? 'दर्ज करने की तिथि' : 'Opened On');

  String get resolvedOnLabel => language == AppLanguage.marathi
      ? 'निवारण दिनांक'
      : (language == AppLanguage.hindi ? 'समाधान तिथि' : 'Resolved On');

  String get observationsHeader => language == AppLanguage.marathi
      ? 'नोंदवलेली लक्षणे व निरीक्षणे'
      : (language == AppLanguage.hindi ? 'दर्ज लक्षण और अवलोकन' : 'Field Observations');

  // Step 5: Referrals
  String get referralsTitle => language == AppLanguage.marathi
      ? 'कृषी मदत व संपर्क केंद्र'
      : (language == AppLanguage.hindi ? 'कृषि सहायता एवं संपर्क केंद्र' : 'KVK & Agricultural Helpline');

  String get kvkHeader => language == AppLanguage.marathi
      ? 'स्थानिक कृषी विज्ञान केंद्र (KVK)'
      : (language == AppLanguage.hindi ? 'स्थानीय कृषि विज्ञान केंद्र (KVK)' : 'Krishi Vigyan Kendra (KVK)');

  String get helplineHeader => language == AppLanguage.marathi
      ? 'शासकीय किसान कॉल सेंटर'
      : (language == AppLanguage.hindi ? 'सरकारी किसान कॉल सेंटर' : 'Kisan Call Center');

  String get callButton => language == AppLanguage.marathi
      ? 'कॉल करा'
      : (language == AppLanguage.hindi ? 'कॉल करें' : 'Call');

  String get noReferralsTitle => language == AppLanguage.marathi
      ? 'संपर्क माहिती उपलब्ध नाही'
      : (language == AppLanguage.hindi ? 'संपर्क जानकारी उपलब्ध नहीं है' : 'No referrals available');

  String get noReferralsMessage => language == AppLanguage.marathi
      ? 'स्थानिक कृषी संपर्क माहिती लवकरच अद्यतनित केली जाईल.'
      : (language == AppLanguage.hindi
          ? 'स्थानीय कृषि संपर्क विवरण जल्द ही उपलब्ध होगा।'
          : 'Local referral centers will appear once registered for your region.');

  // =========================================================================
  // STEP 6: VOICE-FIRST, CONNECTIVITY RESILIENCE & ACCESSIBILITY STRINGS
  // =========================================================================

  // Voice Interaction System
  String get greetingPartnerSubtitle => language == AppLanguage.marathi
      ? 'तुमचा शेतकरी साथी'
      : (language == AppLanguage.hindi ? 'आपका किसान साथी' : 'Your Farming Companion');

  String get voiceHeroTitle => language == AppLanguage.marathi
      ? 'बोलून विचारा'
      : (language == AppLanguage.hindi ? 'बोलकर पूछें' : 'Ask Bhoomi');

  String get voiceHeroSubtitle => language == AppLanguage.marathi
      ? 'तुमच्या पिकाबद्दल विचारा'
      : (language == AppLanguage.hindi ? 'अपनी फसल के बारे में पूछें' : 'Ask about your crop');

  String get voiceHeroSubtitleFull => language == AppLanguage.marathi
      ? 'तुमच्या पिकाबद्दल काहीही विचारा'
      : (language == AppLanguage.hindi ? 'अपनी फसल के बारे में कुछ भी पूछें' : 'Ask anything about your crop');

  String get voiceHeroCta => language == AppLanguage.marathi
      ? 'बोलायला सुरुवात करा'
      : (language == AppLanguage.hindi ? 'बोलना शुरू करें' : 'Start Speaking');

  String get checkCropCardSubtitle => language == AppLanguage.marathi
      ? 'फोटो काढून पिकाची समस्या जाणून घ्या'
      : (language == AppLanguage.hindi ? 'फोटो खींचकर फसल की समस्या जानें' : 'Take a photo to identify crop issues');

  String get checkCropCardCta => language == AppLanguage.marathi
      ? 'तपासणी करा →'
      : (language == AppLanguage.hindi ? 'जांच करें →' : 'Check Crop →');

  String get voiceHeroBadge => language == AppLanguage.marathi
      ? 'आवाज सहाय्यक'
      : (language == AppLanguage.hindi ? 'आवाज़ सहायक' : 'Voice Assistant');

  String get voiceTapToSpeak => language == AppLanguage.marathi
      ? 'बोलण्यासाठी टॅप करा'
      : (language == AppLanguage.hindi ? 'बोलने के लिए टैप करें' : 'Tap to speak');

  String get voiceContextDiagnosis => language == AppLanguage.marathi
      ? 'या समस्येबद्दल विचारा'
      : (language == AppLanguage.hindi ? 'इस समस्या के बारे में पूछें' : 'Ask about this problem');

  String get voiceContextAlert => language == AppLanguage.marathi
      ? 'हा इशारा का आला?'
      : (language == AppLanguage.hindi ? 'यह चेतावनी क्यों आई?' : 'Why did I get this alert?');

  String get voiceContextAlertWhy => voiceContextAlert;

  String get voiceContextAdvisoryExplain => language == AppLanguage.marathi
      ? 'मला समजावून सांगा'
      : (language == AppLanguage.hindi ? 'मुझे समझाइए' : 'Explain this to me');

  String get voiceContextAdvisoryAsk => language == AppLanguage.marathi
      ? 'आणखी काही विचारा'
      : (language == AppLanguage.hindi ? 'और पूछें' : 'Ask another question');

  String get voiceContextFollowupTell => language == AppLanguage.marathi
      ? 'बोलून सांगा'
      : (language == AppLanguage.hindi ? 'बोलकर बताएं' : 'Tell Bhoomi');

  String get voiceContextFollowupPrompt => language == AppLanguage.marathi
      ? 'पिकाची स्थिती आता कशी आहे?'
      : (language == AppLanguage.hindi ? 'फसल की स्थिति अब कैसी है?' : 'How is the crop condition now?');

  String get voiceContextHistoryListen => language == AppLanguage.marathi
      ? 'पुन्हा ऐका'
      : (language == AppLanguage.hindi ? 'दोबारा सुनें' : 'Listen again');

  String get voiceContextHistoryAsk => language == AppLanguage.marathi
      ? 'या तपासणीबद्दल विचारा'
      : (language == AppLanguage.hindi ? 'इस जांच के बारे में पूछें' : 'Ask about this check');

  String get voiceAboutContextPrefix => language == AppLanguage.marathi
      ? 'विषय'
      : (language == AppLanguage.hindi ? 'विषय' : 'Topic');

  String get voiceListeningPrompt => language == AppLanguage.marathi
      ? 'ऐकत आहे... बोला'
      : (language == AppLanguage.hindi ? 'सुन रहे हैं... बोलिए' : 'Listening... Speak now');

  String get voiceProcessingPrompt => language == AppLanguage.marathi
      ? 'तुमचा प्रश्न समजून घेत आहोत...'
      : (language == AppLanguage.hindi
          ? 'आपके प्रश्न को समझ रहे हैं...'
          : 'Understanding your question...');

  String get voiceProcessingSubtitle => language == AppLanguage.marathi
      ? 'कृपया थोडा वेळ थांबा...'
      : (language == AppLanguage.hindi
          ? 'कृपया प्रतीक्षा करें...'
          : 'Please wait, preparing advice...');

  String get voiceResultTitle => language == AppLanguage.marathi
      ? 'तुमचा प्रश्न'
      : (language == AppLanguage.hindi ? 'आपका प्रश्न' : 'Your Question');

  String get voiceStopListening => language == AppLanguage.marathi
      ? 'थांबवा'
      : (language == AppLanguage.hindi ? 'रोकें' : 'Stop');

  String get voiceRetry => language == AppLanguage.marathi
      ? 'पुन्हा बोला'
      : (language == AppLanguage.hindi ? 'फिर से बोलें' : 'Speak Again');

  String get voiceSubmit => language == AppLanguage.marathi
      ? 'विचारणा करा'
      : (language == AppLanguage.hindi ? 'पूछें' : 'Submit Query');

  String get voicePlayingAudio => language == AppLanguage.marathi
      ? 'सल्ला ऐकत आहात'
      : (language == AppLanguage.hindi ? 'सलाह सुन रहे हैं' : 'Playing Advice');

  String get listenSpokenSummary => language == AppLanguage.marathi
      ? 'सल्ला ऐका (Listen)'
      : (language == AppLanguage.hindi ? 'सलाह सुनें (Listen)' : 'Listen to Advice');

  String get pauseSpokenSummary => language == AppLanguage.marathi
      ? 'थांबवा (Pause)'
      : (language == AppLanguage.hindi ? 'रोकें (Pause)' : 'Pause Audio');

  String get replaySpokenSummary => language == AppLanguage.marathi
      ? 'पुन्हा ऐका (Replay)'
      : (language == AppLanguage.hindi ? 'दोबारा सुनें (Replay)' : 'Replay Audio');

  // Phase 2 Core Voice Experience Strings
  String get voiceBhoomiAnswer => language == AppLanguage.marathi
      ? 'Bhoomi चे उत्तर'
      : (language == AppLanguage.hindi ? 'Bhoomi का जवाब' : "Bhoomi's Answer");

  String get voiceAskAgain => language == AppLanguage.marathi
      ? 'आणखी विचारा'
      : (language == AppLanguage.hindi ? 'और पूछें' : 'Ask Another Question');

  String get voiceSpeakInYourLanguage => language == AppLanguage.marathi
      ? 'तुमच्या भाषेत बोला'
      : (language == AppLanguage.hindi ? 'अपनी भाषा में बोलें' : 'Speak in your language');

  String get voiceErrorNotUnderstood => language == AppLanguage.marathi
      ? 'आवाज समजला नाही'
      : (language == AppLanguage.hindi ? 'आवाज़ समझ नहीं आई' : 'Could not understand speech');

  String get voiceErrorNotUnderstoodDesc => language == AppLanguage.marathi
      ? 'कृपया थोडे हळू आणि स्पष्ट बोलून पुन्हा प्रयत्न करा.'
      : (language == AppLanguage.hindi
          ? 'कृपया थोड़ा धीरे और स्पष्ट बोलकर दोबारा प्रयास करें।'
          : 'Please speak slowly and clearly, and try again.');

  String get voiceTypeFallback => language == AppLanguage.marathi
      ? 'टाइप करा'
      : (language == AppLanguage.hindi ? 'टाइप करें' : 'Type instead');

  String get voicePermissionTitle => language == AppLanguage.marathi
      ? 'मायक्रोफोनची परवानगी आवश्यक आहे'
      : (language == AppLanguage.hindi ? 'माइक्रोफ़ोन की अनुमति चाहिए' : 'Microphone Permission Required');

  String get voicePermissionDesc => language == AppLanguage.marathi
      ? 'Bhoomi ला तुमचा आवाज ऐकण्यासाठी मायक्रोफोनची परवानगी आवश्यक आहे.'
      : (language == AppLanguage.hindi
          ? 'Bhoomi को आपकी आवाज़ सुनने के लिए माइक्रोफ़ोन की अनुमति चाहिए।'
          : 'Bhoomi needs microphone permission to listen to your question.');

  String get voiceGrantPermission => language == AppLanguage.marathi
      ? 'परवानगी द्या'
      : (language == AppLanguage.hindi ? 'अनुमति दें' : 'Grant Permission');

  String get voiceOpenSettings => language == AppLanguage.marathi
      ? 'सेटिंग्ज उघडा'
      : (language == AppLanguage.hindi ? 'सेटिंग्स खोलें' : 'Open Settings');

  String get voiceServiceUnavailable => language == AppLanguage.marathi
      ? 'आत्ता आवाजाची सेवा उपलब्ध नाही.'
      : (language == AppLanguage.hindi ? 'अभी आवाज़ सेवा उपलब्ध नहीं है।' : 'Voice service is currently unavailable.');

  String get voiceServiceUnavailableDesc => language == AppLanguage.marathi
      ? 'कृपया पुन्हा प्रयत्न करा.'
      : (language == AppLanguage.hindi ? 'कृपया दोबारा प्रयास करें।' : 'Please try again.');

  String get voiceListenAnswer => language == AppLanguage.marathi
      ? 'उत्तर ऐका'
      : (language == AppLanguage.hindi ? 'जवाब सुनें' : 'Listen to Answer');

  String get voicePauseAnswer => language == AppLanguage.marathi
      ? 'ऐकणे थांबवा'
      : (language == AppLanguage.hindi ? 'सुनना रोकें' : 'Pause Audio');

  String get voiceReplayAnswer => language == AppLanguage.marathi
      ? 'पुन्हा ऐका'
      : (language == AppLanguage.hindi ? 'दोबारा सुनें' : 'Listen Again');

  String get voiceEditQuestion => language == AppLanguage.marathi
      ? 'प्रश्न बदला'
      : (language == AppLanguage.hindi ? 'सवाल बदलें' : 'Edit Question');

  String get voiceDefaultAnswer => language == AppLanguage.marathi
      ? 'पिकावर करप्याची किंवा बुरशीची लक्षणे असू शकतात. नत्रयुक्त खतांचा अतिवापर टाळा, शेतातून पाण्याचा निचरा करा आणि ट्रायकोग्रामा किंवा सेंद्रिय उपायांचा वापर करा.'
      : (language == AppLanguage.hindi
          ? 'फसल पर झुलसा या फफूंद के लक्षण हो सकते हैं। नाइट्रोजन का अत्यधिक उपयोग न करें, जल निकासी करें और जैविक उपायों का उपयोग करें।'
          : 'Crop may have blast or fungal symptoms. Avoid excess nitrogen fertilizer, ensure field drainage, and use organic IPM measures.');

  // Low Connectivity & Upload Failure Resilience
  String get presignFailedTitle => language == AppLanguage.marathi
      ? 'सर्व्हरशी संपर्क होऊ शकला नाही'
      : (language == AppLanguage.hindi
          ? 'सर्वर से संपर्क नहीं हो सका'
          : 'Could not connect to server');

  String get presignFailedDesc => language == AppLanguage.marathi
      ? 'इंटरनेट कनेक्शन धीमे आहे किंवा बंद आहे. कृपया नेटवर्क तपासा.'
      : (language == AppLanguage.hindi
          ? 'इंटरनेट धीमा है या बंद है। कृपया नेटवर्क जांचें।'
          : 'Connection is slow or offline. Please check your network.');

  String get uploadFailedTitle => language == AppLanguage.marathi
      ? 'फोटो अपलोड अयशस्वी झाला'
      : (language == AppLanguage.hindi ? 'तस्वीर अपलोड नहीं हो सकी' : 'Photo upload failed');

  String get uploadFailedDesc => language == AppLanguage.marathi
      ? 'तुमचा फोटो सुरक्षित आहे. इंटरनेट जोडणी तपासून पुन्हा पाठवा.'
      : (language == AppLanguage.hindi
          ? 'आपकी तस्वीर सुरक्षित है। इंटरनेट जांचकर पुनः भेजें।'
          : 'Your photo is safe. Check your connection and try again.');

  String get diagnosisTimeoutTitle => language == AppLanguage.marathi
      ? 'निदान प्रक्रियेस वेळ लागत आहे'
      : (language == AppLanguage.hindi
          ? 'निदान में अधिक समय लग रहा है'
          : 'Diagnosis is taking longer than usual');

  String get diagnosisTimeoutDesc => language == AppLanguage.marathi
      ? 'नेटवर्क धीमे असल्याने वेळ लागत आहे. कृपया पुन्हा प्रयत्न करा.'
      : (language == AppLanguage.hindi
          ? 'धीमे नेटवर्क के कारण समय लग रहा है। कृपया पुनः प्रयास करें।'
          : 'Slow network detected. Please retry or check your connection.');

  String get retryAction => language == AppLanguage.marathi
      ? 'पुन्हा प्रयत्न करा'
      : (language == AppLanguage.hindi ? 'पुनः प्रयास करें' : 'Retry');

  String get changePhotoAction => language == AppLanguage.marathi
      ? 'दुसरा फोटो निवडा'
      : (language == AppLanguage.hindi ? 'दूसरी तस्वीर चुनें' : 'Choose Another Photo');

  // Accessibility Semantics
  String get semanticsCapturePhoto => language == AppLanguage.marathi
      ? 'कॅमेराने पिकाचा फोटो काढा'
      : (language == AppLanguage.hindi ? 'कैमरे से फसल की फोटो लें' : 'Capture crop photo with camera');

  String get semanticsToggleFlash => language == AppLanguage.marathi
      ? 'कॅमेरा फ्लॅश चालू किंवा बंद करा'
      : (language == AppLanguage.hindi ? 'फ़्लैश चालू या बंद करें' : 'Toggle camera flash');

  String get semanticsVoiceMic => language == AppLanguage.marathi
      ? 'आवाजाने प्रश्न विचारा'
      : (language == AppLanguage.hindi ? 'बोलकर प्रश्न पूछें' : 'Ask question by voice');

  String get semanticsPlayAudio => language == AppLanguage.marathi
      ? 'सल्ला आवाजात ऐका'
      : (language == AppLanguage.hindi ? 'सलाह आवाज़ में सुनें' : 'Listen to spoken advice');

  String get semanticsStopAudio => language == AppLanguage.marathi
      ? 'आवाज थांबवा'
      : (language == AppLanguage.hindi ? 'आवाज़ रोकें' : 'Stop audio playback');

  // Farm Health Card Pure Localized Strings
  String get fieldHealthStatusTitle => language == AppLanguage.marathi
      ? 'शेतातील पिकाची स्थिती'
      : (language == AppLanguage.hindi ? 'खेत की फसल की स्थिति' : 'FIELD HEALTH STATUS');

  String get trendImproving => language == AppLanguage.marathi
      ? 'सुधारणा'
      : (language == AppLanguage.hindi ? 'सुधार' : 'Improving');

  String get trendNeedsAttention => language == AppLanguage.marathi
      ? 'लक्ष द्या'
      : (language == AppLanguage.hindi ? 'ध्यान दें' : 'Needs attention');

  String get trendStable => language == AppLanguage.marathi
      ? 'स्थिर'
      : (language == AppLanguage.hindi ? 'स्थिर' : 'Stable');

  String get statusIssuesLabel => language == AppLanguage.marathi
      ? 'समस्या'
      : (language == AppLanguage.hindi ? 'समस्याएं' : 'Issues');

  String get statusFollowupLabel => language == AppLanguage.marathi
      ? 'तपासणी'
      : (language == AppLanguage.hindi ? 'जांच' : 'Follow-up');

  String get statusAlertsLabel => language == AppLanguage.marathi
      ? 'सूचना'
      : (language == AppLanguage.hindi ? 'सूचनाएं' : 'Alerts');

  String get statusAllClearLabel => language == AppLanguage.marathi
      ? 'पीक सुरक्षित आहे'
      : (language == AppLanguage.hindi ? 'फसल सुरक्षित है' : 'Crop is Safe');

  String get defaultFarmName => language == AppLanguage.marathi
      ? 'माझे भाताचे शेत'
      : (language == AppLanguage.hindi ? 'मेरा धान का खेत' : 'My Paddy Field');
}


