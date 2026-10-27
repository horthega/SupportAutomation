#Requires AutoHotkey v2.0
#SingleInstance Force

#Include OCR.ahk
#Include UIA.ahk
#Include PersonalizeAqui.ahk

SetTitleMatchMode 2
CoordMode "Mouse", "Client"

PastaImagens := A_ScriptDir "\Imagens"

global avisoAcrylicHwnd := 0
OnMessage(0x0014, WM_ERASEBKGND_Aviso)


MostrarAviso(mensagem, tempo := 3) {
    global avisoAcrylicHwnd

    static avisoGui := 0
    static timerAviso := 0

    ; Cancela o temporizador anterior
    if IsObject(timerAviso) {
        try SetTimer(timerAviso, 0)
        timerAviso := 0
    }

    ; Fecha o aviso anterior
    if IsObject(avisoGui) {
        try avisoGui.Destroy()
        avisoGui := 0
    }

    ; ---------------------------------------------
    ; IDENTIFICA O TIPO DE AVISO
    ; ---------------------------------------------

    rodape := "SUPPORTAUTOMATION  |  INFORMAÇÃO"
    corRodape := "B0BEC5"

    corpo := Trim(mensagem)

    if (InStr(corpo, "✓") || InStr(corpo, "✅")) {
        rodape := "SUPPORTAUTOMATION  |  SUCESSO"
        corRodape := "66E3A2"
    }
    else if InStr(corpo, "❌") {
        rodape := "SUPPORTAUTOMATION  |  ERRO"
        corRodape := "FF7A84"
        TocarSom("Error.mp3")
    }
    else if InStr(corpo, "⚠") {
        rodape := "SUPPORTAUTOMATION  |  ATENÇÃO"
        corRodape := "FFC45C"
    }

    ; ---------------------------------------------
    ; REMOVE SÍMBOLOS DO INÍCIO
    ; PRESERVA AS QUEBRAS DE LINHA
    ; ---------------------------------------------

    corpo := RegExReplace(corpo, "^[✓✅❌⚠️\s]+", "")
    corpo := Trim(corpo)

    ; Normaliza as quebras de linha do Windows
    corpo := StrReplace(corpo, "`r`n", "`n")
    corpo := StrReplace(corpo, "`r", "`n")

    ; ---------------------------------------------
    ; QUEBRA O TEXTO AUTOMATICAMENTE
    ; PRESERVA AS QUEBRAS DE LINHA ORIGINAIS
    ; ---------------------------------------------

    linhas := []
    maiorLinha := 0

    ; Processa cada parágrafo separadamente
    for paragrafo in StrSplit(corpo, "`n") {

        ; Normaliza espaços e tabulações,
        ; sem remover as quebras de linha
        paragrafo := Trim(
            RegExReplace(paragrafo, "[ \t]+", " ")
        )

        ; Preserva linhas vazias
        if (paragrafo = "") {
            linhas.Push("")
            continue
        }

        palavras := StrSplit(paragrafo, " ")
        linhaAtual := ""

        ; Quebra linhas longas automaticamente
        for palavra in palavras {

            if (linhaAtual = "") {
                linhaAtual := palavra
            }
            else if (
                StrLen(linhaAtual) + 1 + StrLen(palavra) <= 42
            ) {
                linhaAtual .= " " . palavra
            }
            else {
                linhas.Push(linhaAtual)

                maiorLinha := Max(
                    maiorLinha,
                    StrLen(linhaAtual)
                )

                linhaAtual := palavra
            }
        }

        if (linhaAtual != "") {
            linhas.Push(linhaAtual)

            maiorLinha := Max(
                maiorLinha,
                StrLen(linhaAtual)
            )
        }
    }

    ; ---------------------------------------------
    ; MONTA O TEXTO FINAL COM AS QUEBRAS DE LINHA
    ; ---------------------------------------------

    corpoExibido := ""

    for i, linha in linhas {
        if (i > 1)
            corpoExibido .= "`n"

        corpoExibido .= linha
    }

    ; ---------------------------------------------
    ; CALCULA O TAMANHO DO BALÃO
    ; ---------------------------------------------

    larguraTexto := Min(440, Max(260, maiorLinha * 8))
    largura := larguraTexto + 44

    alturaTexto := Max(24, linhas.Length * 24)
    yDivisor := 16 + alturaTexto + 10
    yRodape := yDivisor + 10
    altura := yRodape + 16 + 12

    ; ---------------------------------------------
    ; CRIA A JANELA
    ; ---------------------------------------------

    avisoGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    avisoGui.BackColor := "263238"
    avisoGui.MarginX := 0
    avisoGui.MarginY := 0

    ; Registra a janela para o Acrylic
    avisoAcrylicHwnd := avisoGui.Hwnd

    ; Mensagem principal
    avisoGui.SetFont("s11 cFFFFFF", "Segoe UI")

    opcoesTexto := "x22 y16 w" . larguraTexto
        . " h" . alturaTexto . " BackgroundTrans"

    avisoGui.AddText(opcoesTexto, corpoExibido)

    ; Divisor
    opcoesDivisor := "x22 y" . yDivisor
        . " w" . larguraTexto . " h1 Background45515B"

    avisoGui.AddText(opcoesDivisor, "")

    ; Rodapé
    avisoGui.SetFont("s8 c" . corRodape, "Segoe UI")

    opcoesRodape := "x22 y" . yRodape
        . " w" . larguraTexto . " h16 BackgroundTrans"

    avisoGui.AddText(opcoesRodape, rodape)

    ; ---------------------------------------------
    ; POSIÇÃO E ANIMAÇÃO
    ; ---------------------------------------------

    x := A_ScreenWidth - largura - 24
    y := A_ScreenHeight - altura - 60

    distanciaAnimacao := 20
    passosAnimacao := 12

    ; Cria a janela inicialmente oculta,
    ; ligeiramente à direita da posição final
    avisoGui.Show(
        "Hide x" . (x + distanciaAnimacao)
        . " y" . y
        . " w" . largura
        . " h" . altura
    )

    ; Aplica o efeito Acrylic
    resultadoAcrylic := AplicarAcrylic(
        avisoGui.Hwnd,
        0xB0,
        0x263238
    )

    ; Solicita os cantos arredondados do Windows 11
    cantos := Buffer(4, 0)
    NumPut("Int", 2, cantos, 0)

    resultadoCantos := DllCall(
        "dwmapi\DwmSetWindowAttribute",
        "Ptr", avisoGui.Hwnd,
        "UInt", 33,
        "Ptr", cantos.Ptr,
        "UInt", 4,
        "Int"
    )

    ; Desativa temporariamente a pausa automática
    atrasoAnterior := SetWinDelay(-1)

    try {
        ; Exibe sem roubar o foco
        avisoGui.Show("NoActivate")

        ; Melhora temporariamente a precisão do Sleep
        precisaoTimerAtivada :=
            (DllCall("Winmm\timeBeginPeriod", "UInt", 1) = 0)

        try {
            ; Desliza a janela inteira para a esquerda
            Loop passosAnimacao {
                deslocamento := Round(
                    distanciaAnimacao
                    * (passosAnimacao - A_Index)
                    / passosAnimacao
                )

                WinMove(
                    x + deslocamento,
                    y,
                    ,
                    ,
                    "ahk_id " . avisoGui.Hwnd
                )

                DllCall("Sleep", "UInt", 8)
            }
        } finally {
            ; Restaura a precisão do temporizador
            if precisaoTimerAtivada {
                DllCall(
                    "Winmm\timeEndPeriod",
                    "UInt",
                    1
                )
            }
        }
    } finally {
        ; Restaura a configuração anterior do WinMove
        SetWinDelay(atrasoAnterior)
    }

    ; ---------------------------------------------
    ; FECHAMENTO AUTOMÁTICO
    ; ---------------------------------------------

    timerAviso := ObjBindMethod(avisoGui, "Destroy")

    SetTimer(
        timerAviso,
        -Max(1, Round(tempo * 1000))
    )
}

WM_ERASEBKGND_Aviso(wParam, lParam, msg, hwnd) {
    global avisoAcrylicHwnd

    if (hwnd = avisoAcrylicHwnd)
        return 1
}

