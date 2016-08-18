require 'rubygems'
require 'bundler/setup'
Bundler.require

Twilio.connect(ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN'])
TWILIO_NUM = ENV['TWILIO_NUM']


class Launch

  def initialize launch_data
    @launch_data = launch_data
  end

  def rocket
    rocket = @launch_data['rocket']
    rocket['name']
  end

  def mission
    missions = @launch_data['missions']
    missions.map{|mission| mission['name']}.join ', '
  end

  def day
    windowstart.strftime('%d').to_i
  end

  def month
    windowstart.strftime '%B'
  end

  def year
    windowstart.strftime('%Y').to_i
  end

  def localtime
    local_time = windowstart.localtime
    local_time.strftime '%l:%M %p'
  end


  def windowstart
    Time.parse @launch_data['windowstart']
  end

  def location
    location = @launch_data['location']
    location['name']
  end

  def this_hour?
    hours_away <= 1
  end

  def today?
    days_away <= 1
  end

  def this_week?
    weeks_away <= 1
  end

  def weeks_away
    days_away / 7.0
  end

  def days_away
    hours_away / 24.0
  end

  def hours_away
    minutes_away / 60.0
  end

  def minutes_away
    seconds_away / 60.0
  end

  def seconds_away
    windowstart - Time.now
  end

  def has_launched?
    seconds_away < 0
  end

  def local?
    location.downcase.include? 'cape canaveral'
  end

end

class LaunchSchedule

  def self.next_local_launches
    response = HTTParty.get 'https://launchlibrary.net/1.1/launch/next/5'
    launches = response['launches']
    launches.map{|launch_data| Launch.new(launch_data)}
            .select{|launch| launch.local?}
            .reject{|launch| launch.has_launched?}
  end

  def self.notification type
    launches = next_local_launches.select{|launch| launch.send("#{type}?")}
    return if (count = launches.size) == 0
    message = "There #{count > 1 ? "are #{count} launches" : 'is a launch'} #{type}!\n" + message(launches)
    File.read('numbers.txt')
        .split(' ')
        .each{|number| puts Twilio::Sms.message(TWILIO_NUM, number, message)}
  end

  def self.message launches
    launches.map { |launch|
      "#{launch.rocket} - #{launch.mission}\n"\
      "#{launch.month} #{launch.day}, #{launch.localtime}"
    }.join("\n")
  end

end

days = 0

while true
  LaunchSchedule.notification :today
  LaunchSchedule.notification :this_week if days == 6
  sleep 86400
  days = days + 1 % 7
end















