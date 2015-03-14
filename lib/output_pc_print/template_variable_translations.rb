module OutputPcPrint::TemplateVariableTranslations
  def fpe_date
    # last_day_of_current_year
    "12/31/#{Time.now.strftime('%Y')}"
  end

  def paid_date
    check.check_date.strftime('%m/%d/%y') # '04/21/09'
  end

  def reported_amount
    sprintf("%.2f", eob.claim_adjustment_charges.to_f)# '192.50'
  end

  def ncvd_denied_amount
    sprintf("%.2f", eob.claim_adjustment_non_covered.to_f)# CLAIM NON-COVERED AND/OR DENIED CHARGES (2-020-CAS OR 2-090-CAS (Any claim and or line level adjustment codes except the following A2, 1, 2, 42, 45, 66, 70, 71, 89, 94, 118, 122))
  end

  def claim_adjs
    sprintf("%.2f", eob.claim_adjustment_contractual_amount.to_f) # CLAIM LEVEL ADJUSTMENTS (2-020-CAS (ADJ 42, 45, 94, 97) (70 Outpatient only))
  end

  def covered
    dont_have # CLAIM COVERED CHARGES (2-062-AMT02 CODE AU)
  end

  def cost_rept
    zero # Cost Report Days (2-033-MIA15)
  end

  def covd_util
    zero # Covered Days (2-033-MIA01)
  end

  def non_covered
    zero
  end

  def covd_visits
    zero # LINE COVERED VISITS (2-2110-AMT02 CODE CA)
  end

  def ncov_visits
    zero # LINE NON COVERED VISITS (2-120-QTY02 CODE NE)
  end

  def reim_rate
    dont_have # REIMBURSEMENT RATE (2-035-MOA01)
  end

  def drg_amount
    dont_have # DRG AMOUNT (2-033-MIA04)
  end

  def drg_oper_cap
    dont_have # OPERATING AND CAPITAL DRG (2-033-MIA06 + 8 + 18)
  end

  def line_adj_amt
    sprintf("%.2f", eob.claim_adjustment_co_insurance.to_f) # LINE LEVEL ADJUSTMENTS (2-090-CAS (ADJS 42, 45, 94, 97))
  end

  def outlier
    dont_have # OUTLIER AMOUNT (2-062-AMT02-ZZ (Inpatient Only))
  end

  def cap_outlier
    dont_have # CAPITAL OUTLIER (2-033-MIA17)
  end

  def cash_deduct
    sprintf("%.2f", eob.claim_adjustment_deductable.to_f) # (2-020-CAS (ADJ 1))
  end

  def blood_deduct
    dont_have # BLOOD DEDUCTIBLE AMOUNT (2-020-CAS (ADJ 66))
  end

  def coinsurance
    sprintf("%.2f", eob.claim_adjustment_co_insurance.to_f) # (2-020-CAS (ADJ 2, 122))
  end

  def pat_refund
    dont_have # PATIENT REFUND AMOUNT (2-020-CAS (ADJ A0))
  end

  def msp_liab_met
    dont_have # MSP PAYER LIABILITY MET (2-020-CAS (ADJ A3))
  end

  def msp_prim_payer
    dont_have # MSP PRIMARY PAYER AMT (2-020-CAS (ADJ 71))
  end

  def prof_component
    dont_have # PROFESSIONAL COMPONENT (2-020 or 2-090 CAS (ADJ 89))
  end

  def esrd_amount
    dont_have # CLAIM ESRD REDUCTION (2-035-MOA08)
  end

  def proc_cd_amount
    dont_have # HCPC/PROC/NDC AMT (2-035-MOA02)
  end

  def allow_reim
    sprintf("%.2f", eob.claim_adjustment_payment.to_f) # MEDICARE ALLOWED LINE REIM AMT FOR OUTPATIENT (AMT OR 2-070-SVC03)
  end

  def g_r_amount
    dont_have # GRAMM-RUDMAN AMOUNTS (2-020-CAS (ADJ 43))
  end

  def interest
    sprintf("%.2f", eob.claim_interest.to_f)
  end

  def contractual_adjustment
    sprintf("%.2f", eob.claim_adjustment_contractual_amount.to_f)
  end

  def per_diem_amt
    dont_have # PER DIEM AMOUNT (2-110-AMT02 CODE DY)
  end

  def net_reim_amt
    sprintf("%.2f", eob.claim_adjustment_contractual_amount.to_f) # CLAIM PAYMENT AMOUNT (2-020-CLP04)
  end

  def npi
    facility.facility_npi # not found in guide
  end

  def clm
    eob.claim_number # 1234A5678BC
  end

  def prov_number
   facility.facility_tin
  end

  def tob
    "#{eob.facility_type_code}#{eob.claim_indicator_code}" # TYPE OF BILL (2-010-CLP08, 09)
  end

  def patient
    "#{eob.patient_last_name}, #{eob.patient_first_name} #{eob.patient_middle_initial}" # Might be last, first, middle initial, though sample was '9999999'
  end

  def hic
    eob.patient_identification_code || eob.subscriber_identification_code # HIC NUMBER (2-030-NM109)
  end

  def pcn
    eob.patient_account_number # PATIENT CONTROL NUMBER (2-010-CLP01)
  end

  def svc_from
   eob.claim_from_date
  end

  def svc_thru
    eob.claim_to_date
  end

  def mrn
    ignore # MEDICAL RECORD NUMBER service_provider_control_number? (2-040-REF02 CODE EA)
  end

  def pat_stat
    ignore # PATIENT STATUS (2-010-CLP10)
  end

  def claim_stat
    eob.claim_type_weight.to_s # CLAIM STATUS (2-020-CLP02) one character
  end

  def icn
    eob.claim_number # INTERNAL CONTROL NUMBER (2-010-CLP07)
  end

  def payer
    check.payer.payer
  end

  def facility_name
    facility.name
  end

  def facility_address
    facility.address_one
  end

  def facility_city_state_zip
    "#{facility.city}, #{facility.state} #{facility.zip_code}"
  end

  def reason_codes
    eob.service_payment_eobs.collect{|spe| spe.get_all_reason_codes}.join(', ')
  end
end