AplicarAcrylic(hwnd, alpha := 0xB0, corRGB := 0x263238) {
    static WCA_ACCENT_POLICY := 19
    static ACCENT_ENABLE_ACRYLICBLURBEHIND := 4

    ; Converte RGB para BGR
    r := (corRGB >> 16) & 0xFF
    g := (corRGB >> 8) & 0xFF
    b := corRGB & 0xFF

    corBGR := (b << 16) | (g << 8) | r
    corAcrylic := (alpha << 24) | corBGR

    ; Configura a política Acrylic
    politica := Buffer(16, 0)
    NumPut("Int", ACCENT_ENABLE_ACRYLICBLURBEHIND, politica, 0)
    NumPut("Int", 0, politica, 4)
    NumPut("UInt", corAcrylic, politica, 8)
    NumPut("Int", 0, politica, 12)

    ; Prepara os dados para a API do Windows
    dados := Buffer(A_PtrSize = 8 ? 24 : 12, 0)
    NumPut("UInt", WCA_ACCENT_POLICY, dados, 0)
    NumPut("Ptr", politica.Ptr, dados, A_PtrSize = 8 ? 8 : 4)
    NumPut("UInt", 16, dados, A_PtrSize = 8 ? 16 : 8)

    ; Aplica o efeito
    return DllCall(
        "user32\SetWindowCompositionAttribute",
        "Ptr", hwnd,
        "Ptr", dados.Ptr,
        "Int"
    )
}

TocarSom(arquivo) {
    caminho := A_ScriptDir . "\sons\" . arquivo

    if FileExist(caminho)
        SoundPlay(caminho)
}

;=========================
; CAPTURA DE TEXTO
;========================= 

F1::{
    Send "#+t"
}

;=========================
; PESQUISA DE CLIENTE
;=========================

F2::{
    A_Clipboard := ""
    Send "^c"

    if !ClipWait(1){
        MostrarAviso("❌ Nenhum texto selecionado.")
        return
    }

    txt := Trim(A_Clipboard)

    ; ---------------------------------------------
    ; IDENTIFICA SE O TEXTO ORIGINAL É UM LOGIN
    ; ---------------------------------------------

    ehLogin := RegExMatch(
        txt,
        "i)^(LOGIN PPPoE|LOGIN)\s*:?\s*"
    )

    ; ---------------------------------------------
    ; REMOVE RÓTULOS
    ; ---------------------------------------------

    txt := RegExReplace(
        txt,
        "i)^(CPF|CNPJ|CLIENTE|LOGIN PPPoE|LOGIN|NOME)\s*:?\s*"
    )

    nums := RegExReplace(txt, "\D")

    ; ---------------------------------------------
    ; IDENTIFICA O TIPO DA PESQUISA
    ; ---------------------------------------------

    if (StrLen(nums) = 11 || StrLen(nums) = 14){
        pesquisa := nums
        tipo := StrLen(nums) = 11 ? "CPF" : "CNPJ"

    } else if RegExMatch(
        txt,
        "^[\d\s.\-\/]+$"
    ) && RegExMatch(txt, "\d"){
        pesquisa := nums
        tipo := "CPF/CNPJ"

    } else if ehLogin || (
        RegExMatch(
            txt,
            "^[A-Za-z0-9._-]+$"
        ) && RegExMatch(txt, "\d")
    ){
        pesquisa := txt
        tipo := "Login PPPoE"

    } else {
        pesquisa := txt
        tipo := "Nome"
    }

    ; ---------------------------------------------
    ; PROCURA DIRETAMENTE A ABA DO IXC
    ; ---------------------------------------------

    nomeAba := "linq telecom"
    encontrado := false

    for hwnd in WinGetList(){

        try{
            processo := WinGetProcessName("ahk_id " hwnd)

            if !RegExMatch(
                processo,
                "i)^(chrome|msedge|firefox|brave|opera|vivaldi)\.exe$"
            ){
                continue
            }

            janelaUIA := UIA.ElementFromHandle(hwnd,,0)

            abas := janelaUIA.FindElements({
                Type: "TabItem"
            })

            for i, aba in abas{

                tituloAba := StrLower(
                    Trim(aba.Name)
                )

                if InStr(tituloAba, nomeAba){

                    if !WinActive("ahk_id " hwnd){

                        WinActivate "ahk_id " hwnd

                        if !WinWaitActive(
                            "ahk_id " hwnd,
                            ,
                            0.4
                        ){
                            continue
                        }
                    }

                    aba.Select()

                    encontrado := true
                    break
                }
            }

            if encontrado
                break

        } catch {
            continue
        }
    }

    ; ---------------------------------------------
    ; SE NÃO ENCONTROU A ABA
    ; ---------------------------------------------

    if !encontrado{
        MostrarAviso("❌ Não foi possível localizar a aba do IXC.")
        return
    }

    Sleep 80

    ; ---------------------------------------------
    ; LOCALIZA O CAMPO DE PESQUISA VIA OCR
    ;
    ; 1. Procura "Contém"
    ; 2. Procura "Todos" e clica 270 pixels à direita
    ; 3. Pressiona ESC até 5 vezes e tenta novamente
    ; ---------------------------------------------

    campoEncontrado := false
    tipoCampo := ""

    Loop 6 {

        ; Captura novamente a região após cada tentativa
        WinGetClientPos &wx, &wy, &ww, &wh, "A"

        xOCR := wx + Round(ww * 0.18)
        yOCR := wy + Round(wh * 0.08)
        wOCR := Round(ww * 0.50)
        hOCR := Round(wh * 0.17)

        resultadoCampo := OCR.FromRect(
            xOCR,
            yOCR,
            wOCR,
            hOCR,
            {
                lang: "pt-BR",
                scale: 2.5
            }
        )

        ; ---------------------------------------------
        ; TENTATIVA 1 — "CONTÉM"
        ; ---------------------------------------------

        for palavra in resultadoCampo.Words{

            textoPalavra := StrLower(
                Trim(palavra.Text)
            )

            ; Normaliza "Contém" para "contem"
            textoPalavra := StrReplace(
                textoPalavra,
                "é",
                "e"
            )

            if InStr(textoPalavra, "contem"){

                palavra.Click()

                campoEncontrado := true
                tipoCampo := "contem"
                break
            }
        }

        if campoEncontrado
            break

        ; ---------------------------------------------
        ; TENTATIVA 2 — "TODOS" + 270 PIXELS
        ; ---------------------------------------------

        for palavra in resultadoCampo.Words{

            textoPalavra := StrLower(
                Trim(palavra.Text)
            )

            if InStr(textoPalavra, "todos"){

                xClique := Round(
                    palavra.x + palavra.w / 2 + 270
                )

                yClique := Round(
                    palavra.y + palavra.h / 2
                )

                ; O OCR fornece coordenadas de tela
                modoMouseAnterior := A_CoordModeMouse
                CoordMode "Mouse", "Screen"

                Click xClique, yClique

                CoordMode "Mouse", modoMouseAnterior

                campoEncontrado := true
                tipoCampo := "todos"
                break
            }
        }

        if campoEncontrado
            break

        ; ---------------------------------------------
        ; TENTATIVA 3 — FECHA JANELAS INTERNAS
        ; Máximo de 5 pressionamentos de ESC
        ; ---------------------------------------------

        if (A_Index <= 5){
            Send "{Esc}"
            Sleep 90
        }
    }

    ; ---------------------------------------------
    ; SE NÃO ENCONTROU O CAMPO
    ; ---------------------------------------------

    if !campoEncontrado{
        MostrarAviso(
            "❌ Não foi possível localizar o campo de pesquisa do IXC, verifique a resolução ou zoom da tela.",
            7
        )
        return
    }

    ; ---------------------------------------------
    ; LIMPA O CAMPO DE PESQUISA
    ; ---------------------------------------------

    Sleep 80
    Send "^a"
    Sleep 30
    Send "{Backspace}"
    Sleep 80

    ; ---------------------------------------------
    ; COLOCA A NOVA PESQUISA
    ; ---------------------------------------------

    A_Clipboard := pesquisa

    Sleep 15
    Send "^v"
    Sleep 25
    Send "{Enter}"

    ; ---------------------------------------------
    ; FINALIZA
    ; ---------------------------------------------
    TocarSom("completed.mp3")
    MostrarAviso("✓ Pesquisa realizada!")
}
F3::{
    A_Clipboard := ""
    Send "^c"

    if !ClipWait(1){
        MostrarAviso("❌ Não foi possível copiar o endereço.")
        return
    }

    t := Trim(A_Clipboard)

    ; Normaliza o texto
    t := StrReplace(t, "`r", " ")
    t := StrReplace(t, "`n", " ")
    t := RegExReplace(t, "\s+", " ")
    t := Trim(t)

    ; Normaliza variações
    t := RegExReplace(t, "i)Complemento\s+Endereço\s*:", "Complemento:")

    ; Extrai os campos independentemente da ordem
    e := ExtrairCampo(t, "Endereço")
    num := ExtrairCampo(t, "Número|NUMERO")
    cond := ExtrairCampo(t, "Condomínio")
    bairro := ExtrairCampo(t, "Bairro")
    apt := ExtrairCampo(t, "Apartamento|Apto")
    cidade := ExtrairCampo(t, "Cidade")
    estado := ExtrairCampo(t, "Estado")
    comp := ExtrairCampo(t, "Complemento")
    referencia := ExtrairCampo(t, "Referência")

    arr := []

    ; Endereço
    e := Trim(e, " ,;-")
    if e != ""
        arr.Push(e)

    ; Número
    num := Trim(num, " ,;-")

    if !(num = "" || RegExMatch(num, "i)^(SN|S/N|-)$"))
        arr.Push(num)

    ; Condomínio
    cond := Trim(cond, " ,;-")

    if cond != ""
        arr.Push(cond)

    ; Bairro
    bairro := Trim(bairro, " ,;-")

    if bairro != ""
        arr.Push(bairro)

    ; Apartamento
    apt := Trim(apt, " ,;-")

    if !(apt = "" || apt = "-")
        arr.Push("Apartamento " apt)

    ; Cidade + Estado
    cidade := Trim(cidade, " ,;-")
    estado := Trim(estado, " ,;-")

    localidade := ""

    if cidade != ""
        localidade := cidade

    if estado != ""{
        if localidade != ""
            localidade .= " - " estado
        else
            localidade := estado
    }

    if localidade != ""
        arr.Push(localidade)

    ; Complemento
    comp := Trim(comp, " ,;-")

    if comp != ""{

        for w in ["QUADRA", "LOTE", "CASA", "SALA", "BLOCO", "TORRE", "ANDAR"]
            comp := RegExReplace(comp, "\s+" w, ", " w)

        comp := Trim(comp, " ,;-")

        if comp != ""
            arr.Push(comp)
    }

    ; Referência
    referencia := Trim(referencia, " ,;-")

    if referencia != ""
        arr.Push(referencia)

    ; Remove duplicidades
    arrFinal := []

    for v in arr{

        v := Trim(v, " ,;-")

        if v = ""
            continue

        repetido := false

        for existente in arrFinal{
            if StrLower(existente) = StrLower(v){
                repetido := true
                break
            }
        }

        if !repetido
            arrFinal.Push(v)
    }

    ; Monta o resultado
    out := ""

    for i, v in arrFinal{

        if i > 1
            out .= ", "

        out .= v
    }

    A_Clipboard := "Endereço: " out "`n"

    TocarSom("AddressFormatting.mp3")
    MostrarAviso("✓ Endereço formatado e copiado!")
}

