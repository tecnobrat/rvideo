$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'rvideo/inspector'
require 'rvideo/tools/abstract_tool'
require 'rvideo/tools/ffmpeg'
require 'rvideo/tools/flvtool2'
require 'rvideo/errors'
require 'rvideo/transcoder'
require 'yaml'
require 'rubygems'
require 'active_support'

TEMP_PATH = File.expand_path(File.dirname(__FILE__) + '/../tmp')
FIXTURE_PATH = File.expand_path(File.dirname(__FILE__) + '/../spec/fixtures')
TEST_FILE_PATH = File.expand_path(File.dirname(__FILE__) + '/../spec/files')
REPORT_PATH = File.expand_path(File.dirname(__FILE__) + '/../report')
