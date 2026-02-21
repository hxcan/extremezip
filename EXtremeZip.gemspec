Gem::Specification.new do |s|
  s.name = 'EXtremeZip'
  s.version = '2025.1.28'
  s.date = '2025-01-28'
  s.summary = 'EXtremeZip'
  s.description = 'Extreme zip.'
  s.authors = ['Hxcan Cai']
  s.email = 'caihuosheng@gmail.com'
  s.files = ['lib/extremezip.zzaqsv.rb', 'lib/extremeunzip.zzaqsu.rb', 'bin/exz', 'bin/exuz']
  s.homepage = 'http://rubygems.org/gems/EXtremeZip'
  s.license = 'MIT'
  
  s.add_runtime_dependency 'cod', '>= 0.6.0'
  s.add_runtime_dependency 'get_process_mem', '>= 0.2.7'
  s.add_runtime_dependency 'ruby-lzma', '>= 0.4.3'
  s.add_runtime_dependency 'notifier', '>= 0.5.2'
  s.add_runtime_dependency 'uuid', '>= 2.3.9'
  s.add_runtime_dependency 'VictoriaFreSh', '~>2024.9.17', '>= 2024.9.17'
  s.add_runtime_dependency 'hx_cbor', '>= 2021.8.20'
  
  s.executables << 'exz' << 'exuz'
end
