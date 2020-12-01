require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "byebug"

puts "EventManager Initialized!"


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    )
    legislators.officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") { |file| file.puts form_letter }
end

def clean_phone_number(phone_number)
  return false if phone_number.length < 10
  return phone_number if phone_number.length == 10
  return phone_number[1..-1] if phone_number.length == 11 && phone_number[0] == "1"
  return false if phone_number.length > 10
end

def log_registration(regdate)
  date_object = DateTime.strptime(regdate, "%m/%d/%y %k:%M")
  $regtimes[date_object.hour] += 1
  $regdays[date_object.wday] += 1
end


contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

$regtimes = Hash.new(0)
$regdays = Hash.new(0)

contents.each do |row|

  id = row[0]
  name = row[:first_name]

  regdate = row[:regdate]

  log_registration(regdate)

  zipcode = row[:zipcode]

  zipcode = clean_zipcode(zipcode)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

end

$regdays = $regdays.sort_by { |k, v| v }
$regtimes = $regtimes.sort_by { |k, v| v }
p $regtimes
p $regdays

