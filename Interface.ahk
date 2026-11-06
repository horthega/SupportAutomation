#Requires AutoHotkey v2.0

; ============================================
; SUPPORTAUTOMATION — INTERFACE E PREFERÊNCIAS
; ============================================

AppVersion := "2.2.1"

SA_PastaConfiguracoes := A_AppData "\SupportAutomation"
SA_ArquivoConfiguracoes := SA_PastaConfiguracoes "\config.ini"

SA_JanelaPrincipal := 0
SA_JanelaPersonalizacao := 0 ; Mantido por compatibilidade até revisar o arquivo principal
SA_CamposPersonalizacao := Map()

SA_BtnSons := 0
SA_BtnAvisos := 0
SA_BtnWindows := 0

SA_ControlesPrincipal := []
SA_ControlesMensagens := []
SA_ControleVersao := 0

; Valores padrão
AvisosAtivos := true
SonsAtivos := true
IniciarComWindows := false

; Carrega as preferências salvas pelo usuário
CarregarConfiguracoes()


; ============================================
; CARREGAR E SALVAR CONFIGURAÇÕES
; ============================================

CarregarConfiguracoes() {
    global SA_PastaConfiguracoes, SA_ArquivoConfiguracoes
    global AvisosAtivos, SonsAtivos, IniciarComWindows
    global NomeAtendente, MensagemFinalizacao
    global frase1, frase2, frase3

    if !DirExist(SA_PastaConfiguracoes)
        DirCreate(SA_PastaConfiguracoes)

    if !FileExist(SA_ArquivoConfiguracoes)
        return

    AvisosAtivos := (
        IniRead(
            SA_ArquivoConfiguracoes,
            "Preferencias",
            "AvisosAtivos",
            "1"
        ) = "1"
    )

    SonsAtivos := (
        IniRead(
            SA_ArquivoConfiguracoes,
            "Preferencias",
            "SonsAtivos",
            "1"
        ) = "1"
    )

    IniciarComWindows := (
        IniRead(
            SA_ArquivoConfiguracoes,
            "Preferencias",
            "IniciarComWindows",
            "0"
        ) = "1"
    )

    NomeAtendente := TextoDeConfig(
        IniRead(
            SA_ArquivoConfiguracoes,
            "Personalizacao",
            "NomeAtendente",
            TextoParaConfig(NomeAtendente)
        )
    )

    MensagemFinalizacao := TextoDeConfig(
        IniRead(
            SA_ArquivoConfiguracoes,
            "Personalizacao",
            "MensagemFinalizacao",
            TextoParaConfig(MensagemFinalizacao)
        )
    )

    frase1 := TextoDeConfig(
        IniRead(
            SA_ArquivoConfiguracoes,
            "Personalizacao",
            "Frase1",
            TextoParaConfig(frase1)
        )
    )

    frase2 := TextoDeConfig(
        IniRead(
            SA_ArquivoConfiguracoes,
            "Personalizacao",
            "Frase2",
            TextoParaConfig(frase2)
        )
    )

    frase3 := TextoDeConfig(
        IniRead(
            SA_ArquivoConfiguracoes,
            "Personalizacao",
            "Frase3",
            TextoParaConfig(frase3)
        )
    )
}


