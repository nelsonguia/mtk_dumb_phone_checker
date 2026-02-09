#!/bin/bash

# Título do programa
# Versão 1.4
# Versão portuguesa
echo ""
echo "##########################"
echo "# MTK dumb phone checker #"
echo "##########################"
echo ""
echo "O_o Nelson Guia o_O"
echo ""

# Pausa para que o título seja visível
sleep 2

# Função para verificar o dispositivo (MediaTek)
check_device() {
    local product_found=false
    local non_mtk_found=false

    # Captura do sinal SIGINT (Ctrl+c) interrompe a monitorização para voltar ao menu principal
    trap 'echo ""; echo "Monitorização interrompida. Regressando ao menu principal..."; sleep 1; show_menu' INT

    # Monitoriza os logs
    while read -r line; do
        # Verifica se o dispositivo conectado tem um chip MediaTek
        if [[ "$line" =~ "idVendor=0e8d" || "$line" =~ "idVendor=08ed" ]]; then
            echo "#############################################################################################################"
            echo "O dispositivo tem um chip MediaTek Inc."
            product_found=true
        else
            # Marca como dispositivo não encontrado, caso o dispositivo não seja MediaTek
            if [[ "$line" =~ "idVendor" ]]; then
                non_mtk_found=true
            fi
        fi

        # Exibe a linha do log que contém "idProduct"
        if [[ "$line" =~ "idProduct" ]]; then
            echo "$line"
        fi

        # Se um dispositivo MediaTek for encontrado, exibe informações adicionais
        if $product_found; then
            {
                # Monitoriza o log do kernel durante 15 segundos ou até encontrar a linha que contém "Product:"
                timeout -s 15 15 tail -f /var/log/kern.log | grep -m 1 -i "Product:" | while read -r product_line; do
                    echo "$product_line"
                    break
                done
            } &
            local tail_pid=$!
            wait $tail_pid 2>/dev/null

            # Lista os dispositivos USB conectados e exibe a linha que contém "MediaTek"
            lsusb | grep -i "MediaTek"
            echo "#############################################################################################################"
            break  # Interrompe o loop após encontrar e exibir as informações
        fi

        # Se encontrar um dispositivo que não é MediaTek, interrompe a verificação e exibe a informação Nenhum dispositivo MediaTek encontrado
        if $non_mtk_found && [ "$product_found" = false ]; then
            echo ""
            echo "###########################################"
            echo "# Nenhum dispositivo MediaTek encontrado. #"
            echo "###########################################"
            echo ""
            break
        fi
    done < <(journalctl -kf)
}

