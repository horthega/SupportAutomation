#Requires AutoHotkey v2.0

;@Ahk2Exe-SetVersion 2.3.0
#SingleInstance Force
#MaxThreadsPerHotkey 2

IUIAutomationActivateScreenReader := 0

#Include OCR.ahk
#Include UIA.ahk
#Include Personalizaveis.ahk
#Include Interface.ahk
#Include Atualizacao.ahk

TraySetIcon(A_ScriptDir "\Imagens\IDV\Logo.ico")

SetTitleMatchMode 2
CoordMode "Mouse", "Client"

PastaImagens := A_ScriptDir "\Imagens"

global avisoAcrylicHwnd := 0
OnMessage(0x0014, WM_ERASEBKGND_Aviso)

global F7_EmExecucao := false
global F7_Cancelar := false
global F7_CancelamentoAvisado := false

InicializarInterface()
InicializarAtualizacao()

MostrarAviso(mensagem, tempo := 3) {
    global avisoAcrylicHwnd
    global AvisosAtivos

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
        TocarSom("alert3.mp3")
    }

    if !AvisosAtivos
    return

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
    global SonsAtivos

    if !SonsAtivos
        return

    caminho := A_ScriptDir . "\sons\" . arquivo

    if FileExist(caminho)
        SoundPlay(caminho)
}

; =============================================
; COPIAR NÚMERO DA CHAMADA DO 3CXPHONE
; =============================================
F1::{
    if KeyWait("F1", "T0.2") {
        ExecutarF1()
    } else {
        ExecutarF1(true)
        KeyWait("F1")
    }
}

ExecutarF1(pesquisarIXC := false) {
    try {

        ; Caminho do 3CXPhone
        caminho3CX := "C:\Program Files (x86)\3CXPhone\3CXPhone.exe"

        ; Verifica se o aplicativo já está aberto
        hwnd := WinExist("ahk_exe 3CXPhone.exe")

        ; Se estiver fechado, abre o aplicativo
        if !hwnd {

            Run('"' . caminho3CX . '"')

            hwnd := WinWait(
                "ahk_exe 3CXPhone.exe",
                ,
                10
            )

            if !hwnd
                throw Error("Não foi possível abrir o 3CXPhone.")
        }

        ; Ativa a janela do telefone
        WinActivate("ahk_id " hwnd)

        if !WinWaitActive("ahk_id " hwnd, , 5)
            throw Error("Não foi possível ativar o 3CXPhone.")

        ; ---------------------------------------------
        ; CAPTURA A REGIÃO DO NÚMERO
        ; ---------------------------------------------

        WinGetClientPos &wx, &wy, &ww, &wh, "ahk_id " hwnd

        xOCR := wx + Round(ww * 0.08)
        yOCR := wy + Round(wh * 0.10)

        wOCR := Round(ww * 0.84)
        hOCR := Round(wh * 0.30)

        ; ---------------------------------------------
        ; IDENTIFICA O NÚMERO PELO OCR
        ; ---------------------------------------------

        resultadoOCR := OCR.FromRect(
            xOCR,
            yOCR,
            wOCR,
            hOCR,
            {
                lang: "pt-BR",
                scale: 4.0
            }
        )

        ; Procura um número com 10 ou 11 dígitos
        if RegExMatch(
            resultadoOCR.Text,
            "(?<!\d)\d{10,11}(?!\d)",
            &mNumero
        ) {

            numero := mNumero[0]

            ; Copia somente o número
            A_Clipboard := numero

            TocarSom("ContactCopy.mp3")

            MostrarAviso(
                "✓ Número copiado do 3CXPhone! " numero,
                5
            )

            ; Se for pressionamento longo, pesquisa no IXC
            if pesquisarIXC
                ExecutarF2(false, numero)

        } else {

            ; No modo longo, não inicia a pesquisa
            if pesquisarIXC {
                MostrarAviso(
                    "❌ Não foi possível identificar o número da chamada.",
                    5
                )
            } else {
                ; Preserva o comportamento original do F1 rápido
                TocarSom("alert2.mp3")

                MostrarAviso(
                    "❌ Não foi possível identificar o número da chamada.",
                    5
                )
            }
        }

    } catch as erro {

        MostrarAviso(
            "❌ Erro ao acessar o 3CXPhone:`n" erro.Message,
            5
        )
    }
}

;=========================
; PESQUISA DE CLIENTE
;=========================
F2::{
    if KeyWait("F2", "T0.2") {
        ExecutarF2()
    } else {
        ExecutarF2(true)
        KeyWait("F2")
    }
}

