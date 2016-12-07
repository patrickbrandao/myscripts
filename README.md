# myscripts
Meus scripts facilitadores


MyScripts

	Scripts utilitarios que sao usados como programas no shell

Como instalar
----------------------------------------------------------------------------------------
	Baixa o projeto, entre na pasta descompactada e execute:
	sh _make.sh


Comandos a serem instalados
----------------------------------------------------------------------------------------

	depcheck.sh -> depcheck
			Verificar dependencias de binarios e verificar se essas dependencias existem
			Usado para verificar a coerencia de um pacote e dos binarios instalados


	dezip.sh -> dezip
			Informe o nome do arquivo compactado e em qual pasta deseja descompactar.

	duptester.sh
			Verificar arquivos duplicados em pastas e ficheiros

	getmd5sum.sh -> getmd5sum
			Retorna md5 do arquivo

	getsha256sum.sh -> getsha256
			Retorna hash sha do arquivo

	http-sync.sh -> http-sync
			Sincronizar arquivo remoto com arquivo local via http (requer arquivo .md5 no servidor)

	lsfiles.sh -> lsfiles
			Lista todos os arquivos em uma pasta, recursivamente

	portclose.sh -> portclose
			Procura qual processo e' responsavel por abrir uma porta tcp/udp e extermina-o
			(canditado a ser transformado em C)

	strmd5.sh -> strmd5
			Retorna o hash md5 de uma string (parametro 1)

	ziplist.sh -> ziplist
			Lista arquivos em um ficheiro compactado

	sh-to-base64run.sh -> sh-to-base64run
			Converter shell-script em script obfuscado e codificado
			Requer que o SHC esteja instalado (https://github.com/neurobin/shc)
			Forma de usar:
			sh-to-base64run -f (input-script) -o (output-script) -R (relative-root-path)
			
			Exemplo:
			sh-to-base64run -f /root/meuscript.sh -o /root/meuscript-codificado.sh -R /

