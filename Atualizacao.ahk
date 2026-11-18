#Requires AutoHotkey v2.0


; =====================================================
; SUPPORTAUTOMATION - SISTEMA DE ATUALIZAÇÃO
; =====================================================

; Versão atualmente instalada
SA_VersaoAtual := "2.3.0"

; Endereço público do arquivo de controle
SA_UrlManifesto :=
    "https://raw.githubusercontent.com/horthega/SupportAutomation-Releases/main/version.json"

; Estado da janela visual de atualização.
SA_AtualizacaoJanela := 0
SA_PicAtualizar := 0
SA_PicCancelar := 0
SA_BtnAtualizar := 0
SA_BtnCancelar := 0
SA_ImagensAtualizar := Map()
SA_ImagensCancelar := Map()
SA_EstadoAtualizar := ""
SA_EstadoCancelar := ""
SA_CartaoVersao := 0
SA_FundoSelo := 0
SA_ModoTesteAtualizacao := !A_IsCompiled

; Estado da consulta assíncrona do atualizador.
SA_AtualizacaoPID := 0
SA_ArquivoManifesto := ""

; =====================================================
; INICIALIZA A VERIFICAÇÃO
; =====================================================

InicializarAtualizacao() {
    ; Aguarda 3 segundos após a inicialização.
    SetTimer(IniciarConsultaManifesto, -3000)
}

; =====================================================
; INICIA CONSULTA ASSÍNCRONA DO MANIFESTO (IPV4)
; =====================================================

IniciarConsultaManifesto() {
    global SA_UrlManifesto
    global SA_AtualizacaoPID
    global SA_ArquivoManifesto

    SA_ArquivoManifesto :=
        A_Temp
        . "\SA_Manifesto_"
        . A_TickCount
        . ".json"

    try {
        comando :=
            'curl.exe -4 -L --fail --silent --show-error'
            . ' --connect-timeout 5 --max-time 12'
            . ' -o "' SA_ArquivoManifesto '"'
            . ' "' SA_UrlManifesto '"'

        Run(
            comando,
            ,
            "Hide",
            &SA_AtualizacaoPID
        )

        SetTimer(VerificarConclusaoManifesto, 250)

    } catch as erro {
        ; Falha silenciosa na consulta.
    }
}

; =====================================================
; VERIFICA CONCLUSÃO DA CONSULTA
; =====================================================

VerificarConclusaoManifesto() {
    global SA_AtualizacaoPID
    global SA_ArquivoManifesto

    if ProcessExist(SA_AtualizacaoPID)
        return

    SetTimer(VerificarConclusaoManifesto, 0)

    json := ""

    try {
        if FileExist(SA_ArquivoManifesto)
            json := FileRead(SA_ArquivoManifesto, "UTF-8")
    } catch as erro {
        ; Falha na leitura do manifesto.
    }

    try {
        if FileExist(SA_ArquivoManifesto)
            FileDelete(SA_ArquivoManifesto)
    }

    SA_AtualizacaoPID := 0
    SA_ArquivoManifesto := ""

    if (json = "")
        return

    ProcessarManifestoAtualizacao(json)
}

; =====================================================
; PROCESSA O MANIFESTO RECEBIDO
; =====================================================

ProcessarManifestoAtualizacao(json) {
    global SA_VersaoAtual, SA_ModoTesteAtualizacao

    try {
        versaoRemota := ExtrairCampoJSONAtualizacao(
            json,
            "version"
        )

        downloadUrl := ExtrairCampoJSONAtualizacao(
            json,
            "download_url"
        )

        novidades := ExtrairCampoJSONAtualizacao(
            json,
            "notes"
        )

        sha256 := ExtrairCampoJSONAtualizacao(
            json,
            "sha256"
        )

        if !RegExMatch(
            versaoRemota,
            "^\d+\.\d+\.\d+$"
        )
            return

        resultadoComparacao := VersaoMaisNova(
            versaoRemota,
            SA_VersaoAtual
        )

        if !resultadoComparacao
            return

        MostrarJanelaAtualizacao(
            versaoRemota,
            novidades,
            downloadUrl,
            sha256,
            SA_ModoTesteAtualizacao
        )

    } catch as erro {
        ; Falha silenciosa no processamento.
    }
}
; =====================================================
; EXTRAI CAMPOS DO JSON
; =====================================================

