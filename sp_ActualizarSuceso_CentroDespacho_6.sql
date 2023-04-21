USE [sae911]
GO
/****** Object:  StoredProcedure [dbo].[sp_ActualizarSuceso_CentroDespacho_6]    Script Date: 28/10/2022 10:07:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_ActualizarSuceso_CentroDespacho_6]
(
@comp_id int					/* id del usuario que ejecuta la accion*/
,@usin_usuario varchar(30)      /* nombre de usuario que ejecuta la accion*/
,@codigo_unico_pc varchar(max)  /* codigo unico que identifica la accion*/
,@id_comp_modificada int        /* id de la empresa que se modifica, tener en cuenta que si es 0 no se genera el archivo xml*/

,@Codigo_PC_Unico bigint
,@sucd_suce_id bigint
,@sucd_cede_id int
,@sucd_cede_id_anterior int
,@sucd_suti_id int
,@sucd_subti_id int
,@sucd_supr_id int
,@sucd_sues_id int
,@sucd_sure_id int
,@sucd_prov_id	int
,@sucd_depar_id	int
,@sucd_loca_id	int
,@sucd_latitud	float
,@sucd_longitud	float
,@sucd_usuario_despachador varchar(30)
,@sucd_usuario_supervisor varchar(30)
,@sucd_fecha_hora_ini datetime
,@sucd_fecha_hora_fin datetime
,@sucd_calle varchar(255)
,@sucd_numero int
,@sucd_numero_validado bit
,@sucd_piso varchar(5)
,@sucd_depto varchar(5)
,@sucd_cuerpo varchar(5)
,@sucd_calle_entre_1_auto varchar(255)
,@sucd_calle_entre_2_auto varchar(255)
,@sucd_altura_entre_1_auto int
,@sucd_altura_entre_2_auto int
,@sucd_calle_entre_1_manual varchar(255)
,@sucd_calle_entre_2_manual varchar(255)
,@sucd_altura_entre_1_manual int
,@sucd_altura_entre_2_manual int
,@sucd_cierre_despachador text
,@sucd_cierre_supervisor text
,@sucd_interseccion_valida bit
,@sucd_cuadricula varchar(50)
,@sucd_comisaria varchar(50)
,@sucd_departamental varchar(50)
,@sucd_sub_cede_id int
,@sucd_suce_id_asociado bigint
,@sucd_calle_comentario varchar(255)
,@sucd_hecho_relevante bit
,@sucd_emal_id int
,@sucd_detenidos_mayores int
,@sucd_detenidos_menores int
,@sucd_secuestro_vehiculos int
,@sucd_secuestro_armas int
,@sucd_secuestro_drogas int
,@sucd_hito_id int
,@sucd_id_cate bigint
,@sucd_movi_id int
,@sucd_usuario_operador varchar(30)
,@sucd_cede_id_derivacion int
,@sucd_sub_cede_id_derivacion int
,@sucd_confidencial bit
,@sucd_tomado varchar(30)
,@usuario varchar(30)
,@sucd_fecha_aviso_reserva datetime=null
,@sucd_es_deslinde int =0
,@sucd_victimas int =0
,@sucd_heridos int =0
,@sucd_es_alerta int =0
,@sucd_cuartel_bomberos varchar(255)=''
,@sucd_jurisdiccion_salud varchar(255)=''
,@sucd_calle_alias varchar(255)=''
,@sucd_offline_id int=0
,@sucd_ref_id bigint=0
,@sucd_ref_descripcion varchar(2000)=''
,@sucd_ref_pais_id bigint=0
,@sucd_ref_prov_id bigint=0
,@sucd_ref_depar_id bigint=0
,@sucd_ref_loca_id bigint=0
,@sucd_vcm bit=0
,@sucd_offline_fecha datetime=null
,@sucd_offline_usuario varchar(255)=''
,@sucd_offline_cede_id int=0
,@sucd_fecha_actualizacion datetime=0
)
AS
BEGIN
	SET NOCOUNT ON;
	set dateformat 'DMY'
	
	declare @fecha datetime
	
	if (@sucd_fecha_actualizacion<=0) set @fecha = getdate() else set @fecha=@sucd_fecha_actualizacion

	set @sucd_calle_comentario = replace(@sucd_calle_comentario, '|', '')

	declare @actualizar int = 1
	declare @sues_id_actual int
	declare @usuario_operador varchar(500)

	select top 1 @sues_id_actual=sucd_sues_id, @usuario_operador = sucd_usuario_operador
	from suceso_centro_despacho with (nolock) 
	where sucd_suce_id=@sucd_suce_id and sucd_cede_id=@sucd_cede_id

	if (@sucd_offline_id=1)
	begin		
		if ((@sues_id_actual is not null) and (@sues_id_actual>0))
		begin
			-- 1. Control de Estados. Si el estado de la carta en el server tiene un estado de peso superior al que viene como parametro, no se actualiza el SUCD !
			-- Si el estado es ABIERTA, nunca se actualiza la carta
			if (@sucd_sues_id=5)
			begin
				set @actualizar=0
			end else
			-- Si el estado es PENDIENTE, se actualiza la carta si el estado no es EN PROCESO, EN ESPERA DE CIERRE o CERRADO
			if ((@sucd_sues_id=1) and (@sues_id_actual in (2,3,4)))
			begin
				set @actualizar=0
			end else
			-- Si el estado es EN PROCESO, se actualiza la carta si el estado no es EN ESPERA DE CIERRE o CERRADO
			if ((@sucd_sues_id=2) and (@sues_id_actual in (3,4)))
			begin
				set @actualizar=0
			end else
			-- Si el estado es EN ESPERA DE CIERRE, se actualiza la carta si el estado no es CERRADO
			if ((@sucd_sues_id=3) and (@sues_id_actual in (4)))
			begin
				set @actualizar=0
			end
			if (@actualizar=1)
			begin
				-- 2. Si el usuario operador de la carta es un operador, no se actualiza el campo sucd_usuario_operador
				if ((@usuario_operador is not null) and (@usuario_operador<>''))
				begin
					if exists(select top 1 usin_id from mapsoft.dbo.usuarios_internet with(nolock) where lower(usin_usuario)=lower(@usuario_operador) and usin_rol911_id=2)
					begin
						set @sucd_usuario_operador = @usuario_operador
					end
				end
			end
		end		
	end else
	begin
		if (@sucd_sues_id in (1, 5))
		begin			
			if ((@sues_id_actual is not null) and (@sues_id_actual>0))
			begin
				-- Si el estado es ABIERTA, y el estado actual es distinto de ABIERTA
				if (@sucd_sues_id = 5) and (@sues_id_actual <> 5)
				begin
					set @sucd_sues_id = @sues_id_actual
					set @actualizar = 0
				end else
				-- Si el estado es PENDIENTE, y el estado actual EN PROCESO
				if ((@sucd_sues_id = 1) and (@sues_id_actual = 2))
				begin
					set @sucd_sues_id = @sues_id_actual
					set @actualizar = 0 
				end else
				if ((@sucd_sues_id=1) and (@sues_id_actual in (2,3,4)))
				begin
					set @sucd_sues_id = @sues_id_actual
					set @actualizar = 0
				end
			end	
		end	
	end
	
	if (@actualizar<>1) -- solo es distinto de 1, si es una sincronizacion offline, y no pasa los controles de estados
	begin
		update suceso_centro_despacho set sucd_fecha_actualizacion=@fecha where (sucd_suce_id=@sucd_suce_id) and (sucd_cede_id=@sucd_cede_id_anterior)
		select @sucd_suce_id as ID_INSERTADO, @fecha as FECHA_ACTUALIZACION
	end else
	begin
		if (@sucd_offline_fecha is null) 		set @sucd_offline_fecha = getdate()
		if (@sucd_fecha_aviso_reserva is null)	set @sucd_fecha_aviso_reserva = getdate()		
				
		/*Por si el parametro de tipo viene vacio*/
		if (((@sucd_suti_id is null) or (@sucd_suti_id<=0)) and (@sucd_subti_id>0))
			select @sucd_suti_id=subti_suti_id from suceso_subtipo with(nolock) where subti_id=@sucd_subti_id
		
		declare @sucd_sues_id_ant int
		declare @sucd_suti_id_ant int
		declare @sucd_subti_id_ant int
		declare @sucd_sure_id_ant int
		declare @sucd_prov_id_ant int
		declare @sucd_depar_id_ant int
		declare @sucd_loca_id_ant int
		declare @sucd_calle_ant varchar(255)	
		declare @sucd_numero_ant int
		declare @sucd_piso_ant varchar(5)
		declare @sucd_depto_ant varchar(5)
		declare @sucd_cuerpo_ant varchar(5)
		declare @sucd_calle_entre_1_auto_ant varchar(255)
		declare @sucd_calle_entre_2_auto_ant varchar(255)
		declare @sucd_calle_entre_1_manual_ant varchar(255)
		declare @sucd_calle_entre_2_manual_ant varchar(255)
		declare @sucd_cuadricula_ant varchar(50)
		declare @sucd_comisaria_ant varchar(50)
		declare @sucd_departamental_ant varchar(50)
		declare @sucd_id_gestion_cate_ant bigint
		declare @sucd_id_cate_ant bigint
		declare @sucd_usuario_operador_ant varchar(20)
		declare @sucd_calle_alias_ant varchar(255)
		declare @sucd_calle_comentario_ant varchar(max)
		declare @sucd_ref_id_ant bigint
		declare @sucd_ref_descripcion_ant varchar(2000)
		declare @sucd_ref_pais_id_ant bigint
		declare @sucd_ref_prov_id_ant bigint
		declare @sucd_ref_depar_id_ant bigint
		declare @sucd_ref_loca_id_ant bigint
		declare @sucd_hecho_relevante_ant bit
		declare @sucd_vcm_ant bit
		declare @suti_descripcion_ant varchar(255)
		declare @subti_descripcion_ant varchar(255)
		declare @supr_descripcion_ant varchar(255)
		declare @sure_descripcion_ant varchar(255)
		declare @sucd_confidencial_ant bit
		declare @sucd_latitud_ant float
		declare @sucd_longitud_ant float

		declare @suev_descripcion varchar(500)
		declare @cambio_de_ubicacion varchar(max)
		declare @cambio_de_ubicacion_nueva varchar(max)
							
		select  @sucd_suti_id_ant          = scd.sucd_suti_id,
			@sucd_sues_id_ant       	   = scd.sucd_sues_id,
			@sucd_subti_id_ant             = scd.sucd_subti_id,
			@sucd_sure_id_ant              = scd.sucd_sure_id,
			@sucd_prov_id_ant              = scd.sucd_prov_id,
			@sucd_depar_id_ant             = scd.sucd_depar_id,
			@sucd_loca_id_ant              = scd.sucd_loca_id,
			@sucd_calle_ant                = scd.sucd_calle,
			@sucd_calle_alias_ant          = scd.sucd_calle_alias,
			@sucd_numero_ant               = scd.sucd_numero,
			@sucd_piso_ant                 = scd.sucd_piso,
			@sucd_depto_ant                = scd.sucd_depto,
			@sucd_cuerpo_ant               = scd.sucd_cuerpo,
			@sucd_calle_entre_1_auto_ant   = scd.sucd_calle_entre_1_auto,
			@sucd_calle_entre_2_auto_ant   = scd.sucd_calle_entre_2_auto,
			@sucd_calle_entre_1_manual_ant = scd.sucd_calle_entre_1_manual,
			@sucd_calle_entre_2_manual_ant = scd.sucd_calle_entre_2_manual,
			@sucd_cuadricula_ant           = scd.sucd_cuadricula,
			@sucd_comisaria_ant            = scd.sucd_comisaria,
			@sucd_departamental_ant        = scd.sucd_departamental,
			@sucd_id_gestion_cate_ant      = scd.sucd_id_gestion_cate,
			@sucd_id_cate_ant              = scd.sucd_id_cate,
			@sucd_usuario_operador_ant     = scd.sucd_usuario_operador,
			@suti_descripcion_ant		   = st.suti_descripcion,
			@subti_descripcion_ant		   = sst.subti_descripcion,
			@supr_descripcion_ant		   = sp.supr_descripcion,
			@sure_descripcion_ant		   = sr.sure_descripcion,
			@sucd_ref_id_ant 			   = scd.sucd_ref_id,
			@sucd_ref_descripcion_ant	   = scd.sucd_ref_descripcion,
			@sucd_ref_pais_id_ant 		   = scd.sucd_ref_pais_id,
			@sucd_ref_prov_id_ant		   = scd.sucd_ref_prov_id,
			@sucd_ref_depar_id_ant		   = scd.sucd_ref_depar_id,
			@sucd_ref_loca_id_ant		   = scd.sucd_ref_loca_id,
			@sucd_hecho_relevante_ant 	   = scd.sucd_hecho_relevante,
			@sucd_calle_comentario_ant     = scd.sucd_calle_comentario,
			@sucd_vcm_ant				   = scd.sucd_vcm,
			@sucd_confidencial_ant		   = scd.sucd_confidencial,
			@sucd_latitud_ant			   = scd.sucd_latitud,
			@sucd_longitud_ant			   = scd.sucd_longitud
		from [suceso_centro_despacho] scd with (nolock)
		left join [suceso_tipo]      st with(nolock) on st.suti_id   = scd.sucd_suti_id
		left join [suceso_subtipo]   sst with(nolock) on sst.subti_id = scd.sucd_subti_id		 
		left join [suceso_prioridad] sp with(nolock) on sp.supr_id   = sst.subti_supr_id
		left join [suceso_resultado] sr with(nolock) on sr.sure_id   = scd.sucd_sure_id 
		where ([sucd_suce_id]=@sucd_suce_id) and 
			  ([sucd_cede_id]=@sucd_cede_id)
				
		declare @suti_descripcion_nuevo varchar(50)
		declare @subti_descripcion_nuevo varchar(50)
		declare @supr_descripcion_nuevo varchar(30)  

		if (isnull(@sucd_suti_id,0)>0) and (isnull(@sucd_subti_id,0)>0)
		begin
			select top 1 @suti_descripcion_nuevo=isnull(suti_descripcion,'') from suceso_tipo with(nolock) where suti_id=@sucd_suti_id
				
			select top 1 @subti_descripcion_nuevo=isnull(subti_descripcion,''), @supr_descripcion_nuevo=isnull(supr_descripcion,'')
			from suceso_subtipo with(nolock)
			left join suceso_prioridad with(nolock) on supr_id=subti_supr_id
			where subti_id=@sucd_subti_id
		end
					
		if (@sucd_sues_id in (1,2,3,4)) and ((@sucd_suti_id_ant<>@sucd_suti_id) or (@sucd_subti_id_ant<>@sucd_subti_id) /*or (@sucd_sure_id_ant<>@sucd_sure_id)*/) and
			(@sucd_suti_id_ant>0) and (@sucd_subti_id_ant>0) and (@sucd_suti_id_ant is not null) and (@sucd_subti_id_ant is not null) and (@sucd_sure_id_ant is not null)
		begin
			BEGIN TRY
				set @suev_descripcion = isnull(@suti_descripcion_ant,'')+' ('+isnull(@subti_descripcion_ant,'')+') Prioridad '+isnull(@supr_descripcion_ant,'')
				
				if ((@sucd_suti_id_ant<>@sucd_suti_id) or (@sucd_subti_id_ant<>@sucd_subti_id))
				begin			  
					set @suev_descripcion = @suev_descripcion + ' por ' 
					set @suev_descripcion = @suev_descripcion + @suti_descripcion_nuevo+' ('+@subti_descripcion_nuevo+') Prioridad '+@supr_descripcion_nuevo
				end
			
				exec sp_Insertar_SucesoEvento @comp_id, @usin_usuario, @codigo_unico_pc, @id_comp_modificada, 
					@sucd_suce_id, @sucd_cede_id, 23 /*TIPIFICACION DE SUCESO*/, @fecha, @suev_descripcion, @usuario, -1, -1, -1
			END TRY
			BEGIN CATCH
				exec [dbo].[sp_LoguearUltimoError] 'sp_ActualizarSuceso_CentroDespacho_Comparacion [Diferencia Tipificacion]' 
			END CATCH
				 
			declare @valor nvarchar(500)
			exec sp_getConfiguracion 'insertar_acciones_telefonica',@valor out
			if (@valor = '1') 
			begin
				BEGIN TRY
					insert into acciones_telefonica(actel_descripcion, actel_tabla, actel_tabla_id, actel_cede_id, actel_usuario, actel_tipo, actel_subtipo)
				  	values ('RETIPIFICACION', '', @sucd_id_gestion_cate_ant, @sucd_cede_id, @usuario, @sucd_suti_id, @subti_descripcion_ant)                                                                                
				END TRY
				BEGIN CATCH
					exec [dbo].[sp_LoguearUltimoError] 'sp_ActualizarSuceso_CentroDespacho_Comparacion [Registrar Accion Telefonica]' 
				END CATCH                                                                                  
			end
		end
			 
		if (@sucd_sues_id in (1,2,3,4)) and (@sucd_ref_descripcion_ant is not null) and (@sucd_ref_descripcion_ant<>'') and 
			((@sucd_ref_descripcion_ant<>@sucd_ref_descripcion) or (@sucd_ref_id_ant<>@sucd_ref_id) or (@sucd_ref_pais_id_ant<>@sucd_ref_pais_id) or (@sucd_ref_prov_id_ant<>@sucd_ref_prov_id) or
			 (@sucd_ref_depar_id_ant<>@sucd_ref_depar_id) or (@sucd_ref_loca_id_ant<>@sucd_ref_loca_id))
		begin
			BEGIN TRY
				set @suev_descripcion='Referencia Anterior: '+@sucd_ref_descripcion_ant
				if (@sucd_ref_id_ant>0) 
					set @suev_descripcion=@suev_descripcion+' [ref]'
				else if (@sucd_ref_loca_id_ant=0)
					set @suev_descripcion=@suev_descripcion+' [partido]'
				else if (@sucd_ref_depar_id_ant=0)
					set @suev_descripcion=@suev_descripcion+' [localidad]'

				exec [dbo].[sp_Insertar_SucesoEvento] @comp_id, @usin_usuario, @codigo_unico_pc, @id_comp_modificada, @sucd_suce_id, @sucd_cede_id, 46 /*EDICION DE REFERENCIA*/, @fecha, @suev_descripcion, @usuario, -1, -1, -1
			END TRY
			BEGIN CATCH
				exec [dbo].[sp_LoguearUltimoError] 'sp_ActualizarSuceso_CentroDespacho_Comparacion [Diferencia Referencia]' 
			END CATCH			 
		end

		if (@sucd_sues_id in (1,2,3,4)) and (@sucd_calle_ant is not null) and (@sucd_calle_ant<>'')
		begin
			set @cambio_de_ubicacion = ''
			set @cambio_de_ubicacion_nueva = ''
			if (@sucd_prov_id_ant<>@sucd_prov_id)
			begin
				set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Provincia: '+isnull((select top 1 prov_descripcion from provincia with(nolock) where prov_id=@sucd_prov_id_ant),'')
				set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Provincia: '+isnull((select top 1 prov_descripcion from provincia with(nolock) where prov_id=@sucd_prov_id),'')
			end

			if (@sucd_depar_id_ant<>@sucd_depar_id)
			begin
				set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Partido: '+isnull((select top 1 depar_descripcion from departamento with(nolock) where depar_id=@sucd_depar_id_ant),'')
				set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Partido: '+isnull((select top 1 depar_descripcion from departamento with(nolock) where depar_id=@sucd_depar_id),'')
			end

			if (@sucd_loca_id_ant<>@sucd_loca_id)
			begin
				set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Localidad: '+isnull((select top 1 loca_descripcion from localidad with(nolock) where loca_id=@sucd_loca_id_ant), '')
				set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Localidad: '+isnull((select top 1 loca_descripcion from localidad with(nolock) where loca_id=@sucd_loca_id),'')
			end

			if (@sucd_calle_ant<>@sucd_calle) or (@sucd_numero_ant<>@sucd_numero) or
				(@sucd_calle_alias_ant<>@sucd_calle_alias) or
				(@sucd_piso_ant<>@sucd_piso) or (@sucd_depto_ant<>@sucd_depto) or
				(@sucd_cuerpo_ant<>@sucd_cuerpo) or
				(@sucd_calle_entre_1_auto_ant<>@sucd_calle_entre_1_auto) or
				(@sucd_calle_entre_2_auto_ant<>@sucd_calle_entre_2_auto) or
				(@sucd_calle_entre_1_manual_ant<>@sucd_calle_entre_1_manual) or
				(@sucd_calle_entre_2_manual_ant<>@sucd_calle_entre_2_manual)
			begin
				set @cambio_de_ubicacion = @cambio_de_ubicacion + ' '+@sucd_calle_ant
				set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' '+@sucd_calle
				if (ltrim(rtrim(@sucd_calle_alias_ant))<>'') and (@sucd_calle_alias_ant is not null)
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' (Alias: '+@sucd_calle_alias_ant+')'
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' (Alias: '+@sucd_calle_alias+')'
				end
				set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Nº '+cast(@sucd_numero_ant as varchar(20))
				set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Nº '+cast(@sucd_numero as varchar(20))
					  
				if (ltrim(rtrim(@sucd_piso_ant))<>'')
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Piso '+@sucd_piso_ant
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Piso '+@sucd_piso
				end

				if (ltrim(rtrim(@sucd_depto_ant))<>'')
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Depto '+@sucd_depto_ant
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Depto '+@sucd_depto
				end

				if (ltrim(rtrim(@sucd_cuerpo_ant))<>'')
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Cuerpo '+@sucd_cuerpo_ant
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Cuerpo '+@sucd_cuerpo
				end

				if (ltrim(rtrim(@sucd_calle_entre_1_auto_ant))<>'') or (ltrim(rtrim(@sucd_calle_entre_2_auto_ant))<>'')
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' e/ '+@sucd_calle_entre_1_auto_ant
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' e/ '+@sucd_calle_entre_1_auto
					if (ltrim(rtrim(@sucd_calle_entre_2_auto_ant))<>'')
					begin
						set @cambio_de_ubicacion = @cambio_de_ubicacion + ' y ' + @sucd_calle_entre_2_auto_ant
						set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' y ' + @sucd_calle_entre_2_auto
					end
				end else
				if (ltrim(rtrim(@sucd_calle_entre_1_manual_ant))<>'') or (ltrim(rtrim(@sucd_calle_entre_2_manual_ant))<>'')
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' e/ '+@sucd_calle_entre_1_manual_ant
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' e/ '+@sucd_calle_entre_1_manual
					if (ltrim(rtrim(@sucd_calle_entre_2_manual_ant))<>'')
					begin
						set @cambio_de_ubicacion = @cambio_de_ubicacion + ' y ' + @sucd_calle_entre_2_manual_ant
						set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' y ' + @sucd_calle_entre_2_manual
					end
				end

				if (@sucd_cuadricula_ant<>@sucd_cuadricula) or
					(@sucd_comisaria_ant<>@sucd_comisaria) or
					(@sucd_departamental_ant<>@sucd_departamental)
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Cuadricula: '+@sucd_cuadricula_ant+' Comisaria: '+@sucd_comisaria_ant+' Distrital: '+@sucd_departamental_ant
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Cuadricula: '+@sucd_cuadricula+' Comisaria: '+@sucd_comisaria+' Distrital: '+@sucd_departamental
				end

				if (@sucd_calle_comentario_ant<>@sucd_calle_comentario)
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Comentario: '+@sucd_calle_comentario_ant
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Comentario: '+@sucd_calle_comentario
				end
							
				if (ltrim(rtrim(@cambio_de_ubicacion))='') and (ltrim(rtrim(@cambio_de_ubicacion_nueva))='') and 
					((abs(@sucd_latitud_ant-@sucd_latitud)>0.0000000000000001) or (abs(@sucd_longitud_ant-@sucd_longitud)>0.0000000000000001))
				begin
					set @cambio_de_ubicacion = @cambio_de_ubicacion + ' Latitud ' + CAST(@sucd_latitud_ant AS varchar(50)) + ' Longitud ' + CAST(@sucd_longitud_ant AS varchar(50));
					set @cambio_de_ubicacion_nueva = @cambio_de_ubicacion_nueva + ' Latitud ' + CAST(@sucd_latitud AS varchar(50)) + ' Longitud ' + CAST(@sucd_longitud AS varchar(50));
				end

				if (@cambio_de_ubicacion is not null) and (ltrim(rtrim(@cambio_de_ubicacion))<>'')
				begin
					BEGIN TRY
						set @suev_descripcion = 'Ubicacion Anterior: ' + ltrim(rtrim(@cambio_de_ubicacion)) + ' - Ubicacion Actual: ' + ltrim(rtrim(@cambio_de_ubicacion_nueva))
						exec [dbo].[sp_Insertar_SucesoEvento] @comp_id, @usin_usuario, @codigo_unico_pc, @id_comp_modificada, @sucd_suce_id, @sucd_cede_id, 24 /*REUBICACION DE SUCESO*/, @fecha, @suev_descripcion, @usuario, -1, -1, -1
					END TRY
					BEGIN CATCH
						exec [dbo].[sp_LoguearUltimoError] 'sp_ActualizarSuceso_CentroDespacho_Comparacion [Diferencia Ubicacion]'
					END CATCH                                           
				end
			end
		end

		if (@sucd_sues_id in (1,2,3,4)) and (@sucd_hecho_relevante_ant is not null) and (@sucd_hecho_relevante_ant<>@sucd_hecho_relevante)
		begin
			set @suev_descripcion = 'Seguimiento Anterior: '+iif((@sucd_hecho_relevante_ant=1),'Si','No')			
			exec [dbo].[sp_Insertar_SucesoEvento] @comp_id, @usin_usuario, @codigo_unico_pc, @id_comp_modificada, @sucd_suce_id, @sucd_cede_id, 71 /*CAMBIO DE SEGUIMIENTO*/, @fecha, @suev_descripcion, @usuario, -1, -1, -1
		end
			
		if (@sucd_sues_id in (1,2,3,4)) and (@sucd_vcm_ant is not null) and (@sucd_vcm_ant<>@sucd_vcm)
		begin
			set @suev_descripcion = 'VCM Anterior: '+iif((@sucd_vcm_ant=1),'Si','No')			
			exec [dbo].[sp_Insertar_SucesoEvento] @comp_id, @usin_usuario, @codigo_unico_pc, @id_comp_modificada, @sucd_suce_id, @sucd_cede_id, 72 /*CAMBIO DE VCM*/, @fecha, @suev_descripcion, @usuario, -1, -1, -1
		end

		if (@sucd_sues_id in (1,2,3,4)) and (@sucd_confidencial_ant is not null) and (@sucd_confidencial_ant<>@sucd_confidencial)
		begin
			set @suev_descripcion = 'Confidencialidad Anterior: '+iif((@sucd_confidencial_ant=1),'Si','No')
			exec [dbo].[sp_Insertar_SucesoEvento] @comp_id, @usin_usuario, @codigo_unico_pc, @id_comp_modificada, @sucd_suce_id, @sucd_cede_id, 36 /*CAMBIO DE CONFIDENCIALIDAD*/, @fecha, @suev_descripcion, @usuario, -1, -1, -1
		end

		--Controlar si se debe insertar evento de cierre
		if (@sucd_sues_id in (3,4)) and (@sucd_sues_id<>@sucd_sues_id_ant) and (@sucd_offline_id=0)
		begin
			declare @suev_descripcion_cierre varchar(500)

			set @suev_descripcion_cierre = 'Tipo/Subtipo: '+isnull(@suti_descripcion_nuevo,'')+' ('+isnull(@subti_descripcion_nuevo,'')+') '+
				'Prioridad: '+isnull(@supr_descripcion_nuevo,'')+' '+
				'Resultado de cierre: '+cast(iif(@sucd_sues_id=4, isnull(@sucd_cierre_supervisor,''), isnull(@sucd_cierre_despachador,'')) as varchar(max))

			if (@sucd_sues_id = 4)
			begin
				BEGIN TRY
					exec [dbo].[sp_Insertar_SucesoEvento] @comp_id, @usin_usuario, @codigo_unico_pc, @id_comp_modificada, @sucd_suce_id, @sucd_cede_id, 6 /*CIERRE DESPACHO*/, @fecha, @suev_descripcion_cierre, @usuario, -1, -1, -1
				END TRY
				BEGIN CATCH
					exec [dbo].[sp_LoguearUltimoError] 'sp_ActualizarSuceso_CentroDespacho_6.sp_Insertar_SucesoEvento (Cierre)'
				END CATCH                                        
	    	end else
	    	begin
	    		BEGIN TRY 
	        		exec [dbo].[sp_Insertar_SucesoEvento] @comp_id, @usin_usuario, @codigo_unico_pc, @id_comp_modificada, @sucd_suce_id, @sucd_cede_id, 5 /*DESPACHO EN ESPERA DE CIERRE*/, @fecha, @suev_descripcion_cierre, @usuario, -1, -1, -1          
	        	END TRY
				BEGIN CATCH
					exec [dbo].[sp_LoguearUltimoError] 'sp_ActualizarSuceso_CentroDespacho_6.sp_Insertar_SucesoEvento (Espera de Cierre)'
				END CATCH                                      
			end  
		end
		
		--Si cambio el valor de ID_CATE se actualiza en la tabla SUCESO y en la SUCESO_CENTRO_DESPACHO de los otros centros de despachos con el mismo SUCE_ID
		if ((@sucd_id_cate_ant <> @sucd_id_cate) or (@sucd_usuario_operador_ant <> @sucd_usuario_operador))
		begin
			if (@sucd_id_cate_ant <> @sucd_id_cate)
			begin
				update [suceso] set suce_id_cate=@sucd_id_cate where suce_id=@sucd_suce_id
			end

			if exists(select top 1 sucd_suce_id from suceso_centro_despacho with(nolock) where (sucd_suce_id=@sucd_suce_id) and (sucd_cede_id<>@sucd_cede_id))
			begin
				update suceso_centro_despacho
				set sucd_id_cate = @sucd_id_cate,
					sucd_usuario_operador = @sucd_usuario_operador,
					sucd_fecha_actualizacion = getdate()
				where (sucd_suce_id = @sucd_suce_id)
			end
		end

		/*Por si se quiere cambiar el Centro de Despacho -----------------*/
		if ((@sucd_cede_id_anterior<=0) or (@sucd_cede_id_anterior is null))
			set @sucd_cede_id_anterior = @sucd_cede_id
		else
		begin
			update [suceso_evento] set [suev_cede_id]=@sucd_cede_id, [suev_fecha_actualizacion]=getdate() where [suev_suce_id]=@sucd_suce_id and [suev_cede_id]=@sucd_cede_id_anterior;
			update [suceso_recurso] set [surec_cede_id]=@sucd_cede_id, [surec_fecha_actualizacion]=getdate() where [surec_suce_id]=@sucd_suce_id and [surec_cede_id]=@sucd_cede_id_anterior;
		end
		  
		set @fecha=getdate()
		update [suceso_centro_despacho] set
			   [sucd_cede_id]				= @sucd_cede_id,
			   [sucd_suti_id]               = @sucd_suti_id,
			   [sucd_subti_id]              = @sucd_subti_id,
			   [sucd_supr_id]               = @sucd_supr_id,
			   [sucd_sues_id]               = @sucd_sues_id,
			   [sucd_sure_id]               = @sucd_sure_id,
			   [sucd_prov_id]               = @sucd_prov_id,	
			   [sucd_depar_id]				= @sucd_depar_id,	
			   [sucd_loca_id]				= @sucd_loca_id,	
			   [sucd_latitud]				= @sucd_latitud,
			   [sucd_longitud]				= @sucd_longitud,	
			   [sucd_usuario_despachador]   = @sucd_usuario_despachador,
			   [sucd_usuario_supervisor]    = @sucd_usuario_supervisor,
			   [sucd_fecha_hora_ini]        = @sucd_fecha_hora_ini,
			   [sucd_fecha_hora_fin]        = @sucd_fecha_hora_fin,
			   [sucd_calle]                 = @sucd_calle,
			   [sucd_numero]                = @sucd_numero,
			   [sucd_numero_validado]       = @sucd_numero_validado,
			   [sucd_piso]                  = @sucd_piso,
			   [sucd_depto]                 = @sucd_depto,
			   [sucd_cuerpo]                = @sucd_cuerpo,
			   [sucd_calle_entre_1_auto]    = @sucd_calle_entre_1_auto,
			   [sucd_calle_entre_2_auto]    = @sucd_calle_entre_2_auto,
			   [sucd_altura_entre_1_auto]   = @sucd_altura_entre_1_auto,
			   [sucd_altura_entre_2_auto]   = @sucd_altura_entre_2_auto,
			   [sucd_calle_entre_1_manual]  = @sucd_calle_entre_1_manual,
			   [sucd_calle_entre_2_manual]  = @sucd_calle_entre_2_manual,
			   [sucd_altura_entre_1_manual] = @sucd_altura_entre_1_manual,
			   [sucd_altura_entre_2_manual] = @sucd_altura_entre_2_manual,
			   [sucd_cierre_despachador]    = @sucd_cierre_despachador,
			   [sucd_cierre_supervisor]     = @sucd_cierre_supervisor,
			   [sucd_fecha_actualizacion]   = @fecha,
			   [sucd_interseccion_valida]   = @sucd_interseccion_valida,
			   [sucd_cuadricula]		    = @sucd_cuadricula,
			   [sucd_comisaria]				= @sucd_comisaria,
			   [sucd_departamental]			= @sucd_departamental,
			   [sucd_sub_cede_id]           = @sucd_sub_cede_id,
			   [sucd_suce_id_asociado]      = @sucd_suce_id_asociado,
			   [sucd_calle_comentario]      = @sucd_calle_comentario,
			   [sucd_hecho_relevante]       = @sucd_hecho_relevante,
			   [sucd_emal_id]               = @sucd_emal_id,
			   [sucd_detenidos_mayores]     = @sucd_detenidos_mayores,
			   [sucd_detenidos_menores]     = @sucd_detenidos_menores,
			   [sucd_secuestro_vehiculos]   = @sucd_secuestro_vehiculos,
			   [sucd_secuestro_armas]       = @sucd_secuestro_armas,
			   [sucd_secuestro_drogas]      = @sucd_secuestro_drogas,
			   [sucd_hito_id]               = @sucd_hito_id, 
			   [sucd_id_cate]               = @sucd_id_cate,
			   [sucd_movi_id]			    = @sucd_movi_id,
			   [sucd_usuario_operador]      = @sucd_usuario_operador,
			   [sucd_cede_id_derivacion]	= @sucd_cede_id_derivacion,
			   [sucd_sub_cede_id_derivacion]= @sucd_sub_cede_id_derivacion,
			   [sucd_confidencial]          = @sucd_confidencial,
			   [sucd_tomado]				= @sucd_tomado,
			   [sucd_cede_id_anterior]      = @sucd_cede_id_anterior,
			   [sucd_fecha_aviso_reserva]   = @sucd_fecha_aviso_reserva,
			   [sucd_es_deslinde]			= @sucd_es_deslinde,
			   [sucd_victimas]				= @sucd_victimas,
			   [sucd_heridos]				= @sucd_heridos,
			   [sucd_es_alerta]			    = @sucd_es_alerta,
			   [sucd_cuartel_bomberos]	    = @sucd_cuartel_bomberos,
			   [sucd_jurisdiccion_salud]    = @sucd_jurisdiccion_salud,
			   [sucd_calle_alias]           = @sucd_calle_alias,
			   [sucd_ref_id]				= @sucd_ref_id,
			   [sucd_ref_descripcion]		= @sucd_ref_descripcion,
			   [sucd_ref_pais_id]			= @sucd_ref_pais_id,			  
			   [sucd_ref_prov_id]			= @sucd_ref_prov_id,
			   [sucd_ref_depar_id]			= @sucd_ref_depar_id,
			   [sucd_ref_loca_id]			= @sucd_ref_loca_id,			   
			   [sucd_vcm]					= @sucd_vcm
		where  ([sucd_suce_id]=@sucd_suce_id) and ([sucd_cede_id]=@sucd_cede_id_anterior)		       
	end

	select @sucd_suce_id as ID_INSERTADO, @fecha as FECHA_ACTUALIZACION
END