ExtrairCampo(txt, nomes){
    campos := "Endereço|CEP|Número|NUMERO|Condomínio|Bairro|Apartamento|Apto|Cidade|Estado|Complemento|Referência|Bloco"

    padrao := "i)(?:" nomes ")\s*:\s*(.*?)(?=\s*(?:" campos ")\s*:|$)"

    if RegExMatch(txt, padrao, &m)
        return Trim(m[1])

    return ""
}

;=========================
; LOGIN EM ROTEADORES
;=========================

F4::{
    ; -------------------------------------------------
    ; COPIA O IPV4 SELECIONADO
    ; -------------------------------------------------

    A_Clipboard := ""
    Send "^c"

    if !ClipWait(1){
        MostrarAviso("❌ Selecione o IPv4.")
        return
    }

    ip := Trim(A_Clipboard)

    ; Verifica se o conteúdo parece ser um IPv4
    if !RegExMatch(ip, "^\d{1,3}(?:\.\d{1,3}){3}$"){
        MostrarAviso("❌ O texto selecionado não parece ser um IPv4.")
        return
    }

    ; -------------------------------------------------
    ; ABRE NOVA GUIA E ACESSA O IP
    ; -------------------------------------------------

    Send "^t"
    Sleep 100
    SendText ip
    Sleep 50
    Send "{Enter}"

    ; -------------------------------------------------
    ; DETECÇÃO INICIAL
    ;
    ; 1. Huawei
    ; 2. TP-Link
    ; 3. Zyxel pelo texto dos campos de login
    ; 4. Tela de certificado
    ; -------------------------------------------------

    CoordMode "Pixel", "Screen"

    inicio := A_TickCount
    roteador := ""

    ; Coordenadas onde o campo de usuário será clicado
    zyxelClickX := 0
    zyxelClickY := 0

    while (A_TickCount - inicio < 10000){

        ; ---------------------------------------------
        ; HUAWEI DIRETO
        ; ---------------------------------------------

        if ImageSearch(
            &x,
            &y,
            0,
            0,
            A_ScreenWidth,
            A_ScreenHeight * 0.25,
            "*100 " PastaImagens "\HuaweiLogo.png"
        ){
            roteador := "Huawei"
            break
        }

        ; ---------------------------------------------
        ; TP-LINK DIRETO
        ; ---------------------------------------------

        if ImageSearch(
            &x,
            &y,
            0,
            0,
            A_ScreenWidth,
            A_ScreenHeight * 0.35,
            "*100 " PastaImagens "\TPLinkHeader.png"
        ){
            roteador := "TP-Link"
            break
        }

        ; ---------------------------------------------
        ; ZYXEL PELOS CAMPOS DE LOGIN
        ; ---------------------------------------------

        if DetectarZyxel(&zyxelClickX, &zyxelClickY){
            roteador := "Zyxel"
            break
        }

        ; ---------------------------------------------
        ; TELA DE CERTIFICADO VIA OCR
        ; ---------------------------------------------

        if DetectarTelaCertificado(){
            roteador := "Certificado"
            break
        }

        Sleep 100
    }

    ; -------------------------------------------------
    ; NÃO IDENTIFICOU NADA NA DETECÇÃO INICIAL
    ; -------------------------------------------------

    if (roteador = ""){

        TocarSom("alert2.mp3")
        MostrarAviso(
            "⚠️ Sem gerência ou roteador não compatível com a automação.",
            7
        )
        return
    }

    ; -------------------------------------------------
    ; CAMINHO COM CERTIFICADO
    ; -------------------------------------------------

    if (roteador = "Certificado"){

        navegador := WinGetProcessName("A")

        ; ---------------------------------------------
        ; CHROME
        ; ---------------------------------------------

        if (navegador = "chrome.exe"){

            ; Vai para "Avançadas"
            Send "{Tab}"
            Send "{Tab}"
            Send "{Tab}"
            Send "{Tab}"
            Send "{Enter}"

            Sleep 200

            ; Vai para o link do IP do roteador
            Send "{Tab}"
            Send "{Enter}"
        }

        ; ---------------------------------------------
        ; EDGE
        ; ---------------------------------------------

        else if (navegador = "msedge.exe"){

            ; Vai para "Avançado"
            Send "{Tab}"
            Send "{Tab}"
            Send "{Enter}"

            Sleep 200

            ; Vai para o link do IP do roteador
            Send "{Tab}"
            Send "{Enter}"
        }

        ; ---------------------------------------------
        ; OUTRO NAVEGADOR
        ; ---------------------------------------------

        else{
            TocarSom("alert2.mp3")
            MostrarAviso(
                "⚠️ Navegador não compatível com o fluxo do certificado.",
                5
            )
            return
        }

        ; -------------------------------------------------
        ; DEPOIS DO CERTIFICADO, IDENTIFICA O FABRICANTE
        ; -------------------------------------------------

        inicio := A_TickCount
        roteador := ""

        while (A_TickCount - inicio < 7000){

            ; ---------------------------------------------
            ; HUAWEI
            ; ---------------------------------------------

            if ImageSearch(
                &x,
                &y,
                0,
                0,
                A_ScreenWidth,
                A_ScreenHeight * 0.25,
                "*100 " PastaImagens "\HuaweiLogo.png"
            ){
                roteador := "Huawei"
                break
            }

            ; ---------------------------------------------
            ; TP-LINK
            ; ---------------------------------------------

            if ImageSearch(
                &x,
                &y,
                0,
                0,
                A_ScreenWidth,
                A_ScreenHeight * 0.35,
                "*100 " PastaImagens "\TPLinkHeader.png"
            ){
                roteador := "TP-Link"
                break
            }

            ; ---------------------------------------------
            ; ZYXEL PELOS CAMPOS DE LOGIN
            ; ---------------------------------------------

            if DetectarZyxel(&zyxelClickX, &zyxelClickY){
                roteador := "Zyxel"
                break
            }

            ; Evita repetir as verificações sem pausa
            Sleep 100
        }

        ; ---------------------------------------------
        ; NÃO IDENTIFICOU APÓS O CERTIFICADO
        ; ---------------------------------------------

        if (roteador = ""){
            TocarSom("alert2.mp3")
            MostrarAviso(
                "⚠️ Não foi possível identificar o roteador.",
                5
            )
            return
        }
    }

    ; -------------------------------------------------
    ; HUAWEI
    ; -------------------------------------------------

    if (roteador = "Huawei"){

        TocarSom("completed.mp3")
        MostrarAviso("✓ Huawei detectado")

        SendText "LinQ@12345"
        Send "{Enter}"

        return
    }

    ; -------------------------------------------------
    ; TP-LINK
    ; -------------------------------------------------

    if (roteador = "TP-Link"){

        TocarSom("completed.mp3")
        MostrarAviso("✓ TP-Link detectado")

        SendText "LinQ@12345"
        Send "{Enter}"

        return
    }

    ; -------------------------------------------------
    ; ZYXEL
    ; -------------------------------------------------

    if (roteador = "Zyxel"){

        TocarSom("completed.mp3")
        MostrarAviso("✓ Zyxel detectado")

        ; Aguarda a tela de login estar pronta
        ;Sleep 20
        ; Usa coordenadas de tela para clicar
        ; na posição calculada pelo OCR
        modoMouseAnterior := A_CoordModeMouse
        CoordMode "Mouse", "Screen"

        Click zyxelClickX, zyxelClickY

        ; Restaura o modo de coordenadas anterior
        CoordMode "Mouse", modoMouseAnterior

        ; Usuário
        SendText "admin"

        ; Senha
        Send "{Tab}"
        SendText "LinQ@12345"

        ; Login
        Send "{Enter}"

        return
    }
}

