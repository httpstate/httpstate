# gem install httpstate

require 'httpstate'
require 'time'

HttpState.new('58bff2fcbeb846958f36e7ae5b8a75b0')
  .on('change') { |data| puts Time.now.utc.iso8601 + ' data ' + data }

# Not needed per se, only meant to keep the script alive
loop do
  sleep 1
end
