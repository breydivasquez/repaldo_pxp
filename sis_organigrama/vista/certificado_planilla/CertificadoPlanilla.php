<?php
/**
*@package pXP
*@file gen-CertificadoPlanilla.php
*@author  (MMV)
*@date 24-07-2017 14:48:34
*@description Archivo con la interfaz de usuario que permite la ejecucion de todas las funcionalidades del sistema
*/

header("content-type: text/javascript; charset=UTF-8");
?>
<script>
    Phx.vista.CertificadoPlanilla = {
        require: '../../../sis_organigrama/vista/certificado_planilla/Certificado.php',
        requireclase: 'Phx.vista.Certificado',
        title: 'Certificado',
        nombreVista: 'CertificadoPlanilla',
        constructor: function (config) {
		this.tbarItems = ['-',this.cmbGestion,'-'];        	
            this.Atributos.unshift({
                config: {
                    name: 'control',
                    fieldLabel: 'Seleccion',
                    allowBlank: true,
                    anchor: '50%',
                    gwidth: 80,
                    maxLength: 3,
                    renderer: function (value) {
                        var checked = '';
                        if (value == 'si') {
                            checked = 'checked';
                        }
                        return String.format('<div style="vertical-align:middle;text-align:center;"><input style="height:40px;width:40px;" type="checkbox"  {0}></div>', checked);

                    }
                },
                type: 'TextField',
                filters: {pfiltro: 'planc.impreso', type: 'string'},
                id_grupo: 0,
                grid: true,
                form: false
            });
            this.Atributos[this.getIndAtributo('impreso')].grid=false;
            Phx.vista.CertificadoPlanilla.superclass.constructor.call(this, config);
            this.grid.addListener('cellclick', this.oncellclick,this);
            this.store.baseParams={tipo_interfaz:this.nombreVista};
            this.cmbGestion.on('select',this.capturarEventos, this);
            this.store.baseParams.pes_estado = 'borrador';
            var date = new Date();
            this.store.baseParams.gestion = date.getFullYear();
            this.load({params:{start:0, limit:this.tam_pag}});
            this.getBoton('ant_estado').setVisible(false);            
            this.getBoton('btnImprimir').setVisible(false);
            this.getBoton('FirmaDigital').setVisible(false);
            this.finCons = true;
        },
        gruposBarraTareas:[
            {name:'borrador',title:'<H1 align="center"><i class="fa fa-list-ul"></i> Borrador</h1>',grupo:0,height:0},
            {name:'penfirma',title:'<H1 align="center"><i class="fa fa-list-ul"></i> Pendiente Firma</h1>', grupo:1,height:0},
            {name:'emitido',title:'<H1 align="center"><i class="fa fa-list-ul"></i> Emitido</h1>',grupo:2,height:0},
            {name:'anulado',title:'<H1 align="center"><i class="fa fa-list-ul"></i> Anulado</h1>',grupo:3,height:0}
        ],

        actualizarSegunTab: function(name, indice){            
            this.cm.config[1].hidden = true;
            this.cm.config[3].hidden = true;
            if(this.finCons){
                this.store.baseParams.pes_estado = name;
                if(name == 'emitido'){
                    this.cm.config[1].hidden = true;      
                    this.cm.config[3].hidden = false;                    
                    this.getBoton('ant_estado').setVisible(false);                    
                }else if(name == 'penfirma'){
                    this.cm.config[1].hidden = false;
                    this.cm.config[3].hidden = true;                    
                    this.getBoton('ant_estado').setVisible(true);
                }
                else{                    
                    this.getBoton('ant_estado').setVisible(false);
                }
                this.load({params:{start:0, limit:this.tam_pag}});
            }
        },
        beditGroups: [0,2],
        btestGroups: [0,2,3,1],
        bdelGroups:  [0,2],
        bactGroups:  [0,2,3,1],
        bexcelGroups: [0,2,3,1],        
        oncellclick : function(grid, rowIndex, columnIndex, e) {
            var record = this.store.getAt(rowIndex),
                fieldName = grid.getColumnModel().getDataIndex(columnIndex); // Get field name
                this.objRec = record.data;
            if(fieldName == 'control') {
                this.id_document_general = record.data.id_documento_wf;
                this.verifyDoc(record);                
                //this.cambiarRevision(record);                
            }else if(fieldName == 'firma_digital'){    
                this.VisorArchivo(record);            
                //if(record.data.extension != '')                 
            }
        },        
        /* consulta si documento existe en BD */
        verifyDoc: function (rec){
            var id_document = rec.data.id_documento_wf;
            var id_cert_plani = rec.data.id_certificado_planilla;
            Ext.Ajax.request({
                url: '../../sis_organigrama/control/CertificadoPlanilla/consulDocument',
                params:{id_doc: id_document, id_cert_plan:id_cert_plani},
                success:function(resp){
                    var reg = Ext.util.JSON.decode(Ext.util.Format.trim(resp.responseText));
                    if(!reg.ROOT.error){
                        this.reload();
                    }
                },
                //success: this.resulVerify,
                failure: this.conexionFailure,
                timeout: this.timeout,
                scope: this
            })
        },
        /*************************************************************************************
        verificamos si el documento ya fu procesado y almacenado en Bd
        **en caso de no serlo, se procede a generar el documento si este no esta en el
        **sistema de archivos, caso contrario se captura el documento de la ruta de archivos
        **************************************************************************************/
        resulVerify:function (resp){
            
            var reg = Ext.util.JSON.decode(Ext.util.Format.trim(resp.responseText));
            console.log('v',reg);
            if(reg.ROOT.datos.id_doc_pdf == 'void'){
                //this.pdfGeneradoFirm(this.objRec);
            }else{
                this.reload();
            }                        
        },
        cambiarRevision: function(record){            
            var d = record.data;
            Ext.Ajax.request({
                url:'../../sis_organigrama/control/CertificadoPlanilla/controlImpreso',
                params:{ id_certificado_planilla: d.id_certificado_planilla},
                success: this.successRevision,
                failure: this.conexionFailure,
                timeout: this.timeout,
                scope: this
            });            
        },
        successRevision: function(resp){
            Phx.CP.loadingHide();
            var reg = Ext.util.JSON.decode(Ext.util.Format.trim(resp.responseText));
        },
        preparaMenu:function(n){
            var data = this.getSelectedData();
            var tb =this.tbar;
            Phx.vista.CertificadoPlanilla.superclass.preparaMenu.call(this,n);

            if( data['impreso'] ==  'no'){
                this.getBoton('btnImprimir').enable();
                //this. enableTabDetalle();
            }
            return tb;
        },

        liberaMenu:function(){
            var tb = Phx.vista.CertificadoPlanilla.superclass.liberaMenu.call(this);
            if(tb){
                this.getBoton('btnImprimir').disable();
            }
            return tb;
        },

        VisorArchivo : function(rec) {                         
            console.log('rec => ',rec);
            var that = this;        
            var action = rec.data.action;
            var ext = rec.data.extension.length;
            var url = rec.data.url;
            var check = rec.data.chequeado;
            this.name_first = rec.data.nombre;

            if(check == 'no' && url ==''){                
                this.pdfGenedaroSF(rec.data);                 
            }else{                                               
                var data = "id=" + rec.data['id_documento_wf'];
                data += "&extension=pdf";
                data += "&sistema=sis_organigrama";
                data += "&clase=CertificadoPlanilla";
                data += "&url="+rec.data['url'];                
                url_send_view = `../../../lib/lib_control/CTOpenFile.php?${data}`;                
                var num_int = fetch(url_send_view).then(response => response.arrayBuffer()).then(function(data){
                var base = this.arrayBufferToBase64(data);                
                this.servicioValidadorFirmaDigital(base, url_send_view, that.name_first);
                });
            }        
        },        
        pdfGenedaroSF: function (rec) {        
            Ext.Ajax.request({
                url:'../../'+rec.action,
                params:{'id_proceso_wf':rec.id_proceso_wf, 'action':rec.action},
                success: this.pdfSinFirma, 
                failure: this.conexionFailure,
                timeout:this.timeout,
                scope:this
            });            
        },
        pdfSinFirma : function (resp){                    
            var objRes = Ext.util.JSON.decode(Ext.util.Format.trim(resp.responseText));            
            var nomRep = objRes.ROOT.detalle.archivo_generado;            
            if(Phx.CP.config_ini.x==1){  			
                nomRep = Phx.CP.CRIPT.Encriptar(nomRep);
            }
            url_send_view = `../../../lib/lib_control/Intermediario.php?r=${nomRep}&t=${new Date().toLocaleTimeString()}`;
            window.visorPdfVerificado('', url_send_view, false, this.name_first);
        },       
        pdfGeneradoFirm: function (rec) {
            Phx.CP.loadingShow();
            var that = this;            
            if(rec.chequeado == 'no' && rec.url ==''){
                Ext.Ajax.request({
                    url:'../../'+rec.action,
                    params:{'id_proceso_wf':rec.id_proceso_wf, 'action':rec.action},
                    success: this.firmPdf,
                    failure: this.conexionFailure,
                    timeout:this.timeout,
                    scope:this
                });                     
            }else{
                var data = "id=" + rec['id_documento_wf'];
                data += "&extension=" + rec['extension'];
                data += "&sistema=sis_organigrama";
                data += "&clase=CertificadoPlanilla";
                data += "&url="+rec['url'];                

                url_send_view = `../../../lib/lib_control/CTOpenFile.php?${data}`;                                
                var num_int = fetch(url_send_view).then(response => response.arrayBuffer()).then(function(data){                
                var buffer = window.arrayBufferToBase64(data);
                //that.fileSaveurl(window.arrayBufferToBase64(data));
                that.savebase64DB(buffer, this.id_document_general);
                });                 
            }             
        },
        firmPdf:function(resp){            
            var that = this;            
            var objRes = Ext.util.JSON.decode(Ext.util.Format.trim(resp.responseText));
            var nomRep = objRes.ROOT.detalle.archivo_generado;            
            if(Phx.CP.config_ini.x==1){  			
        	    nomRep = Phx.CP.CRIPT.Encriptar(nomRep);
            }
            var url = `../../../lib/lib_control/Intermediario.php?r=${nomRep}&t=${new Date().toLocaleTimeString()}`;     
            const fet = fetch(url).then(response => response.arrayBuffer()).then( (data) => {
                var buffer = window.arrayBufferToBase64(data);                
                that.savebase64DB(buffer, this.id_document_general);
            });            
        },
        savebase64DB:function(buffer, id_docw){
            var id_certificado_plani = this.objRec.id_certificado_planilla;
            Ext.Ajax.request({
                    url:'../../sis_organigrama/control/CertificadoPlanilla/saveDocumentoToSing',
                    params:{'pdf':buffer, codigo:'certificado_trabajo_sis_orga', 'id_documento_wf':id_docw, 'id_certificado_planilla':id_certificado_plani},
                    success: this.respuesta,
                    failure: this.conexionFailure,
                    timeout:this.timeout,
                    scope:this
                });                
        },
        respuesta:function(data){
            Phx.CP.loadingHide();
            var reg = Ext.util.JSON.decode(Ext.util.Format.trim(data.responseText));            
            console.log('freee',reg);
        },        
        fileSaveurl:function(base){              
            this.docPdf.push(
                {             
                base64: `data:application/pdf;base64,${base}`,
                name: this.id_document_general
                },
            );                        
        },        
        cmbGestion: new Ext.form.ComboBox({
                name: 'gestion',                
                fieldLabel: 'Gestion',
                allowBlank: true,
                emptyText: 'Gestion...',                
                blankText: 'Año',
                editable: false,
                store: new Ext.data.JsonStore(
                    {
                        url: '../../sis_parametros/control/Gestion/listarGestion',
                        id: 'id_gestion',
                        root: 'datos',
                        sortInfo: {
                            field: 'gestion',
                            direction: 'DESC'
                        },
                        totalProperty: 'total',
                        fields: ['gestion'],                        
                        remoteSort: true,
                        baseParams: {par_filtro: 'gestion'}
                    }),
                valueField: 'gestion',
                value: new Date().getFullYear(),
                triggerAction: 'all',
                displayField: 'gestion',
                hiddenName: 'gestion',
                mode: 'remote',
                pageSize: 50,
                queryDelay: 500,
                listWidth: '280',
                hidden: false,
                width: 80
            }),
    capturarEventos: function () {         	
        this.store.baseParams.gestion=this.cmbGestion.getValue();     
        this.load({params:{start:0, limit:this.tam_pag}});
    },        
    }
</script>