; -------------------------------------------------
; FUNÇÃO: DETECTAR TELA DE CERTIFICADO
; -------------------------------------------------

DetectarTelaCertificado(){
    try{
        WinGetClientPos &wx, &wy, &ww, &wh, "A"

        x := wx + Round(ww * 0.10)
        y := wy + Round(wh * 0.05)
        w := Round(ww * 0.80)
        h := Round(wh * 0.70)

        resultado := OCR.FromRect(
            x,
            y,
            w,
            h,
            {
                lang: "pt-BR",
                scale: 1.5
            }
        )

        texto := StrLower(resultado.Text)

        if InStr(texto, "sua conexão não é privada")
            return true

        if InStr(texto, "sua conexão não é particular")
            return true

        if InStr(texto, "a sua ligação não é privada")
            return true

        if InStr(texto, "a sua ligacao nao e privada")
            return true

        if InStr(texto, "err_cert_authority_invalid")
            return true

    } catch {
        return false
    }

    return false
}

; -------------------------------------------------
; FUNÇÃO: DETECTAR ZYXEL E LOCALIZAR O CAMPO DE USUÁRIO
; -------------------------------------------------

DetectarZyxel(&zyxelClickX, &zyxelClickY){
    try{
        WinGetClientPos &wx, &wy, &ww, &wh, "A"

        ; Área de captura usada no diagnóstico
        xOCR := wx
        yOCR := wy
        wOCR := Round(ww * 0.75)
        hOCR := Round(wh * 0.40)

        resultado := OCR.FromRect(
            xOCR,
            yOCR,
            wOCR,
            hOCR,
            {
                lang: "pt-BR",
                scale: 3.0
            }
        )

        ; Procura o rótulo do campo de usuário
        encontrado := ""

        rotulos := [
            "User Name",
            "Nome de utilizador",
        ]

        for rotulo in rotulos {
            try {
                encontrado := resultado.FindString(rotulo)
                break
            } catch {
                continue
            }
        }

        ; Se nenhum rótulo for localizado, encerra a detecção
        if !IsObject(encontrado)
            return false

        ; A posição retornada corresponde à tela,
        ; pois a captura foi feita com OCR.FromRect
        retangulo := encontrado.BoundingRect

        ; Clica no centro horizontal do rótulo,
        ; 40 pixels abaixo dele
        zyxelClickX := retangulo.x + Round(retangulo.w / 2)
        zyxelClickY := retangulo.y + 40

        return true

    } catch {
        return false
    }
}


; =====================================================
; F6 - CONTATO OU CONTATO + PROTOCOLO FORTICS
; =====================================================

F6::{
    ; Se soltar antes de 0,2 segundo
    if KeyWait("F6", "T0.2"){
        ExecutarF6(true)
    } else {
        ; Se mantiver pressionado por 0,2 segundo
        ExecutarF6(false)

        ; Evita nova execução enquanto continua segurando
        KeyWait("F6")
    }
}

; PROCESSAMENTO DO F6
ExecutarF6(copiarProtocolo := false){

    ; Guarda o clipboard atual
    clipboardAnterior := A_Clipboard

    try{
        ; ---------------------------------------------
        ; PEGA A ÁREA ÚTIL DA JANELA ATUAL
        ; ---------------------------------------------

        WinGetClientPos &wx, &wy, &ww, &wh, "A"

        ; ---------------------------------------------
        ; REGIÃO DO CABEÇALHO DO CONTATO
        ; ---------------------------------------------

        xOCR := wx + Round(ww * 0.15)
        yOCR := wy + Round(wh * 0.05)

        wOCR := Round(ww * 0.32)
        hOCR := Round(wh * 0.20)

        ; ---------------------------------------------
        ; FAZ OCR AUTOMATICAMENTE
        ; ---------------------------------------------

        resultadoOCR := OCR.FromRect(
            xOCR,
            yOCR,
            wOCR,
            hOCR,
            {
                lang: "pt-BR",
                scale: 2.5
            }
        )

        ; ---------------------------------------------
        ; CONVERTE AS LINHAS PARA UM ARRAY SIMPLES
        ; ---------------------------------------------

        linhas := []

        for linha in resultadoOCR.Lines{
            textoLinha := Trim(linha.Text)

            if (textoLinha != "")
                linhas.Push(textoLinha)
        }

        ; ---------------------------------------------
        ; PROCURA "SUPORTE"
        ; ---------------------------------------------

        indiceSuporte := 0

        for i, linha in linhas{
            if InStr(StrLower(linha), "suporte"){
                indiceSuporte := i
                break
            }
        }

        ; ---------------------------------------------
        ; PROCURA O TELEFONE
        ; ---------------------------------------------

        telefone := ""
        indiceTelefone := 0

        ; TENTATIVA 1 - PRÓXIMO À PALAVRA "SUPORTE"

        if (indiceSuporte > 1){

            inicioBusca := Max(1, indiceSuporte - 4)
            i := indiceSuporte - 1

            while (i >= inicioBusca){

                linhaAtual := Trim(linhas[i])
                numeros := RegExReplace(linhaAtual, "\D")

                if RegExMatch(
                    numeros,
                    "^55\d{10,11}",
                    &correspondencia
                ){
                    telefone := correspondencia[0]
                    indiceTelefone := i
                    break
                }

                i--
            }
        }

        ; ---------------------------------------------
        ; TENTATIVA 2 - TODAS AS LINHAS
        ; ---------------------------------------------

        if (telefone = ""){

            for i, linhaAtual in linhas{

                numeros := RegExReplace(linhaAtual, "\D")

                if RegExMatch(
                    numeros,
                    "^55\d{10,11}",
                    &correspondencia
                ){
                    telefone := correspondencia[0]
                    indiceTelefone := i
                    break
                }
            }
        }

        ; ---------------------------------------------
        ; RECUPERAÇÃO - OCR COM REGIÃO MAIOR
        ; Executado somente se a primeira leitura falhar
        ; ---------------------------------------------

        if (telefone = ""){

            xOCR := wx + Round(ww * 0.10)
            yOCR := wy + Round(wh * 0.02)

            wOCR := Round(ww * 0.44)
            hOCR := Round(wh * 0.25)

            resultadoOCR := OCR.FromRect(
                xOCR,
                yOCR,
                wOCR,
                hOCR,
                {
                    lang: "pt-BR",
                    scale: 3.5
                }
            )

            ; Reconstrói as linhas da nova captura
            linhas := []

            for linha in resultadoOCR.Lines{

                textoLinha := Trim(linha.Text)

                if (textoLinha != "")
                    linhas.Push(textoLinha)
            }

            ; Procura o telefone em qualquer linha
            for i, linhaAtual in linhas{

                numeros := RegExReplace(
                    linhaAtual,
                    "\D"
                )

                if RegExMatch(
                    numeros,
                    "55\d{10,11}",
                    &correspondencia
                ){
                    telefone := correspondencia[0]
                    indiceTelefone := i
                    break
                }
            }
        }

        ; ---------------------------------------------
        ; VALIDA SE O TELEFONE FOI ENCONTRADO
        ; ---------------------------------------------

        if (telefone = ""){

            A_Clipboard := clipboardAnterior

            MostrarAviso(
                "❌ Não foi possível identificar o telefone. Tente novamente."
            )

            return
        }

        ; ---------------------------------------------
        ; REMOVE O CÓDIGO DO BRASIL
        ; ---------------------------------------------

        telefone := SubStr(telefone, 3)

        ; ---------------------------------------------
        ; MODO 1 - SOMENTE CONTATO
        ; ---------------------------------------------

        if (!copiarProtocolo){
            
            A_Clipboard := telefone

            TocarSom("ContactCopy.mp3")

            MostrarAviso(
                "✓ Contato identificado! " telefone
            )

            return
        }

        ; ---------------------------------------------
        ; MODO 2 - CONTATO + PROTOCOLO FORTICS
        ; ---------------------------------------------

        protocolo := ExtrairProtocoloFortics()

        ; Se não encontrar o protocolo, mantém o telefone
        if (protocolo = ""){

            A_Clipboard := telefone

            TocarSom("ContactCopy.mp3")

            MostrarAviso(
                "⚠️ Contato copiado, mas não foi possível identificar o protocolo do Fortics."
            )

            return
        }

        ; ---------------------------------------------
        ; MONTA O TEXTO FINAL
        ; ---------------------------------------------

        resultadoFinal := telefone
        resultadoFinal .= "`nPROTOCOLO DO FORTICS: "
        resultadoFinal .= protocolo

        ; Substitui o conteúdo anterior do clipboard
        A_Clipboard := resultadoFinal

        TocarSom("ContactCopy.mp3")

        ; ---------------------------------------------
        ; AVISO FINAL
        ; ---------------------------------------------

        avisoFinal := "✓ Informações identificadas!`r`n"
        avisoFinal .= "`r`n"
        avisoFinal .= "Contato: " telefone "`r`n"
        avisoFinal .= "Protocolo do Fortics:  " protocolo

        MostrarAviso(avisoFinal)

    } catch as erro {

        A_Clipboard := clipboardAnterior

        MsgBox(
            "ERRO AO IDENTIFICAR O CONTATO:`n`n"
            erro.Message
        )
    }
}

