CREATE OR REPLACE FUNCTION orga.ft_certificado_planilla_ime (
  p_administrador integer,
  p_id_usuario integer,
  p_tabla varchar,
  p_transaccion varchar
)
RETURNS varchar AS
$body$
/**************************************************************************
 SISTEMA:		Organigrama
 FUNCION: 		orga.ft_certificado_planilla_ime
 DESCRIPCION:   Funcion que gestiona las operaciones basicas (inserciones, modificaciones, eliminaciones de la tabla 'orga.tcertificado_planilla'
 AUTOR: 		 (miguel.mamani)
 FECHA:	        24-07-2017 14:48:34
 COMENTARIOS:
***************************************************************************
 HISTORIAL DE MODIFICACIONES:

 DESCRIPCION:
 AUTOR:
 FECHA:
***************************************************************************/

DECLARE

	v_nro_requerimiento    			integer;
	v_parametros           			record;
	v_id_requerimiento     			integer;
	v_resp		            		varchar;
	v_nombre_funcion        		text;
	v_mensaje_error         		text;
	v_id_certificado_planilla		integer;
    v_id_gestion					integer;
    v_nro_tramite					varchar;
   	v_id_proceso_wf					integer;
    v_id_estado_wf					integer;
    v_codigo_estado					varchar;
    v_codigo_tipo_proceso 			varchar;
    v_id_proceso_macro				integer;

    v_registo						record;
    v_acceso_directo				varchar;
    v_clase							varchar;
    v_parametros_ad					varchar;
    v_tipo_noti						varchar;
    v_titulo						varchar;
    v_id_tipo_estado				integer;
    v_pedir_obs						varchar;
    v_codigo_estado_siguiente 		varchar;
    v_obs							varchar;
    v_id_estado_actual				integer;
    v_id_depto						integer;
    v_operacion						varchar;
    v_registros_cer					record;
    v_id_funcionario 				integer;
    v_id_usuario_reg 				integer;
    v_id_estado_wf_ant				integer;
    v_count							integer;
    v_valor							integer;
    v_funcionario					varchar;
    v_impreso 						varchar;
    v_bo							integer;
    v_url							varchar;
    v_id_documento_wf				integer;
    v_fun							record;
	v_haber_basico					orga.tcertificado_planilla.haber_basico%TYPE;