SalvarConfiguracoes() {
    global SA_PastaConfiguracoes, SA_ArquivoConfiguracoes
    global AvisosAtivos, SonsAtivos, IniciarComWindows
    global NomeAtendente, MensagemFinalizacao
    global frase1, frase2, frase3

    if !DirExist(SA_PastaConfiguracoes)
        DirCreate(SA_PastaConfiguracoes)

    ; Preferências gerais
    IniWrite(
        AvisosAtivos ? "1" : "0",
        SA_ArquivoConfiguracoes,
        "Preferencias",
        "AvisosAtivos"
    )

    IniWrite(
        SonsAtivos ? "1" : "0",
        SA_ArquivoConfiguracoes,
        "Preferencias",
        "SonsAtivos"
    )

    IniWrite(
        IniciarComWindows ? "1" : "0",
        SA_ArquivoConfiguracoes,
        "Preferencias",
        "IniciarComWindows"
    )

    ; Mensagens personalizadas
    IniWrite(
        TextoParaConfig(NomeAtendente),
        SA_ArquivoConfiguracoes,
        "Personalizacao",
        "NomeAtendente"
    )

    IniWrite(
        TextoParaConfig(MensagemFinalizacao),
        SA_ArquivoConfiguracoes,
        "Personalizacao",
        "MensagemFinalizacao"
    )

    IniWrite(
        TextoParaConfig(frase1),
        SA_ArquivoConfiguracoes,
        "Personalizacao",
        "Frase1"
    )

    IniWrite(
        TextoParaConfig(frase2),
        SA_ArquivoConfiguracoes,
        "Personalizacao",
        "Frase2"
    )

    IniWrite(
        TextoParaConfig(frase3),
        SA_ArquivoConfiguracoes,
        "Personalizacao",
        "Frase3"
    )
}


; Codifica quebras de linha para preservar mensagens no arquivo INI
TextoParaConfig(texto) {
    texto := StrReplace(texto, "%", "%25")
    texto := StrReplace(texto, "`r`n", "%0D%0A")
    texto := StrReplace(texto, "`n", "%0A")
    texto := StrReplace(texto, "`r", "%0D")

    return texto
}


TextoDeConfig(texto) {
    texto := StrReplace(texto, "%0D%0A", "`r`n")
    texto := StrReplace(texto, "%0D", "`r")
    texto := StrReplace(texto, "%0A", "`n")
    texto := StrReplace(texto, "%25", "%")

    return texto
}


; BANDEJA DO WINDOWS
InicializarInterface() {
    A_TrayMenu.Delete()

    A_TrayMenu.Add(
        "Abrir configurações",
        (*) => MostrarJanelaPrincipal()
    )

    A_TrayMenu.Add(
        "Recarregar",
        (*) => Reload()
    )

    A_TrayMenu.Add(
        "Sair do SupportAutomation",
        (*) => ExitApp()
    )

    ; Quando iniciado com o Windows, fica em segundo plano
    iniciarOculto := false

    for argumento in A_Args {
        if (argumento = "--iniciar-fundo") {
            iniciarOculto := true
            break
        }
    }

    if !iniciarOculto
        MostrarJanelaPrincipal()
}


; ============================================
; JANELA ÚNICA — SUPPORTAUTOMATION
; ============================================

MostrarJanelaPrincipal() {
    global SA_JanelaPrincipal
    global SA_ControleVersao
    global SA_ControlesPrincipal, SA_ControlesMensagens

    ; Cria a janela e seus controles apenas na primeira abertura.
    if !IsObject(SA_JanelaPrincipal) {
        janela := Gui("+MinSize620x480", "Configurações")
        janela.BackColor := "FFFFFF"

        ; Ícone de configurações à esquerda do título
        janela.AddPicture(
            "x22 y33 w26 h26 BackgroundTrans",
            A_ScriptDir "\Imagens\icone_configuracoes.png"
        )

        ; Título do aplicativo
        janela.SetFont("s22 Bold c202124", "Segoe UI")
        janela.AddText(
            "x59 y23 w350 h40 BackgroundTrans",
            "SupportAutomation"
        )

        ; Fundo arredondado do selo da versão
        SA_FundoVersao := janela.AddPicture(
            "x502 y37 w90 h19",
            A_ScriptDir "\Imagens\fundo_versao.png"
        )

        ; Texto da versão por cima do fundo
        janela.SetFont("s9 c266d2d", "Segoe UI Semibold")
        SA_ControleVersao := janela.AddText(
            "x502 y37 w90 h19 Center +0x200 BackgroundTrans",
            "Versão " AppVersion
        )

        janela.AddText(
            "x26 y80 w568 h1 BackgroundE5E7EB",
            ""
        )

        ; Cria as duas telas dentro da mesma janela
        SA_ControlesPrincipal := []
        SA_ControlesMensagens := []

        MontarTelaPrincipal(janela)
        MontarTelaMensagens(janela)

        janela.OnEvent("Close", OcultarJanelaPrincipal)
        SA_JanelaPrincipal := janela
    }

    ; Este caminho é usado tanto na primeira abertura quanto ao reabrir pelo menu.
    TrocarTelaInterface("principal")

}

