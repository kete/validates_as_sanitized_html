require 'hpricot'
# thanks to validates_xml plugin for example code
# add simple sanitizing and valid html validation
module ActiveRecord
  module Validations
    module ClassMethods
      def validates_as_sanitized_html(*attr_names)
        configuration = { :message => ActiveRecord::Errors.default_error_messages[:invalid],
                          :on => :save,
                          :with => nil }
        configuration.update(attr_names.pop) if attr_names.last.is_a?(Hash)
        validates_each(attr_names, configuration) do |record, attr_name, value|
          # allow for turning off sanitization on a record by record basis
          # via virtual attribute on record
          do_not_sanitize = !record.do_not_sanitize.nil? &&
            record.do_not_sanitize.to_s != 'false' &&
            (record.do_not_sanitize.to_s == 'true' || record.do_not_sanitize.to_i == 1) ?  true : false
          unless do_not_sanitize
            # TODO: see if we can reuse sanitization
            # from rail's html/sanitize or helpers/sanitize_helper
            # very simple check for bad elements
            if !value.blank?
              # Catches <form> and <form action="">
              # But leaves things like <format> or <input_date> as valid
              if value =~ /(<form|<script|<input|<iframe)(\s|>)/i
                record.errors.add(attr_name,
                                  ": we aren't currently allowing forms or javascript in submitted HTML for security reasons.")
              else
                # Walter McGinnis, 2008-02-04
                # this is not accurate enough, get false positives
                # new_value = Hpricot(value).to_html
                # record.errors.add(attr_name, ": is not valid html.  It looks like you didn't close all your tags.") if new_value != value
              end
            end
          end
        end
      end
    end
  end
end

