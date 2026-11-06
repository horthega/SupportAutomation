;=========================
; CONFIGURAÇÕES PESSOAIS
;=========================

NomeAtendente := ""

; ============================================================
; MENSAGEM DE FINALIZAÇÃO DO PROTOCOLO
; ============================================================

MensagemFinalizacao := "
(
Qualquer necessidade, é só nos chamar novamente. Segue o protocolo:
)"

; MONTA A MENSAGEM FINAL COM O PROTOCOLO
MontarMensagemFinalizacao(protocolo) {
    global MensagemFinalizacao

    texto := Trim(MensagemFinalizacao)

    if (texto = "")
        return "Protocolo: " . protocolo

    ; Mantém compatibilidade com mensagens antigas.
    if InStr(texto, "{PROTOCOLO}")
        return StrReplace(texto, "{PROTOCOLO}", protocolo)

    ; Procura "Protocolo:" sem atravessar quebras de linha.
    if RegExMatch(texto, "i)protocolo(?:[ \t]+(?:do|deste)[ \t]+atendimento)?[ \t]*:", &m) {
        fimCabecalho := m.Pos + m.Len - 1

        ; Insere o número na mesma linha do cabeçalho.
        return SubStr(texto, 1, fimCabecalho)
            . " " . protocolo
            . SubStr(texto, fimCabecalho + 1)
    }

    ; Se não houver cabeçalho, acrescenta o protocolo ao final.
    return texto . "`r`n`r`nProtocolo: " . protocolo
}

; ============================================================
; MENSAGEMS TEMPORÁRIA
; ============================================================

; Alt + W:
frase1 := "Vi aqui e está tudo certo com sua visita técnica, somente aguardar que o técnico entrará em contato quando estiver indo ao local"

; Alt + Y:
frase2 := "Passado prazo para o cliente"

; Alt + Z:
frase3 := "Cliente estava na falha"