; ============================================
; CONTEÚDO DA TELA PRINCIPAL
; ============================================

MontarTelaPrincipal(janela) {
    global SA_ControlesPrincipal
    global SA_BtnSons, SA_BtnAvisos, SA_BtnWindows
    global SonsAtivos, AvisosAtivos, IniciarComWindows

    c := SA_ControlesPrincipal

    ; ========================================
    ; PERSONALIZAÇÃO
    ; ========================================

    ; Ícone de personalização
    c.Push(janela.AddPicture(
        "x25 y102 w23 h23 BackgroundTrans",
        A_ScriptDir "\Imagens\Personalizacao.png"
    ))

    ; Título
    janela.SetFont("s14 Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x55 y100 w390 h30 BackgroundTrans",
        "Personalização"
    ))

    janela.SetFont("s10 Norm c606060", "Segoe UI")
    c.Push(janela.AddText(
        "x29 y132 w385 h24 BackgroundTrans",
        "Personalize as respostas utilizadas nos atalhos"
    ))

    janela.SetFont("s10 Bold c202124", "Segoe UI")

    btnPersonalizar := janela.AddButton(
        "x426 y115 w165 h34",
        "Editar mensagens"
    )

    c.Push(btnPersonalizar)
    btnPersonalizar.OnEvent(
        "Click",
        (*) => MostrarJanelaPersonalizacao()
    )

    c.Push(janela.AddText(
        "x26 y173 w568 h1 BackgroundE5E7EB",
        ""
    ))

    ; ========================================
    ; EFEITOS SONOROS
    ; ========================================

    ; Ícone de efeitos sonoros
    c.Push(janela.AddPicture(
        "x29 y193 w20 h20 BackgroundTrans",
        A_ScriptDir "\Imagens\som.png"
    ))

    ; Título
    janela.SetFont("s14 Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x55 y190 w350 h24 BackgroundTrans",
        "Efeitos sonoros"
    ))

    ; subtítulo
    janela.SetFont("s10 Norm c606060", "Segoe UI")
    c.Push(janela.AddText(
        "x29 y216 w390 h22 BackgroundTrans",
        "Reproduzir sons de confirmação e alertas."
    ))

    SA_BtnSons := CriarInterruptor(
        janela, 562, 193, SonsAtivos, AlternarSons
    )

    c.Push(SA_BtnSons["controle"])

    AtualizarBotaoStatus(SA_BtnSons, SonsAtivos)

    c.Push(janela.AddText(
        "x26 y246 w568 h1 BackgroundE5E7EB",
        ""
    ))

    ; ========================================
    ; AVISOS
    ; ========================================

    ; Ícone de personalização
    c.Push(janela.AddPicture(
        "x29 y268 w19 h19 BackgroundTrans",
        A_ScriptDir "\Imagens\avisos.png"
    ))

    ; Título
    janela.SetFont("s14 Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x55 y263 w350 h24 BackgroundTrans",
        "Avisos"
    ))

    ; Subtítulo
    janela.SetFont("s10 Norm c606060", "Segoe UI")
    c.Push(janela.AddText(
        "x29 y289 w390 h22 BackgroundTrans",
        "Exibir notificações de conclusão e alertas."
    ))

    SA_BtnAvisos := CriarInterruptor(
        janela, 562, 266, AvisosAtivos, AlternarAvisos
    )

    c.Push(SA_BtnAvisos["controle"])

    AtualizarBotaoStatus(SA_BtnAvisos, AvisosAtivos)

    c.Push(janela.AddText(
        "x26 y319 w568 h1 BackgroundE5E7EB",
        ""
    ))

    ; ========================================
    ; INICIAR COM WINDOWS
    ; ========================================

    ; Ícone de personalização
    c.Push(janela.AddPicture(
        "x29 y341 w17 h17 BackgroundTrans",
        A_ScriptDir "\Imagens\windows.png"
    ))

    ; Título
    janela.SetFont("s14 Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x55 y336 w350 h24 BackgroundTrans",
        "Iniciar com Windows"
    ))

    ; Subtítulo
    janela.SetFont("s10 Norm c606060", "Segoe UI")
    c.Push(janela.AddText(
        "x29 y362 w400 h22 BackgroundTrans",
        "Executar automaticamente ao entrar no sistema."
    ))

    SA_BtnWindows := CriarInterruptor(
        janela, 562, 339,
        IniciarComWindows, AlternarInicializacaoWindows
    )

    c.Push(SA_BtnWindows["controle"])

    AtualizarBotaoStatus(SA_BtnWindows, IniciarComWindows)

    ; ========================================
    ; RODAPÉ
    ; ========================================

    c.Push(janela.AddText(
        "x26 y392 w568 h1 BackgroundE5E7EB",
        ""
    ))

}

