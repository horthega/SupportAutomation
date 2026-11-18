#Requires AutoHotkey v2.0

; ============================================
; SUPPORTAUTOMATION — INTERFACE E PREFERÊNCIAS
; ============================================

AppVersion := "2.3.0"

SA_PastaConfiguracoes := A_AppData "\SupportAutomation"
SA_ArquivoConfiguracoes := SA_PastaConfiguracoes "\config.ini"

SA_JanelaPrincipal := 0
SA_JanelaPersonalizacao := 0 ; Mantido por compatibilidade até revisar o arquivo principal
SA_CamposPersonalizacao := Map()
SA_AreaPersonalizacao := 0
SA_ControlesRolagem := []
SA_DeslocamentoRolagem := 0
SA_LimiteRolagem := 0

SA_CardsInterativos := Map()
SA_CardHoverAtual := 0
SA_CardPressionado := 0

SA_BtnSons := 0
SA_BtnAvisos := 0
SA_BtnWindows := 0

SA_ControlesPrincipal := []
SA_ControlesMensagens := []
SA_ControlesEdicaoOS := []
SA_ControlesEdicaoRapidas := []
SA_ControlesEdicaoFraseologias := []
SA_ItensRolagemFraseologias := []
SA_LimiteRolagemFraseologias := 0
SA_CamposFraseologias := Map()

SA_CamposOS := Map()
SA_CamposMensagensRapidas := Map()

SA_ControleVersao := 0

; COR DE FUNDO DOS QUATRO CARDS DA PERSONALIZAÇÃO
SA_CorFundoSecoes := "f4f6f8"

SA_UsuarioRoteador := ""
SA_SenhaRoteador := ""

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
    global frase1, frase2, frase3, MensagensOS, MensagensFraseologias
    global SA_UsuarioRoteador, SA_SenhaRoteador

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

    ; Carrega as mensagens de preenchimento de O.S.
    for numero, mensagem in MensagensOS {
        MensagensOS[numero] := TextoDeConfig(
            IniRead(
                SA_ArquivoConfiguracoes,
                "Personalizacao",
                "MensagemOS" numero,
                TextoParaConfig(mensagem)
            )
        )
    }
    ; Carrega as Fraseologias personalizadas
    for numero, mensagem in MensagensFraseologias {
        MensagensFraseologias[numero] := TextoDeConfig(
            IniRead(
                SA_ArquivoConfiguracoes,
                "Personalizacao",
                "Fraseologia" numero,
                TextoParaConfig(mensagem)
            )
        )
    }
        ; Carrega as credenciais protegidas do roteador
    usuarioProtegido := IniRead(
        SA_ArquivoConfiguracoes,
        "Credenciais",
        "Usuario",
        ""
    )

    senhaProtegida := IniRead(
        SA_ArquivoConfiguracoes,
        "Credenciais",
        "Senha",
        ""
    )

    try {
        SA_UsuarioRoteador := DesprotegerCredencial(usuarioProtegido)
        SA_SenhaRoteador := DesprotegerCredencial(senhaProtegida)
    } catch {
        SA_UsuarioRoteador := ""
        SA_SenhaRoteador := ""
    }
}