# Função para confirmar idVendor via dmesg
confirm_idvendor() {
    local spreadtrum_found=false
    local other_found=false
    local vendor_line=""
    local mfr_line=""
    local vendor_value=""

    # Ctrl+C volta ao menu
    trap 'echo ""; echo "Monitorização interrompida. Regressando ao menu principal..."; sleep 1; show_menu' INT

    echo ""
    echo "=============================================="
    echo "= A limpar o buffer do dmesg (sudo dmesg -C) ="
    echo "=============================================="
    echo ""
    sudo dmesg -C

    echo "============================================================="
    echo "= À escuta do dmesg (sudo dmesg -w). Ligue o dispositivo... ="
    echo "= Para voltar ao menu, pressione Ctrl+C                     ="
    echo "============================================================="
    echo ""

    # É lido o dmesg -w com timeout para dar feedback caso nada apareça
    # (pode-se ajustar o 15 para mais/menos segundos)
    while read -r line; do
        # Capturar a primeira ocorrência de idVendor=
        if [[ -z "$vendor_line" && "$line" =~ idVendor=([0-9a-fA-F]{4}) ]]; then
            vendor_value="${BASH_REMATCH[1]}"
            vendor_line="$line"

            if [[ "${vendor_value,,}" == "1782" ]]; then
                spreadtrum_found=true
            else
                other_found=true
            fi
        fi

        # Capturar a primeira ocorrência de Mfr=
        if [[ -z "$mfr_line" && "$line" =~ Mfr= ]]; then
            mfr_line="$line"
        fi

        # Se já se tem idVendor e Mfr, pode-se decidir e terminar
        if [[ -n "$vendor_line" && -n "$mfr_line" ]]; then
            if $spreadtrum_found; then
                echo ""
                echo "###########################################"
                echo "#    Dispositivo Spreadtrum encontrado.   #"
                echo "###########################################"
                echo ""
                echo "$vendor_line"
                echo "$mfr_line"
                break
            elif $other_found; then
                echo ""
                echo "#######################################################"
                echo "# Foi detetado o dispositivo com o seguinte idVendor  #"
                echo "#######################################################"
                echo ""
                echo "$vendor_line"
                echo "$mfr_line"
                break
            fi
        fi

    done < <(timeout 15 sudo dmesg -w)

    # Se sair do timeout sem apanhar idVendor=
    if [[ -z "$vendor_line" ]]; then
        echo ""
        echo "############################################################"
        echo "#   Não foram detetados dispositivos, repita a pesquisa.   #"
        echo "############################################################"
        echo ""
        return
    fi

    # Se apanhar idVendor= mas não apanhar Mfr= dentro do tempo, mostra-se o que se tem
    if [[ -n "$vendor_line" && -z "$mfr_line" ]]; then
        if [[ "${vendor_value,,}" == "1782" ]]; then
            echo ""
            echo "###########################################"
            echo "#    Dispositivo Spreadtrum encontrado.   #"
            echo "###########################################"
            echo ""
            echo "$vendor_line"
            echo "(Não foi detetada nenhuma linha com Mfr= no período de escuta.)"
        else
            echo ""
            echo "#######################################################"
            echo "#  Foi detetado o dispositivo com seguinte idVendor   #"
            echo "#######################################################"
            echo ""
            echo "$vendor_line"
            echo "(Não foi detetada nenhuma linha com Mfr= no período de escuta.)"
        fi
    fi
}

# Função para exibir o menu e iniciar a verificação do dispositivo
show_menu() {
    while true; do
        clear
        echo ""
        echo "##########################"
        echo "# MTK dumb phone checker #"
        echo "##########################"
        echo ""
        echo "Selecione uma opção:"
        echo "1) Iniciar pesquisa para verificar se é um dispositivo MediaTek"
        echo "2) Forçar a limpeza de logs para nova pesquisa (opção 1)"
        echo "3) Verificar idVendor"
        echo "4) Sair"

        read -rp "Opção: " choice </dev/tty

        case $choice in
            1)
                echo ""
                echo "Para interromper a pesquisa e regressar ao menu principal, pressione as teclas 'Ctrl+C'"
                echo ""
                echo "============================================================"
                echo "= Ligue o telemóvel ao computador através do cabo USB e    ="
                echo "= aguarde o mesmo iniciar o carregamento... Se necessário, ="
                echo "= desligue o cabo, aguarde um pouco e volte a ligar....    ="
                echo "============================================================"
                echo ""
                check_device
                echo ""
                read -rp "Pressione Enter para voltar ao menu..."
                ;;
            2)
                echo ""
                echo "==================================="
                echo "= Realizando a limpeza de logs... ="
                echo "==================================="
                echo ""
                sudo journalctl --rotate
                sudo journalctl --vacuum-time=1s
                echo ""
                echo "================================================"
                echo "= Logs apagados, pode realizar nova pesquisa   ="
                echo "= para verificar se é um dispositivo MediaTek. ="
                echo "================================================"
                echo ""
                read -rp "Pressione Enter para voltar ao menu..."
                ;;
            3)
                confirm_idvendor
                echo ""
                read -rp "Pressione Enter para voltar ao menu..."
                ;;
            4)
                echo ""
                echo "Saindo... Até breve!"
                echo ""
                exit
                ;;
            *)
                echo "Opção inválida. Por favor, escolha uma opção válida."
                read -rp "Pressione Enter para continuar..."
                ;;
        esac
    done
}

# Inicia o menu
show_menu