; ============================================
; CRIAR INTERRUPTOR
; ============================================

CriarInterruptor(janela, x, y, ativo, callback) {
    caminhoAtivo := A_ScriptDir
        . "\Imagens\interruptor_ativo.png"

    caminhoInativo := A_ScriptDir
        . "\Imagens\interruptor_inativo.png"

    caminho := ativo ? caminhoAtivo : caminhoInativo

    controle := janela.AddPicture(
        "x" . x . " y" . y . " w32 h-1 BackgroundTrans",
        caminho
    )

    controle.OnEvent("Click", callback)

    return Map(
        "controle", controle,
        "caminhoAtivo", caminhoAtivo,
        "caminhoInativo", caminhoInativo
    )
}

; ============================================
; CONTEÚDO DA TELA DE MENSAGENS
; ============================================

MontarTelaMensagens(janela) {
    global SA_ControlesMensagens
    global SA_CamposPersonalizacao
    global NomeAtendente, MensagemFinalizacao
    global frase1, frase2, frase3

    c := SA_ControlesMensagens
    SA_CamposPersonalizacao := Map()

    janela.SetFont("s16 Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x29 y88 w560 h30 BackgroundTrans",
        "Personalize com base nas suas preferências"
    ))

    ; Cartão do nome
    c.Push(janela.AddText(
        "x20 y158 w596 h71 BackgroundF9FAFB",
        ""
    ))

    janela.SetFont("s10 Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x29 y168 w550 h20 BackgroundTrans",
        "Nome de apresentação do atendente"
    ))

    janela.SetFont("s10 Norm c202124", "Segoe UI")

    SA_CamposPersonalizacao["nome"] :=
        janela.AddEdit(
            "x36 y190 w568 h29",
            NomeAtendente
        )
    c.Push(SA_CamposPersonalizacao["nome"])

    ; Cartão da mensagem de finalização
    c.Push(janela.AddText(
        "x20 y240 w596 h136 BackgroundF9FAFB",
        ""
    ))

    janela.SetFont("s10 Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x29 y250 w550 h20 BackgroundTrans",
        "Mensagem de finalização (Alt + Q)"
    ))

    textoFinal := Trim(
        StrReplace(MensagemFinalizacao, "{PROTOCOLO}", "")
    )

    janela.SetFont("s10 Norm c202124", "Segoe UI")

    SA_CamposPersonalizacao["finalizacao"] :=
        janela.AddEdit(
            "x36 y275 w568 h64 Multi WantReturn",
            textoFinal
        )
    c.Push(SA_CamposPersonalizacao["finalizacao"])

    janela.SetFont("s8 italic c797d85", "Segoe UI")
    c.Push(janela.AddText(
        "x36 y343 w568 h22 BackgroundTrans",
        "O número do protocolo será acrescentado automaticamente."
    ))

    janela.SetFont("s10 Norm Bold c202124", "Segoe UI")
    ; Título das mensagens rápidas
    c.Push(janela.AddText(
        "x29 y390 w580 h23 BackgroundTrans",
        "Mensagens rápidas"
    ))

    ; Alt + W
    c.Push(janela.AddText(
        "x20 y418 w596 h48 BackgroundF9FAFB",
        ""
    ))

    janela.SetFont("s10 Norm Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x34 y430 w66 h24 Center +0x200 BackgroundE0F2FE",
        "Alt + W"
    ))
    janela.SetFont("s10 Norm c202124", "Segoe UI")

    SA_CamposPersonalizacao["frase1"] :=
        janela.AddEdit(
            "x112 y428 w492 h28",
            frase1
        )
    c.Push(SA_CamposPersonalizacao["frase1"])

    ; Alt + Y
    c.Push(janela.AddText(
        "x20 y472 w596 h48 BackgroundF9FAFB",
        ""
    ))
    janela.SetFont("s10 Norm Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x34 y484 w66 h24 Center +0x200 BackgroundE0F2FE",
        "Alt + Y"
    ))

    janela.SetFont("s10 Norm c202124", "Segoe UI")

    SA_CamposPersonalizacao["frase2"] :=
        janela.AddEdit(
            "x112 y482 w492 h28",
            frase2
        )
    c.Push(SA_CamposPersonalizacao["frase2"])

    ; Alt + Z
    c.Push(janela.AddText(
        "x20 y526 w596 h48 BackgroundF9FAFB",
        ""
    ))
    janela.SetFont("s10 Norm Bold c202124", "Segoe UI")
    c.Push(janela.AddText(
        "x34 y538 w66 h24 Center +0x200 BackgroundE0F2FE",
        "Alt + Z"
    ))

    janela.SetFont("s10 Norm c202124", "Segoe UI")

    SA_CamposPersonalizacao["frase3"] :=
        janela.AddEdit(
            "x112 y536 w492 h28",
            frase3
        )
    c.Push(SA_CamposPersonalizacao["frase3"])

    ; Botões de navegação e salvamento
    c.Push(janela.AddText(
        "x24 y588 w592 h1 BackgroundE5E7EB",
        ""
    ))

    janela.SetFont("s10 Bold c202124", "Segoe UI")

    btnVoltar := janela.AddButton(
        "x238 y605 w150 h34",
        "Voltar"
    )
    c.Push(btnVoltar)
    btnVoltar.OnEvent(
        "Click",
        (*) => TrocarTelaInterface("principal")
    )

    btnSalvar := janela.AddButton(
        "x402 y605 w190 h34 Default",
        "Salvar alterações"
    )
    c.Push(btnSalvar)
    btnSalvar.OnEvent(
        "Click",
        SalvarPersonalizacao
    )
}