ExtrairCampoJSONAtualizacao(json, campo) {

    aspas := Chr(34)

    padrao :=
        aspas . campo . aspas
        . "\s*:\s*"
        . aspas
        . "([^" . aspas . "]*)"
        . aspas

    if RegExMatch(json, padrao, &m)
        return m[1]

    return ""
}


; =====================================================
; COMPARA AS VERSÕES
; =====================================================

VersaoMaisNova(remota, atual) {

    partesRemotas := StrSplit(remota, ".")
    partesAtuais := StrSplit(atual, ".")

    Loop 3 {

        numeroRemoto := Integer(partesRemotas[A_Index])
        numeroAtual := Integer(partesAtuais[A_Index])

        if (numeroRemoto > numeroAtual)
            return true

        if (numeroRemoto < numeroAtual)
            return false
    }

    return false
}


; =====================================================
; BAIXA E VALIDA O INSTALADOR
; =====================================================

BaixarEInstalarAtualizacao(
    versao,
    url,
    hashEsperado
) {

    try {

        ; Confere se o endereço corresponde
        ; ao instalador esperado no GitHub
        urlEsperada :=
            "https://github.com/horthega/SupportAutomation-Releases/releases/download/v"
            . versao
            . "/SupportAutomation-Setup-v"
            . versao
            . ".exe"

        if (url != urlEsperada)
            throw Error("Endereço de download inválido.")

        ; Exige uma hash SHA-256 válida
        hashEsperado := StrLower(hashEsperado)

        if !RegExMatch(
            hashEsperado,
            "^[a-f0-9]{64}$"
        ) {
            throw Error(
                "O manifesto não possui uma hash SHA-256 válida."
            )
        }

        ; Caminho temporário do instalador
        caminhoInstalador :=
            A_Temp
            . "\SupportAutomation-Setup-v"
            . versao
            . ".exe"

        try FileDelete(caminhoInstalador)

        ; Baixa o instalador
        Download(
            url,
            caminhoInstalador
        )

        ; Confirma se o arquivo foi baixado
        if !FileExist(caminhoInstalador)
            throw Error("O instalador não foi encontrado após o download.")

        if (FileGetSize(caminhoInstalador) < 100000)
            throw Error("O arquivo baixado parece estar incompleto.")

        ; Calcula a hash do arquivo
        hashObtido := CalcularHashSHA256(
            caminhoInstalador
        )

        ; Compara as hashes
        if (hashObtido != hashEsperado) {

            try FileDelete(caminhoInstalador)

            throw Error(
                "A verificação de integridade falhou. A instalação foi cancelada."
            )
        }

        ; Inicia a instalação
        IniciarInstaladorAtualizacao(
            caminhoInstalador
        )

    } catch as erro {

        MsgBox(
            "Não foi possível concluir a atualização."
            . "`n`n" erro.Message,
            "SupportAutomation",
            "Iconx"
        )
    }
}


; =====================================================
; CALCULA A HASH SHA-256
; =====================================================

CalcularHashSHA256(caminhoArquivo) {

    arquivoSaida :=
        A_Temp
        . "\SA_SHA256_"
        . A_TickCount
        . ".txt"

    comando :=
        A_ComSpec
        . ' /c certutil -hashfile "'
        . caminhoArquivo
        . '" SHA256 > "'
        . arquivoSaida
        . '"'

    codigo := RunWait(
        comando,
        ,
        "Hide"
    )

    if (codigo != 0)
        throw Error("Não foi possível calcular a hash SHA-256.")

    if !FileExist(arquivoSaida)
        throw Error("Arquivo temporário de verificação não encontrado.")

    resultado := FileRead(arquivoSaida)

    try FileDelete(arquivoSaida)

    if !RegExMatch(
        resultado,
        "im)^\s*([a-f0-9]{64})\s*$",
        &mHash
    ) {
        throw Error("Não foi possível interpretar a hash SHA-256.")
    }

    return StrLower(mHash[1])
}


; =====================================================
; INICIA A INSTALAÇÃO E REABRE O PROGRAMA
; =====================================================

