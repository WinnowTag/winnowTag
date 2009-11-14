class ActiveRecord::Errors
  if instance_methods.include?("delete")
    raise "ActiveRecord::Errors already has a #delete method. You may be able to remove this plugin or something is getting loaded twice."
  else
    def delete(attr)
      @errors.delete(attr.to_s)
    end
  end
end