; ============================================
; ALTERNAR ENTRE AS TELAS
; ============================================

TrocarTelaInterface(pagina) {
    global SA_JanelaPrincipal
    global SA_ControlesPrincipal
    global SA_ControlesMensagens
    global SA_BtnSons, SA_BtnAvisos, SA_BtnWindows

    if !IsObject(SA_JanelaPrincipal)
        return

    mostrarPrincipal := (pagina = "principal")

    ; Exibe ou oculta os controles da tela principal
    for controle in SA_ControlesPrincipal {
        if IsObject(controle)
            controle.Visible := mostrarPrincipal
    }

    ; Exibe ou oculta os controles da tela de mensagens
    for controle in SA_ControlesMensagens {
        if IsObject(controle)
            controle.Visible := !mostrarPrincipal
    }

    ; Ajusta o tamanho da janela
    if mostrarPrincipal
        SA_JanelaPrincipal.Show("w620 h480")
    else
        SA_JanelaPrincipal.Show("w620 h660")

}


; ============================================
; ESTILO DOS CONTROLES DE ATIVAÇÃO
; ============================================

; ============================================
; ATUALIZAR INTERRUPTOR
; ============================================

AtualizarBotaoStatus(interruptor, ativo) {
    if !IsObject(interruptor)
        return

    controle := interruptor["controle"]

    if ativo
        controle.Value := interruptor["caminhoAtivo"]
    else
        controle.Value := interruptor["caminhoInativo"]

    controle.Redraw()
}
; ============================================
; ALTERNAR SONS
; ============================================

