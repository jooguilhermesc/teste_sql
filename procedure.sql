USE [corporerm]
GO

/****** Object:  StoredProcedure [dbo].[SP_ProducaoEB_DN]    Script Date: 27/04/2023 19:21:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[SP_ProducaoEB_DN]
	@MES VARCHAR(2),
	@ANO VARCHAR(4)
AS
BEGIN
/********************************************************************
*	AUTOR:			Ricardo de Fran�a Dantas
*	DATA:			12/04/2023
*	DESCRICAO:		MIT021 - SCAE - Vers�o 25.1
*	VERS�O:			1 
*********************************************************************/

	SELECT 
		/*UF*/
		GCOLIGADA.ESTADO uf,

		/*Curso*/
		CASE 
			WHEN SCURSO.CODMODALIDADECURSO <> 3 THEN LEFT(ISNULL(SHABILITACAOCOMPL.CODCURSOSCAE,CONCAT(SCURSO.CODCURSO,SGRADE.CODHABILITACAO,SGRADE.CODGRADE)),28)
			ELSE LEFT(ISNULL(SHABILITACAOCOMPL.CODCURSOSCAE,CONCAT(SCURSO.CODCURSO,SGRADE.CODGRADE)),30)
		END codCurso,
		SHABILITACAOCOMPL.CODSERVICOSCAE codServico,
		SHABILITACAOCOMPL.CODTIPOPORTFOLIO codTipoPortfolio,
		CASE
			WHEN SHABILITACAOCOMPL.TIPORTFOLIO = 'N' THEN SHABILITACAOCOMPL.CODPORTFOLION
			WHEN SHABILITACAOCOMPL.TIPORTFOLIO = 'R' THEN SHABILITACAOCOMPL.CODPORTFOLIOR
		END codPortfolio,
		LEFT(SCURSO.NOME, 256) nomCurso,
		LEFT(SCURSO.NOME, 256) desCurso,
		CASE
			WHEN SCURSO.CODMODALIDADECURSO <> 3 THEN SGRADE.CARGAHORARIA
			ELSE LEFT(SGRADE.CARGAHORARIA, 4)
		END numCargaHorariaHora,
		CASE
			WHEN SCURSO.CODMODALIDADECURSO <> 3 THEN SGRADE.CARGAHORARIA
			ELSE LEFT(SGRADE.CARGAHORARIA * 60, 4)
		END numCargaHorariaMinuto,
		'CR' desCentroResp,
		CASE
			WHEN SCURSO.CODMODALIDADECURSO <> 3 THEN SGRADE.STATUS 
			ELSE 1
		END indAtivo, 

		/*Unidade*/
		ISNULL(DFILIAL.CAMPOLIVRE1,GFILIAL.CODFILIAL) codUnidade,
	
		/*Turma*/
		ISNULL(STURMACOMPL.CODTURMASCAE,CONCAT(STURMA.CODFILIAL,STURMA.CODTURMA,SPLETIVO.CODPERLET)) codTurma,
		STURMA.TIPOMEDIACAO codModalidade,
		ISNULL(STURMA.NOME,STURMA.CODTURMA) nomTurma,
		STURMA.DTINICIAL datInicio,
		CASE
			WHEN SCURSO.CODMODALIDADECURSO <> 3 THEN STURMA.DTFINAL
			ELSE STURMACOMPL.DATAFINALTURMA
		END datTermino,
		STURMA.MAXALUNOS numVagas,
		STURMACOMPL.EMPRESAP cnpjInstituicaoParceira,
		
		/*Matr�cula*/
		ISNULL(SMATRICPLCOMPL.CODMATRICULASCAE,CONCAT(STURMA.IDFT,SALUNO.RA)) codMatricula,
		SMATRICPLCOMPL.EBEP indEbep,
		SMATRICPLCOMPL.TEMPOINTEGRAL indTempoIntegral,
		SMATRICPLCOMPL.VIRAVIDA IndViravida,
		SMATRICPLCOMPL.CODFINANC codFinanciamento,
		PPESSOA.GRAUINSTRUCAO codEscolaridade,
		SMATRICPL.CODSTATUS codSituacao,
		SMATRICPLCOMPL.CATEGORIA codVinculo,
		(SELECT
			datEfetivacaoMatricula
		FROM [dbo].[FN_RETORNA_DATA_MOV_MATRICULA_EB](SMATRICPL.CODCOLIGADA,SMATRICPL.IDPERLET,SMATRICPL.IDHABILITACAOFILIAL,SMATRICPL.RA)) datEfetivacaoMatricula,
		(SELECT
			datEfetivacaoReconhecimento
		FROM [dbo].[FN_RETORNA_DATA_MOV_MATRICULA_EB](SMATRICPL.CODCOLIGADA,SMATRICPL.IDPERLET,SMATRICPL.IDHABILITACAOFILIAL,SMATRICPL.RA)) datEfetivacaoReconhecimento,
		(SELECT
			datMovimentacao
		FROM [dbo].[FN_RETORNA_DATA_MOV_MATRICULA_EB](SMATRICPL.CODCOLIGADA,SMATRICPL.IDPERLET,SMATRICPL.IDHABILITACAOFILIAL,SMATRICPL.RA)) datMovimentacao,
		CASE SSTATUS.DESCRICAO
			WHEN 'Cancelado' THEN 1
			ELSE 0
		END indExclusao,
		CASE SMATRICPLCOMPL.TIPODOCUMENTO
			WHEN 'CEI' THEN SMATRICPLCOMPL.CEIEMPRESA
			WHEN 'CNPJ' THEN SMATRICPLCOMPL.CNPJEMPRESA
		END numCnpjVinculo,
		SMATRICPLCOMPL.NOMEEMPRESA nomeRazaoSocialIndustria,
		CICLO.CODCLIENTE codCiclo,
		(SELECT
			horaReconhecimentoSaberes
		FROM [dbo].[FN_RETORNA_DATA_MOV_MATRICULA_EB](SMATRICPL.CODCOLIGADA,SMATRICPL.IDPERLET,SMATRICPL.IDHABILITACAOFILIAL,SMATRICPL.RA)) horaReconhecimentoSaberes,
		(SELECT [dbo].[FN_HORA_ALUNO_PRESENCIAL_EB] (
			SMATRICPL.CODCOLIGADA
			,SMATRICPL.IDPERLET
			,SMATRICPL.IDHABILITACAOFILIAL
			,STURMADISC.IDTURMADISC
			,SMATRICPL.RA
			,SHABILITACAOFILIAL.CODCURSO
			,STURMADISC.TIPO
			,@MES
			,@ANO)
		) horaDestinada,
		IIF(SSTATUS.DESCRICAO = 'Cancelada',1,0) horaDestinada,
	
		/*ESTUDANTE*/
		ISNULL(SALUNOCOMPL.CODALUNOSCAE, SALUNO.RA) codEstudante,
		PPESSOA.NOME nomEstudante,
		CONVERT(date, PPESSOA.DTNASCIMENTO) AS datNascimento,
		PPESSOA.SEXO sexo,
		PPESSOA.EMAIL desEmail,
		PPESSOA.CARTIDENTIDADE numRegistroGeral,
		PPESSOA.ORGEMISSORIDENT sigOrgaoExpeditor,
		PESSOA_PAI.NOME nomPaiResp,
		PPESSOA.TELEFONE1 numTelefone,
		PPESSOA.TELEFONE2 numCelular,
		PPESSOA.CEP numCep,
		PPESSOA.RUA endLogradouro,
		PPESSOA.COMPLEMENTO endComplemento,
		PPESSOA.NUMERO endNumero,
		PPESSOA.BAIRRO nomBairro,
		CASE
			WHEN PPESSOA.ESTADOCIVIL = 'S' THEN 1
			WHEN PPESSOA.ESTADOCIVIL = 'C' THEN 2
			WHEN PPESSOA.ESTADOCIVIL = 'I' OR  PPESSOA.ESTADOCIVIL = 'P' THEN 3
			WHEN PPESSOA.ESTADOCIVIL = 'V' THEN 4
		END codEstadoCivil,
		ZSCAEMUNICIPIO.CODIGO codMunicipio,
		PESSOA_MAE.NOME nomMae,
		PPESSOA.CPF numCpf,
		SALUNOCOMPL.NIT numNIT,
		CASE
			WHEN PPESSOA.NACIONALIDADE = 10 THEN 'B'
			ELSE 'E'
		END indBrasileiro,
		FCFO.NOME nomeResponsavelLegal,
	
		/*Disciplina*/
		SDISCGRADECOMPL.DISCEJA codDisciplina,
		(SELECT datEfetivacaoMatriculaDisciplina FROM [dbo].[FN_RETORNA_DATA_MOV_MAT_DISC_EB] (
			SMATRICPL.CODCOLIGADA, 
			SMATRICPL.IDPERLET,
			SMATRICPL.IDHABILITACAOFILIAL,
			SMATRICULA.IDTURMADISC,
			SMATRICPL.RA
		)) datEfetivacaoMatriculaDisciplina,
		(SELECT datMovimentacaoDisciplina FROM [dbo].[FN_RETORNA_DATA_MOV_MAT_DISC_EB] (
			SMATRICPL.CODCOLIGADA, 
			SMATRICPL.IDPERLET,
			SMATRICPL.IDHABILITACAOFILIAL,
			SMATRICULA.IDTURMADISC,
			SMATRICPL.RA
		)) datMovimentacaoDisciplina,
		CASE 
			WHEN SHABILITACAOFILIAL.CODCURSO IN ('EJA PRO','NOVA EJA') THEN SMATRICULA.CODSTATUS
			ELSE NULL
		END codSituacaoDisciplina,
		CASE 
			WHEN SHABILITACAOFILIAL.CODCURSO IN ('EJA PRO','NOVA EJA') AND ISNULL(SMATRICULA.CODSTATUSRES,SMATRICULA.CODSTATUS) = 72 THEN 2
			WHEN SHABILITACAOFILIAL.CODCURSO IN ('EJA PRO','NOVA EJA') AND ISNULL(SMATRICULA.CODSTATUSRES,SMATRICULA.CODSTATUS) IN (2,39) THEN 1
			ELSE NULL
		END codTipoAvaliacao
	FROM SMATRICPL WITH (NOLOCK)
	LEFT JOIN STURMA WITH (NOLOCK)
		ON SMATRICPL.CODCOLIGADA = STURMA.CODCOLIGADA
		AND SMATRICPL.CODFILIAL = STURMA.CODFILIAL
		AND SMATRICPL.CODTURMA = STURMA.CODTURMA
		AND SMATRICPL.IDPERLET = STURMA.IDPERLET
	INNER JOIN SMATRICULA WITH (NOLOCK)
		ON SMATRICULA.CODCOLIGADA = SMATRICPL.CODCOLIGADA
		AND SMATRICULA.IDPERLET = SMATRICPL.IDPERLET
		AND SMATRICULA.IDHABILITACAOFILIAL = SMATRICPL.IDHABILITACAOFILIAL
		AND SMATRICULA.RA = SMATRICPL.RA
	LEFT JOIN SALUNO WITH (NOLOCK)
		ON SMATRICPL.CODCOLIGADA = SALUNO.CODCOLIGADA
		AND SMATRICPL.RA = SALUNO.RA
	LEFT JOIN SSTATUS WITH (NOLOCK)
		ON SMATRICPL.CODCOLIGADA = SSTATUS.CODCOLIGADA
		AND SMATRICPL.CODSTATUS = SSTATUS.CODSTATUS
	LEFT JOIN PPESSOA WITH (NOLOCK)
		ON SALUNO.CODPESSOA = PPESSOA.CODIGO
	LEFT JOIN STURMACOMPL WITH (NOLOCK)
		ON STURMACOMPL.CODCOLIGADA = STURMA.CODCOLIGADA
		AND STURMACOMPL.CODFILIAL = STURMA.CODFILIAL
		AND STURMACOMPL.CODTURMA = STURMA.CODTURMA
		AND STURMACOMPL.IDPERLET = STURMA.IDPERLET
	LEFT JOIN SHABILITACAOFILIAL WITH (NOLOCK)
		ON SHABILITACAOFILIAL.CODCOLIGADA = SMATRICPL.CODCOLIGADA
		AND SHABILITACAOFILIAL.IDHABILITACAOFILIAL = SMATRICPL.IDHABILITACAOFILIAL
	LEFT JOIN SGRADE WITH (NOLOCK)
		ON SHABILITACAOFILIAL.CODCOLIGADA = SGRADE.CODCOLIGADA
		AND SHABILITACAOFILIAL.CODCURSO = SGRADE.CODCURSO
		AND SHABILITACAOFILIAL.CODHABILITACAO = SGRADE.CODHABILITACAO
		AND SHABILITACAOFILIAL.CODGRADE = SGRADE.CODGRADE
	LEFT JOIN SHABILITACAO WITH (NOLOCK)
		ON SHABILITACAOFILIAL.CODCOLIGADA = SHABILITACAO.CODCOLIGADA
		AND SHABILITACAOFILIAL.CODCURSO = SHABILITACAO.CODCURSO
		AND SHABILITACAOFILIAL.CODHABILITACAO = SHABILITACAO.CODHABILITACAO
	LEFT JOIN SCURSO WITH (NOLOCK)
		ON SCURSO.CODCOLIGADA = SHABILITACAO.CODCOLIGADA
		AND SCURSO.CODCURSO = SHABILITACAO.CODCURSO
	LEFT JOIN SMODALIDADECURSO WITH (NOLOCK)
		ON SCURSO.CODCOLIGADA = SMODALIDADECURSO.CODCOLIGADA
		AND SCURSO.CODMODALIDADECURSO = SMODALIDADECURSO.CODMODALIDADECURSO
	LEFT JOIN GFILIAL WITH (NOLOCK)
		ON GFILIAL.CODCOLIGADA = SMATRICPL.CODCOLIGADA
		AND GFILIAL.CODFILIAL = SMATRICPL.CODFILIAL
	LEFT JOIN DFILIAL WITH (NOLOCK)
		ON GFILIAL.CODCOLIGADA = DFILIAL.CODCOLIGADA
		AND GFILIAL.CODFILIAL = DFILIAL.CODFILIAL
	LEFT JOIN SMATRICPLCOMPL WITH (NOLOCK)
		ON SMATRICPLCOMPL.CODCOLIGADA = SMATRICPL.CODCOLIGADA
		AND SMATRICPLCOMPL.IDPERLET = SMATRICPL.IDPERLET
		AND SMATRICPLCOMPL.IDHABILITACAOFILIAL = SMATRICPL.IDHABILITACAOFILIAL
		AND SMATRICPLCOMPL.RA = SMATRICPL.RA
	LEFT JOIN STURMADISC WITH (NOLOCK)
		ON STURMADISC.CODCOLIGADA = SMATRICULA.CODCOLIGADA
		AND STURMADISC.IDTURMADISC = SMATRICULA.IDTURMADISC
	LEFT JOIN SPLETIVO WITH (NOLOCK)
		ON SPLETIVO.CODCOLIGADA = SMATRICPL.CODCOLIGADA
		AND SPLETIVO.IDPERLET = SMATRICPL.IDPERLET
	LEFT JOIN GCOLIGADA WITH (NOLOCK)
		ON GCOLIGADA.CODCOLIGADA = SHABILITACAOFILIAL.CODCOLIGADA
	LEFT JOIN SHABILITACAOCOMPL WITH (NOLOCK)
		ON SHABILITACAOCOMPL.CODCOLIGADA = SHABILITACAO.CODCOLIGADA
		AND SHABILITACAOCOMPL.CODCURSO = SHABILITACAO.CODCURSO
		AND SHABILITACAOCOMPL.CODHABILITACAO = SHABILITACAO.CODHABILITACAO
	LEFT JOIN SALUNOCOMPL WITH (NOLOCK)
		ON SALUNOCOMPL.CODCOLIGADA = SALUNO.CODCOLIGADA
		AND SALUNOCOMPL.RA = SALUNO.RA
	LEFT JOIN VFILIACAO PAI WITH (NOLOCK)
		ON PPESSOA.CODIGO = PAI.CODPESSOAFILHO
		AND PAI.TIPORELACIONAMENTO = 'P'
	LEFT JOIN PPESSOA PESSOA_PAI
		ON PESSOA_PAI.CODIGO = PAI.CODPESSOAFILIACAO
	LEFT JOIN VFILIACAO MAE WITH (NOLOCK)
		ON PPESSOA.CODIGO = MAE.CODPESSOAFILHO
		AND MAE.TIPORELACIONAMENTO = 'P'
	LEFT JOIN PPESSOA PESSOA_MAE
		ON PESSOA_MAE.CODIGO = MAE.CODPESSOAFILIACAO
	LEFT JOIN SDISCGRADE WITH (NOLOCK)
		ON SDISCGRADE.CODCOLIGADA = SGRADE.CODCOLIGADA
		AND SDISCGRADE.CODDISC = STURMADISC.CODDISC
		AND SDISCGRADE.CODGRADE = SGRADE.CODGRADE
		AND SDISCGRADE.CODHABILITACAO = SGRADE.CODHABILITACAO
	LEFT JOIN SDISCGRADECOMPL WITH (NOLOCK)
		ON SDISCGRADECOMPL.CODCOLIGADA = SDISCGRADE.CODCOLIGADA
		AND SDISCGRADECOMPL.CODCURSO = SDISCGRADE.CODCURSO
		AND SDISCGRADECOMPL.CODHABILITACAO = SDISCGRADE.CODHABILITACAO
		AND SDISCGRADECOMPL.CODGRADE = SDISCGRADE.CODGRADE
		AND SDISCGRADECOMPL.CODDISC = SDISCGRADE.CODDISC
	LEFT JOIN GCONSIST CICLO WITH (NOLOCK)
		ON CICLO.CODCOLIGADA = SMATRICPL.CODCOLIGADA
		AND CICLO.DESCRICAO = CONCAT(@ANO,'-',@MES)
		AND CICLO.APLICACAO = 'S'
		AND CICLO.CODTABELA = 'CODCICLO'
	LEFT JOIN GMUNICIPIO WITH (NOLOCK)
		ON GMUNICIPIO.CODMUNICIPIO = PPESSOA.CODMUNICIPIO
		AND GMUNICIPIO.CODETDMUNICIPIO = PPESSOA.ESTADO
	LEFT JOIN ZSCAEMUNICIPIO WITH (NOLOCK)
		ON ZSCAEMUNICIPIO.MUNICIPIO = GMUNICIPIO.NOMEMUNICIPIO
		AND ZSCAEMUNICIPIO.UF = GMUNICIPIO.CODETDMUNICIPIO
	LEFT JOIN FCFO WITH (NOLOCK)
		ON FCFO.CODCOLIGADA = SALUNO.CODCOLIGADA
		AND FCFO.CODCFO = SALUNO.CODCFO
	
	WHERE SMATRICPL.CODCOLIGADA = 2
		AND SMATRICPL.CODSTATUS NOT IN (4)
		AND SCURSO.CODMODALIDADECURSO NOT IN (95,96,97,98,99) /*ECO*/
		AND MONTH(STURMA.DTINICIAL) <= @MES
		AND YEAR(STURMA.DTINICIAL) <= @ANO
		AND MONTH(STURMA.DTFINAL) >= @MES
		AND YEAR(STURMA.DTFINAL) >= @ANO
END
GO


