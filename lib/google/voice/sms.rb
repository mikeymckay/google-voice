# coding: UTF-8
require File.join(File.expand_path(File.dirname(__FILE__)), 'base')

module Google
  module Voice      
    class Sms < Base    
      def sms(number, text)
        @curb.http_post([ 
          Curl::PostField.content('phoneNumber', number),
          Curl::PostField.content('text', text),
          Curl::PostField.content('_rnr_se', @_rnr_se) 
        ])
        @curb.url = "https://www.google.com/voice/sms/send"        
        @curb.perform
        @curb.response_code
      end
      
      def recent
        @curb.url = "https://www.google.com/voice/inbox/recent/"        
        @curb.http_get
        doc = Nokogiri::XML::Document.parse(@curb.body_str)
        data = doc.xpath('/response/json').first.text
        html = Nokogiri::HTML::DocumentFragment.parse(doc.to_html)
        json = JSON.parse(data)        
        # Format for messages is [id, {attributes}]
        json['messages'].map do |conversation|
          next unless conversation[1]['labels'].include? "sms"
          html.css("##{conversation[0]} div.gc-message-sms-row").map do |row|
            next if row.css('span.gc-message-sms-from').inner_html.strip! =~ /Me:/
            text = row.css('span.gc-message-sms-text').inner_html
            time = row.css('span.gc-message-sms-time').inner_html
            from = conversation[1]['phoneNumber']
            {
              :id => Digest::SHA1.hexdigest(conversation[0]+text+from),
              :text => text,
              :time => time,
              :from => from
            }
          end
        end.flatten.compact
      end      
    end
  end
end
