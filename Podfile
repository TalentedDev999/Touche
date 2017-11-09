platform :ios, '10.0'
use_frameworks!
source 'https://github.com/CocoaPods/Specs'
source 'https://github.com/twilio/cocoapod-specs'

target 'Touche' do
  pod 'MBProgressHUD'

  pod 'SwiftyJSON', :git => 'https://github.com/SwiftyJSON/SwiftyJSON.git'
  pod 'Siren'

  pod 'ImageViewer'

  pod 'AWSCognito'
  pod 'AWSLambda'
  pod 'AWSSNS'
  pod 'AWSS3'
  pod 'AWSMobileAnalytics'

  pod 'TreasureData-iOS-SDK'

  pod 'ImgixSwift', '= 0.3.0'
  pod 'Alamofire'
  pod 'AlamofireImage'

  pod 'JSQWebViewController'

  pod 'Fusuma'

  pod 'Eureka'
  pod 'SDCAlertView'
  pod "PKHUD"

  pod 'Firebase'
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/AdMob'
  pod 'Firebase/Crash'

  pod 'SwiftDate'

  pod 'Emoji-swift'

  pod 'SwiftMessages'

  pod 'PopupDialog'
  pod 'TZStackView'

  pod 'CryptoSwift'

  # pod 'Chatto', '= 3.0.1'
  # pod 'ChattoAdditions', '= 3.0.1'

  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Mapbox-iOS-SDK'

  pod 'AppsFlyerFramework'

  pod 'TagListView'

  pod 'SwiftLocation'
  pod 'SwiftySound'
  pod 'Cupcake'
  pod 'SwiftyTimer'
  pod 'NVActivityIndicatorView'
  pod 'SwiftRandom'
  pod 'LUAutocompleteView'

  pod 'NoChat', '~> 0.3'
  pod 'TwilioChatClient', '~> 0.17'
  pod 'TwilioAccessManager', '~> 0.1.3'
  pod 'HPGrowingTextView'
  pod 'YYText'
  pod 'mopub-ios-sdk'
  pod 'Walker'
  pod 'CircleMenu'
  pod 'Tabby', :git => 'https://github.com/hyperoslo/Tabby.git'
  pod "GTProgressBar"
  pod 'Sparrow/Modules/RequestPermission', :git => 'https://github.com/IvanVorobei/Sparrow.git'
  pod 'ImageSlideshow', '~> 1.3'
  pod "ImageSlideshow/Alamofire"
  pod 'ISHPullUp'
  pod 'Money'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
