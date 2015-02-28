#module Spree
  #OrdersController.class_eval do
    #def populate_with_parts
      #populate_without_parts
      #binding.pry
    #end
    #alias_method :populate_without_parts, :populate
    #alias_method :populate, :populate_with_parts
  #end
#end