; EXTRAIR PROTOCOLO DO FORTICS
ExtrairProtocoloFortics(){

    try{
        WinGetClientPos &wx, &wy, &ww, &wh, "A"

        ; ---------------------------------------------
        ; PRIMEIRA LEITURA: LOCALIZA O RÓTULO
        ; ---------------------------------------------

        xPainel := wx + Round(ww * 0.72)
        yPainel := wy + Round(wh * 0.10)
        wPainel := Round(ww * 0.28)
        hPainel := Round(wh * 0.80)

        resultadoPainel := OCR.FromRect(
            xPainel,
            yPainel,
            wPainel,
            hPainel,
            {
                lang: "pt-BR",
                scale: 3.0
            }
        )

        ; Procura a palavra Protocolo
        rotulo := resultadoPainel.FindString("Protocolo")

        ; Posição do rótulo encontrado
        retangulo := rotulo.BoundingRect

        ; ---------------------------------------------
        ; SEGUNDA LEITURA: AMPLIA A LINHA DO PROTOCOLO
        ; ---------------------------------------------

        xLinha := Max(wx, retangulo.x - 8)
        yLinha := Max(wy, retangulo.y - 12)

        limiteDireito := wx + ww
        limiteInferior := wy + wh

        wLinha := limiteDireito - xLinha
        hLinha := Max(50, retangulo.h + 30)

        if (yLinha + hLinha > limiteInferior)
            hLinha := limiteInferior - yLinha

        resultadoLinha := OCR.FromRect(
            xLinha,
            yLinha,
            wLinha,
            hLinha,
            {
                lang: "pt-BR",
                scale: 6.0
            }
        )

        textoLinha := Trim(resultadoLinha.Text)

        ; ---------------------------------------------
        ; EXTRAI O NÚMERO DA LINHA AMPLIADA
        ; ---------------------------------------------

        if RegExMatch(
            textoLinha,
            "\d(?:[\s.-]*\d){9,19}",
            &mProtocolo
        ){

            protocolo := RegExReplace(
                mProtocolo[0],
                "\D"
            )

            if (
                StrLen(protocolo) >= 10
                && StrLen(protocolo) <= 20
            ){
                return protocolo
            }
        }

        ; ---------------------------------------------
        ; DIAGNÓSTICO SE O NÚMERO NÃO FOR RECONHECIDO
        ; ---------------------------------------------

        MsgBox(
            "O rótulo Protocolo foi encontrado, mas o número não."
            "`n`nTexto da linha ampliada:"
            "`n" textoLinha
        )

    } catch as erro {

        MsgBox(
            "Erro ao localizar o protocolo do Fortics:"
            "`n`n" erro.Message
        )
    }

    return ""
}


; =====================================================
; PREENCHER PLANILHA DE MANUTENÇÃO E ABRIR ROTAS
; =====================================================

F7::{
    ; ---------------------------------------------
    ; IDENTIFICA O CONTEÚDO DA ÁREA DE TRANSFERÊNCIA
    ; ---------------------------------------------

    textoOS := Trim(A_Clipboard)
    textoMaiusculo := StrUpper(textoOS)

    ; PRIMEIRO: VERIFICA SE É UMA OS
    ehOS := (
        InStr(textoMaiusculo, "NOME")
        && InStr(textoMaiusculo, "RECLAMAÇÃO")
        && InStr(textoMaiusculo, "LOGIN")
    )

    ; ---------------------------------------------
    ; SE NÃO FOR OS, VERIFICA SE É ENDEREÇO ISOLADO
    ; ---------------------------------------------

    if !ehOS {

        if RegExMatch(
            textoOS,
            "i)\b(?:ENDEREÇO|AVENIDA|RUA|QUADRA|LOTE)\b"
        ) {
            ; Tenta extrair o endereço após o rótulo.
            if RegExMatch(
                textoOS,
                "im)^[ \t]*ENDEREÇO(?:[ \t]+CONFIRMADO)?[ \t]*:[ \t]*(.+?)[ \t]*$",
                &mEnderecoDireto
            ) {
                enderecoDireto := Trim(mEnderecoDireto[1])
            } else {
                ; Sem o rótulo, utiliza o texto completo.
                enderecoDireto := textoOS
            }

            if (enderecoDireto = "") {
                MostrarAviso("❌ O campo ENDEREÇO está vazio.")
                return
            }

            EnviarEnderecoParaRotas(enderecoDireto, false)
            return
        }

        MostrarAviso(
            "❌ O texto copiado não parece ser uma OS nem conter um endereço."
        )
        return
    }

    ; A PARTIR DAQUI, CONTINUA O FLUXO ATUAL DA OS.

    ; ---------------------------------------------
    ; EXTRAI NOME
    ; ---------------------------------------------

    if !RegExMatch(
        textoOS,
        "im)^[ \t]*NOME[^\r\n:]*:[ \t]*(.+?)[ \t]*$",
        &mNome
    ){
        MostrarAviso("❌ Não foi possível localizar o NOME na OS.")
        return
    }

    nome := Trim(mNome[1])

    ; ---------------------------------------------
    ; EXTRAI LOGIN
    ; ---------------------------------------------

    if !RegExMatch(
        textoOS,
        "im)^[ \t]*LOGIN[ \t]*:[ \t]*(.+?)[ \t]*$",
        &mLogin
    ){
        MostrarAviso("❌ Não foi possível localizar o LOGIN na OS.")
        return
    }

    login := Trim(mLogin[1])

    ; ---------------------------------------------
    ; DATA DE ABERTURA
    ; ---------------------------------------------

    dataAbertura := FormatTime(A_Now, "dd/MM/yyyy")

    ; ---------------------------------------------
    ; EXTRAI E CONVERTE PERÍODO
    ; ---------------------------------------------

    if !RegExMatch(
        textoOS,
        "i)\b(?:HORA|PER[IÍ]ODO(?:[ \t]+AGENDADO)?)[ \t]*:[ \t]*([^\r\n]+)",
        &mHora
    ){
        MostrarAviso(
            "❌ Não foi possível localizar o período na OS."
            "`nCertifique de colocar o horário ou período no campo correspondente.",
            5
        )
        return
    }

    periodoOriginal := Trim(mHora[1])
    periodo := ObterPeriodoF7(periodoOriginal)

    if (periodo = ""){
        MostrarAviso(
            "❌ Não reconheci o período: " periodoOriginal
            "`nConfira as opções disponíveis na planilha.",
            5
        )
        return
    }

    ; ---------------------------------------------
    ; EXTRAI E CONVERTE CAUSA
    ; ---------------------------------------------

    if !RegExMatch(
        textoOS,
        "i)\bRECLAMAÇÃO(?:[ \t]*/[ \t]*MOTIVO)?[^\r\n:]*:[ \t]*([^\r\n]+)",
        &mCausa
    ){
        MostrarAviso(
            "❌ Não foi possível localizar a RECLAMAÇÃO/MOTIVO."
        )
        return
    }

    causaOriginal := Trim(mCausa[1])
    causa := ObterCausaF7(causaOriginal)

    ; ---------------------------------------------
    ; EXTRAI ENDEREÇO
    ; ---------------------------------------------

    if !RegExMatch(
        textoOS,
        "im)^[ \t]*ENDEREÇO(?:[ \t]+CONFIRMADO)?[ \t]*:[ \t]*(.+?)[ \t]*$",
        &mEndereco
    ){
        MostrarAviso("❌ Não foi possível localizar o endereço na OS.")
        return
    }

    endereco := Trim(mEndereco[1])

    ; ---------------------------------------------
    ; FASE 1 - PREENCHE A PLANILHA
    ; O usuário deve selecionar a célula NOME.
    ; ---------------------------------------------

    ; NOME
    A_Clipboard := nome
    Sleep 50
    Send "^v"
    Sleep 120
    Send "{Tab}"
    Sleep 50

    ; LOCALIZAÇÃO / LOGIN
    A_Clipboard := login
    Sleep 50
    Send "^v"
    Sleep 120
    Send "{Tab}"
    Sleep 50

    ; DATA DE ABERTURA
    A_Clipboard := dataAbertura
    Sleep 70
    Send "^v"
    Sleep 120
    Send "{Tab}"

    ; PERÍODO
    A_Clipboard := periodo
    Sleep 50
    Send "^v"
    Sleep 120
    Send "{Tab}"
    Sleep 50

    ; CAUSA
    A_Clipboard := causa
    Sleep 50
    Send "^v"
    Sleep 150

    ; PULA ATÉ A COLUNA REGIÃO
    Sleep 150
    Send "{Tab 6}"
    Send "{Enter}"

    ; ---------------------------------------------
    ; FASE 2 - ACESSA ROTAS SUPORTE
    ; ---------------------------------------------

    EnviarEnderecoParaRotas(endereco, true)
}

