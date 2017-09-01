Pod::Spec.new do |s|
  s.name     = 'QGSocketIO'
  s.version  = '0.1.1'
  s.platform = :ios, '7.0'
  s.license  = 'MIT'
  s.summary  = 'SocketIO client with object-c'
  s.homepage = 'https://github.com/QuanGe/QGSocketIO-objc'
  s.author   = { 'QuanGe' => 'zhang_ru_quan@163.com' }
  s.source   = { :git => 'https://github.com/QuanGe/QGSocketIO-objc.git', :tag => s.version.to_s }

  s.description = 'SocketIO client with object-c ' 
  s.source_files = 'QGSocketIO/*.{h,m}'
  s.requires_arc = true
end