AlternarSons(*) {
    global SonsAtivos, SA_BtnSons

    SonsAtivos := !SonsAtivos

    SalvarConfiguracoes()
    AtualizarBotaoStatus(SA_BtnSons, SonsAtivos)
}


; ============================================
; ALTERNAR AVISOS NA TELA
; ============================================

AlternarAvisos(*) {
    global AvisosAtivos, SA_BtnAvisos

    AvisosAtivos := !AvisosAtivos

    SalvarConfiguracoes()
    AtualizarBotaoStatus(SA_BtnAvisos, AvisosAtivos)
}

; ============================================
; ALTERNAR INICIALIZAÇÃO COM O WINDOWS
; ============================================

AlternarInicializacaoWindows(*) {
    global IniciarComWindows, SA_BtnWindows

    novoEstado := !IniciarComWindows

    try {
        ConfigurarInicializacaoWindows(novoEstado)

        IniciarComWindows := novoEstado

        SalvarConfiguracoes()
        AtualizarBotaoStatus(
            SA_BtnWindows,
            IniciarComWindows
        )
    } catch as erro {
        AtualizarBotaoStatus(
            SA_BtnWindows,
            IniciarComWindows
        )

        MsgBox(
            "Não foi possível alterar a inicialização com o Windows.`n`n"
            . erro.Message,
            "SupportAutomation",
            "Iconx"
        )
    }
}

ConfigurarInicializacaoWindows(ativar) {
    chave := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"

    if ativar {
        if A_IsCompiled {
            comando := Chr(34) . A_ScriptFullPath
                . Chr(34) . " --iniciar-fundo"
        } else {
            comando := Chr(34) . A_AhkPath . Chr(34)
                . " " . Chr(34) . A_ScriptFullPath
                . Chr(34) . " --iniciar-fundo"
        }

        RegWrite(
            comando,
            "REG_SZ",
            chave,
            "SupportAutomation"
        )
    } else {
        try RegDelete(chave, "SupportAutomation")
    }
}


; ============================================
; OCULTAR A JANELA PRINCIPAL
; ============================================

OcultarJanelaPrincipal(janela) {
    janela.Hide()
    return true
}

SalvarPersonalizacao(*) {
    global SA_CamposPersonalizacao
    global NomeAtendente, MensagemFinalizacao
    global frase1, frase2, frase3

    nome := Trim(SA_CamposPersonalizacao["nome"].Value)

    ; Só altera o nome se o usuário digitar um novo.
    if (nome != "")
        NomeAtendente := nome

    MensagemFinalizacao := Trim(
        SA_CamposPersonalizacao["finalizacao"].Value
    )

    frase1 := SA_CamposPersonalizacao["frase1"].Value
    frase2 := SA_CamposPersonalizacao["frase2"].Value
    frase3 := SA_CamposPersonalizacao["frase3"].Value

    SalvarConfiguracoes()

    TrocarTelaInterface("principal")
}


; Função antiga da janela separada. Mantida por enquanto porque outros arquivos do projeto podem referenciá-la.
FecharJanelaPersonalizacao(janela) {
    global SA_JanelaPersonalizacao

    SA_JanelaPersonalizacao := 0
}

MostrarJanelaPersonalizacao() {
    TrocarTelaInterface("mensagens")
}