; =====================================================
; FUNÇÕES AUXILIARES PARA O F7
; =====================================================

; ENVIA ENDEREÇO PARA ROTAS SUPORTE
EnviarEnderecoParaRotas(endereco, planilhaPreenchida := false) {

    ; ---------------------------------------------
    ; MANTÉM O ENDEREÇO NA ÁREA DE TRANSFERÊNCIA
    ; ---------------------------------------------

    A_Clipboard := endereco
    Sleep 500

    ; ---------------------------------------------
    ; ACESSA A ABA ROTAS SUPORTE
    ; ---------------------------------------------

    try {
        navegadorUIA := UIA.ElementFromHandle("A")

        abaRotas := navegadorUIA.FindElement({
            Type: "TabItem",
            Name: "ROTAS SUPORTE",
            matchmode: 2,
            casesense: false
        })

        abaRotas.Click()

    } catch as erro {
        A_Clipboard := endereco

        TocarSom("alert2.mp3")
        MostrarAviso(
            "⚠️ Não foi possível localizar a aba ROTAS SUPORTE."
            . "`nO endereço continua na área de transferência.",
            5
        )
        return
    }

    Sleep 500

    ; ---------------------------------------------
    ; FECHA EVENTUAL JANELA DE ATALHOS DO MAPA
    ; ---------------------------------------------

    Send "{Esc}"
    Sleep 150

    ; ---------------------------------------------
    ; OCR - VERIFICA SE EXISTE COMPARTILHAR
    ; ---------------------------------------------

    temCompartilhar := false

    try {
        resultadoRotas := OCR.FromRect(
            0,
            0,
            Min(410, A_ScreenWidth),
            A_ScreenHeight,
            {
                lang: "pt-BR",
                scale: 2.5
            }
        )

        textoPainel := StrUpper(resultadoRotas.Text)

        temCompartilhar := InStr(
            textoPainel,
            "COMPARTILHAR"
        ) > 0

    } catch {
        ; Se o OCR falhar, utiliza o fluxo alternativo.
        temCompartilhar := false
    }

    ; ---------------------------------------------
    ; CONFIGURA CLIQUES POR COORDENADAS CLIENT
    ; ---------------------------------------------

    CoordMode "Mouse", "Client"

    ; ---------------------------------------------
    ; FLUXO 1 - TELA INICIAL DO MAPA DE ROTAS
    ; ---------------------------------------------

    if (temCompartilhar) {

        Click 168, 850
        Sleep 100

        Send "+{Tab}"
        Send "+{Tab}"
        Send "{Enter}"

        Sleep 150

        A_Clipboard := endereco
        Send "^v"
        Sleep 300
        Send "{Enter}"

    } else {

        ; -----------------------------------------
        ; FLUXO 2 - OUTRA TELA DO MAPA DE ROTAS
        ; -----------------------------------------

        Click 168, 850
        Sleep 200

        Send "+{Tab}"
        Sleep 150
        Send "+{Tab}"
        Sleep 150
        Send "{Enter}"
        Sleep 200

        A_Clipboard := endereco
        Send "^v"
        Sleep 500

        Send "{Enter}"
    }

    ; ---------------------------------------------
    ; AVISO FINAL
    ; ---------------------------------------------

    TocarSom("success.mp3")

    if (planilhaPreenchida) {
        MostrarAviso(
            "✓ Planilha preenchida e endereço enviado para ROTAS SUPORTE."
        )
    } else {
        MostrarAviso(
            "✓ Endereço enviado para ROTAS SUPORTE."
        )
    }
}
; LOCALIZA UM TEXTO PELO OCR
; ---------------------------------------------
LocalizarTextoOCRF7(resultado, termos){
    for termo in termos {
        try {
            encontrado := resultado.FindString(termo)

            if IsObject(encontrado){
                retangulo := encontrado.BoundingRect

                if IsObject(retangulo)
                    return retangulo
            }
        } catch {
            continue
        }
    }

    return false
}

; NORMALIZA TEXTO PARA COMPARAÇÃO
; ---------------------------------------------
NormalizarTextoF7(texto){
    texto := StrUpper(Trim(texto))

    substituicoes := [
        ["Á", "A"],
        ["À", "A"],
        ["Â", "A"],
        ["Ã", "A"],
        ["Ä", "A"],
        ["É", "E"],
        ["È", "E"],
        ["Ê", "E"],
        ["Ë", "E"],
        ["Í", "I"],
        ["Ì", "I"],
        ["Î", "I"],
        ["Ï", "I"],
        ["Ó", "O"],
        ["Ò", "O"],
        ["Ô", "O"],
        ["Õ", "O"],
        ["Ö", "O"],
        ["Ú", "U"],
        ["Ù", "U"],
        ["Û", "U"],
        ["Ü", "U"],
        ["Ç", "C"]
    ]

    for par in substituicoes
        texto := StrReplace(texto, par[1], par[2])

    return texto
}

; CONVERTE O PERÍODO
; Para os valores exatos do menu suspenso.
; ---------------------------------------------
ObterPeriodoF7(texto){
    p := NormalizarTextoF7(texto)

    if InStr(p, "QUALQUER")
        return "QUALQUER HORARIO"

    if InStr(p, "MANHA") || InStr(p, "9h") || InStr(p, "9 horas") || InStr(p, "11h") || InStr(p, "11 horas")
        return "MANHA"

    if InStr(p, "TARDE") || InStr(p, "15h") || InStr(p, "15 horas") || InStr(p, "13h") || InStr(p, "13 horas") || InStr(p, "17h") || InStr(p, "17 horas")
        return "TARDE"

    if InStr(p, "NOITE")
        return "NOITE"

    if InStr(p, "8h") || InStr(p, "8 horas")
        return "08:00 até 10:00"

    if InStr(p, "10h") || InStr(p, "10 horas")
        return "10:00 ate 12:00"

    if InStr(p, "12h") || InStr(p, "12 horas")
        return "12:00 até 14:00"

    if InStr(p, "14h") || InStr(p, "14 horas")
        return "14:00 até 16:00"

    if InStr(p, "16h") || InStr(p, "16 horas")
        return "16:00 até 18:00"

    if InStr(p, "18h") || InStr(p, "18 horas") || InStr(p, "noite")
        return "APÓS 18:00"

    return ""
}