IniciarInstaladorAtualizacao(caminhoInstalador) {

    ; Caminho do próprio SupportAutomation
    caminhoPrograma := A_ScriptFullPath

    ; Arquivo temporário auxiliar em PowerShell
    caminhoPowerShell :=
        A_Temp
        . "\SupportAutomation_Update_"
        . A_TickCount
        . ".ps1"

    ; Escapa apóstrofos nos caminhos
    instaladorPS := StrReplace(
        caminhoInstalador,
        "'",
        "''"
    )

    programaPS := StrReplace(
        caminhoPrograma,
        "'",
        "''"
    )

    ; Monta o script auxiliar
    scriptPS := "$ErrorActionPreference = 'Stop'`r`n"

    scriptPS .=
        "$instalador = '" instaladorPS "'`r`n"

    scriptPS .=
        "$programa = '" programaPS "'`r`n"

    scriptPS .=
        "$argumentos = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /CLOSEAPPLICATIONS /NORESTARTAPPLICATIONS'`r`n"

    scriptPS .= "try {`r`n"

    scriptPS .=
        "    Start-Sleep -Seconds 2`r`n"

    scriptPS .=
        "    $processo = Start-Process -FilePath $instalador -ArgumentList $argumentos -Verb RunAs -PassThru -Wait`r`n"

    scriptPS .=
        "    if ($processo.ExitCode -ne 0) { throw 'Falha na instalação.' }`r`n"

    scriptPS .=
        "    Start-Process -FilePath $programa`r`n"

    scriptPS .= "} catch {`r`n"

    ; Se a instalação for cancelada ou falhar,
    ; tenta reabrir a versão anterior.
    scriptPS .=
        "    Start-Process -FilePath $programa`r`n"

    scriptPS .= "} finally {`r`n"

    scriptPS .=
        "    Start-Sleep -Milliseconds 500`r`n"

    scriptPS .=
        "    Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue`r`n"

    scriptPS .= "}`r`n"

    ; Salva o script com codificação Unicode
    FileAppend(
        scriptPS,
        caminhoPowerShell,
        "UTF-16"
    )

    ; Executa o auxiliar em segundo plano
    Run(
        'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' . caminhoPowerShell . '"',
        ,
        "Hide"
    )

    ; Encerra a versão atual para permitir a substituição
    ExitApp()
}

; Atalho temporário para testar a janela durante o desenvolvimento.
; Não fica disponível na versão compilada.
#HotIf !A_IsCompiled
F9::{
    novidades := "
    (

• Aprimoramentos nos atalhos F1, F2, F4, F6 e F7.

• Novo recurso de personalização: agora as fraseologias podem ser customizadas para cada usuário.

• Interface de configurações reformulada, com novos cards, ícones e melhorias de navegação.

• Sistema de atualização automática aprimorado, com verificação de integridade do instalador.
    )"

    MostrarJanelaAtualizacao("2.3.0", novidades, "", "", true)
}
#HotIf


; =====================================================
; JANELA VISUAL DE ATUALIZAÇÃO
; =====================================================