SalvarConfiguracoes() {
    global SA_PastaConfiguracoes, SA_ArquivoConfiguracoes
    global AvisosAtivos, SonsAtivos, IniciarComWindows
    global NomeAtendente, MensagemFinalizacao
    global frase1, frase2, frase3, MensagensOS, MensagensFraseologias
    global SA_UsuarioRoteador, SA_SenhaRoteador

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

    ; Salva as mensagens de preenchimento de O.S.
    for numero, mensagem in MensagensOS {
        IniWrite(
            TextoParaConfig(mensagem),
            SA_ArquivoConfiguracoes,
            "Personalizacao",
            "MensagemOS" numero
        )
    }

    ; Salva as Fraseologias personalizadas
    for numero, mensagem in MensagensFraseologias {
        IniWrite(
            TextoParaConfig(mensagem),
            SA_ArquivoConfiguracoes,
            "Personalizacao",
            "Fraseologia" numero
        )
    }

    usuarioProtegido := ProtegerCredencial(SA_UsuarioRoteador)
    senhaProtegida := ProtegerCredencial(SA_SenhaRoteador)

    IniWrite(
        usuarioProtegido,
        SA_ArquivoConfiguracoes,
        "Credenciais",
        "Usuario"
    )

    IniWrite(
        senhaProtegida,
        SA_ArquivoConfiguracoes,
        "Credenciais",
        "Senha"
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


; ============================================
; PROTEÇÃO DE CREDENCIAIS — WINDOWS DPAPI
; ============================================

ProtegerCredencial(texto) {
    if (texto = "")
        return ""

    tamanho := StrPut(texto, "UTF-16") * 2
    dadosEntrada := Buffer(tamanho, 0)
    StrPut(texto, dadosEntrada, "UTF-16")

    entrada := Buffer(A_PtrSize * 2, 0)
    saida := Buffer(A_PtrSize * 2, 0)

    NumPut("UInt", tamanho, entrada, 0)
    NumPut("Ptr", dadosEntrada.Ptr, entrada, A_PtrSize = 8 ? 8 : 4)

    sucesso := DllCall(
        "Crypt32\CryptProtectData",
        "Ptr", entrada.Ptr,
        "Ptr", 0,
        "Ptr", 0,
        "Ptr", 0,
        "Ptr", 0,
        "UInt", 0,
        "Ptr", saida.Ptr,
        "Int"
    )

    if !sucesso
        throw Error("Não foi possível proteger a credencial.")

    tamanhoSaida := NumGet(saida, 0, "UInt")
    ponteiroSaida := NumGet(saida, A_PtrSize = 8 ? 8 : 4, "Ptr")

    try {
        resultado := ""

        loop tamanhoSaida
            resultado .= Format("{:02X}", NumGet(ponteiroSaida, A_Index - 1, "UChar"))

        return resultado
    } finally {
        DllCall("Kernel32\LocalFree", "Ptr", ponteiroSaida, "Ptr")
    }
}


DesprotegerCredencial(textoProtegido) {
    if (textoProtegido = "")
        return ""

    if !RegExMatch(textoProtegido, "i)^[0-9a-f]+$")
        throw Error("Formato da credencial protegida inválido.")

    if Mod(StrLen(textoProtegido), 2)
        throw Error("Dados da credencial protegida inválidos.")

    tamanho := StrLen(textoProtegido) // 2
    dadosEntrada := Buffer(tamanho, 0)

    loop tamanho
        NumPut(
            "UChar",
            Integer("0x" SubStr(textoProtegido, A_Index * 2 - 1, 2)),
            dadosEntrada,
            A_Index - 1
        )

    entrada := Buffer(A_PtrSize * 2, 0)
    saida := Buffer(A_PtrSize * 2, 0)

    NumPut("UInt", tamanho, entrada, 0)
    NumPut("Ptr", dadosEntrada.Ptr, entrada, A_PtrSize = 8 ? 8 : 4)

    sucesso := DllCall(
        "Crypt32\CryptUnprotectData",
        "Ptr", entrada.Ptr,
        "Ptr", 0,
        "Ptr", 0,
        "Ptr", 0,
        "Ptr", 0,
        "UInt", 0,
        "Ptr", saida.Ptr,
        "Int"
    )

    if !sucesso
        throw Error("Não foi possível recuperar a credencial protegida.")

    tamanhoSaida := NumGet(saida, 0, "UInt")
    ponteiroSaida := NumGet(saida, A_PtrSize = 8 ? 8 : 4, "Ptr")

    try {
        return StrGet(ponteiroSaida, tamanhoSaida // 2, "UTF-16")
    } finally {
        DllCall("Kernel32\LocalFree", "Ptr", ponteiroSaida, "Ptr")
    }
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
        SA_ControlesEdicaoOS := []
        SA_ControlesEdicaoRapidas := []
        SA_ControlesEdicaoFraseologias := []

        MontarTelaPrincipal(janela)
        MontarTelaPersonalizacao(janela)
        MontarTelaEdicaoOS()
        MontarTelaEdicaoRapidas()
        MontarTelaEdicaoFraseologias()
        MontarTelaEdicaoCredenciais()

        janela.OnEvent("Close", OcultarJanelaPrincipal)
        OnMessage(0x020A, RolarPersonalizacao) ; WM_MOUSEWHEEL
        OnMessage(0x0200, MonitorarHoverCards) ; WM_MOUSEMOVE
        OnMessage(0x0201, PressionarCard)      ; WM_LBUTTONDOWN
        OnMessage(0x0202, SoltarCard)          ; WM_LBUTTONUP
        OnMessage(0x0201, PressionarBotaoSalvar)
        OnMessage(0x0202, SoltarBotaoSalvar)

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
MontarTelaPersonalizacao(janela) {
    global SA_ControlesMensagens, SA_CamposPersonalizacao
    global SA_AreaPersonalizacao, SA_ControlesRolagem
    global SA_LimiteRolagem
    global NomeAtendente, MensagemFinalizacao
    global SA_ControleImagemSalvar, SA_ControleBotaoSalvar
    global SA_ImagemBotaoSalvar, SA_ImagemBotaoSalvarPressionado

    c := SA_ControlesMensagens
    SA_CamposPersonalizacao := Map()
    SA_ControlesRolagem := []

    ; Área rolável — preserva o mecanismo atual.
    SA_AreaPersonalizacao := Gui("+Parent" janela.Hwnd " -Caption +ToolWindow")
    SA_AreaPersonalizacao.BackColor := "FFFFFF"
    SA_AreaPersonalizacao.Show("x20 y95 w580 h389")

    area := SA_AreaPersonalizacao

    ; Nome do atendente
    y := 8
    AdicionarControleRolagem(area, "Text", "x-8 y" y " w620 h71 Background" SA_CorFundoSecoes, "")

    area.SetFont("s12 Norm Bold c202124", "Segoe UI")
    AdicionarControleRolagem(area, "Text", "x9 y" (y + 4) " w550 h20 BackgroundTrans", "Nome de apresentação")

    area.SetFont("s10 Norm c202124", "Segoe UI")
    SA_CamposPersonalizacao["nome"] := AdicionarControleRolagem(area, "Edit", "x9 y" (y + 32) " w560 h29", NomeAtendente)

    ; Finalização com protocolo
    y := 90
    AdicionarControleRolagem(area, "Text", "x-8 y" y " w620 h136 Background" SA_CorFundoSecoes, "")

    area.SetFont("s12 Norm Bold c202124", "Segoe UI")
    AdicionarControleRolagem(area, "Text", "x9 y" (y + 4) " w550 h20 BackgroundTrans", "Finalização com protocolo (Alt + Q)")

    textoFinal := Trim(StrReplace(MensagemFinalizacao, "{PROTOCOLO}", ""))

    area.SetFont("s10 Norm c202124", "Segoe UI")
    SA_CamposPersonalizacao["finalizacao"] := AdicionarControleRolagem(area, "Edit", "x9 y" (y + 35) " w560 h64 Multi WantReturn", textoFinal)

    area.SetFont("s8 italic c797d85", "Segoe UI")
    AdicionarControleRolagem(area, "Text", "x9 y" (y + 103) " w560 h22 BackgroundTrans", "O número do protocolo será acrescentado automaticamente.")


; ============================================================
; CARD — FRASEOLOGIAS
; ============================================================

; COR DA BORDA DOS CARDS
corBordaCard := "eaedf1"

; POSIÇÃO VERTICAL DO CARD DE FRASEOLOGIAS
y := 245

AdicionarControleRolagem(
    area,
    "Text",
    "x0 y" y " w580 h76 Background" corBordaCard,
    ""
)

cardFraseologias := AdicionarControleRolagem(
    area,
    "Text",
    "x1 y" (y + 1) " w578 h74 Background" SA_CorFundoSecoes,
    ""
)

iconeFraseologias := AdicionarControleRolagem(
    area,
    "Picture",
    "x11 y" (y + 22) " w25 h25 +BackgroundTrans",
    A_ScriptDir "\Imagens\fraseologias.png"
)

area.SetFont("s12 Norm Bold c202124", "Segoe UI")
tituloFraseologias := AdicionarControleRolagem(
    area,
    "Text",
    "x46 y" (y + 13) " w490 h22 BackgroundTrans",
    "Fraseologias"
)

area.SetFont("s9 Norm c606060", "Segoe UI")
descricaoFraseologias := AdicionarControleRolagem(
    area,
    "Text",
    "x46 y" (y + 37) " w490 h20 BackgroundTrans",
    "Personalize suas mensagens de atendimento."
)

area.SetFont("s25 Norm c606060", "Calibri Light")
setaFraseologias := AdicionarControleRolagem(
    area,
    "Text",
    "x545 y" (y + 18) " w35 h40 Center BackgroundTrans",
    "›"
)

ConfigurarCardInterativo(
    cardFraseologias,
    [tituloFraseologias, descricaoFraseologias, setaFraseologias, iconeFraseologias]
)

for controle in [cardFraseologias, tituloFraseologias, descricaoFraseologias, setaFraseologias, iconeFraseologias]
    controle.OnEvent("Click", (*) => TrocarTelaInterface("editarFraseologias"))

; ============================================================
; CARD — PREENCHIMENTO DE O.S.
; ============================================================

    y := 330

    ; BORDA DO CARD — altere a cor em corBordaCard
    AdicionarControleRolagem(
        area,
        "Text",
        "x0 y" y " w580 h76 Background" corBordaCard,
        ""
    )

    ; FUNDO DO CARD — cor normal e cores de hover/clique configuradas separadamente
    cardOS := AdicionarControleRolagem(
        area,
        "Text",
        "x1 y" (y + 1) " w578 h74 Background" SA_CorFundoSecoes,
        ""
    )

    iconeOS := AdicionarControleRolagem(
    area,
    "Picture",
    "x10 y" (y + 21) " w30 h30 +BackgroundTrans",
    A_ScriptDir "\Imagens\preenchimentoOS.png"
    )

    area.SetFont("s12 Norm Bold c202124", "Segoe UI")
    tituloOS := AdicionarControleRolagem(
        area,
        "Text",
        "x46 y" (y + 13) " w490 h22 BackgroundTrans",
        "Preenchimento de O.S."
    )

    area.SetFont("s9 Norm c606060", "Segoe UI")
    descricaoOS := AdicionarControleRolagem(
        area,
        "Text",
        "x46 y" (y + 37) " w490 h20 BackgroundTrans",
        "Defina o conteúdo que cada atalho enviará."
    )

    area.SetFont("s25 Norm c606060", "Calibri Light")
    setaOS := AdicionarControleRolagem(
        area,
        "Text",
        "x545 y" (y + 18) " w35 h40 Center BackgroundTrans",
        "›"
    )

    ConfigurarCardInterativo(
        cardOS,
        [tituloOS, descricaoOS, setaOS, iconeOS]
    )

    ; Todos os elementos do card recebem o mesmo clique.
    for controle in [cardOS, tituloOS, descricaoOS, setaOS, iconeOS]
        controle.OnEvent("Click", (*) => TrocarTelaInterface("editarOS"))


; ============================================================
; CARD — MENSAGENS RÁPIDAS
; ============================================================

; POSIÇÃO VERTICAL DO CARD MENSAGENS RÁPIDAS
y := 415

; BORDA DO CARD — utiliza a mesma cor configurada acima
AdicionarControleRolagem(
    area,
    "Text",
    "x0 y" y " w580 h76 Background" corBordaCard,
    ""
)

; FUNDO DO CARD — cor normal e cores de hover/clique configuradas separadamente
cardRapidas := AdicionarControleRolagem(
    area,
    "Text",
    "x1 y" (y + 1) " w578 h74 Background" SA_CorFundoSecoes,
    ""
)

iconeRapidas := AdicionarControleRolagem(
    area,
    "Picture",
    "x10 y" (y + 20) " w29 h29 +BackgroundTrans",
    A_ScriptDir "\Imagens\MsgRapidas.png"
)

area.SetFont("s12 Norm Bold c202124", "Segoe UI")
tituloRapidas := AdicionarControleRolagem(
    area,
    "Text",
        "x46 y" (y + 13) " w490 h22 BackgroundTrans",
    "Mensagens temporárias"
)

area.SetFont("s9 Norm c606060", "Segoe UI")
descricaoRapidas := AdicionarControleRolagem(
    area,
    "Text",
        "x46 y" (y + 37) " w490 h20 BackgroundTrans",
    "Defina mensagens usadas ocasionalmente."
)

area.SetFont("s25 Norm c606060", "Calibri Light")
setaRapidas := AdicionarControleRolagem(
    area,
    "Text",
    "x545 y" (y + 18) " w35 h40 Center BackgroundTrans",
    "›"
)

ConfigurarCardInterativo(
cardRapidas,
[tituloRapidas, descricaoRapidas, setaRapidas, iconeRapidas]
)

; Todos os elementos do card recebem o mesmo clique.
for controle in [cardRapidas, tituloRapidas, descricaoRapidas, setaRapidas, iconeRapidas]
    controle.OnEvent("Click", (*) => TrocarTelaInterface("editarMensagens"))

; ============================================================
; CARD — CREDENCIAIS DO ROTEADOR
; ============================================================

; POSIÇÃO VERTICAL DO CARD CREDENCIAIS
y := 500

; BORDA DO CARD
AdicionarControleRolagem(
    area,
    "Text",
    "x0 y" y " w580 h76 Background" corBordaCard,
    ""
)

; FUNDO DO CARD
cardCredenciais := AdicionarControleRolagem(
    area,
    "Text",
    "x1 y" (y + 1) " w578 h74 Background" SA_CorFundoSecoes,
    ""
)

iconeCredenciais := AdicionarControleRolagem(
    area,
    "Picture",
    "x10 y" (y + 20) " w30 h30 +BackgroundTrans",
    A_ScriptDir "\Imagens\credenciais.png"
)

area.SetFont("s12 Norm Bold c202124", "Segoe UI")
tituloCredenciais := AdicionarControleRolagem(
    area,
    "Text",
    "x46 y" (y + 13) " w490 h22 BackgroundTrans",
    "Credenciais do roteador"
)

area.SetFont("s9 Norm c606060", "Segoe UI")
descricaoCredenciais := AdicionarControleRolagem(
    area,
    "Text",
    "x46 y" (y + 37) " w490 h20 BackgroundTrans",
    "Defina as credenciais que o atalho F4 usará para acessar o roteador."
)

area.SetFont("s25 Norm c606060", "Calibri Light")
setaCredenciais := AdicionarControleRolagem(
    area,
    "Text",
    "x545 y" (y + 18) " w35 h40 Center BackgroundTrans",
    "›"
)

ConfigurarCardInterativo(
    cardCredenciais,
    [tituloCredenciais, descricaoCredenciais, setaCredenciais, iconeCredenciais]
)

; Todos os elementos do card recebem o mesmo clique.
for controle in [cardCredenciais, tituloCredenciais, descricaoCredenciais, setaCredenciais, iconeCredenciais]
    controle.OnEvent("Click", (*) => TrocarTelaInterface("editarCredenciais"))

; Limite de rolagem
SA_LimiteRolagem := Max(0, y + 77 - 329)

; Rodapé fixo
c.Push(janela.AddText("x26 y490 w568 h1 BackgroundE5E7EB", ""))

janela.SetFont("s10 Norm Bold c202124", "Segoe UI")

; Botão Voltar
btnVoltar := janela.AddButton("x356 y500 w110 h32", "Voltar")

; Fundo verde arredondado do botão Salvar.
SA_ImagemBotaoSalvar := CriarBotaoGDI(
    0xFF16834A,
    0,
    122,
    32,
    3
)

SA_ImagemBotaoSalvarPressionado := CriarBotaoGDI(
    0xFF105F36,
    0,
    122,
    32,
    3
)

SA_ControleImagemSalvar := janela.AddPicture(
    "x472 y500 w122 h32",
    "HBITMAP:*" SA_ImagemBotaoSalvar
)

btnSalvar := janela.AddText(
    "x472 y500 w122 h32 Center 0x200 BackgroundTrans cffffff",
    "Salvar alterações"
)

SA_ControleBotaoSalvar := btnSalvar

btnSalvar.SetFont("s10 Bold", "Segoe UI")

c.Push(btnVoltar)
c.Push(btnSalvar)

btnVoltar.OnEvent("Click", VoltarTelaAtual)
btnSalvar.OnEvent("Click", SalvarTelaAtual)

; Os eventos dos botões de edição serão conectados na próxima etapa.
}

; ============================================================
; TELA DE EDIÇÃO — PREENCHIMENTO DE O.S.
; ============================================================

MontarTelaEdicaoOS() {
    global SA_AreaPersonalizacao, SA_ControlesEdicaoOS
    global MensagensOS

    area := SA_AreaPersonalizacao
    SA_ControlesEdicaoOS := []

    area.SetFont("s12 Bold c202124", "Segoe UI")

    tituloOS := area.AddText(
        "x10 y8 w550 h28 BackgroundTrans",
        "Personalize o texto enviado por cada atalho"
    )

    SA_ControlesEdicaoOS.Push(tituloOS)

    loop 7 {
        numero := A_Index
        y := 70 + ((numero - 1) * 38)

        area.SetFont("s9 Bold c202124", "Segoe UI")
        SA_ControlesEdicaoOS.Push(area.AddText(
            "x10 y" y " w70 h22 BackgroundTrans",
            "Alt + " numero
        ))

        area.SetFont("s9 Norm c202124", "Segoe UI")
        campo := area.AddEdit(
            "x85 y" (y - 3) " w475 h30",
            MensagensOS[numero]
        )

        SA_ControlesEdicaoOS.Push(campo)
    }

}

; ============================================================
; TELA DE EDIÇÃO — MENSAGENS RÁPIDAS
; ============================================================

MontarTelaEdicaoRapidas() {
    global SA_AreaPersonalizacao, SA_ControlesEdicaoRapidas
    global SA_CamposMensagensRapidas
    global frase1, frase2, frase3

    area := SA_AreaPersonalizacao
    SA_ControlesEdicaoRapidas := []
    SA_CamposMensagensRapidas := Map()

    area.SetFont("s12 Bold c202124", "Segoe UI")
    tituloRapidas := area.AddText(
        "x10 y8 w550 h25 BackgroundTrans",
        "Defina os textos dos seguintes atalhos"
    )

    SA_ControlesEdicaoRapidas.Push(tituloRapidas)

    mensagens := Map(
        "frase1", ["Alt + W", frase1],
        "frase2", ["Alt + Y", frase2],
        "frase3", ["Alt + Z", frase3]
    )
    ;altura vertical dos textos dos atalhos
    posicoes := [65, 165, 265]

    for chave, dados in mensagens {
        y := posicoes[A_Index]

        area.SetFont("s9 Bold c202124", "Segoe UI")
        SA_ControlesEdicaoRapidas.Push(area.AddText(
            "x10 y" y " w70 h22 BackgroundTrans",
            dados[1]
        ))

        area.SetFont("s9 Norm c202124", "Segoe UI")
        campo := area.AddEdit(
            "x85 y" y " w475 h65 Multi WantReturn",
            dados[2]
        )

        SA_CamposMensagensRapidas[chave] := campo
        SA_ControlesEdicaoRapidas.Push(campo)
    }

    ; Mantém os campos ocultos até abrir a tela de mensagens rápidas.
    for controle in SA_ControlesEdicaoRapidas
        controle.Visible := false
}


; ============================================================
; TELA DE EDIÇÃO — FRASEOLOGIAS
; ============================================================

MontarTelaEdicaoFraseologias() {
    global SA_AreaPersonalizacao
    global SA_ControlesEdicaoFraseologias
    global SA_ItensRolagemFraseologias
    global SA_CamposFraseologias
    global SA_LimiteRolagemFraseologias
    global MensagensFraseologias

    area := SA_AreaPersonalizacao

    SA_ControlesEdicaoFraseologias := []
    SA_ControlesEdicaoCredenciais := []
    SA_ItensRolagemFraseologias := []
    SA_CamposFraseologias := Map()

    area.SetFont("s12 Bold c202124", "Segoe UI")

    tituloFraseologias := area.AddText(
        "x10 y8 w550 h25 BackgroundTrans",
        "Personalize suas mensagens de atendimento"
    )

    SA_ControlesEdicaoFraseologias.Push(tituloFraseologias)

    SA_ItensRolagemFraseologias.Push(
        Map("controle", tituloFraseologias, "y", 8)
    )

    mensagens := Map(
        1, "Ctrl + A",
        2, "Alt + C",
        3, "Alt Gr + C",
        4, "Alt + F",
        5, "Alt Gr + J",
        6, "Alt Gr + L",
        7, "Alt Gr + O",
        8, "Alt Gr + P",
        9, "Alt Gr + V",
        10, "Alt + V",
        11, "Alt + X",
        12, 'Ctrl + "?"'
    )

    posicaoY := 55

    for numero, atalho in mensagens {

        ; Atalho à esquerda, em negrito
        area.SetFont("s9 Bold c202124", "Segoe UI")

        rotulo := area.AddText(
            "x10 y" posicaoY " w80 h55 BackgroundTrans",
            atalho
        )

        ; Texto da mensagem à direita, em fonte normal
        area.SetFont("s9 Norm c202124", "Segoe UI")

        campo := area.AddEdit(
            "x95 y" posicaoY " w465 h55 Multi WantReturn",
            MensagensFraseologias[numero]
        )
        SA_ControlesEdicaoFraseologias.Push(rotulo)
        SA_ControlesEdicaoFraseologias.Push(campo)

        SA_ItensRolagemFraseologias.Push(
            Map("controle", rotulo, "y", posicaoY)
        )
        SA_ItensRolagemFraseologias.Push(
            Map("controle", campo, "y", posicaoY)
        )

        SA_CamposFraseologias[numero] := campo

        posicaoY += 85
    }

    SA_LimiteRolagemFraseologias := Max(0, posicaoY - 85 + 77 - 389)

    for controle in SA_ControlesEdicaoFraseologias
        controle.Visible := false
}

; ============================================================
; TELA DE EDIÇÃO — CREDENCIAIS DO ROTEADOR
; ============================================================

MontarTelaEdicaoCredenciais() {
    global SA_AreaPersonalizacao
    global SA_ControlesEdicaoCredenciais
    global SA_CampoUsuarioRoteador, SA_CampoSenhaRoteador
    global SA_UsuarioRoteador, SA_SenhaRoteador

    area := SA_AreaPersonalizacao
    SA_ControlesEdicaoCredenciais := []

    area.SetFont("s12 Bold c202124", "Segoe UI")
    SA_ControlesEdicaoCredenciais.Push(area.AddText(
        "x10 y8 w550 h45 BackgroundTrans",
        "Defina as credenciais que o atalho F4 usará para acessar o roteador"
    ))

    area.SetFont("s10 Bold c202124", "Segoe UI")
    SA_ControlesEdicaoCredenciais.Push(area.AddText(
        "x10 y65 w550 h22 BackgroundTrans",
        "Usuário"
    ))

    area.SetFont("s10 Norm c202124", "Segoe UI")
    SA_CampoUsuarioRoteador := area.AddEdit(
        "x10 y92 w550 h35",
        SA_UsuarioRoteador
    )
    SA_ControlesEdicaoCredenciais.Push(SA_CampoUsuarioRoteador)

    area.SetFont("s10 Bold c202124", "Segoe UI")
    SA_ControlesEdicaoCredenciais.Push(area.AddText(
        "x10 y155 w550 h22 BackgroundTrans",
        "Senha"
    ))

    area.SetFont("s10 Norm c202124", "Segoe UI")
    SA_CampoSenhaRoteador := area.AddEdit(
        "x10 y182 w550 h35 Password",
        SA_SenhaRoteador
    )
    SA_ControlesEdicaoCredenciais.Push(SA_CampoSenhaRoteador)

    for controle in SA_ControlesEdicaoCredenciais
        controle.Visible := false
}


AdicionarControleRolagem(area, tipo, opcoes, texto) {
    global SA_ControlesRolagem

    controle := area.Add(tipo, opcoes, texto)
    y := RegExMatch(opcoes, "i)y(-?\d+)", &m) ? Integer(m[1]) : 0
    SA_ControlesRolagem.Push(Map("controle", controle, "y", y))
    return controle
}


RolarPersonalizacao(wParam, lParam, msg, hwnd) {
    global SA_AreaPersonalizacao, SA_ControlesRolagem
    global SA_DeslocamentoRolagem, SA_LimiteRolagem
    global SA_TelaAtual
    global SA_ItensRolagemFraseologias
    global SA_LimiteRolagemFraseologias

    if (SA_TelaAtual = "principal")
        return

    if !IsObject(SA_AreaPersonalizacao)
        return

    delta := (wParam >> 16) & 0xFFFF

    if (delta > 32767)
        delta -= 65536

    if (delta = 0)
        return

    passo := delta > 0 ? -60 : 60

    if (SA_TelaAtual = "editarFraseologias") {

        novoDeslocamento := Max(
            0,
            Min(
                SA_LimiteRolagemFraseologias,
                SA_DeslocamentoRolagem + passo
            )
        )

        if (novoDeslocamento = SA_DeslocamentoRolagem)
            return 0

        SA_DeslocamentoRolagem := novoDeslocamento

        for item in SA_ItensRolagemFraseologias {
            item["controle"].Move(
                ,
                item["y"] - SA_DeslocamentoRolagem
            )
        }

    } else {

        novoDeslocamento := Max(
            0,
            Min(
                SA_LimiteRolagem,
                SA_DeslocamentoRolagem + passo
            )
        )

        if (novoDeslocamento = SA_DeslocamentoRolagem)
            return 0

        SA_DeslocamentoRolagem := novoDeslocamento

        for item in SA_ControlesRolagem {
            item["controle"].Move(
                ,
                item["y"] - SA_DeslocamentoRolagem
            )

            item["controle"].Redraw()
        }
    }

    DllCall(
        "RedrawWindow",
        "ptr", SA_AreaPersonalizacao.Hwnd,
        "ptr", 0,
        "ptr", 0,
        "uint", 0x85
    )

    return 0
}

; ============================================
; ALTERNAR ENTRE AS TELAS
; ============================================

TrocarTelaInterface(pagina) {
    global SA_JanelaPrincipal, SA_ControlesPrincipal
    global SA_ControlesMensagens, SA_AreaPersonalizacao
    global SA_ControlesRolagem, SA_DeslocamentoRolagem
    global SA_TelaAtual
    global SA_ControlesEdicaoOS
    global SA_ControlesEdicaoRapidas
    global SA_ControlesEdicaoFraseologias
    global SA_ItensRolagemFraseologias
    global SA_ControlesEdicaoCredenciais

    if !IsObject(SA_JanelaPrincipal)
        return

    mostrarPrincipal := (pagina = "principal")
    SA_TelaAtual := pagina

    for controle in SA_ControlesPrincipal
        controle.Visible := mostrarPrincipal

    for controle in SA_ControlesMensagens
        controle.Visible := !mostrarPrincipal

    ; Exibe os controles da tela correspondente.
    mostrarMensagens := (pagina = "mensagens")
    mostrarEdicaoOS := (pagina = "editarOS")
    mostrarEdicaoRapidas := (pagina = "editarMensagens")
    mostrarEdicaoFraseologias := (pagina = "editarFraseologias")
    mostrarEdicaoCredenciais := (pagina = "editarCredenciais")
    if mostrarEdicaoFraseologias {
    SA_DeslocamentoRolagem := 0

    for item in SA_ItensRolagemFraseologias
        item["controle"].Move(, item["y"])
}
    for item in SA_ControlesRolagem
        item["controle"].Visible := mostrarMensagens

    for controle in SA_ControlesEdicaoOS
        controle.Visible := mostrarEdicaoOS

    for controle in SA_ControlesEdicaoRapidas
        controle.Visible := mostrarEdicaoRapidas

    for controle in SA_ControlesEdicaoFraseologias
    controle.Visible := mostrarEdicaoFraseologias

    for controle in SA_ControlesEdicaoCredenciais
        controle.Visible := mostrarEdicaoCredenciais

    if IsObject(SA_AreaPersonalizacao) {
        if mostrarPrincipal {
            SA_AreaPersonalizacao.Hide()
        } else {
            if (pagina = "mensagens") {
                SA_DeslocamentoRolagem := 0

                for item in SA_ControlesRolagem
                    item["controle"].Move(, item["y"])
            }

            SA_AreaPersonalizacao.Show("x20 y95 w580 h389")
        }
    }

    if mostrarPrincipal
        SA_JanelaPrincipal.Show("w620 h480")
    else
        SA_JanelaPrincipal.Show("w620 h540")
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
    global frase1, frase2, frase3, MensagensOS, MensagensFraseologias

    nome := Trim(SA_CamposPersonalizacao["nome"].Value)

    ; Só altera o nome se o usuário digitar um novo.
    if (nome != "")
        NomeAtendente := nome

    MensagemFinalizacao := Trim(
        SA_CamposPersonalizacao["finalizacao"].Value
    )

    SalvarConfiguracoes()

    TrocarTelaInterface("mensagens")
}

; Função antiga da janela separada. Mantida por enquanto porque outros arquivos do projeto podem referenciá-la.
FecharJanelaPersonalizacao(janela) {
    global SA_JanelaPersonalizacao

    SA_JanelaPersonalizacao := 0
}

MostrarJanelaPersonalizacao() {
    TrocarTelaInterface("mensagens")
}

VoltarTelaAtual(*) {
    global SA_TelaAtual

    if (
        SA_TelaAtual = "editarOS"
        || SA_TelaAtual = "editarMensagens"
        || SA_TelaAtual = "editarFraseologias"
        || SA_TelaAtual = "editarCredenciais"
    )
        TrocarTelaInterface("mensagens")
    else
        TrocarTelaInterface("principal")
}

SalvarTelaAtual(*) {
    global SA_TelaAtual

    if (SA_TelaAtual = "editarOS")
        SalvarEdicaoOS()
    else if (SA_TelaAtual = "editarMensagens")
        SalvarEdicaoRapidas()
    else if (SA_TelaAtual = "editarCredenciais")
        SalvarEdicaoCredenciais()
    else if (SA_TelaAtual = "editarFraseologias")
        SalvarEdicaoFraseologias()
    else
        SalvarPersonalizacao()

    TocarSom("completed.mp3")
}

SalvarEdicaoCredenciais(*) {
    global SA_CampoUsuarioRoteador, SA_CampoSenhaRoteador
    global SA_UsuarioRoteador, SA_SenhaRoteador

    SA_UsuarioRoteador := Trim(SA_CampoUsuarioRoteador.Value)
    SA_SenhaRoteador := SA_CampoSenhaRoteador.Value

    SalvarConfiguracoes()
}

SalvarEdicaoOS(*) {
    global SA_ControlesEdicaoOS, MensagensOS

    loop 7 {
        numero := A_Index
        indiceCampo := 3 + ((numero - 1) * 2)

        MensagensOS[numero] :=
            SA_ControlesEdicaoOS[indiceCampo].Value
    }

    SalvarConfiguracoes()
}

SalvarEdicaoFraseologias(*) {
    global SA_CamposFraseologias, MensagensFraseologias

    for numero, campo in SA_CamposFraseologias
        MensagensFraseologias[numero] := campo.Value

    SalvarConfiguracoes()
}

SalvarEdicaoRapidas(*) {
    global SA_CamposMensagensRapidas, frase1, frase2, frase3

    frase1 := Trim(SA_CamposMensagensRapidas["frase1"].Value)
    frase2 := Trim(SA_CamposMensagensRapidas["frase2"].Value)
    frase3 := Trim(SA_CamposMensagensRapidas["frase3"].Value)

    SalvarConfiguracoes()
}

; Configura o card e seus elementos.
ConfigurarCardInterativo(card, controles) {
    global SA_CardsInterativos
    global SA_CorFundoSecoes

    dados := {
        card: card,
        controles: controles,
        normal: SA_CorFundoSecoes,
        hover: "eaedf1",
        pressionado: "f0f3f7"
    }

    for controle in controles
        SA_CardsInterativos[controle.Hwnd] := dados

    SA_CardsInterativos[card.Hwnd] := dados

    return dados
}


AtualizarCorCard(dados, cor) {
    dados.card.Opt("Background" cor)
    dados.card.Redraw()
}


MonitorarHoverCards(wParam, lParam, msg, hwnd) {
    global SA_CardsInterativos, SA_CardHoverAtual
    global SA_CardPressionado

    if !SA_CardsInterativos.Has(hwnd) {
        if IsObject(SA_CardHoverAtual) && !SA_CardPressionado
            AtualizarCorCard(SA_CardHoverAtual, SA_CardHoverAtual.normal)

        SA_CardHoverAtual := 0
        return
    }

    dados := SA_CardsInterativos[hwnd]

    if (SA_CardPressionado = dados)
        return

    if (SA_CardHoverAtual != dados) {
        if IsObject(SA_CardHoverAtual)
            AtualizarCorCard(SA_CardHoverAtual, SA_CardHoverAtual.normal)

        SA_CardHoverAtual := dados
        AtualizarCorCard(dados, dados.hover)
    }
}


PressionarCard(wParam, lParam, msg, hwnd) {
    global SA_CardsInterativos, SA_CardPressionado

    if !SA_CardsInterativos.Has(hwnd)
        return

    dados := SA_CardsInterativos[hwnd]
    SA_CardPressionado := dados

    AtualizarCorCard(dados, dados.pressionado)
}

PressionarBotaoSalvar(wParam, lParam, msg, hwnd) {
    global SA_ControleBotaoSalvar
    global SA_ControleImagemSalvar
    global SA_ImagemBotaoSalvarPressionado

    if (hwnd = SA_ControleBotaoSalvar.Hwnd)
        SA_ControleImagemSalvar.Value :=
            "HBITMAP:*" SA_ImagemBotaoSalvarPressionado
}

SoltarBotaoSalvar(wParam, lParam, msg, hwnd) {
    global SA_ControleBotaoSalvar
    global SA_ControleImagemSalvar
    global SA_ImagemBotaoSalvar

    if (hwnd = SA_ControleBotaoSalvar.Hwnd)
        SA_ControleImagemSalvar.Value :=
            "HBITMAP:*" SA_ImagemBotaoSalvar
}

SoltarCard(wParam, lParam, msg, hwnd) {
    global SA_CardsInterativos, SA_CardPressionado
    global SA_CardHoverAtual

    if !IsObject(SA_CardPressionado)
        return

    dados := SA_CardPressionado
    SA_CardPressionado := 0

    if (SA_CardsInterativos.Has(hwnd) && SA_CardsInterativos[hwnd] = dados) {
        SA_CardHoverAtual := dados
        AtualizarCorCard(dados, dados.hover)
    } else {
        AtualizarCorCard(dados, dados.normal)
        SA_CardHoverAtual := 0
    }
}