; MAPEIA A CAUSA
; Para uma das opções aceitas pela planilha.
; ---------------------------------------------
ObterCausaF7(texto){
    c := NormalizarTextoF7(texto)

    if InStr(c, "HOME HELP")
        return "HOME HELP"

    if InStr(c, "RECHAMADO") && InStr(c, "NIVEL 2")
        return "RECHAMADO NIVEL 2"

    if InStr(c, "RECHAMADO")
        return "RECHAMADO"

    if InStr(c, "INCLUSAO DE ROTEADOR") || InStr(c, "UPGRADE") || InStr(c, "INCLUIR SEGUNDO PONTO")
        return "INCLUSAO DE ROTEADOR"

    if InStr(c, "TROCAR") && InStr(c, "ROTEADOR")
        return "TROCA DE ROTEADOR"

    if InStr(c, "SENHA") && InStr(c, "TROCAR") || InStr(c, "ALTERAR")
        return "TROCA DE SENHA"

    if InStr(c, "Mudar o roteador") || InStr(c, "MUDANÇA DE PONTO") || InStr(c, "MUDAR O PONTO")
        return "MUDANÇA DE PONTO"

    if InStr(c, "LENTID") || InStr(c, "OSCIL") || InStr(c, "LENTO")
        return "LENTIDÃO"

    if InStr(c, "QUEDA") || InStr(c, "CAINDO")
        return "QUEDAS"

    if InStr(c, "SEM CONEXAO") || InStr(c, "SEM INTERNET") || InStr(c, "LOS") || InStr(c, "SEM SINAL")
        return "SEM CONEXÃO"

    if InStr(c, "Problema") && InStr(c, "repetidor") || InStr(c, "Segundo ponto") || InStr(c, "MESH") 
        return "OUTROS"

    ; Causa não identificada: opção genérica válida
    return "OUTROS"
}

;=========================
; ENVIO DO PROTOCOLO
;=========================

; SÓ O PROTOCOLO
!p::{
    protocolo := Trim(A_Clipboard)

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ Copie um protocolo válido antes de usar esta função.")
        return
    }
    TocarSom("Protocol.mp3")
    SendText "Segue o protocolo: " protocolo
}

; PROTOCOLO COM ENCERRAMENTO POR INATIVIDADE
!e::{
    protocolo := Trim(A_Clipboard)

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ Copie um protocolo válido antes de usar esta função.")
        return
    }

    TocarSom("Protocol.mp3")
    texto := "Olá,`n`n"
          . "Encerramos o atendimento devido à falta de comunicação. Caso seu atendimento não tenha sido concluído, por favor, entre em contato conosco novamente.`n`n"
          . "Segue o protocolo do atendimento: " protocolo "`n`n"
          . "A LinQ agradece o seu contato e será um prazer ajudar você! 😉🤝"

    A_Clipboard := texto
    Sleep 50
    Send "^v"
}

; PROTOCOLO COM TRANSFERÊNCIA
!t::{
    protocolo := Trim(A_Clipboard)

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ Copie um protocolo válido antes de usar esta função.")
        return
    }
    TocarSom("Protocol.mp3")
    SendText "Nesse caso irei transferir o seu atendimento para o departamento responsável. Segue o protocolo: " protocolo
}

; PROTOCOLO COM FINALIZAÇÃO
!q::{
    protocolo := Trim(A_Clipboard)

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ Copie um protocolo válido antes de usar esta função.")
        return
    }

    if !InStr(MensagemFinalizacao, "{PROTOCOLO}") {
        MostrarAviso("❌ A mensagem de finalização está sem o marcador {PROTOCOLO}.")
        return
    }

    texto := StrReplace(
        MensagemFinalizacao,
        "{PROTOCOLO}",
        protocolo
    )

    A_Clipboard := texto

    Sleep 50

    TocarSom("Protocol.mp3")
    Send "^v"
}

;=========================
; FRASEOLOGIAS
;=========================

; FINALIZAÇÃO DE ATENDIMENTO
>+a:: {
    SendText "Auxilio você em algo mais no momento?"
}
; MOMENTO PARA VERIFICAÇÃO
>^a::{
    SendText "Aguarde um momento enquanto verifico por gentileza"
}
; APREENTAÇÃO SEM PERGUNTA
!a::{
    global NomeAtendente

    saudacao := ObterSaudacao()

    if (saudacao = ""){
        TocarSom("alert2.mp3")
        MostrarAviso("⚠️ Horário fora do período configurado.")
        return
    }

    texto := saudacao " Sou " NomeAtendente ", do suporte técnico da LinQ Telecom. Vou seguir com o seu atendimento. Um momento, por favor, enquanto verifico a conversa."

    SendText texto
}
; PROTOCOLO COM BLOQUEIO FINANCEIRO
!b::{
    protocolo := Trim(A_Clipboard)

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ O texto copiado não parece ser um protocolo válido.")
        return
    }

    texto := "Verifiquei que sua conexão entrou em bloqueio automático devido a mensalidade em aberto. Vou te transferir para o setor responsável. Segue o protocolo: " protocolo

    A_Clipboard := texto
    Sleep 50
    Send "^v"
}
;SOLICITAR CPF/CNPJ
!c::{
    SendText "Poderia, por gentileza, me informar o CPF/CNPJ do contrato?"
}
;CPF/CNPJ NÃO ENCONTRADO
<^>!c::{
    SendText "Por gentileza, poderia verificar se o CPF/CNPJ informado está correto? Não consegui localizá-lo em nossa base."
}
; PEDIR FOTOS DOS EQUIPAMENTOS
!f::{
    global NomeAtendente

    SendText "Poderia me enviar fotos dos equipamentos da LinQ por favor para eu verificar as luzes dele?"
}
; CHAMADO JÁ ABERTO
<^>!j::{
    SendText "Já tem um chamado em aberto, somente aguardar que o técnico entrará em contato quando estiver indo ao local."
}
; EXPLICAÇÃO DO LOS
<^>!l::
{
    texto := "
    (
A luz vermelha (LOS) acesa indica algum problema na fibra que pode estar rompida ou dobrada.

Como existem diferentes possíveis causas, será aberta uma solicitação de visita técnica para verificação no local e identificar a origem do problema.

O prazo de execução é de até 24 horas.
    )"

    A_Clipboard := texto
    Sleep 50
    Send "^v"

    MostrarAviso("✓ Mensagem de LOS enviada!")
}
; PERGUNTA COMPLETA
<^>!o::{
    SendText "O que você estava acessando na internet na hora que percebeu esse problema? Se puder me dar um exemplo na prática, pois isso ajuda a entender melhor a situação, a verificar e poder resolver."
}
; PRAZO DE FALHA
<^>!p::{
    SendText "Prazo de normalização até às "
}
; CLIENTE RELATOU QUEDAS MAS A CONEXÃO RETORNOU
<^>!v::{
    SendText "Verifiquei aqui em nosso sistema e consta que a sua conexão retornou, verifique se está normal agora, por favor"
}
; CLIENTE RELATOU QUEDAS MAS A CONEXÃO ESTÁ NORMAL
!v::{
    SendText "Verifiquei aqui em nosso sistema e consta que a sua conexão está normal, está aparecendo algum erro de rede? É em todos os dispositivos? Se for possível me enviar uma foto, melhor ainda!"
}
; APREENTAÇÃO COM PERGUNTA
<!SC073::{
    global NomeAtendente

    saudacao := ObterSaudacao()

    if (saudacao = ""){
        TocarSom("alert2.mp3")
        MostrarAviso("⚠️ Horário fora do período configurado.")
        return
    }

    texto := saudacao " Eu sou " NomeAtendente ", do suporte técnico da LinQ Telecom. É um prazer atendê-lo(a). Em que posso auxiliá-lo(a) hoje?"

    SendText texto
}
ObterSaudacao(){
    hora := Integer(A_Hour)

    if (hora >= 5 && hora < 12){
        return "Bom dia!"

    } else if (hora >= 12 && hora < 18){
        return "Boa tarde!"

    } else if (hora >= 18 && hora <= 23){
        return "Boa noite!"

    } else {
        return ""
    }
}
; ============================================================
; MENSAGENS DE PRAZO, PROTOCOLO E PROCEDIMENTOS REMOTOS
; ============================================================
!Numpad0::{
    SendText "Verifiquei que houve um atraso devido a alta demanda de atendimentos na região, mas irei solicitar prioridade para que o técnico vá no seu endereço o quanto antes."
}
!Numpad1::{
    SendText "Certo, irei realizar um procedimento na sua conexão e reiniciar ela, retire o roteador da tomada, aguarde 10 segundos e conecte novamente. Quando fizer o procedimento me avise por favor."
}
!Numpad2::{
    EnviarMensagemPrazo("24 horas")
}
!Numpad3::{
    SendText "Retire o roteador da tomada, aguarde 30 segundos e conecte novamente, por favor."
}
!Numpad4::{
    EnviarMensagemPrazo("48 horas")
}
!Numpad7::{
    EnviarMensagemPrazo("72 horas")
    
}
!Numpad5::{
    protocolo := Trim(A_Clipboard)

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ Copie um protocolo válido antes de usar esta função.")
        return
    }

    texto := "
    (
    Certo, foi aberto uma solicitação com prazo máximo para execução de até 5 dias úteis, podendo ser bem antes dependendo da rota do técnico.

    Somente aguardar que ele entrará em contato quando for ao local. Segue o protocolo deste atendimento: [protocolo]
    )"

    texto := StrReplace(
        texto,
        "[protocolo]",
        protocolo
    )

    A_Clipboard := texto

    Sleep 50
    TocarSom("Protocol.mp3")
    Send "^v"
}