BEGIN

    v_nombre_funcion = 'orga.ft_certificado_planilla_ime';
    v_parametros = pxp.f_get_record(p_tabla);

	/*********************************
 	#TRANSACCION:  'OR_PLANC_INS'
 	#DESCRIPCION:	Insercion de registros
 	#AUTOR:		miguel.mamani
 	#FECHA:		24-07-2017 14:48:34
	***********************************/

	if(p_transaccion='OR_PLANC_INS')then


        begin

        select v.valor
        into
        v_valor
        from pxp.variable_global v
        where v.variable = 'control_registros';

        select count(c.id_certificado_planilla)
        into
        v_count
		from orga.tcertificado_planilla c
		where c.id_funcionario = v_parametros.id_funcionario
        and EXTRACT( YEAR FROM c.fecha_solicitud) = EXTRACT(YEAR FROM current_date) and
        (c.tipo_certificado='General' or c.tipo_certificado='Con viáticos de los últimos tres meses')
        and  c.estado='emitido';

        select desc_funcionario1
        into
        v_funcionario
        from orga.vfuncionario
        where id_funcionario = v_parametros.id_funcionario;

        if(pxp.f_existe_parametro(p_tabla,'factura'))then

              if (v_parametros.factura ='') then
                  if v_valor = v_count then
                  raise exception 'El Funcionario %, sobrepaso el limite maximo de certificados emitidos por gestion = %.',v_funcionario,v_valor;
                  end if ;
              end if;
          else
                if v_valor = v_count then
                    raise exception 'El Funcionario %, sobrepaso el limite maximo de certificados emitidos por gestion = %.',v_funcionario,v_valor;
                end if;
        end if;

        --Gestion para WF
         SELECT g.id_gestion
         INTO v_id_gestion
         FROM param.tgestion g
         WHERE g.gestion = EXTRACT(YEAR FROM current_date);



          select    tp.codigo, pm.id_proceso_macro
         into v_codigo_tipo_proceso, v_id_proceso_macro
         from  wf.tproceso_macro pm
         inner join wf.ttipo_proceso tp on tp.id_proceso_macro = pm.id_proceso_macro
         where pm.codigo='CT' and tp.estado_reg = 'activo' and tp.inicio = 'si' ;

            SELECT
                 ps_num_tramite ,
                 ps_id_proceso_wf ,
                 ps_id_estado_wf ,
                 ps_codigo_estado
              into
                 v_nro_tramite,
                 v_id_proceso_wf,
                 v_id_estado_wf,
                 v_codigo_estado

            FROM wf.f_inicia_tramite(
                 p_id_usuario,
                 v_parametros._id_usuario_ai,
                 v_parametros._nombre_usuario_ai,
                 v_id_gestion,
                 v_codigo_tipo_proceso,
                 NULL,
                 NULL,
                 'Certificados de Trabajo',
                 v_codigo_tipo_proceso);


		-- Obtencion de cargo funcionario, a la fecha solicitud 
          SELECT c.descripcion_cargo,c.id_uo_funcionario into v_fun 
          FROM orga.vfuncionario_cargo_lugar c
          where c.id_funcionario = v_parametros.id_funcionario;
          
        -- Obtencion de haber basico de, a la fecha solicitud   
          select
            round(colval.valor,2) into v_haber_basico 
            from plani.tcolumna_valor colval
            inner join plani.tfuncionario_planilla funpla on funpla.id_funcionario_planilla = colval.id_funcionario_planilla
            inner join plani.tplanilla pla on pla.id_planilla = funpla.id_planilla and pla.id_tipo_planilla = 1
            where  funpla.id_funcionario = v_parametros.id_funcionario
            and colval.codigo_columna = 'COTIZABLE'
            and pla.fecha_planilla =
                (select p.fecha_planilla
                  from plani.tplanilla p
                  where 
                  p.id_tipo_planilla = 1
                  and p.id_periodo = (select p.id_periodo
                                        from param.tperiodo p
                                        where  current_date between p.fecha_ini and p.fecha_fin
                                        ) - 1);


	if(pxp.f_existe_parametro(p_tabla,'factura'))then

        	--Sentencia de la insercion
        	insert into orga.tcertificado_planilla(
			tipo_certificado,
			fecha_solicitud,
			id_funcionario,
			estado_reg,
			importe_viatico,
			id_usuario_ai,
			fecha_reg,
			usuario_ai,
			id_usuario_reg,
			fecha_mod,
			id_usuario_mod,
            nro_tramite,
            estado,
            id_proceso_wf,
            id_estado_wf,
            nro_factura,
            haber_basico,
            cargo_funcionario            
          	) values(
			v_parametros.tipo_certificado,
			v_parametros.fecha_solicitud,
			--v_parametros.id_funcionario,
			v_fun.id_uo_funcionario,            
			'activo',
			COALESCE (v_parametros.importe_viatico,0),
			v_parametros._id_usuario_ai,
			now(),
			v_parametros._nombre_usuario_ai,
			p_id_usuario,
			null,
			null,
            v_nro_tramite,
            v_codigo_estado,
            v_id_proceso_wf,
			v_id_estado_wf,
            v_parametros.factura,
            v_haber_basico,
            v_fun.descripcion_cargo            
			)RETURNING id_certificado_planilla into v_id_certificado_planilla;
	ELSE
        	--Sentencia de la insercion
        	insert into orga.tcertificado_planilla(
			tipo_certificado,
			fecha_solicitud,
			id_funcionario,
			estado_reg,
			importe_viatico,
			id_usuario_ai,
			fecha_reg,
			usuario_ai,
			id_usuario_reg,
			fecha_mod,
			id_usuario_mod,
            nro_tramite,
            estado,
            id_proceso_wf,
            id_estado_wf,
            haber_basico,
            cargo_funcionario             
          	) values(
			v_parametros.tipo_certificado,
			v_parametros.fecha_solicitud,
			--v_parametros.id_funcionario,
			v_fun.id_uo_funcionario,
			'activo',
			COALESCE (v_parametros.importe_viatico,0),
			v_parametros._id_usuario_ai,
			now(),
			v_parametros._nombre_usuario_ai,
			p_id_usuario,
			null,
			null,
            v_nro_tramite,
            v_codigo_estado,
            v_id_proceso_wf,
			v_id_estado_wf,
            v_haber_basico,
            v_fun.descripcion_cargo            
			)RETURNING id_certificado_planilla into v_id_certificado_planilla;
	end if;

			--Definicion de la respuesta
			v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Certificado Planilla almacenado(a) con exito (id_certificado_planilla'||v_id_certificado_planilla||')');
            v_resp = pxp.f_agrega_clave(v_resp,'id_certificado_planilla',v_id_certificado_planilla::varchar);

            --Devuelve la respuesta
            return v_resp;

		end;

	/*********************************
 	#TRANSACCION:  'OR_PLANC_MOD'
 	#DESCRIPCION:	Modificacion de registros
 	#AUTOR:		miguel.mamani
 	#FECHA:		24-07-2017 14:48:34
	***********************************/

	elsif(p_transaccion='OR_PLANC_MOD')then

		begin
			--Sentencia de la modificacion
			update orga.tcertificado_planilla set
			tipo_certificado = v_parametros.tipo_certificado,
			fecha_solicitud = v_parametros.fecha_solicitud,
			beneficiario = v_parametros.beneficiario,
			id_funcionario = v_parametros.id_funcionario,
			importe_viatico = v_parametros.importe_viatico,
			fecha_mod = now(),
			id_usuario_mod = p_id_usuario,
			id_usuario_ai = v_parametros._id_usuario_ai,
			usuario_ai = v_parametros._nombre_usuario_ai,
            nro_factura = v_parametros.factura
			where id_certificado_planilla=v_parametros.id_certificado_planilla;

			--Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Certificado Planilla modificado(a)');
            v_resp = pxp.f_agrega_clave(v_resp,'id_certificado_planilla',v_parametros.id_certificado_planilla::varchar);

            --Devuelve la respuesta
            return v_resp;

		end;

	/*********************************
 	#TRANSACCION:  'OR_PLANC_ELI'
 	#DESCRIPCION:	Eliminacion de registros
 	#AUTOR:		miguel.mamani
 	#FECHA:		24-07-2017 14:48:34
	***********************************/

	elsif(p_transaccion='OR_PLANC_ELI')then

		begin
			 select 	ma.id_proceso_wf,
        		ma.id_estado_wf,
                ma.estado
                into
                v_id_proceso_wf,
                v_id_estado_wf,
        		v_codigo_estado
        from orga.tcertificado_planilla ma
        where ma.id_certificado_planilla = v_parametros.id_certificado_planilla;

        select
        	te.id_tipo_estado
        into
        	v_id_tipo_estado
        from wf.tproceso_wf pw
        inner join wf.ttipo_proceso tp on pw.id_tipo_proceso = tp.id_tipo_proceso
        inner join wf.ttipo_estado te on te.id_tipo_proceso = tp.id_tipo_proceso and te.codigo = 'anulado'
        where pw.id_proceso_wf = v_id_proceso_wf;


        if v_id_tipo_estado is null  then
        	raise exception 'No se parametrizo el estado "anulado" ';
        end if;
          -- pasamos la solicitud  al siguiente anulado
           v_id_estado_actual =  wf.f_registra_estado_wf(	v_id_tipo_estado,
           													v_id_funcionario,
                                                          	v_id_estado_wf,
            												v_id_proceso_wf,
                                                           	p_id_usuario,
                                                           	v_parametros._id_usuario_ai,
            											   	v_parametros._nombre_usuario_ai,
                                                           	v_id_depto,
                                                           	'Certificado Anulado');


        -- actualiza estado en la solicitud
        update orga.tcertificado_planilla set
                 id_estado_wf =  v_id_estado_actual,
                 estado = 'anulado',
                 id_usuario_mod=p_id_usuario,
                 fecha_mod=now(),
                 estado_reg='inactivo',
                 id_usuario_ai = v_parametros._id_usuario_ai,
                 usuario_ai = v_parametros._nombre_usuario_ai
               where id_certificado_planilla = v_parametros.id_certificado_planilla;
            --Definicion de la respuesta
            v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Certificado Planilla eliminado(a)');
            v_resp = pxp.f_agrega_clave(v_resp,'id_certificado_planilla',v_parametros.id_certificado_planilla::varchar);

            --Devuelve la respuesta
            return v_resp;

		end;
     /*********************************
 	#TRANSACCION:  'OR_SIGUE_EMI'
 	#DESCRIPCION:	Siguiente e
 	#AUTOR:		MMV
 	#FECHA:		06-06-2017 17:32:59
	***********************************/
    elseif(p_transaccion='OR_SIGUE_EMI') then
    	begin

		IF NOT EXISTS (
        		select h.estado_reg
                  from wf.tdocumento_historico_wf h
                  inner join wf.tdocumento_wf d on d.id_documento_wf=h.id_documento
                  where d.id_proceso_wf= v_parametros.id_proceso_wf_act)then
		v_bo =1;
        ELSE 
        v_bo =0;
        end if;

		if(v_parametros.factura<>'' and v_bo=1 and (v_parametros.tipo_certificado='General(Factura)' or v_parametros.tipo_certificado='Con viáticos de los últimos tres meses(Factura)'))then
    	    	raise exception 'Adjunte Su Factura Por Favor';

		ELSE

          --recupera el registro de la CVPN
          select *
          into v_registo
          from orga.tcertificado_planilla
          where id_proceso_wf = v_parametros.id_proceso_wf_act;

          SELECT
            ew.id_tipo_estado ,
            te.pedir_obs,
            ew.id_estado_wf
           into
            v_id_tipo_estado,
            v_pedir_obs,
            v_id_estado_wf
          FROM wf.testado_wf ew
          INNER JOIN wf.ttipo_estado te ON te.id_tipo_estado = ew.id_tipo_estado
          WHERE ew.id_estado_wf =  v_parametros.id_estado_wf_act;

           -- obtener datos tipo estado siguiente
           select te.codigo into
             v_codigo_estado_siguiente
           from wf.ttipo_estado te
           where te.id_tipo_estado = v_parametros.id_tipo_estado;


           IF  pxp.f_existe_parametro(p_tabla,'id_depto_wf') THEN
           	 v_id_depto = v_parametros.id_depto_wf;
           END IF;

           IF  pxp.f_existe_parametro(p_tabla,'obs') THEN
           	 v_obs = v_parametros.obs;
           ELSE
           	 v_obs='---';
           END IF;

             --configurar acceso directo para la alarma
             v_acceso_directo = '';
             v_clase = '';
             v_parametros_ad = '';
             v_tipo_noti = 'notificacion';
             v_titulo  = 'Emitido';


             IF   v_codigo_estado_siguiente not in('borrador')   THEN

                  v_acceso_directo = '../../../sis_organigrama/vista/certificado_planilla/CertificadoPlanilla.php';
             	  v_clase = 'CertificadoPlanilla';
                  v_parametros_ad = '{filtro_directo:{campo:"cvpn.id_proceso_wf",valor:"'||v_parametros.id_proceso_wf_act::varchar||'"}}';
                  v_tipo_noti = 'notificacion';
                  v_titulo  = 'Notificacion';
             END IF;


             -- hay que recuperar el supervidor que seria el estado inmediato...
            	v_id_estado_actual =  wf.f_registra_estado_wf(v_parametros.id_tipo_estado,
                                                             v_parametros.id_funcionario_wf,
                                                             v_parametros.id_estado_wf_act,
                                                             v_parametros.id_proceso_wf_act,
                                                             p_id_usuario,
                                                             v_parametros._id_usuario_ai,
                                                             v_parametros._nombre_usuario_ai,
                                                             v_id_depto,
                                                             COALESCE(v_registo.nro_tramite,'--')||' Obs:'||v_obs,
                                                             v_acceso_directo ,
                                                             v_clase,
                                                             v_parametros_ad,
                                                             v_tipo_noti,
                                                             v_titulo);



         		IF orga.f_procesar_estados_certificado(p_id_usuario,
           									v_parametros._id_usuario_ai,
                                            v_parametros._nombre_usuario_ai,
                                            v_id_estado_actual,
                                            v_parametros.id_proceso_wf_act,
                                            v_codigo_estado_siguiente) THEN

         			RAISE NOTICE 'PASANDO DE ESTADO';

          		END IF;

        end if;
          -- si hay mas de un estado disponible  preguntamos al usuario
          v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Se realizo el cambio de estado del Reclamo)');
          v_resp = pxp.f_agrega_clave(v_resp,'operacion','cambio_exitoso');
          v_resp = pxp.f_agrega_clave(v_resp,'v_codigo_estado_siguiente',v_codigo_estado_siguiente);

          -- Devuelve la respuesta
          return v_resp;
        end;

    /*********************************
 	#TRANSACCION:  'OR_ANTE_IME'
 	#DESCRIPCION:	Anterior estado
 	#AUTOR:		MMV
 	#FECHA:		06-06-2017 17:32:59
	***********************************/
    elseif(p_transaccion='OR_ANTE_IME') then
    	begin

        	v_operacion = 'anterior';

            IF  pxp.f_existe_parametro(p_tabla , 'estado_destino')  THEN
               v_operacion = v_parametros.estado_destino;
            END IF;

            --obtenemos los datos del registro de solicitud VPN
            select
                tcv.id_certificado_planilla,
                tcv.id_proceso_wf,
                tcv.estado
            into v_registros_cer
            from orga.tcertificado_planilla  tcv
            inner  join wf.tproceso_wf pwf  on  pwf.id_proceso_wf = tcv.id_proceso_wf
            where tcv.id_proceso_wf  = v_parametros.id_proceso_wf;

            --v_id_proceso_wf = v_registros_cvpn.id_proceso_wf;
            
              select d.id_documento_wf	into v_id_documento_wf
              from wf.tdocumento_wf d
              inner join wf.ttipo_documento t on t.id_tipo_documento = d.id_tipo_documento
              where d.id_proceso_wf = v_parametros.id_proceso_wf 
              and t.codigo = 'CERT';

            IF  v_operacion = 'anterior' THEN
                --------------------------------------------------
                --Retrocede al estado inmediatamente anterior
                -------------------------------------------------
               	--recuperaq estado anterior segun Log del WF
                  SELECT

                     ps_id_tipo_estado,
                     ps_id_funcionario,
                     ps_id_usuario_reg,
                     ps_id_depto,
                     ps_codigo_estado,
                     ps_id_estado_wf_ant
                  into
                     v_id_tipo_estado,
                     v_id_funcionario,
                     v_id_usuario_reg,
                     v_id_depto,
                     v_codigo_estado,
                     v_id_estado_wf_ant
                  FROM wf.f_obtener_estado_ant_log_wf(v_parametros.id_estado_wf);

                  select
                    ew.id_proceso_wf
                  into
                    v_id_proceso_wf
                  from wf.testado_wf ew
                  where ew.id_estado_wf= v_id_estado_wf_ant;
            END IF;


			 v_acceso_directo = '../../../sis_organigrama/vista/certificado_planilla/CertificadoPlanilla.php';
             v_clase = 'CertificadoPlanilla';
             v_parametros_ad = '{filtro_directo:{campo:"cvpn.id_proceso_wf",valor:"'||v_id_proceso_wf::varchar||'"}}';
             v_tipo_noti = 'notificacion';
             v_titulo  = 'Visto Bueno';

              -- registra nuevo estado

              v_id_estado_actual = wf.f_registra_estado_wf(
                    v_id_tipo_estado,                --  id_tipo_estado al que retrocede
                    v_id_funcionario,                --  funcionario del estado anterior
                    v_parametros.id_estado_wf,       --  estado actual ...
                    v_id_proceso_wf,                 --  id del proceso actual
                    p_id_usuario,                    -- usuario que registra
                    v_parametros._id_usuario_ai,
                    v_parametros._nombre_usuario_ai,
                    v_id_depto,                       --depto del estado anterior
                    '[RETROCESO] '|| v_parametros.obs,
                    v_acceso_directo,
                    v_clase,
                    v_parametros_ad,
                    v_tipo_noti,
                    v_titulo);

                IF  not orga.f_ant_estado_certificado (p_id_usuario,
                                                       v_parametros._id_usuario_ai,
                                                       v_parametros._nombre_usuario_ai,
                                                       v_id_estado_actual,
                                                       v_parametros.id_proceso_wf,
                                                       v_codigo_estado) THEN

                   raise exception 'Error al retroceder estado';                   
                END IF;
                
				delete from firmdig.tdocumento_firm_dig 
                where id_documento_wf = v_id_documento_wf;
                
                update orga.tcertificado_planilla set
                impreso = 'no'
                where id_certificado_planilla = v_registros_cer.id_certificado_planilla;                            
                
                v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Se volvio al anterior estado)');
                v_resp = pxp.f_agrega_clave(v_resp,'operacion','cambio_exitoso');

              --Devuelve la respuesta
                return v_resp;

        end;
    /*********************************
 	#TRANSACCION:  'OR_ANTE_CON'
 	#DESCRIPCION:	Control Impreso certificado de trabajo
 	#AUTOR:		MMV
 	#FECHA:		06-06-2017 17:32:59
	***********************************/
    elseif(p_transaccion='OR_ANTE_CON') then
    	begin

        select cp.impreso
        into
        v_impreso
        from orga.tcertificado_planilla cp
        where cp.id_certificado_planilla = v_parametros.id_certificado_planilla;

        if (v_impreso = 'si')then
        v_impreso = 'no';
        else
        v_impreso = 'si';
        end if;

        update orga.tcertificado_planilla set
        impreso = v_impreso
        where id_certificado_planilla = v_parametros.id_certificado_planilla;

 		v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Revision con exito (id_certificado_planilla'||v_parametros.id_certificado_planilla||')');
        v_resp = pxp.f_agrega_clave(v_resp,'id_certificado_planilla',v_parametros.id_certificado_planilla::varchar);
        v_resp = pxp.f_agrega_clave(v_resp,'check',v_impreso::varchar);

		--Devuelve la respuesta
        return v_resp;

	end;

     /*********************************
 	#TRANSACCION:  'OR_SIGUE_EMIFIRM'
 	#DESCRIPCION:	Siguiente estado certificado de trabajo firmado digitalmente
 	#AUTOR:		BVP
 	#FECHA:		
	***********************************/
    elseif(p_transaccion='OR_SIGUE_EMIFIRM') then
    	begin

          --recupera el registro          
          select pla.*
          into v_registo
          from wf.tdocumento_wf dw 
          inner join orga.tcertificado_planilla pla on pla.id_proceso_wf = dw.id_proceso_wf
          where dw.id_documento_wf = v_parametros.id_doc_wf;

          SELECT
            ew.id_tipo_estado ,
            te.pedir_obs,
            ew.id_estado_wf
           into
            v_id_tipo_estado,
            v_pedir_obs,
            v_id_estado_wf
          FROM wf.testado_wf ew
          INNER JOIN wf.ttipo_estado te ON te.id_tipo_estado = ew.id_tipo_estado
          WHERE ew.id_estado_wf =  v_registo.id_estado_wf;
	
           -- obtener datos tipo estado siguiente
             v_codigo_estado_siguiente = 'emitido';

           IF  pxp.f_existe_parametro(p_tabla,'id_depto_wf') THEN
           	 v_id_depto = v_parametros.id_depto_wf;
           END IF;

           IF  pxp.f_existe_parametro(p_tabla,'obs') THEN
           	 v_obs = v_parametros.obs;
           ELSE
           	 v_obs='---';
           END IF;

             --configurar acceso directo para la alarma
             v_acceso_directo = '';
             v_clase = '';
             v_parametros_ad = '';
             v_tipo_noti = 'notificacion';
             v_titulo  = 'Emitido';


             IF   v_codigo_estado_siguiente not in('borrador')   THEN

                  v_acceso_directo = '../../../sis_organigrama/vista/certificado_planilla/CertificadoPlanilla.php';
             	  v_clase = 'CertificadoPlanilla';
                  v_parametros_ad = '{filtro_directo:{campo:"cvpn.id_proceso_wf",valor:"'||1104::varchar||'"}}';
                  v_tipo_noti = 'notificacion';
                  v_titulo  = 'Notificacion';
             END IF;
             
             select fun.id_funcionario
             		into v_id_funcionario 
             from orga.vfuncionario fun
			 inner join segu.tusuario us on us.id_persona = fun.id_persona
             where us.id_usuario = p_id_usuario;


             -- hay que recuperar el supervidor que seria el estado inmediato...
            	v_id_estado_actual =  wf.f_registra_estado_wf(898,
                                                             v_id_funcionario,
                                                             v_id_estado_wf,
                                                             v_registo.id_proceso_wf,
                                                             p_id_usuario,
                                                             v_parametros._id_usuario_ai,
                                                             v_parametros._nombre_usuario_ai,
                                                             v_id_depto,
                                                             COALESCE(v_registo.nro_tramite,'--')||' Obs:'||v_obs,
                                                             v_acceso_directo ,
                                                             v_clase,
                                                             v_parametros_ad,
                                                             v_tipo_noti,
                                                             v_titulo);



         		IF orga.f_procesar_estados_certificado(p_id_usuario,
           									v_parametros._id_usuario_ai,
                                            v_parametros._nombre_usuario_ai,
                                            v_id_estado_actual,
                                            v_registo.id_proceso_wf,
                                            v_codigo_estado_siguiente) THEN

         			RAISE NOTICE 'PASANDO DE ESTADO';

          		END IF;
          
              delete from firmdig.tdocumento_firm_dig 
              where id_documento_wf = v_parametros.id_doc_wf;      

          -- si hay mas de un estado disponible  preguntamos al usuario
          v_resp = pxp.f_agrega_clave(v_resp,'mensaje','Se realizo el cambio de estado del Reclamo)');
          v_resp = pxp.f_agrega_clave(v_resp,'operacion','cambio_exitoso');
          v_resp = pxp.f_agrega_clave(v_resp,'v_codigo_estado_siguiente',v_codigo_estado_siguiente);

          -- Devuelve la respuesta
          return v_resp;
        end; 
           
	else

    	raise exception 'Transaccion inexistente: %',p_transaccion;

	end if;

EXCEPTION

	WHEN OTHERS THEN
		v_resp='';
		v_resp = pxp.f_agrega_clave(v_resp,'mensaje',SQLERRM);
		v_resp = pxp.f_agrega_clave(v_resp,'codigo_error',SQLSTATE);
		v_resp = pxp.f_agrega_clave(v_resp,'procedimientos',v_nombre_funcion);
		raise exception '%',v_resp;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100;

ALTER FUNCTION orga.ft_certificado_planilla_ime (p_administrador integer, p_id_usuario integer, p_tabla varchar, p_transaccion varchar)
  OWNER TO postgres;