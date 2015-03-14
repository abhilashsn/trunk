var grid;
Ext.onReady(function(){
    Ext.QuickTips.init();
    var store = new Ext.data.JsonStore({
        root: 'Eobs',
        totalProperty: 'Total',
        remoteSort: false,
        fields: [
        'uid','claim_from_date', 'a_no', 'l_name', 'f_name', 'v_info', 'c_num','c_amt','b_id'
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
        header: "Unique ID",
        dataIndex: "uid",
        width: 80,
        menuDisabled: true
    },

    {
        header: "Account Number",
        dataIndex: "a_no",
        width: 80,
        menuDisabled: true
    },



    {
        header: "Last Name ",
        dataIndex: "l_name",
        width: 80,
        menuDisabled: true
    },

    {
        header: "First Name",
        dataIndex: "f_name",
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
        header: "Batch Id",
        dataIndex: "b_id",
        width: 60,
        menuDisabled: true
    },

    {
        header: "Check #",
        dataIndex: "c_num",
        width: 60,
        menuDisabled: true
    },

    {
        header: "Check Amount",
        dataIndex: "c_amt",
        width: 60,
        menuDisabled: true
    },

    {
        header: "View Information",
        dataIndex: "v_info",
        width: 78,
        menuDisabled: true
    }
    ]);
  	  	   	  
    grid = new Ext.grid.GridPanel({
        el:'eob-grid',
        width: screen_width,
        height: screen_height,
        store: store,
        frame: true,
        title: "Client Retrieval",
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


