class EditSiteCodesNavicureFacilities < ActiveRecord::Migration
  def up
     
    navicure  = Client.find_by_name("Navicure")
    ofa = Facility.find_by_name("ORTHOPAEDIC FOOT AND ANKLE CTR")
    sso = Facility.find_by_name("SAVANNAH SURGICAL ONCOLOGY")
    chh = Facility.find_by_name("CHATHAM HOSPITALISTS")
    gea = Facility.find_by_name("GEORGIA EAR ASSOCIATES")

    if (navicure && ofa)
      ofa.sitecode = 'wbRB083H'        
      p "Updated sitecode for OFA" if (ofa.save!)       
    end
    if (navicure && sso)
      sso.sitecode = 'wZR9083H'
      p "Updates sitecode for SSO" if (sso.save!)
    end
    if (navicure && chh)
      chh.sitecode = 'n55Q078S' 
      p "Updates sitecode for CHH" if (chh.save!)
    end
    if (navicure && gea)
      gea.sitecode = 'bCNY071Y' 
      p "Updates sitecode for GEA" if (gea.save!)
    end

  end

  def down
  end
end