MostrarJanelaAtualizacao(versaoRemota, novidades, downloadUrl, sha256, modoTeste := false) {
    global SA_VersaoAtual
    global SA_AtualizacaoJanela
    global SA_PicAtualizar, SA_PicCancelar
    global SA_BtnAtualizar, SA_BtnCancelar
    global SA_ImagensAtualizar, SA_ImagensCancelar
    global SA_EstadoAtualizar, SA_EstadoCancelar
    global SA_CartaoVersao, SA_FundoSelo

    ; Evita abrir duas janelas de atualização simultaneamente.
    if IsObject(SA_AtualizacaoJanela) {
        try {
            SA_AtualizacaoJanela.Show()
            WinActivate("ahk_id " SA_AtualizacaoJanela.Hwnd)
            return
        }
    }

    janela := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox", "SupportAutomation")
    janela.BackColor := "FFFFFF"
    janela.SetFont("s10", "Segoe UI")
    larguraJanela := 420

    ; Ícone e título
    janela.AddPicture(
        "x20 y25 w32 h32 BackgroundTrans",
        A_ScriptDir "\Imagens\cloud-download.png"
    )

    janela.SetFont("s15 Bold c202124", "Segoe UI")
    janela.AddText(
        "x58 y25 w315 h28",
        "Nova atualização disponível"
    )

    janela.SetFont("s10 norm c404040", "Segoe UI")
    janela.AddText(
        "x58 y60 w340 h35",
        "Atualize o SupportAutomation para continuar com a`nmelhor experiência."
    )

    ; Cartão da versão com fundo e borda GDI+.
    SA_CartaoVersao := CriarBotaoGDI(
        0xFFF5F5F5,
        0xFFDCDCDC,
        380,
        65,
        6,
        0xFFFFFFFF
    )

    janela.AddPicture(
        "x20 y115 w380 h65",
        "HBITMAP:*" SA_CartaoVersao
    )

    janela.SetFont("s12 Bold c202124", "Segoe UI")
    janela.AddText(
        "x35 y125 w235 h25 BackgroundTrans",
        "SupportAutomation " versaoRemota
    )

    ; Selo Nova versão criado com GDI+.
    SA_FundoSelo := CriarBotaoGDI(
        0xFFB8EBCB,
        0,
        90,
        22,
        11,
        0xFFF2F2F2
    )

    janela.AddPicture(
        "x248 y125 w90 h22 BackgroundTrans",
        "HBITMAP:*" SA_FundoSelo
    )

    janela.SetFont("s9 Bold c16834A", "Segoe UI")
    janela.AddText(
        "x248 y125 w90 h22 Center 0x200 BackgroundTrans",
        "Nova versão"
    )

    janela.SetFont("s9 norm c242424", "Segoe UI")
    janela.AddText(
        "x35 y151 w300 h20 BackgroundTrans",
        "Versão atual: " SA_VersaoAtual
    )

    ; Novidades recebidas no manifesto.
    novidades := Trim(StrReplace(novidades, "\n", "`n"))
    if (novidades = "")
        novidades := "• Melhorias e correções do sistema."

    yNovidades := 195

    janela.SetFont("s11 Bold c202124", "Segoe UI")
    janela.AddText(
        "x35 y" yNovidades " w400 h22",
        "O que há de novo?"
    )

    janela.SetFont("s9 norm c303030", "Segoe UI")
    txtNovidades := janela.AddText(
        "x40 y" (yNovidades + 27) " w350",
        novidades
    )

    txtNovidades.GetPos(,,, &alturaNovidades)
    alturaNovidades += 6

    xAtualizar := larguraJanela - 305
    xCancelar := larguraJanela - 115
    yBotoes := yNovidades + 27 + alturaNovidades + 25

    ; Imagens dos estados do botão Atualizar agora.
    SA_ImagensAtualizar := Map(
        "normal", CriarBotaoGDI(0xFF16834A, 0, 180, 38, 6),
        "hover", CriarBotaoGDI(0xFF1B9655, 0, 180, 38, 6),
        "pressed", CriarBotaoGDI(0xFF116B3C, 0, 180, 38, 6)
    )

    SA_PicAtualizar := janela.AddPicture(
        "x" xAtualizar " y" yBotoes " w180 h38",
        "HBITMAP:*" SA_ImagensAtualizar["normal"]
    )

    SA_BtnAtualizar := janela.AddText(
        "x" xAtualizar " y" yBotoes " w180 h38 Center 0x200 BackgroundTrans cFFFFFF",
        "Atualizar agora"
    )
    SA_BtnAtualizar.SetFont("s10 Bold", "Segoe UI")

    SA_BtnAtualizar.OnEvent(
        "Click",
        (*) => ExecutarAtualizacaoPelaJanela(
            janela,
            versaoRemota,
            downloadUrl,
            sha256,
            modoTeste
        )
    )

    ; Imagens dos estados do botão Mais tarde.
    SA_ImagensCancelar := Map(
        "normal", CriarBotaoGDI(0xFFFFFFFF, 0xFFC8CDD2, 100, 38, 6),
        "hover", CriarBotaoGDI(0xFFF3F7F4, 0xFFAAB8AF, 100, 38, 6),
        "pressed", CriarBotaoGDI(0xFFE5EEE8, 0xFF8FA99A, 100, 38, 6)
    )

    SA_PicCancelar := janela.AddPicture(
        "x" xCancelar " y" yBotoes " w100 h38",
        "HBITMAP:*" SA_ImagensCancelar["normal"]
    )

    SA_BtnCancelar := janela.AddText(
        "x" xCancelar " y" yBotoes " w100 h38 Center 0x200 BackgroundTrans c202124",
        "Mais tarde"
    )
    SA_BtnCancelar.SetFont("s9", "Segoe UI")
    SA_BtnCancelar.OnEvent(
        "Click",
        (*) => FecharJanelaAtualizacao(janela)
    )

    ; Guarda a janela e inicializa os estados visuais.
    SA_AtualizacaoJanela := janela
    SA_EstadoAtualizar := "normal"
    SA_EstadoCancelar := "normal"

    janela.OnEvent("Close", FecharJanelaAtualizacao)

    alturaJanela := yBotoes + 38 + 18
    janela.Show("w" larguraJanela " h" alturaJanela " Center")

    SetTimer(MonitorarBotoesAtualizacao, 30)
}