; ============================================================
; FUNÇÃO PARA 24h / 48h / 72h
; ============================================================

EnviarMensagemPrazo(prazo){
    protocolo := Trim(A_Clipboard)

    ; ---------------------------------------------
    ; VALIDA O PROTOCOLO
    ; ---------------------------------------------

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ Copie um protocolo válido antes de usar esta função.")
        return
    }

    ; ---------------------------------------------
    ; MENSAGEM
    ; ---------------------------------------------

    texto := "
    (
    Certo! Seu chamado foi aberto e encaminhado para a equipe técnica.

    *O prazo para execução é de até [prazo],* o técnico fará o possível para ir o quanto antes, ele entrará em contato quando estiver a caminho.

    Segue o protocolo: [protocolo]
    )"

    ; ---------------------------------------------
    ; SUBSTITUI OS MARCADORES
    ; ---------------------------------------------

    texto := StrReplace(
        texto,
        "[prazo]",
        prazo
    )

    texto := StrReplace(
        texto,
        "[protocolo]",
        protocolo
    )

    ; ---------------------------------------------
    ; COLOCA NO CLIPBOARD E COLA
    ; ---------------------------------------------

    A_Clipboard := texto

    Sleep 50
    TocarSom("Protocol.mp3")
    Send "^v"
}

; ============================================================
; PREENCHIMENTO DE O.S.
; ============================================================

!1::{
    TocarSom("O.S.Filling.mp3")
    SendText "Cliente com lentidão. Feito procedimento remoto e voltou ao normal"
}
!2::{
    TocarSom("O.S.Filling.mp3")
    SendText "Cliente contestou a velocidade, foi dado as devidas explicações e o mesmo compreendeu"
}
!3::{
    TocarSom("O.S.Filling.mp3")
    SendText "Foi setado o DNS do google 8.8.8.8 e 8.8.4.4"
}
!4::{
    TocarSom("O.S.Filling.mp3")
    SendText "Conexão do cliente voltou/normalizou após reinício do roteador"
}
!5::{
    TocarSom("O.S.Filling.mp3")
    SendText "Cliente falou que a conexão normalizou"
}
!6::{
    TocarSom("O.S.Filling.mp3")
    SendText "Foi explicado para o cliente sobre às redes 2.4G e 5G"
}
!7::{
    TocarSom("O.S.Filling.mp3")
    SendText "Cliente solicitou uma posição do seu atendimento, foi solicitado prioridade passado previsão para o cliente"
}


; ============================================================
; PASSO A PASSOS E LISTAS
; ============================================================

; ATIVAÇÃO HBO MAX
AppsKey & h::{
    clipboardOriginal := A_Clipboard

    ; Procura um e-mail no conteúdo copiado
    if !RegExMatch(
        clipboardOriginal,
        "i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}",
        &correspondenciaEmail
    ){
        MostrarAviso("❌ Copie um e-mail válido antes de usar este atalho.")
        return
    }

    email := correspondenciaEmail[0]

    texto := "
    (
    *Como ativar sua HBO Max™ pela Watch Brasil (ativação é feita apenas uma vez)*

    Passo 1: Acesse a Watch Brasil: https://play.watch.tv.br/ative
    Passo 2: Entre utilizando seu e-mail cadastrado: [e-mail]
    Passo 3: Clique no banner da HBO Max™
    Passo 4: Você será direcionado para a página de ativação.

    Se você já possui uma conta HBO Max™: faça login utilizando suas credenciais.
    Se você ainda não possui uma conta HBO Max™: preencha os dados solicitados para concluir o cadastro.

    Depois de ativado, você pode assistir por:

    📱 Celular/Tablet:
    Baixe o app HBO Max™ (Google Play ou App Store). Toque em "Entrar" e faça login com o e-mail e senha da Watch.

    📺 Smart TV:
    Instale o app HBO Max™ na loja de aplicativos da sua TV. Faça login com o e-mail e senha da Watch.

    💻 Navegador (PC/celular):
    Acesse a Watch e clique no banner da HBO Max™. Faça login com os dados da Watch.

    👉 Clique no link abaixo e aprenda o passo a passo!
    https://canva.link/wdjkejta2v62int

    Qualquer dúvida, estamos à disposição!
    )"

    ; Substitui o marcador pelo e-mail copiado
    texto := StrReplace(texto, "[e-mail]", email)

    A_Clipboard := texto
    Sleep 50
    Send "^v"

    MostrarAviso("✓ Instruções de ativação HBO Max")
}
; ATIVAÇÃO DISNEY+
AppsKey & d::{
    texto := "
    (
    *🎬 Como ativar o Disney+*

    1️⃣ Acesse o Portal do Assinante:
    https://www.portaldoassinante.com/linq

    Entre com o número de celular cadastrado e ative o Disney+.

    Após isso, aguarde um SMS com o link de ativação.

    2️⃣ Clique no link recebido no SMS: https://ativefacil.com.br/

    3️⃣ Informe seu número de telefone cadastrado e avance.

    4️⃣ Digite o código de segurança enviado por SMS ou WhatsApp.

    5️⃣ Clique em “Ativar” para acessar o site do Disney+.

    6️⃣ Crie sua conta informando um e-mail e senha.

    7️⃣ Aceite os termos de uso.

    8️⃣ Configure seu perfil e pronto! 🎉

    Agora é só aproveitar o Disney+.
    )"

    A_Clipboard := texto
    Sleep 50
    Send "^v"

    MostrarAviso("✓ Instruções de ativação Disney+")
}
; ACESSO AO ROTEADOR
AppsKey & r::{
    texto := "
    (
    *Como acessar o roteador:*

    1- Abra qualquer navegador em algum aparelho que esteja conectado na rede Wi-Fi ou por cabo de rede.

    2- Digite o número de IP 192.168.1.1 e pressione Enter até abrir a tela de login do roteador.

    3- Coloque o nome de usuário "admin" (se pedir) e a senha de acesso "LinQ@12345".
    )"

    A_Clipboard := texto
    Sleep 50
    Send "^v"

    MostrarAviso("✓ Instruções de acesso ao roteador enviadas!")
}
AppsKey & u::{
    texto := "
    (
    ATIVAR UBOOK
    NOME:
    Telefone:
    E-mail:
    CPF:
    )"

    A_Clipboard := texto
    Sleep 50
    Send "^v"

    MostrarAviso("✓ Ativação de Ubook!")
}
AppsKey & q::{
    texto := "
    (
    Entendi, me fale qual desses sinais você notou no seu dispositivo quando notou a queda:

    1 - Apareceu "conectado, sem internet"
    2 - O símbolo do Wi-Fi sumiu
    3 - Apareceu um ponto de exclamação (!) no ícone do Wi-Fi
    4 - Aparece uma mensagem de erro de rede no site ou aplicativo
    5 - Outro
    )"

    A_Clipboard := texto
    Sleep 50
    Send "^v"

    MostrarAviso("✓ validação de quedas enviada!")
}
; ============================================================
; MENSAGEMS TEMPORÁRIA
; ============================================================

; PRIMEIRA FRASE
!w::{
global frase1

    A_Clipboard := frase1
    Sleep 50
    Send "^v"

    MostrarAviso("✓ Mensagem temporária 1 enviada!")
}
!z::{
global frase2

    A_Clipboard := frase2
    Sleep 50
    Send "^v"
    TocarSom("O.S.Filling.mp3")
    MostrarAviso("✓ Mensagem temporária 2 enviada!")
}