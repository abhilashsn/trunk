var grid;
Ext.onReady(function(){
    Ext.QuickTips.init();
    var store = new Ext.data.JsonStore({
        root: 'Claims',
        totalProperty: 'Total',
        remoteSort: false,
        fields: [
        'a_no','pat_name', 'm_name', 'claim_from_date', 'claim_to_date', 's_charges', 'no_of_services','c_type','pay_name', 'c_fname', 'c_file_arrival_date'
        ],
        proxy: new Ext.data.HttpProxy({
            url: 'ret_search'
        })
		
    });
    var pagingBar = new Ext.PagingToolbar({
        pageSize: 30,
        store: store,
        displayInfo: true,
        displayMsg: 'Displaying records {0} - {1} of {1}',
        emptyMsg: "No records found"      
    });
 
    screen_height = document.viewport.getDimensions().height;
    screen_height = (screen_height<600)? 520 : screen_height - 150;
    screen_width = document.viewport.getDimensions().width
    screen_width = (screen_width<500)? 440 : screen_width - (screen_width*0.25);
    var columnModel = new Ext.grid.ColumnModel([
    {
        header: "Account Number",
        dataIndex: "a_no",
        width: 80,
        menuDisabled: true
    },

    {
        header: "Patient Name",
        dataIndex: "pat_name",
        width: 80,
        menuDisabled: true
    },



    {
        header: "Member Name",
        dataIndex: "m_name",
        width: 80,
        menuDisabled: true
    },

    {
        header: "Claim From Date",
        dataIndex: "claim_from_date",
        width: 80,
        menuDisabled: true
    },

    {
        header: "Claim To Date",
        dataIndex: "claim_to_date",
        width: 80,
        menuDisabled: true
    },
    {
        header: "Submitted Charges",
        dataIndex: "s_charges",
        width: 80,
        menuDisabled: true
    },

    {
        header: "Number of Services",
        dataIndex: "no_of_services",
        width: 80,
        menuDisabled: true
    },

    {
        header: "Claim Type",
        dataIndex: "c_type",
        width: 60,
        menuDisabled: true
    },

    {
        header: "Payer Name",
        dataIndex: "pay_name",
        width: 65,
        menuDisabled: true
    },
    {
        header: "Claim Filename",
        dataIndex: "c_fname",
        width: 65,
        menuDisabled: true
    },
    {
        header: "Claim File Arrival Date",
        dataIndex: "c_file_arrival_date",
        width: 80,
        menuDisabled: true
    }
    ]);
  	  	   	  
    grid = new Ext.grid.GridPanel({
        el:'claim-grid',
        width: screen_width,
        height: screen_height,
        store: store,
        frame: true,
        title: "Claim Retrieval",
        trackMouseOver:true,
        disableSelection:false,
        loadMask: true,
        cm: columnModel,
        view: new Ext.grid.GridView({
            forceFit:true,
            enableRowBody:true,
            showPreview:false	
        }),
        bbar: pagingBar
    });


    grid.render();

    store.on('beforeload', function(obj,options) {
        e_data = Ext.Ajax.serializeForm('e_options');
        store.baseParams = Ext.urlDecode(e_data);
    });
    store.on('load', function() {
        pagingBar.updateInfo();
    });

    store.load({
        params:{
            start:0,
            limit:30
        }
    });
});

function resize_grid()
{
    screen_width = document.viewport.getDimensions().width;
    screen_width =  (screen_width<500)? 440 : screen_width - (screen_width*0.25);
    screen_height = document.viewport.getDimensions().height;
    screen_height = (screen_height<600)? 520 : screen_height - 150;
    grid.setWidth(screen_width);
    grid.setHeight(screen_height);
}

window.onresize = resize_grid; 


function setFilterFlag(){
    $('filter_flag').value = 1;
    grid.store.load({
        params:{
            start:0
        }
    });
}

//Service Information Popup
function svcPopup(url){
    window.open(url,"popup","width=600,height=400,scrollbars=1");
}
