Pod::Spec.new do |s|
  s.name             = 'liquid_design'
  s.version          = '0.2.1'
  s.summary          = 'iOS 26 Liquid Glass for Flutter widgets.'
  s.description      = <<-DESC
Native iOS 26 / macOS 26 Liquid Glass for any Flutter widget, with
iOS 26 interactions and ready-made components.
                       DESC
  s.homepage         = 'https://github.com/hareerapp/fluter-liquid-glass'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mohammed Al-Jaf' => 'mohammedjjaff@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'liquid_design/Sources/liquid_design/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

end