; =====================================================
; EXECUTA A ATUALIZAÇÃO A PARTIR DA JANELA
; =====================================================

ExecutarAtualizacaoPelaJanela(janela, versao, url, sha256, modoTeste := false) {
    FecharJanelaAtualizacao(janela)

    ; No teste visual, não inicia download nem instalação.
    if modoTeste {
        MsgBox(
            "Janela de atualização integrada com sucesso.`n"
            . "O modo de teste não executa download nem instalação.",
            "SupportAutomation",
            "Iconi"
        )
        return
    }

    BaixarEInstalarAtualizacao(
        versao,
        url,
        sha256
    )
}


; =====================================================
; MONITORA HOVER E PRESSIONAMENTO DOS BOTÕES
; =====================================================

MonitorarBotoesAtualizacao() {
    global SA_PicAtualizar, SA_PicCancelar
    global SA_BtnAtualizar, SA_BtnCancelar
    global SA_ImagensAtualizar, SA_ImagensCancelar
    global SA_EstadoAtualizar, SA_EstadoCancelar

    if !IsObject(SA_BtnAtualizar) || !IsObject(SA_BtnCancelar)
        return

    MouseGetPos(,,, &controle, 2)
    pressionado := GetKeyState("LButton", "P")

    novoEstado := "normal"
    if (controle = SA_BtnAtualizar.Hwnd)
        novoEstado := pressionado ? "pressed" : "hover"

    if (novoEstado != SA_EstadoAtualizar) {
        SA_EstadoAtualizar := novoEstado
        SA_PicAtualizar.Value :=
            "HBITMAP:*" SA_ImagensAtualizar[novoEstado]
    }

    novoEstado := "normal"
    if (controle = SA_BtnCancelar.Hwnd)
        novoEstado := pressionado ? "pressed" : "hover"

    if (novoEstado != SA_EstadoCancelar) {
        SA_EstadoCancelar := novoEstado
        SA_PicCancelar.Value :=
            "HBITMAP:*" SA_ImagensCancelar[novoEstado]
    }
}


; =====================================================
; FECHA A JANELA E LIBERA OS BITMAPS
; =====================================================

FecharJanelaAtualizacao(guiObj, *) {
    global SA_AtualizacaoJanela
    global SA_PicAtualizar, SA_PicCancelar
    global SA_BtnAtualizar, SA_BtnCancelar
    global SA_ImagensAtualizar, SA_ImagensCancelar
    global SA_CartaoVersao, SA_FundoSelo
    global SA_EstadoAtualizar, SA_EstadoCancelar

    SetTimer(MonitorarBotoesAtualizacao, 0)

    try guiObj.Destroy()

    ; Libera os HBITMAPs criados para os estados dos botões.
    for imagens in [SA_ImagensAtualizar, SA_ImagensCancelar] {
        if IsObject(imagens) {
            for estado, hBitmap in imagens {
                if hBitmap
                    DllCall("Gdi32\DeleteObject", "Ptr", hBitmap)
            }
        }
    }

    ; Libera o cartão e o selo.
    for hBitmap in [SA_CartaoVersao, SA_FundoSelo] {
        if hBitmap
            DllCall("Gdi32\DeleteObject", "Ptr", hBitmap)
    }

    SA_AtualizacaoJanela := 0
    SA_PicAtualizar := 0
    SA_PicCancelar := 0
    SA_BtnAtualizar := 0
    SA_BtnCancelar := 0
    SA_ImagensAtualizar := Map()
    SA_ImagensCancelar := Map()
    SA_CartaoVersao := 0
    SA_FundoSelo := 0
    SA_EstadoAtualizar := ""
    SA_EstadoCancelar := ""
}


; =====================================================
; CRIA IMAGENS ARREDONDADAS COM GDI+
; =====================================================

