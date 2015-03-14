# This module is meant for translating function calls made in Trident Template.
# This module will be dynamically included in the Document class at processing runtime
module OutputXml::OrbTestFacilityCorrTemplateVariableTranslations
def processing_date
 @check=@checks.first
 @batch=@check.job.batch
 return @batch.date
end


end

