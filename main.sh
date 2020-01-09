#!/usr/bin/env bash

#Coletando Cookies
	#Variáveis geradas
		#JSESSIONID=
		#__cfduid=
echo -e "Acessando site...\n"
curl -s -c - http://digital.mflip.com.br | cut -d$'\t' -f 6,7 | tail -n 2 | tr $'\t' '=' > cookies.txt
source cookies.txt
rm cookies.txt


#Login
hash=219679ff68ff2e6612b79757b526e79c #Essa hash é estática
read -p "Login: " login
read -s -p "Senha: " senha

echo -e "\n\nRealizando autenticação...\n"
curl 'http://digital.mflip.com.br/flip/loginEdicaoAssina.do' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:71.0) Gecko/20100101 Firefox/71.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: http://digital.mflip.com.br' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: http://digital.mflip.com.br/pub/senai/?flip=estante2' -H "Cookie: __cfduid=${__cfduid}; JSESSIONID=${JSESSIONID}" --data "existeassina=N&folder=senai&hash=${hash}&json=true&senha=${senha}&username=${login}"


#Mostra as categorias existentes
echo -e "\n\nInforme a categoria de livros que será baixada"
read -p "Pressione ENTER para apresentar as categorias existentes"
curl -s 'https://digital.mflip.com.br/pub/senai/?flip=estante2#!/books/cover' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:71.0) Gecko/20100101 Firefox/71.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'DNT: 1' -H 'Connection: keep-alive' -H "Cookie: __cfduid=${__cfduid}; JSESSIONID=${JSESSIONID}" -H 'Upgrade-Insecure-Requests: 1' -H 'Cache-Control: max-age=0' -H 'TE: Trailers' > categorias.txt
cat categorias.txt | head -n 24 | tail -n 1 | cut -d= -f 2 | json_pp | grep "Série" -B 1 | tr -d '",-' | sed -e 's/id/ID/g' -e 's/nome/Nome/g'
rm categorias.txt


#Baixar lista de livros em determinada categoria
modelo="6"
read -p "ID: " categoria
curl -s "http://digital.mflip.com.br/flip/edicoesByCategorias.do?modelo=${modelo}&categoria=${categoria}&json=true" -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:71.0) Gecko/20100101 Firefox/71.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H 'Referer: http://digital.mflip.com.br/pub/senai/?flip=estante2' -H "Cookie: __cfduid=${__cfduid}; __atuvc=4%7C1; __utma=137643685.1969848357.1571105807.1578159489.1578161219.7; __utmz=137643685.1571105807.1.1.utmcsr=(direct)|utmccn=(direct)|utmcmd=(none); hibext_instdsigdipv2=1; JSESSIONID=${JSESSIONID}" | json_pp > lista.txt


#Filtragem dos livros e IDs existentes
	#Mostra os Livros que serão baixados
	echo -e "\n\nOs seguintes livros serão baixados:\n"
	cat lista.txt | grep 'nome' | tr -d '", ' | cut -d: -f 2
	echo -e "\n"

	#Salva a lista de IDs e Nome de cada livro
	cat lista.txt | grep 'nr' | cut -d: -f 2 | tr -d '"\|, ' > listaID.txt
	cat lista.txt | grep 'nome' | cut -d: -f 2 | tr -d '"\|,' | tr ' ' '_' > listaNome.txt

	#Loop de todos os livros da categoria
		#Arrumar pasta Livro
		l="1"

	while IFS= read -r nr; do

		#Criar pasta para livro
		livro=$(cat listaNome.txt | head -n ${l} | tail -n 1)
		mkdir ${livro}

		#Numerar página
		p="1"

		#Baixar página de um livro
	    curl -s "http://digital.mflip.com.br/pub/senai/?numero=${nr}" -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:71.0) Gecko/20100101 Firefox/71.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Referer: http://digital.mflip.com.br/pub/senai/?flip=estante2' -H 'DNT: 1' -H 'Connection: keep-alive' -H "Cookie: __cfduid=${__cfduid}; JSESSIONID=${JSESSIONID}" -H 'Upgrade-Insecure-Requests: 1' -H 'Cache-Control: max-age=0' -H 'TE: Trailers' > livro.txt

	    #Filtragem das páginas existentes
		cat livro.txt | grep "pageslist\[index++\]" | cut -d\" -f 4 | cut -d/ -f 6 > paginas.txt
		rm livro.txt

		#Armazenar o total de páginas
		totalp="$(wc -l paginas.txt | cut -d\  -f 1)"

			#Baixa cada página do livro
			while IFS= read -r pag; do
    			curl -s -o ${livro}/${p}.jpg "http://digital.mflip.com.br/files/flip/SENAI/${nr}/up/${pag}" -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:71.0) Gecko/20100101 Firefox/71.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Connection: keep-alive' -H "Cookie: __cfduid=${__cfduid}; JSESSIONID=${JSESSIONID};" -H 'Upgrade-Insecure-Requests: 1' -H 'Cache-Control: max-age=0'

    			#Mostra porcentagem do Download
    			progress=$(echo "scale=2;(${p}/${totalp})*100" | bc)
    			echo -ne "Baixando: ${livro} - [ ${progress} % ] \r"
    			eval "p=\$((p + 1))"
			done < paginas.txt

		eval "l=\$((l + 1))"

	done < listaID.txt