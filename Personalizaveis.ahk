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

; ============================================================
; MENSAGENS DE PREENCHIMENTO DE O.S.
; ============================================================

global MensagensOS := Map(
    1, "Cliente com lentidão. Feito procedimento remoto e voltou ao normal",
    2, "Cliente contestou a velocidade, foi dado as devidas explicações e o mesmo compreendeu",
    3, "Cliente solicitou uma posição do seu atendimento, foi solicitado prioridade passado previsão para o cliente",
    4, "Cliente falou que a conexão voltou/normalizou",
    5, "Conexão do cliente voltou/normalizou após reinício do roteador",
    6, "Foi explicado para o cliente sobre às redes 2.4G e 5G",
    7, "Foi setado o DNS do google 8.8.8.8 e 8.8.4.4"
)

; ============================================================
; MENSAGENS DE FRASEOLOGIAS
; ============================================================

global MensagensFraseologias := Map(
    1, "Aguarde um momento enquanto verifico por gentileza",

    2, "Poderia, por gentileza, me informar o CPF/CNPJ do contrato?",

    3, "Por gentileza, poderia verificar se o CPF/CNPJ informado está correto. Não consegui localizá-lo em nossa base.",

    4, "Poderia me enviar fotos dos equipamentos da LinQ por favor para eu verificar as luzes dele?",

    5, "Já tem um chamado em aberto, somente aguardar que o técnico entrará em contato quando estiver indo ao local.",

    6, "A luz vermelha (LOS) acesa indica algum problema na fibra que pode estar rompida ou dobrada.`n`nComo existem diferentes possíveis causas, será aberta uma solicitação de visita técnica para verificação no local e identificar a origem do problema.`n`nO prazo de execução é de até 24 horas.",

    7, "O que você estava acessando na internet na hora que percebeu esse problema? Se puder me dar um exemplo na prática, pois isso ajuda a entender melhor a situação, a verificar e poder resolver.",

    8, "Prazo de normalização até às ",

    9, "Verifiquei aqui em nosso sistema e consta que a sua conexão retornou, verifique se está normal agora, por favor",

    10, "Verifiquei aqui em nosso sistema e consta que a sua conexão está normal, está aparecendo algum erro de rede? É em todos os dispositivos? Se for possível me enviar uma foto, melhor ainda!",

    11, "Auxilio você em algo mais no momento?",

    12, "Olá, você ainda está aí? 🤔"
)