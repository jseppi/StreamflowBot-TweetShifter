

class USGSServices

	def self.get_nwis_iv_response(site_code)

	    param_codes = "00060,00065" #discharge (cfs), gage height (feet)

	    iv_uri = URI::HTTP.build(
	      :host => "waterservices.usgs.gov",
	      :path => '/nwis/iv/',
	      :query => { 
	        :format => "json",
	        :sites => site_code,
	        :parameterCd => param_codes
	      }.map{|k,v| "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}"}.join("&"))

	    begin
	      data = Net::HTTP.get_response(iv_uri).body
	      j = JSON.parse(data)

	      if not j['value'].key?('timeSeries')
	      	return "NOT_FOUND"
	      end

	      sitename = j['value']['timeSeries'][0]\
	            ['sourceInfo']['siteName']

	      lat = j['value']['timeSeries'][0]\
	          ['sourceInfo']['geoLocation']['geogLocation']['latitude']

	      lon = j['value']['timeSeries'][0]\
	          ['sourceInfo']['geoLocation']['geogLocation']['longitude']

	      #loop through timeSeries list
	      discharge = timestamp = gage_height =  nil

	      j['value']['timeSeries'].each do |item|
	      	if item['variable']['variableCode'][0]['value'] == "00060"
	      	  discharge = item['values'][0]['value'][0]['value']
	      	elsif item['variable']['variableCode'][0]['value'] == "00065"
	      	  gage_height = item['values'][0]['value'][0]['value']
	      	  timestamp = item['values'][0]['value'][0]['dateTime']
	      	end
	      end

	      return {
	        :sitename => sitename, 
	        :lat => lat,
	        :lon => lon,
	        :discharge => discharge, 
	        :gage_height => gage_height, 
	        :timestamp => timestamp
	      }

	    rescue
	       return nil
	    end
  end

end
