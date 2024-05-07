#!/bin/bash

# Título do programa
echo ""
echo "##########################"
echo "# MTK dumb phone checker #"
echo "##########################"
echo ""
echo "O_o Nelson Guia o_O"
echo ""

# Pausa para que o título seja visível
sleep 1

# Função para verificar se o dispositivo contém "idVendor=0e8d" ou "idVendor=08ed" e relatar se é um dispositivo MediaTek
check_device() {
    local product_found=false

    while read -r line; do
        if [[ "$line" =~ "idVendor=0e8d" || "$line" =~ "idVendor=08ed" ]]; then
            echo "O dispositivo tem um chip MediaTek Inc."
            product_found=true
        elif $product_found && [[ "$line" =~ "Product:" ]]; then
            echo "$line"
            break  # Interrompe o loop após encontrar o produto
        fi
    done < <(journalctl -kf)
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
        echo "2) Forçar a limpeza de logs (se necessário) para nova pesquisa (opção 1)"
        echo "3) Sair"

        read -rp "Opção: " choice

        case $choice in
            1)
                echo ""
                echo "Ligue o telemóvel ao computador através do cabo USB e aguarde este iniciar o carregamento... Se necessário, desligue o cabo e volte a ligar...."
                echo ""
                check_device
                echo ""
                read -rp "Pressione Enter para voltar ao menu..."
                ;;
            2)
                echo "Realizando a limpeza de logs..."
                echo ""
                sudo journalctl --rotate
                sudo journalctl --vacuum-time=1s
                echo ""
                echo "Logs apagados, pode realizar nova pesquisa para verificar se é um dispositivo MediaTek"
                echo ""
                read -rp "Pressione Enter para voltar ao menu..."
                ;;
            3)
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

