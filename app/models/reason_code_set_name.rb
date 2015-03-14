class ReasonCodeSetName < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  has_many :payers
  has_many :reason_codes
  has_many :error_popups, :dependent => :destroy

  # A predicate method which check if the associated payer (if any) is a footnote payer or not.
  # Output :
  # true : if footnote payer
  # false : if payer does not exists OR (if payer exists AND not a footnote payer)
  def is_footnote?
    payer = Payer.find_by_reason_code_set_name_id(id, :select => ['footnote_indicator'])
    if !payer.blank? && !payer.footnote_indicator.blank?
      is_footnote = payer.footnote_indicator
    end
    is_footnote || false
  end


  def switch_rcs_to_new_set_and_destroy(new_rc_set_name, payer_id)
    old_rc_set_name = self
    set_name_has_only_one_payer_which_is_current_payer = payers.length == 1 && payers.first.id == payer_id

    if set_name_has_only_one_payer_which_is_current_payer
      logger.info "old_rc_set_name.reason_codes : #{old_rc_set_name.reason_codes.inspect}"
      new_rc_set_name.reason_codes << old_rc_set_name.reason_codes
      logger.info "new_rc_set_name.reason_codes : #{new_rc_set_name.reason_codes.inspect}"
      success = new_rc_set_name.save
      if success
        old_rc_set_name.reload #this object's associations have been changed, so reload to avoid working on a stale object
        no_dependents = old_rc_set_name.reason_codes.blank?
        if no_dependents
          success &&= old_rc_set_name.destroy
          logger.info "destroyed old_rc_set_name? : #{!success.nil?}"
        else
          logger.info "dependents still present, hence cannot destroy old_rc_set_name"
          success = false
        end
      end
    else
      success = true
    end
  end
end