ExecutarF2(copiarContato := false, textoInformado := "") {

    ; Se recebeu um número diretamente, utiliza esse número.
    ; Caso contrário, mantém a cópia normal do texto selecionado.

    if (textoInformado = "") {

        A_Clipboard := ""
        Send "^c"

        if !ClipWait(1) {
            MostrarAviso("❌ Nenhum texto selecionado.")
            return
        }

        txt := Trim(A_Clipboard)

    } else {
        txt := Trim(textoInformado)
    }

    resultadoContato := ""

    if copiarContato {
        A_Clipboard := ""

        try {
            ExecutarF6(true, false)
            resultadoContato := A_Clipboard
        } catch {
            resultadoContato := ""
        }
    }

    ; ---------------------------------------------
    ; IDENTIFICA SE O TEXTO ORIGINAL É UM LOGIN
    ; ---------------------------------------------

    ehLogin := RegExMatch(txt, "i)^(LOGIN PPPoE|LOGIN)\s*.*\s*")

    ; ---------------------------------------------
    ; REMOVE RÓTULOS
    ; ---------------------------------------------

    txt := RegExReplace(txt, "i)^(CPF|CNPJ|CLIENTE|LOGIN PPPoE|LOGIN|NOME)\s*:?\s*")

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
    Sleep 500
    Send "{Enter}"

    ; ---------------------------------------------
    ; FINALIZA
    ; ---------------------------------------------

    if copiarContato {

        if (resultadoContato != "") {
            A_Clipboard := resultadoContato

            if InStr(resultadoContato, "PROTOCOLO DO FORTICS:") {
                MostrarAviso("✓ Pesquisa realizada e número e protocolo copiados!")
            } else {
                MostrarAviso("⚠️ Pesquisa realizada, mas o protocolo não foi identificado. Contato copiado.", 5)
            }

        } else {
            MostrarAviso("⚠️ Pesquisa realizada, porém não foi possível copiar o contato e protocolo.", 5)
        }

    } else {
        MostrarAviso("✓ Pesquisa realizada!")
    }

    if (!copiarContato || InStr(resultadoContato, "PROTOCOLO DO FORTICS:"))
    TocarSom("completed.mp3")
}

; =====================================================
; FORMATAÇÃO DE ENDEREÇO
; Pressionamento rápido: Formata e copia o endereço normalmente.
; Pressionamento por 0,2 segundo: Formata e copia com a frase de confirmação.
; =====================================================

F3::{
    ; Soltou antes de 0,2 segundo: modo normal
    if KeyWait("F3", "T0.2"){
        ExecutarF3(false)
    }
    else{
        ; Atingiu 0,2 segundo: modo com a frase
        ExecutarF3(true)

        ; Impede repetição enquanto continuar pressionado
        KeyWait("F3")
    }
}


; PROCESSAMENTO DO F3
ExecutarF3(confirmarEndereco := false){

    ; Guarda o clipboard atual
    clipboardAnterior := A_Clipboard

    ; ---------------------------------------------
    ; COPIA O TEXTO SELECIONADO
    ; ---------------------------------------------

    A_Clipboard := ""
    Send "^c"

    if !ClipWait(1){
        A_Clipboard := clipboardAnterior
        MostrarAviso("❌ Não foi possível copiar o endereço.")
        return
    }

    t := Trim(A_Clipboard)

    ; ---------------------------------------------
    ; VALIDA SE O TEXTO PARECE SER UM ENDEREÇO
    ;
    ; Palavras aceitas:
    ; Endereço, Rua, Avenida, Quadra ou Lote.
    ; Não aceita apenas parte de outra palavra.
    ; ---------------------------------------------

    if !RegExMatch(
        t,
        "i)(?:^|[^A-Za-zÀ-ÿ])(?:endere[cç]o|rua|avenida|quadra|lote)(?=$|[^A-Za-zÀ-ÿ])"
    ){
        A_Clipboard := clipboardAnterior

        MostrarAviso(
            "❌ O texto selecionado não parece ser um endereço."
        )
        return
    }

    ; ---------------------------------------------
    ; NORMALIZA O TEXTO
    ; ---------------------------------------------

    t := StrReplace(t, "`r", " ")
    t := StrReplace(t, "`n", " ")
    t := RegExReplace(t, "\s+", " ")
    t := Trim(t)

    ; Normaliza variações
    t := RegExReplace(
        t,
        "i)Complemento\s+Endereço\s*:",
        "Complemento:"
    )

    ; ---------------------------------------------
    ; EXTRAI OS CAMPOS INDEPENDENTEMENTE DA ORDEM
    ; ---------------------------------------------

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

    ; ---------------------------------------------
    ; ENDEREÇO
    ; ---------------------------------------------

    e := Trim(e, " ,;-")

    if (e != "")
        arr.Push(e)

    ; ---------------------------------------------
    ; NÚMERO
    ; ---------------------------------------------

    num := Trim(num, " ,;-")

    if !(num = "" || RegExMatch(num, "i)^(SN|S/N|-)$"))
        arr.Push(num)

    ; ---------------------------------------------
    ; CONDOMÍNIO
    ; ---------------------------------------------

    cond := Trim(cond, " ,;-")

    if (cond != "")
        arr.Push(cond)

    ; ---------------------------------------------
    ; BAIRRO
    ; ---------------------------------------------

    bairro := Trim(bairro, " ,;-")

    if (bairro != "")
        arr.Push(bairro)

    ; ---------------------------------------------
    ; APARTAMENTO
    ; ---------------------------------------------

    apt := Trim(apt, " ,;-")

    if !(apt = "" || apt = "-")
        arr.Push("Apartamento " apt)

    ; ---------------------------------------------
    ; CIDADE + ESTADO
    ; ---------------------------------------------

    cidade := Trim(cidade, " ,;-")
    estado := Trim(estado, " ,;-")

    localidade := ""

    if (cidade != "")
        localidade := cidade

    if (estado != ""){
        if (localidade != "")
            localidade .= " - " estado
        else
            localidade := estado
    }

    if (localidade != "")
        arr.Push(localidade)

    ; ---------------------------------------------
    ; COMPLEMENTO
    ; ---------------------------------------------

    comp := Trim(comp, " ,;-")

    if (comp != ""){

        for w in [
            "QUADRA",
            "LOTE",
            "CASA",
            "SALA",
            "BLOCO",
            "TORRE",
            "ANDAR"
        ]{
            comp := RegExReplace(
                comp,
                "i)\s+" w,
                ", " w
            )
        }

        comp := Trim(comp, " ,;-")

        if (comp != "")
            arr.Push(comp)
    }

    ; ---------------------------------------------
    ; REFERÊNCIA
    ; ---------------------------------------------

    referencia := Trim(referencia, " ,;-")

    if (referencia != "")
        arr.Push(referencia)

    ; ---------------------------------------------
    ; REMOVE DUPLICIDADES
    ; ---------------------------------------------

    arrFinal := []

    for v in arr{

        v := Trim(v, " ,;-")

        if (v = "")
            continue

        repetido := false

        for existente in arrFinal{
            if (StrLower(existente) = StrLower(v)){
                repetido := true
                break
            }
        }

        if (!repetido)
            arrFinal.Push(v)
    }

    ; ---------------------------------------------
    ; MONTA O ENDEREÇO FORMATADO
    ; ---------------------------------------------

    out := ""

    for i, v in arrFinal{

        if (i > 1)
            out .= ", "

        out .= v
    }

    ; Impede sucesso se nenhum campo foi extraído
    if (out = ""){
        A_Clipboard := clipboardAnterior

        MostrarAviso(
            "⚠️ Não foi possível extrair os campos do endereço."
        )
        return
    }

    ; ---------------------------------------------
    ; MONTA A SAÍDA CONFORME O TEMPO DE PRESSÃO
    ; ---------------------------------------------

    if (confirmarEndereco){
        resultado := "Me confirme seu Endereço: " out
    }
    else{
        resultado := "Endereço: " out
    }

    ; ---------------------------------------------
    ; COPIA O RESULTADO FINAL
    ; ---------------------------------------------

    A_Clipboard := resultado "`n"

    TocarSom("AddressFormatting.mp3")
    MostrarAviso("✓ Endereço formatado e copiado!")
}

