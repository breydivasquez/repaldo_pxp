<?php

header("content-type: text/javascript; charset=UTF-8");
?>
<script>
    Phx.vista.ConsultaInterinato = Ext.extend(Phx.gridInterfaz, {

            constructor: function (config) {

                this.maestro = config.maestro;
                //llama al constructor de la clase padre
                Phx.vista.ConsultaInterinato.superclass.constructor.call(this, config);
                this.init();

                this.addButton('archivo', {
                    text: 'Adjuntar Archivo',
                    iconCls: 'bfolder',
                    disabled: false,
                    handler: this.archivo,
                    tooltip: '<b>Adjuntar Archivo</b><br><b>Nos permite adjuntar documentos de un funcionario.</b>',
                    grupo: [0,1]
                });

                this.iniciarEventos();
                this.load({params: {start: 0, limit: this.tam_pag}})
            },

            Atributos: [
                {
                    //configuracion del componente
                    config: {
                        labelSeparator: '',
                        inputType: 'hidden',
                        name: 'id_interinato'
                    },
                    type: 'Field',
                    form: true
                },
                ///////// no
                {
                    config: {
                        name: 'fecha_ini',
                        fieldLabel: 'Fecha Ini',
                        allowBlank: false,
                        anchor: '80%',
                        gwidth: 100,
                        format: 'd/m/Y',
                        renderer: function (value, p, record) {
                            return value ? value.dateFormat('d/m/Y') : ''
                        }
                    },
                    type: 'DateField',
                    filters: {pfiltro: 'int.fecha_ini', type: 'date'},
                    valorInicial: new Date(),
                    id_grupo: 1,
                    grid: true,
                    form: true
                },

                {
                    config: {
                        name: 'fecha_fin',
                        fieldLabel: 'Fecha Fin',
                        allowBlank: false,
                        anchor: '80%',
                        gwidth: 100,
                        format: 'd/m/Y',
                        renderer: function (value, p, record) {
                            return value ? value.dateFormat('d/m/Y') : ''
                        }
                    },
                    type: 'DateField',
                    filters: {pfiltro: 'int.fecha_fin', type: 'date'},
                    id_grupo: 1,
                    grid: true,
                    form: true
                },
                {
                    config: {
                        name: 'id_cargo_titular',
                        fieldLabel: 'Titular',
                        allowBlank: false,
                        emptyText: 'Elija una opción...',
                        store: new Ext.data.JsonStore({
                            url: '../../sis_organigrama/control/Funcionario/listarFuncionarioCargo',
                            id: 'id_cargo',
                            root: 'datos',
                            sortInfo: {
                                field: 'descripcion_cargo',
                                direction: 'ASC'
                            },
                            totalProperty: 'total',
                            fields: ['id_cargo', 'nombre', 'desc_funcionario1', 'id_funcionario', 'descripcion_cargo', 'id_cargo'],
                            remoteSort: true,
                            baseParams: {par_filtro: 'descripcion_cargo#desc_funcionario1#desc_funcionario2'}
                        }),
                        tpl: '<tpl for="."><div class="x-combo-list-item"><p><b>{descripcion_cargo}</b></p><p>{desc_funcionario1}</p> </div></tpl>',
                        valueField: 'id_cargo',
                        displayField: 'descripcion_cargo',
                        gdisplayField: 'nombre_titular',
                        hiddenName: 'id_cargo_titular',
                        forceSelection: true,
                        typeAhead: false,
                        triggerAction: 'all',
                        lazyRender: true,
                        mode: 'remote',
                        pageSize: 15,
                        queryDelay: 1000,
                        anchor: '100%',
                        gwidth: 150,
                        minChars: 2,
                        renderer: function (value, p, record) {
                            return String.format('{0}', record.data['nombre_titular']);
                        }
                    },
                    type: 'ComboBox',
                    id_grupo: 0,
                    filters: {pfiltro: 'ct.nombre', type: 'string'},
                    grid: true,
                    form: true
                },
                {
                    config: {
                        name: 'desc_funcionario_titular',
                        fieldLabel: 'Funcionario Titular',
                        allowBlank: true,
                        anchor: '80%',
                        gwidth: 250,
                        maxLength: 4
                    },
                    type: 'Field',
                    filters: {pfiltro: 'ft.desc_funcionario1', type: 'string'},
                    id_grupo: 1,
                    bottom_filter: true,
                    grid: true,
                    form: false
                },
                {
                    config: {
                        name: 'id_cargo_suplente',
                        fieldLabel: 'Suplente',
                        allowBlank: false,
                        emptyText: 'Elija una opción...',
                        store: new Ext.data.JsonStore({
                            url: '../../sis_organigrama/control/Funcionario/listarFuncionarioCargo',
                            id: 'id_cargo',
                            root: 'datos',
                            sortInfo: {
                                field: 'descripcion_cargo',
                                direction: 'ASC'
                            },
                            totalProperty: 'total',
                            fields: ['id_cargo', 'nombre', 'desc_funcionario1', 'id_funcionario', 'descripcion_cargo', 'id_cargo'],
                            remoteSort: true,
                            baseParams: {par_filtro: 'descripcion_cargo#desc_funcionario1#desc_funcionario2'}
                        }),
                        tpl: '<tpl for="."><div class="x-combo-list-item"><p><b>{descripcion_cargo}</b></p><p>{desc_funcionario1}</p> </div></tpl>',
                        valueField: 'id_cargo',
                        displayField: 'descripcion_cargo',
                        gdisplayField: 'nombre_suplente',
                        hiddenName: 'id_cargo_suplente',
                        forceSelection: true,
                        typeAhead: false,
                        triggerAction: 'all',
                        lazyRender: true,
                        mode: 'remote',
                        pageSize: 15,
                        queryDelay: 1000,
                        anchor: '100%',
                        gwidth: 150,
                        minChars: 2,
                        renderer: function (value, p, record) {
                            return String.format('{0}', record.data['nombre_suplente']);
                        }
                    },
                    type: 'ComboBox',
                    id_grupo: 0,
                    filters: {pfiltro: 'cs.nombre', type: 'string'},
                    grid: true,
                    form: true
                },
                {
                    config: {
                        name: 'desc_funcionario_suplente',
                        fieldLabel: 'Funcionario Suplente',
                        allowBlank: true,
                        anchor: '80%',
                        gwidth: 250,
                        maxLength: 4
                    },
                    type: 'Field',
                    filters: {pfiltro: 'fs.desc_funcionario1', type: 'string'},
                    id_grupo: 1,
                    bottom_filter: true,
                    grid: true,
                    form: false
                },
                {
                    config: {
                        name: 'descripcion',
                        fieldLabel: 'Obs',
                        allowBlank: true,
                        anchor: '80%',
                        gwidth: 100,
                        maxLength: 150
                    },
                    type: 'TextArea',
                    filters: {pfiltro: 'int.descripcion', type: 'string'},
                    id_grupo: 1,
                    grid: true,
                    form: true
                },
                {
                    config: {
                        name: 'estado_reg',
                        fieldLabel: 'Estado Reg.',
                        allowBlank: true,
                        anchor: '80%',
                        gwidth: 100,
                        maxLength: 10
                    },
                    type: 'TextField',
                    filters: {pfiltro: 'int.estado_reg', type: 'string'},
                    id_grupo: 1,
                    grid: true,
                    form: false
                },
                {
                    config: {
                        name: 'usr_reg',
                        fieldLabel: 'Creado por',
                        allowBlank: true,
                        anchor: '80%',
                        gwidth: 100,
                        maxLength: 4
                    },
                    type: 'Field',
                    filters: {pfiltro: 'usu1.cuenta', type: 'string'},
                    id_grupo: 1,
                    grid: true,
                    form: false
                },
                {
                    config: {
                        name: 'fecha_reg',
                        fieldLabel: 'Fecha creación',
                        allowBlank: true,
                        anchor: '80%',
                        gwidth: 100,
                        format: 'd/m/Y',
                        renderer: function (value, p, record) {
                            return value ? value.dateFormat('d/m/Y H:i:s') : ''
                        }
                    },
                    type: 'DateField',
                    filters: {pfiltro: 'int.fecha_reg', type: 'date'},
                    id_grupo: 1,
                    grid: true,
                    form: false
                },
                {
                    config: {
                        name: 'usr_mod',
                        fieldLabel: 'Modificado por',
                        allowBlank: true,
                        anchor: '80%',
                        gwidth: 100,
                        maxLength: 4
                    },
                    type: 'NumberField',
                    filters: {pfiltro: 'usu2.cuenta', type: 'string'},
                    id_grupo: 1,
                    grid: true,
                    form: false
                },
                {
                    config: {
                        name: 'fecha_mod',
                        fieldLabel: 'Fecha Modif.',
                        allowBlank: true,
                        anchor: '80%',
                        gwidth: 100,
                        format: 'd/m/Y',
                        renderer: function (value, p, record) {
                            return value ? value.dateFormat('d/m/Y H:i:s') : ''
                        }
                    },
                    type: 'DateField',
                    filters: {pfiltro: 'int.fecha_mod', type: 'date'},
                    id_grupo: 1,
                    grid: true,
                    form: false
                }
            ],
            tam_pag: 50,
            title: 'Consulta Interinato',
            ActSave:'../../sis_organigrama/control/Interinato/insertarInterinato',
            ActDel:'../../sis_organigrama/control/Interinato/eliminarInterinato',
            ActList: '../../sis_organigrama/control/Interinato/listarConsultaInterinato',
            id_store: 'id_interinato',
            fields: [
                {name: 'id_interinato', type: 'numeric'},
                {name: 'id_cargo_titular', type: 'numeric'},
                {name: 'id_cargo_suplente', type: 'numeric'},
                {name: 'fecha_ini', type: 'date', dateFormat: 'Y-m-d'},
                {name: 'descripcion', type: 'string'},
                {name: 'id_usuario_ai', type: 'numeric'},
                {name: 'fecha_fin', type: 'date', dateFormat: 'Y-m-d'},
                {name: 'estado_reg', type: 'string'},
                {name: 'id_usuario_reg', type: 'numeric'},
                {name: 'fecha_reg', type: 'date', dateFormat: 'Y-m-d H:i:s.u'},
                {name: 'id_usuario_mod', type: 'numeric'},
                {name: 'fecha_mod', type: 'date', dateFormat: 'Y-m-d H:i:s.u'},
                {name: 'usr_reg', type: 'string'},
                {name: 'usr_mod', type: 'string'},
                'nombre_suplente', 'nombre_titular',
                'desc_funcionario_titular',
                'desc_funcionario_suplente'

            ],

            iniciarEventos: function () {

                //inicio de eventos
                this.Cmp.fecha_ini.on('change', function (f) {

                    this.Cmp.id_cargo_titular.enable();
                    this.Cmp.id_cargo_titular.store.baseParams.fecha = this.Cmp.fecha_ini.getValue().dateFormat(this.Cmp.fecha_ini.format);
                    this.Cmp.id_cargo_titular.modificado = true;

                    this.Cmp.id_cargo_suplente.enable();
                    this.Cmp.id_cargo_suplente.store.baseParams.fecha = this.Cmp.fecha_ini.getValue().dateFormat(this.Cmp.fecha_ini.format);
                    this.Cmp.id_cargo_suplente.modificado = true;

                }, this);
            },
            // onButtonNew : function() {
            //     Phx.vista.ConsultaInterinato.superclass.onButtonNew.call(this);
            //     console.log(this.Cmp);
            //     this.Cmp.id_cargo_titular.store.baseParams.fecha = this.Cmp.fecha_ini.getValue().dateFormat(this.Cmp.fecha_ini.format);
            //     this.Cmp.id_cargo_titular.modificado=true;
            //     this.Cmp.id_cargo_suplente.store.baseParams.fecha = this.Cmp.fecha_ini.getValue().dateFormat(this.Cmp.fecha_ini.format);
            //     this.Cmp.id_cargo_suplente.modificado=true;
            //
            // },

            // onButtonEdit:function(){
            //     Phx.vista.ConsultaInterinato.superclass.onButtonEdit.call(this);
            //     this.Cmp.id_cargo_titular.store.baseParams.fecha = this.Cmp.fecha_ini.getValue().dateFormat(this.Cmp.fecha_ini.format);
            //     this.Cmp.id_cargo_titular.modificado=true;
            //
            //     this.Cmp.id_cargo_suplente.store.baseParams.fecha = this.Cmp.fecha_ini.getValue().dateFormat(this.Cmp.fecha_ini.format);
            //     this.Cmp.id_cargo_suplente.modificado=true;
            //
            //
            //
            // },
            sortInfo: {
                field: 'id_interinato',
                direction: 'DESC'
            },
            archivo: function () {

                var rec = this.getSelectedData();
                //enviamos el id seleccionado para cual el archivo se deba subir
                rec.datos_extras_id = rec.id_interinato;
                //enviamos el nombre de la tabla
                rec.datos_extras_tabla = 'orga.tinterinato';
                //enviamos el codigo ya que una tabla puede tener varios archivos diferentes como ci,pasaporte,contrato,slider,fotos,etc
                rec.datos_extras_codigo = '';

                //esto es cuando queremos darle una ruta personalizada
                //rec.datos_extras_ruta_personalizada = './../../../uploaded_files/favioVideos/videos/';

                Phx.CP.loadWindows('../../../sis_parametros/vista/archivo/Archivo.php',
                    'Archivo',
                    {
                        width: '80%',
                        height: '100%'
                    }, rec, this.idContenedor, 'Archivo');

            },

            bdel: true,
            bsave: false,
            bnew: true,
            bedit: true
        }
    )
</script>

