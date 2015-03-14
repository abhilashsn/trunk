 module Paperclip
   module Interpolations
     def id_partition attachment, style_name
       instance_id = attachment.instance.id || 0
       ("%08d" % instance_id).scan(/\d{4}/).join("/")
     end
     
     def style attachment, style_name
       if style_name == :original || style_name.blank?
         ""
       else
         "_" + style_name.to_s
       end       
     end
   end
 end