CriarBotaoGDI(
    corFundo,
    corBorda,
    largura,
    altura,
    raio := 9,
    corFundoExterno := 0xFFFFFFFF
) {
    static token := 0

    ; Inicializa GDI+ apenas uma vez.
    if !token {
        entrada := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        NumPut("UInt", 1, entrada, 0)

        resultado := DllCall(
            "gdiplus\GdiplusStartup",
            "Ptr*", &token,
            "Ptr", entrada,
            "Ptr", 0
        )

        if resultado != 0
            throw Error("Não foi possível inicializar o GDI+.")
    }

    bitmap := 0
    grafico := 0
    caminho := 0
    pincel := 0
    caneta := 0
    hBitmap := 0

    try {
        resultado := DllCall(
            "gdiplus\GdipCreateBitmapFromScan0",
            "Int", largura,
            "Int", altura,
            "Int", 0,
            "Int", 0x26200A,
            "Ptr", 0,
            "Ptr*", &bitmap
        )

        if resultado != 0
            throw Error("Erro ao criar bitmap.")

        DllCall(
            "gdiplus\GdipGetImageGraphicsContext",
            "Ptr", bitmap,
            "Ptr*", &grafico
        )

        DllCall(
            "gdiplus\GdipSetSmoothingMode",
            "Ptr", grafico,
            "Int", 4
        )

        ; Preenche a área externa com a cor do controle hospedeiro.
        DllCall(
            "gdiplus\GdipGraphicsClear",
            "Ptr", grafico,
            "UInt", corFundoExterno
        )

        DllCall(
            "gdiplus\GdipCreatePath",
            "Int", 0,
            "Ptr*", &caminho
        )

        margem := 0.75
        areaLargura := largura - 1.5
        areaAltura := altura - 1.5
        r := Min(raio, Min(areaLargura, areaAltura) / 2)

        ; Canto superior esquerdo.
        DllCall("gdiplus\GdipAddPathArc",
            "Ptr", caminho,
            "Float", margem, "Float", margem,
            "Float", r * 2, "Float", r * 2,
            "Float", 180, "Float", 90)

        ; Canto superior direito.
        DllCall("gdiplus\GdipAddPathArc",
            "Ptr", caminho,
            "Float", margem + areaLargura - r * 2,
            "Float", margem,
            "Float", r * 2, "Float", r * 2,
            "Float", 270, "Float", 90)

        ; Canto inferior direito.
        DllCall("gdiplus\GdipAddPathArc",
            "Ptr", caminho,
            "Float", margem + areaLargura - r * 2,
            "Float", margem + areaAltura - r * 2,
            "Float", r * 2, "Float", r * 2,
            "Float", 0, "Float", 90)

        ; Canto inferior esquerdo.
        DllCall("gdiplus\GdipAddPathArc",
            "Ptr", caminho,
            "Float", margem,
            "Float", margem + areaAltura - r * 2,
            "Float", r * 2, "Float", r * 2,
            "Float", 90, "Float", 90)

        DllCall("gdiplus\GdipClosePathFigure", "Ptr", caminho)

        DllCall(
            "gdiplus\GdipCreateSolidFill",
            "UInt", corFundo,
            "Ptr*", &pincel
        )

        DllCall(
            "gdiplus\GdipFillPath",
            "Ptr", grafico,
            "Ptr", pincel,
            "Ptr", caminho
        )

        if corBorda {
            DllCall(
                "gdiplus\GdipCreatePen1",
                "UInt", corBorda,
                "Float", 1,
                "Int", 2,
                "Ptr*", &caneta
            )

            DllCall(
                "gdiplus\GdipDrawPath",
                "Ptr", grafico,
                "Ptr", caneta,
                "Ptr", caminho
            )
        }

        DllCall(
            "gdiplus\GdipCreateHBITMAPFromBitmap",
            "Ptr", bitmap,
            "Ptr*", &hBitmap,
            "UInt", corFundoExterno
        )

        return hBitmap
    }
    finally {
        if caneta
            DllCall("gdiplus\GdipDeletePen", "Ptr", caneta)

        if pincel
            DllCall("gdiplus\GdipDeleteBrush", "Ptr", pincel)

        if caminho
            DllCall("gdiplus\GdipDeletePath", "Ptr", caminho)

        if grafico
            DllCall("gdiplus\GdipDeleteGraphics", "Ptr", grafico)

        if bitmap
            DllCall("gdiplus\GdipDisposeImage", "Ptr", bitmap)
    }
}