; FUNÇÃO AUXILIAR - EXTRAI CAMPOS DO ENDEREÇO
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
    if KeyWait("F4", "T0.2") {
        ExecutarF4Completo()
    } else {
        ExecutarF4Direto()
        KeyWait("F4")
    }
}

ExecutarF4Completo() {

    global SA_UsuarioRoteador, SA_SenhaRoteador

    if (SA_UsuarioRoteador = "" || SA_SenhaRoteador = "") {
        MostrarAviso("⚠️ Configure as credenciais do roteador antes de utilizar o F4.")
        return
    }

    ; -------------------------------------------------
    ; COPIA O IPV4 SELECIONADO
    ; -------------------------------------------------

    A_Clipboard := ""
    Send "^c"

    if !ClipWait(0.1){
        MostrarAviso("❌ Selecione um IPv4.")
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

    while (A_TickCount - inicio < 7000){

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
        ; TP-LINK VIA OCR — PRIMEIRA OPÇÃO
        ; ---------------------------------------------

        if DetectarTPLink(){
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
            ; TP-LINK VIA OCR — PRIMEIRA OPÇÃO
            ; ---------------------------------------------

            if DetectarTPLink(){
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

        SendText SA_SenhaRoteador
        Send "{Enter}"

        return
    }

    ; -------------------------------------------------
    ; TP-LINK
    ; -------------------------------------------------

    if (roteador = "TP-Link"){

        TocarSom("completed.mp3")
        MostrarAviso("✓ TP-Link detectado")

        SendText SA_SenhaRoteador
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
        SendText SA_UsuarioRoteador
        ; Senha
        Send "{Tab}"
        SendText SA_SenhaRoteador

        ; Login
        Send "{Enter}"

        return
    }
}

; ============================================================
; F4 — LOGIN DIRETO NO ROTEADOR
; ============================================================

ExecutarF4Direto() {

    global PastaImagens, SA_UsuarioRoteador, SA_SenhaRoteador

    if (SA_UsuarioRoteador = "" || SA_SenhaRoteador = "") {
        MostrarAviso("⚠️ Configure as credenciais do roteador antes de utilizar o F4.", 5)
        return
    }

    CoordMode "Pixel", "Screen"

    roteador := ""
    zyxelClickX := 0
    zyxelClickY := 0

    ; Huawei
    if ImageSearch(
        &x,
        &y,
        0,
        0,
        A_ScreenWidth,
        A_ScreenHeight * 0.25,
        "*100 " PastaImagens "\HuaweiLogo.png"
    ) {
        roteador := "Huawei"
    }

    ; TP-Link
    else if DetectarTPLink() {
        roteador := "TP-Link"
    }

    ; Zyxel
    else if DetectarZyxel(&zyxelClickX, &zyxelClickY) {
        roteador := "Zyxel"
    }

    ; Fabricante não identificado
    if (roteador = "") {
        TocarSom("alert2.mp3")
        MostrarAviso(
            "⚠️ Não foi possível identificar o roteador. Verifique se a página está carregada.",
            5
        )
        return
    }

    ; Huawei
    if (roteador = "Huawei") {
        TocarSom("completed.mp3")
        MostrarAviso("✓ Huawei detectado")

        SendText SA_SenhaRoteador
        Send "{Enter}"
        return
    }

    ; TP-Link
    if (roteador = "TP-Link") {
        TocarSom("completed.mp3")
        MostrarAviso("✓ TP-Link detectado")

        SendText SA_SenhaRoteador
        Send "{Enter}"
        return
    }

    ; Zyxel
    if (roteador = "Zyxel") {
        TocarSom("completed.mp3")
        MostrarAviso("✓ Zyxel detectado")

        modoMouseAnterior := A_CoordModeMouse
        CoordMode "Mouse", "Screen"

        Click zyxelClickX, zyxelClickY

        CoordMode "Mouse", modoMouseAnterior

        SendText SA_UsuarioRoteador
        Send "{Tab}"
        SendText SA_SenhaRoteador
        Send "{Enter}"

        return
    }
}

; FUNÇÃO: DETECTAR TELA DE CERTIFICADO
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

; FUNÇÃO: DETECTAR TP-LINK POR OCR
DetectarTPLink(){
    try{
        WinGetClientPos &wx, &wy, &ww, &wh, "A"

        ; Região central da tela
        xOCR := wx + Round(ww * 0.30)
        yOCR := wy + Round(wh * 0.20)
        wOCR := Round(ww * 0.40)
        hOCR := Round(wh * 0.50)

        ; Faz o reconhecimento do texto
        resultado := OCR.FromRect(
            xOCR,
            yOCR,
            wOCR,
            hOCR,
            {
                lang: "pt-BR",
                scale: 2.0
            }
        )

        ; Normaliza o texto reconhecido
        texto := StrLower(resultado.Text)
        texto := RegExReplace(texto, "[^a-z]", "")

        ; Procura TP-Link, ignorando espaços e hífens
        return InStr(texto, "tplink") > 0

    } catch {
        return false
    }
}

; FUNÇÃO: DETECTAR ZYXEL E LOCALIZAR O CAMPO DE USUÁRIO
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
; CONTATO OU CONTATO + PROTOCOLO FORTICS
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

; PROCESSAMENTO DO F6 - EXTRAÇÃO PELA UIA
ExecutarF6(copiarProtocolo := false, exibirAvisoErro := true) {

    etapaF6 := "Localização do Chat Center"
    encontrado := false
    hwndFortics := 0
    painelInfo := 0

    try {
        ; =============================================
        ; PROCURA O CHAT CENTER NAS OUTRAS ABAS
        ; =============================================

        if !encontrado {

            for hwnd in WinGetList() {

                try {
                    processo := WinGetProcessName("ahk_id " hwnd)

                    if !RegExMatch(
                        processo,
                        "i)^(msedge|chrome|brave)\.exe$"
                    ) {
                        continue
                    }

                    janelaUIA := UIA.ElementFromHandle(
                        hwnd,
                        ,
                        0
                    )

                    abas := janelaUIA.FindElements({
                        Type: "TabItem"
                    })

                    for aba in abas {

                        try {

                            ; Verifica se a aba é o Chat Center
                            nomeAba := aba.Name

                            if !InStr(nomeAba, "Chat Center", true)
                                continue

                            ; Ativa somente a janela que contém o Chat Center
                            WinActivate("ahk_id " hwnd)

                            if !WinWaitActive(
                                "ahk_id " hwnd,
                                ,
                                1
                            ) {
                                continue
                            }

                            ; Seleciona a aba atual da busca
                            aba.Select()

                            Sleep 150

                            ; Obtém o documento da aba selecionada
                            documento := UIA.ElementFromChromium(
                                hwnd,
                                1500
                            )

                            ; Procura o painel do contato
                            painelInfo := documento.FindElement({
                                AutomationId: "info_contact"
                            })

                            hwndFortics := hwnd
                            encontrado := true

                            break

                        } catch {
                            continue
                        }
                    }

                    if encontrado
                        break

                } catch {
                    continue
                }
            }
        }

        ; =============================================
        ; VERIFICA SE ENCONTROU O FORTICS
        ; =============================================

        if !encontrado {

            if exibirAvisoErro {
                MsgBox(
                    "Não foi possível localizar o painel de informações do contato."
                    . "`n`nVerifique se o Chat Center está aberto e com um contato selecionado.",
                    "SupportAutomation",
                    "Icon!"
                )
            }

            A_Clipboard := ""
            return
        }

        ; =============================================
        ; IDENTIFICA O TELEFONE
        ; =============================================

        telefone := ""

        elementosTexto := documento.FindElements({
            Type: "Text"
        })

        for elemento in elementosTexto {

            textoElemento := Trim(elemento.Name)

            numeroEncontrado := RegExReplace(
                textoElemento,
                "\D"
            )

            if RegExMatch(
                numeroEncontrado,
                "^55\d{10,11}$"
            ) {
                telefone := SubStr(numeroEncontrado, 3)
                break
            }
        }

        if (telefone = "")
            throw Error("Não foi possível localizar o telefone no documento.")
        ; =============================================
        ; MODO 1 - SOMENTE CONTATO
        ; =============================================

        if (!copiarProtocolo) {

            A_Clipboard := telefone

            if exibirAvisoErro
                TocarSom("ContactCopy.mp3")

            if exibirAvisoErro {
                MostrarAviso(
                    "✓ Contato identificado! " telefone
                )
            }

            return
        }

        ; =============================================
        ; MODO 2 - CONTATO + PROTOCOLO FORTICS
        ; =============================================

        protocolo := ""

        try {

            etapaF6 := "Localização do protocolo"

            elementoProtocolo := painelInfo.FindElement({
                Type: "Link",
                Name: "Protocolo:",
                matchmode: "Substring"
            })

            textoProtocolo := elementoProtocolo.Name

            if RegExMatch(
                textoProtocolo,
                "\d{10,20}",
                &mProtocolo
            ) {
                protocolo := mProtocolo[0]
            }

        } catch {
            protocolo := ""
        }

        ; Se não encontrar o protocolo, mantém o telefone
        if (protocolo = "") {

            A_Clipboard := telefone

            if exibirAvisoErro
                TocarSom("ContactCopy.mp3")

            if exibirAvisoErro {
                MostrarAviso(
                    "⚠️ Contato copiado, mas não foi possível identificar o protocolo do Fortics."
                )
            }

            return
        }

        ; =============================================
        ; MONTA O TEXTO FINAL
        ; =============================================

        resultadoFinal := telefone
        resultadoFinal .= "`nPROTOCOLO DO FORTICS: "
        resultadoFinal .= protocolo

        ; Copia o resultado
        A_Clipboard := resultadoFinal

        if exibirAvisoErro
            TocarSom("ContactCopy.mp3")

        ; =============================================
        ; AVISO FINAL
        ; =============================================

        avisoFinal := "✓ Número e protocolo do fortics copiados!"
        avisoFinal .= "`r`n`r`n"
        avisoFinal .= "Contato: " telefone "`r`n"
        avisoFinal .= "Protocolo do Fortics: " protocolo

        if exibirAvisoErro
            MostrarAviso(avisoFinal)

        } catch as erro {

            if exibirAvisoErro {
                MsgBox(
                    "Etapa: " etapaF6
                    . "`n`nErro: " erro.Message
                    . "`nLinha: " erro.Line,
                    "Diagnóstico F6",
                    "Iconx"
                )
            }

            A_Clipboard := ""
            return
        }
}

; =====================================================
; PREENCHER PLANILHA DE MANUTENÇÃO E ABRIR ROTAS
; =====================================================

F7::{
    global F7_EmExecucao, F7_Cancelar, F7_CancelamentoAvisado

    ; Se já estiver executando, solicita o cancelamento.
    if F7_EmExecucao {
        F7_Cancelar := true
        return
    }

    F7_EmExecucao := true
    F7_Cancelar := false
    clipboardOriginal := ClipboardAll()

    try {

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


    if RegExMatch(
        textoOS,
        "i)\b(?:HORA|PER[IÍ]ODO(?:[ \t]+AGENDADO)?)[ \t]*:[ \t]*([^\r\n]+)",
        &mHora
    ) {
        periodoOriginal := Trim(mHora[1])
        periodo := ObterPeriodoF7(periodoOriginal)

        if (periodo = "")
            periodo := "QUALQUER HORARIO"

    } else {
        periodo := "QUALQUER HORARIO"
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
    F7Aguardar(50)
    Send "^v"
    F7Aguardar(220)
    Send "{Tab}"
    F7Aguardar(50)

    ; LOCALIZAÇÃO / LOGIN
    A_Clipboard := login
    F7Aguardar(50)
    Send "^v"
    F7Aguardar(120)
    Send "{Tab}"
    F7Aguardar(50)

    ; DATA DE ABERTURA
    A_Clipboard := dataAbertura
    F7Aguardar(70)
    Send "^v"
    F7Aguardar(120)
    Send "{Tab}"

    ; PERÍODO
    A_Clipboard := periodo
    F7Aguardar(50)
    Send "^v"
    F7Aguardar(120)
    Send "{Tab}"
    F7Aguardar(50)

    ; CAUSA
    A_Clipboard := causa
    F7Aguardar(50)
    Send "^v"
    F7Aguardar(150)

    F7VerificarCancelamento()

    ; PULA ATÉ A COLUNA REGIÃO
    F7Aguardar(150)
    Send "{Tab 5}"
    Send "{Enter}"

    ; ---------------------------------------------
    ; FASE 2 - ACESSA ROTAS SUPORTE
    ; ---------------------------------------------

    EnviarEnderecoParaRotas(endereco, true)

    } catch as erro {

        if (erro.Message = "F7_CANCELADO") {
            TocarSom("alert2.mp3")
            MostrarAviso("⚠️ Execução do F7 interrompida.")
        } else {
            throw erro
        }

    } finally {
        A_Clipboard := clipboardOriginal
        F7_EmExecucao := false
        F7_Cancelar := false
    }
}

; =====================================================
; FUNÇÕES AUXILIARES PARA O F7
; =====================================================

; VERIFICA SE O F7 FOI CANCELADO
F7VerificarCancelamento() {
    global F7_Cancelar

    if F7_Cancelar
        throw Error("F7_CANCELADO")
}

; ESPERA COM VERIFICAÇÃO DE CANCELAMENTO
F7Aguardar(tempo) {
    inicio := A_TickCount

    while ((decorrido := A_TickCount - inicio) < tempo) {
        F7VerificarCancelamento()
        Sleep Min(25, tempo - decorrido)
    }

    F7VerificarCancelamento()
}

F7FoiCancelado() {
    global F7_Cancelar, F7_CancelamentoAvisado

    if !F7_Cancelar
        return false

    if !F7_CancelamentoAvisado {
        F7_CancelamentoAvisado := true
        TocarSom("alert2.mp3")
        MostrarAviso("⚠️ Execução do F7 interrompida.")
    }

    return true
}

; ENVIA ENDEREÇO PARA ROTAS SUPORTE
EnviarEnderecoParaRotas(endereco, planilhaPreenchida := false) {

    ; ---------------------------------------------
    ; MANTÉM O ENDEREÇO NA ÁREA DE TRANSFERÊNCIA
    ; ---------------------------------------------

    F7VerificarCancelamento()
    A_Clipboard := endereco
    F7Aguardar(500)

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
        F7VerificarCancelamento()

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

    F7Aguardar(500)

    ; ---------------------------------------------
    ; FECHA EVENTUAL JANELA DE ATALHOS DO MAPA
    ; ---------------------------------------------

    Send "{Esc}"
    F7Aguardar(150)

    ; ---------------------------------------------
    ; OCR - VERIFICA SE EXISTE COMPARTILHAR
    ; ---------------------------------------------

    temCompartilhar := false

    try {
        resultadoRotas := OCR.FromRect(
            0,
            0,
            Min(510, A_ScreenWidth),
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

        Click 270, 850
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

        F7VerificarCancelamento()
        Click 270, 850
        F7Aguardar(200)
        Send "Tab"
        Send "{Enter}"
        F7Aguardar(200)

        F7VerificarCancelamento()
        Click 270, 850
        Send "+{Tab}"
        F7Aguardar(150)
        Send "+{Tab}"
        F7Aguardar(150)
        Send "{Enter}"
        F7Aguardar(200)

        F7VerificarCancelamento()
        A_Clipboard := endereco
        Send "^v"
        F7Aguardar(500)
        F7VerificarCancelamento()
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
ObterCausaF7(texto) {
    c := NormalizarTextoF7(texto)

    ; ---------------------------------------------
    ; IDENTIFICA A PRIMEIRA CAUSA MENCIONADA
    ; ---------------------------------------------

    padrao := "i)("
    padrao .= "HOME HELP|"
    padrao .= "RECHAMADO NIVEL 2|RECHAMADO|"
    padrao .= "INCLUSAO DE ROTEADOR|UPGRADE|INCLUIR SEGUNDO PONTO|"
    padrao .= "TROCAR[ \t]+(?:O[ \t]+)?(?:ROTEADOR|REPETIDOR)|"
    padrao .= "(?:TROCAR|ALTERAR)[^\r\n]*SENHA|"
    padrao .= "MUDAR O ROTEADOR|MUDANCA DE PONTO|MUDAR O PONTO|"
    padrao .= "LENTI|OSCIL|INSTAB|QUEDA|CAINDO|"
    padrao .= "SEM CONEXAO|SEM INTERNET|\bLOS\b|SEM SINAL|"
    padrao .= "PROBLEMA[^\r\n]*REPETIDOR|REPETIDOR[^\r\n]*PROBLEMA|SEGUNDO PONTO|MESH"
    padrao .= ")"

    if !RegExMatch(c, padrao, &mCausa)
        return "OUTROS"

    causaEncontrada := mCausa[1]

    ; ---------------------------------------------
    ; CONVERTE A EXPRESSÃO ENCONTRADA EM CAUSA
    ; ---------------------------------------------

    if InStr(causaEncontrada, "HOME HELP")
        return "HOME HELP"

    if InStr(causaEncontrada, "RECHAMADO") && InStr(causaEncontrada, "NIVEL 2")
        return "RECHAMADO NIVEL 2"

    if InStr(causaEncontrada, "RECHAMADO")
        return "RECHAMADO"

    if InStr(causaEncontrada, "INCLUSAO") || InStr(causaEncontrada, "UPGRADE") || InStr(causaEncontrada, "INCLUIR SEGUNDO PONTO")
        return "INCLUSAO DE ROTEADOR"

    if InStr(causaEncontrada, "TROCAR") && (InStr(causaEncontrada, "ROTEADOR") || InStr(causaEncontrada, "REPETIDOR"))
        return "TROCA DE ROTEADOR"

    if InStr(causaEncontrada, "SENHA")
        return "TROCA DE SENHA"

    if InStr(causaEncontrada, "MUDAR") || InStr(causaEncontrada, "MUDANCA DE PONTO")
        return "MUDANÇA DE PONTO"

    if InStr(causaEncontrada, "LENTI") || InStr(causaEncontrada, "OSCIL") || InStr(causaEncontrada, "INSTAB")
        return "LENTIDÃO"

    if InStr(causaEncontrada, "QUEDA") || InStr(causaEncontrada, "CAINDO")
        return "QUEDAS"

    if InStr(causaEncontrada, "SEM CONEXAO") || InStr(causaEncontrada, "SEM INTERNET") || InStr(causaEncontrada, "LOS") || InStr(causaEncontrada, "SEM SINAL")
        return "SEM CONEXÃO"

    return "OUTROS"
}
;=======================================
; ENVIO DO PROTOCOLO COM MENSAGEM PADRÃO
;=======================================

; PROTOCOLO COM BLOQUEIO FINANCEIRO
!b::{
    clipboardOriginal := A_Clipboard
    protocolo := Trim(A_Clipboard)

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ O texto copiado não parece ser um protocolo válido.")
        return
    }

    texto := "Verifiquei que sua conexão entrou em bloqueio automático devido a mensalidade em aberto. Vou te transferir para o setor responsável. Segue o protocolo: " protocolo

    A_Clipboard := texto
    Sleep 50
    Send "^v"
    Sleep 50

    A_Clipboard := clipboardOriginal
}
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
    clipboardOriginal := A_Clipboard
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
    Sleep 50

    A_Clipboard := clipboardOriginal
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

    clipboardOriginal := A_Clipboard
    protocolo := Trim(A_Clipboard)

    if (!RegExMatch(protocolo, "^20\d+$")) {
        MostrarAviso("❌ Copie um protocolo válido antes de usar esta função.")
        return
    }

    texto := MontarMensagemFinalizacao(protocolo)

    A_Clipboard := texto

    Sleep 50

    TocarSom("Protocol.mp3")
    Send "^v"
    Sleep 50

    A_Clipboard := clipboardOriginal

}
;=======================================
; FRASEOLOGIAS
;=======================================

; MOMENTO PARA VERIFICAÇÃO
>^a::{
    global MensagensFraseologias
    SendText MensagensFraseologias[1]
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
;SOLICITAR CPF/CNPJ
!c::{
    global MensagensFraseologias
    SendText MensagensFraseologias[2]
}
;CPF/CNPJ NÃO ENCONTRADO
<^>!c::{
    global MensagensFraseologias
    SendText MensagensFraseologias[3]
}
; PEDIR FOTOS DOS EQUIPAMENTOS
!f::{
    global MensagensFraseologias
    SendText MensagensFraseologias[4]
}
; CHAMADO JÁ ABERTO
<^>!j::{
    global MensagensFraseologias
    SendText MensagensFraseologias[5]
}
; EXPLICAÇÃO DO LOS
<^>!l::{
    global MensagensFraseologias

    clipboardOriginal := A_Clipboard
    texto := MensagensFraseologias[6]

    A_Clipboard := texto
    Sleep 50
    Send "^v"
    Sleep 50

    A_Clipboard := clipboardOriginal
    MostrarAviso("✓ Mensagem de LOS enviada!")
}
; PERGUNTA COMPLETA
<^>!o::{
    global MensagensFraseologias
    SendText MensagensFraseologias[7]
}
; PRAZO DE FALHA
<^>!p::{
    global MensagensFraseologias
    SendText MensagensFraseologias[8]
}
; CLIENTE RELATOU QUEDAS MAS A CONEXÃO RETORNOU
<^>!v::{
    global MensagensFraseologias
    SendText MensagensFraseologias[9]
}
; CLIENTE RELATOU QUEDAS MAS A CONEXÃO ESTÁ NORMAL
!v::{
    global MensagensFraseologias
    SendText MensagensFraseologias[10]
}
; FINALIZAÇÃO DE ATENDIMENTO
!x::{
    global MensagensFraseologias
    SendText MensagensFraseologias[11]
}
; TENTATIVA DE RETORNO DO CLIENTE
>^SC073::{
    global MensagensFraseologias
    SendText MensagensFraseologias[12]
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
    clipboardOriginal := A_Clipboard
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
    Sleep 50

    A_Clipboard := clipboardOriginal
}

; ============================================================
; FUNÇÃO PARA 24h / 48h / 72h
; ============================================================

EnviarMensagemPrazo(prazo){
    clipboardOriginal := A_Clipboard
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
    Sleep 50

    A_Clipboard := clipboardOriginal
}

; ============================================================
; PREENCHIMENTO DE O.S.
; ============================================================

!1::PreencherOS(1)
!2::PreencherOS(2)
!3::PreencherOS(3)
!4::PreencherOS(4)
!5::PreencherOS(5)
!6::PreencherOS(6)
!7::PreencherOS(7)

PreencherOS(numero) {
    global MensagensOS

    TocarSom("O.S.Filling.mp3")
    SendText MensagensOS[numero]
}

; ============================================================
; PASSO A PASSOS E LISTAS
; ============================================================

; ATIVAÇÃO HBO MAX
AppsKey & h::{
    clipboardOriginal := A_Clipboard

    ; Procura um e-mail no conteúdo copiado
    email := ""

    if RegExMatch(
        clipboardOriginal,
        "i)[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}",
        &correspondenciaEmail
    ){
        email := correspondenciaEmail[0]
    }

    ; ---------------------------------------------
    ; DEFINE A LINHA DO PASSO 2
    ; ---------------------------------------------

    if (email != ""){
        linhaEmail := "Entre utilizando seu e-mail cadastrado: " email
    } else {
        linhaEmail := "Entre utilizando seu e-mail cadastrado"
    }

    ; ---------------------------------------------
    ; MONTA O PASSO A PASSO
    ; ---------------------------------------------

    texto := "
    (
    *Como ativar sua HBO Max™ pela Watch Brasil (ativação é feita apenas uma vez)*

    Passo 1: Acesse a Watch Brasil: https://play.watch.tv.br/ative
    Passo 2: [LINHA_EMAIL]
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

    ; Substitui o marcador pela linha correspondente
    texto := StrReplace(texto, "[LINHA_EMAIL]", linhaEmail)

    ; ---------------------------------------------
    ; COPIA E ENVIA
    ; ---------------------------------------------

    A_Clipboard := texto
    Sleep 50
    Send "^v"
    Sleep 50

    A_Clipboard := clipboardOriginal

    ; ---------------------------------------------
    ; AVISO FINAL
    ; ---------------------------------------------

    if (email != ""){
        MostrarAviso("✓ Instruções de ativação HBO Max")
    } else {
        TocarSom("alert2.mp3")
        MostrarAviso(
            "⚠️ Passo a passo enviado, porém sem o e-mail do cliente.",
            5
        )
    }
}
; ATIVAÇÃO DISNEY+
AppsKey & d::{
    clipboardOriginal := A_Clipboard

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
    Sleep 50

    A_Clipboard := clipboardOriginal


    MostrarAviso("✓ Instruções de ativação Disney+")
}
; ACESSO AO ROTEADOR
AppsKey & r::{

    clipboardOriginal := A_Clipboard

    global SA_UsuarioRoteador, SA_SenhaRoteador

    texto := "
    (
    *Como acessar o roteador:*

    1- Abra qualquer navegador em algum aparelho que esteja conectado na rede Wi-Fi ou por cabo de rede.

    2- Digite o número de IP 192.168.1.1 e pressione Enter até abrir a tela de login do roteador.

    )" . "3- Coloque o nome de usuário '" SA_UsuarioRoteador "' e a senha de acesso '" SA_SenhaRoteador "'."


    A_Clipboard := texto
    Sleep 50
    Send "^v"
    Sleep 50

    A_Clipboard := clipboardOriginal

    MostrarAviso("✓ Instruções de acesso ao roteador enviadas!")
}
AppsKey & u::{

    clipboardOriginal := A_Clipboard

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
    Sleep 50

    A_Clipboard := clipboardOriginal

    MostrarAviso("✓ Ativação de Ubook!")
}
AppsKey & q::{

    clipboardOriginal := A_Clipboard

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
    Sleep 50

    A_Clipboard := clipboardOriginal

    MostrarAviso("✓ validação de quedas enviada!")
}
; ============================================================
; MENSAGEMS TEMPORÁRIA
; ============================================================

; PRIMEIRA FRASE
!w::{
    global frase1
    clipboardOriginal := A_Clipboard

    A_Clipboard := frase1
    Sleep 50
    Send "^v"
    Sleep 50

    A_Clipboard := clipboardOriginal
    TocarSom("alert.mp3")
    MostrarAviso("✓ Mensagem temporária 1 enviada!")
}
!y::{
    global frase2
    clipboardOriginal := A_Clipboard

    A_Clipboard := frase2
    Sleep 50
    Send "^v"
    Sleep 50

    A_Clipboard := clipboardOriginal
    TocarSom("alert.mp3")
    MostrarAviso("✓ Mensagem temporária 2 enviada!")
}
!z::{
    global frase3
    clipboardOriginal := A_Clipboard

    A_Clipboard := frase3
    Sleep 50
    Send "^v"
    Sleep 50

    A_Clipboard := clipboardOriginal
    TocarSom("alert.mp3")
    MostrarAviso("✓ Mensagem temporária 3 enviada!")
}